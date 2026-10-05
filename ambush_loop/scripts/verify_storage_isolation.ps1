param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExe,
    [string]$PowerShellExe = (Get-Process -Id $PID).Path
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixtureId = [guid]::NewGuid().ToString('N')
$fixtureDir = Join-Path $projectRoot "build/ambush_test_runs/sentinel_$fixtureId"
$fakeAppData = Join-Path $fixtureDir 'player_appdata'
$fakeSaveDir = Join-Path $fakeAppData 'Godot/app_userdata/Ambush Loop'
New-Item -ItemType Directory -Path $fakeSaveDir -Force | Out-Null
$save = Join-Path $fakeSaveDir 'ambush_loop.cfg'
$settings = Join-Path $fakeSaveDir 'ambush_loop_settings.cfg'
[IO.File]::WriteAllBytes($save, [Text.Encoding]::UTF8.GetBytes("fake player progress $fixtureId"))
[IO.File]::WriteAllBytes($settings, [Text.Encoding]::UTF8.GetBytes("fake player settings $fixtureId"))
$beforeSave = (Get-FileHash -LiteralPath $save -Algorithm SHA256).Hash
$beforeSettings = (Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash
$launcher = Join-Path $PSScriptRoot 'run_isolated_test.ps1'
$probeShell = (Get-Command $PowerShellExe -ErrorAction Stop).Source
$enginePath = [IO.Path]::GetFullPath($GodotExe)
$proc = $null
$child = $null
$previousAppData = $env:APPDATA
$previousProbeMode = $env:AMBUSH_PROBE_MODE

function Assert-SentinelUnchanged {
    if ((Get-FileHash -LiteralPath $save -Algorithm SHA256).Hash -ne $beforeSave -or
        (Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -ne $beforeSettings) {
        throw 'Simulated player save or settings changed.'
    }
}

function Start-Probe([string]$mode) {
    $env:AMBUSH_PROBE_MODE = $mode
    $stdout = Join-Path $fixtureDir "$mode.stdout.log"
    $stderr = Join-Path $fixtureDir "$mode.stderr.log"
    return Start-Process -FilePath $probeShell -ArgumentList @(
        '-NoProfile', '-File', ('"' + $launcher + '"'),
        '-GodotExe', ('"' + [IO.Path]::GetFullPath($GodotExe) + '"'),
        '-Entry', 'storage_probe.gd'
    ) -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
}

function Get-ProbeChild {
    return @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $($proc.Id)" | Where-Object {
        $_.Name -in @('Godot_v4.7.2-stable_win64.exe', 'Godot_v4.7.2-stable_win64_console.exe') -and
        $_.ExecutablePath -eq $enginePath -and
        $_.CommandLine.IndexOf($projectRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $_.CommandLine.Contains('res://scripts/storage_probe.gd')
    })
}

function Assert-ProbeEvidence([string]$mode) {
    $stdout = Join-Path $fixtureDir "$mode.stdout.log"
    if (-not (Select-String -LiteralPath $stdout -SimpleMatch 'PLAYER_DATA_UNCHANGED=1' -Quiet)) {
        throw "Missing final data check for $mode. See $fixtureDir"
    }
    foreach ($key in @('TEST_LOG', 'TEST_STDOUT_LOG', 'TEST_STDERR_LOG')) {
        $line = Select-String -LiteralPath $stdout -Pattern "^$key=" | Select-Object -Last 1
        if ($null -eq $line -or -not (Test-Path -LiteralPath $line.Line.Substring($key.Length + 1))) {
            throw "Missing $key artifact for $mode. See $fixtureDir"
        }
    }
    $exitLine = Select-String -LiteralPath $stdout -Pattern '^TEST_ENGINE_EXIT=' | Select-Object -Last 1
    if ($null -eq $exitLine -or $exitLine.Line -ne "TEST_ENGINE_EXIT=$($proc.ExitCode)") {
        throw "Engine/wrapper exit mismatch for $mode. See $fixtureDir"
    }
    if ($mode -eq 'assertion_failure') {
        $line = Select-String -LiteralPath $stdout -Pattern '^TEST_STDERR_LOG=' | Select-Object -Last 1
        if (-not (Select-String -LiteralPath $line.Line.Substring(16) -SimpleMatch 'PROBE_EXPECTED_ASSERTION_FAILURE' -Quiet)) {
            throw 'Expected failure stderr was not preserved.'
        }
    }
}

try {
    $env:APPDATA = $fakeAppData
    foreach ($mode in @('normal', 'assertion_failure')) {
        $proc = Start-Probe $mode
        $null = $proc.Handle
        if (-not $proc.WaitForExit(45000)) {
            throw "Probe $mode exceeded 45 seconds; wrapper PID=$($proc.Id). See $fixtureDir"
        }
        $expected = if ($mode -eq 'normal') { 0 } else { 42 }
        if ($proc.ExitCode -ne $expected) {
            throw "$mode exited $($proc.ExitCode), expected $expected. See $fixtureDir"
        }
        Assert-SentinelUnchanged
        Assert-ProbeEvidence $mode
        Write-Output "SENTINEL_OK_$mode exit=$($proc.ExitCode)"
    }

    $runParent = Join-Path $projectRoot 'build/ambush_test_runs'
    $proc = Start-Probe 'forced_termination'
    $null = $proc.Handle
    $child = $null
    $probeLog = $null
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $deadline) {
        $matches = @(Get-ProbeChild)
        if ($matches.Count -eq 1) {
            $child = $matches[0]
            break
        }
        if ($matches.Count -gt 1) { throw "Ambiguous probe children for wrapper PID=$($proc.Id)" }
        Start-Sleep -Milliseconds 100
    }
    if ($null -eq $child) {
        throw "Probe child discovery exceeded 15 seconds; wrapper PID=$($proc.Id). See $fixtureDir"
    }
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $deadline) {
        $wrapperLog = Join-Path $fixtureDir 'forced_termination.stdout.log'
        $idLine = Select-String -LiteralPath $wrapperLog -Pattern '^TEST_RUN_ID=([0-9a-f]{32})$' | Select-Object -Last 1
        if ($null -ne $idLine) {
            $candidate = Join-Path $runParent ($idLine.Matches[0].Groups[1].Value + '/stdout.log')
            if ((Test-Path -LiteralPath $candidate) -and
                (Select-String -LiteralPath $candidate -SimpleMatch 'PROBE_WROTE_ISOLATED' -Quiet)) {
                $probeLog = $candidate
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
    if ($null -eq $probeLog) {
        throw "Probe write marker exceeded 15 seconds; wrapper PID=$($proc.Id), child PID=$($child.ProcessId). See $fixtureDir"
    }
    $liveChildren = @(Get-ProbeChild)
    if ($liveChildren.Count -ne 1 -or $liveChildren[0].ProcessId -ne $child.ProcessId) {
        throw 'Probe child identity changed before forced termination.'
    }
    Stop-Process -Id $child.ProcessId -Force
    if (-not $proc.WaitForExit(20000)) {
        throw 'Launcher did not finish after its test child was terminated.'
    }
    if ($proc.ExitCode -eq 0) { throw 'Forced termination was incorrectly reported as success.' }
    Assert-SentinelUnchanged
    Assert-ProbeEvidence 'forced_termination'
    Write-Output "SENTINEL_OK_forced_termination child_pid=$($child.ProcessId) exit=$($proc.ExitCode)"
    Write-Output "SENTINEL_FIXTURE=$fixtureDir"
}
finally {
    # On a failed bound, clean up only children owned by this exact probe wrapper.
    try {
        if ($null -ne $proc -and -not $proc.HasExited) {
            foreach ($owned in @(Get-ProbeChild)) { Stop-Process -Id $owned.ProcessId -Force -ErrorAction SilentlyContinue }
            if (-not $proc.WaitForExit(5000)) { $proc.Kill() }
        }
    }
    finally {
        $env:APPDATA = $previousAppData
        $env:AMBUSH_PROBE_MODE = $previousProbeMode
    }
}
