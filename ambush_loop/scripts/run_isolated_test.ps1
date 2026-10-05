param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExe,
    [ValidateSet(
        'smoke_test.gd',
        'r45_sweep_gate.gd',
        'm1_height_data_gate.gd',
        'm1_height_los_gate.gd',
        'm1_height_fire_gate.gd',
        'm1_height_coverage_gate.gd',
        'm1_yard_plan_contract_gate.gd',
        'm1_yard_resource_budget_gate.gd',
        'm1_yard_timing_causality_gate.gd',
        'm1_yard_tactical_solutions_gate.gd',
        'm1_yard_end_to_end_gate.gd',
        'm1_yard_visual_evidence_gate.gd',
        'm2_yard_hud_gate.gd',
        'm2_yard_supply_gate.gd',
        'm2_supply_regression_gate.gd',
        'm2_touch_intent_gate.gd',
        'm2_role_dock_gate.gd',
        'm2_i0_3d_seam_gate.gd',
        'm1_ramp_pathfinder_gate.gd',
        'm1_b2_yard_height_gate.gd',
        'accept_cta_flow_gate.gd',
        'feel_gate.gd',
        'playable_dump.gd',
        'visual_dump.gd',
        'storage_probe.gd',
        'eval_dump_0de4f1d.gd',
        'eval_dump_71ca4af.gd',
        'eval_dump_v030.gd',
        'eval_dump_v031.gd',
        'eval_dump_v040.gd',
        'eval_dump_touch_hud.gd'
    )]
    [string]$Entry = 'smoke_test.gd',
    [switch]$ImportOnly,
    [switch]$Rendered
)

$ErrorActionPreference = 'Stop'
if ($Rendered -and ($ImportOnly -or $Entry -notin @('m1_height_coverage_gate.gd', 'm1_yard_visual_evidence_gate.gd', 'm2_yard_hud_gate.gd', 'm2_yard_supply_gate.gd', 'm2_i0_3d_seam_gate.gd'))) {
    throw 'Rendered mode is restricted to the coverage and yard presentation evidence gates.'
}
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$enginePath = [IO.Path]::GetFullPath($GodotExe)
if (-not [IO.File]::Exists($enginePath)) {
    throw "Godot executable not found: $enginePath"
}

$runId = [guid]::NewGuid().ToString('N')
$runParent = Join-Path $projectRoot 'build/ambush_test_runs'
$runDir = Join-Path $runParent $runId
$dataRoot = Join-Path $runDir 'data'
New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
$dataRoot = [IO.Path]::GetFullPath($dataRoot)
$runLog = Join-Path $runDir 'run.log'
$stdoutLog = Join-Path $runDir 'stdout.log'
$stderrLog = Join-Path $runDir 'stderr.log'

# Godot resolves user:// from APPDATA on Windows. Set it before the engine
# process starts so autoloads and the SceneTree script share one private dir.
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousDataRoot = $env:AMBUSH_TEST_DATA_ROOT
$previousRunId = $env:AMBUSH_TEST_RUN_ID
$realDataDir = Join-Path $previousAppData 'Godot/app_userdata/Ambush Loop'
$realSave = Join-Path $realDataDir 'ambush_loop.cfg'
$realSettings = Join-Path $realDataDir 'ambush_loop_settings.cfg'

function Get-ReadOnlyHash([string]$filePath) {
    if (Test-Path -LiteralPath $filePath -PathType Leaf) {
        return (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
    }
    return '<absent>'
}

$beforeSave = Get-ReadOnlyHash $realSave
$beforeSettings = Get-ReadOnlyHash $realSettings
$engineExit = $null
$wrapperExit = 90
try {
    $env:APPDATA = $dataRoot
    $env:LOCALAPPDATA = $dataRoot
    $env:AMBUSH_TEST_DATA_ROOT = $dataRoot.Replace('\', '/')
    $env:AMBUSH_TEST_RUN_ID = $runId
    Write-Output "TEST_RUN_ID=$runId"
    Write-Output "TEST_DATA_ROOT=$dataRoot"
    if ($ImportOnly) {
        Write-Output 'TEST_ENTRY=editor_import'
        $engineArgs = @('--headless', '--editor', '--path', ('"' + $projectRoot + '"'), '--import')
    }
    else {
        Write-Output "TEST_ENTRY=$Entry"
        if ($Rendered) {
            $engineArgs = @('--path', ('"' + $projectRoot + '"'), '-s', "res://scripts/$Entry")
        }
        else {
            $engineArgs = @('--headless', '--path', ('"' + $projectRoot + '"'), '-s', "res://scripts/$Entry")
        }
    }
    # Native stderr must remain evidence, not a terminating PowerShell error.
    $engine = Start-Process -FilePath $enginePath -ArgumentList $engineArgs -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    # Pin the OS handle before waiting (Windows PowerShell 5.1 otherwise loses ExitCode).
    $null = $engine.Handle
    Write-Output "TEST_ENGINE_PID=$($engine.Id)"
    $engine.WaitForExit()
    $engineExit = $engine.ExitCode
    if ($null -eq $engineExit) { throw 'Engine exited without an observable exit code.' }
    $wrapperExit = $engineExit
}
catch {
    Write-Output "TEST_RUNNER_ERROR=$($_.Exception.Message)"
}
finally {
    try {
        # run.log groups stdout then stderr; raw stream files remain authoritative.
        @($stdoutLog, $stderrLog) | ForEach-Object {
            if (Test-Path -LiteralPath $_) { Get-Content -LiteralPath $_ }
        } | Tee-Object -FilePath $runLog
    }
    catch {
        Write-Output "TEST_LOG_ERROR=$($_.Exception.Message)"
        $wrapperExit = 93
    }
    # A log failure must not suppress the independent player-data check.
    try {
        if ((Get-ReadOnlyHash $realSave) -ne $beforeSave -or
            (Get-ReadOnlyHash $realSettings) -ne $beforeSettings) {
            Write-Output 'PLAYER_DATA_UNCHANGED=0'
            Write-Output 'TEST_ISOLATION_BREACH=real player save or settings changed'
            $wrapperExit = 92
        }
        else { Write-Output 'PLAYER_DATA_UNCHANGED=1' }
    }
    catch {
        Write-Output "TEST_POSTCHECK_ERROR=$($_.Exception.Message)"
        $wrapperExit = 93
    }
    finally {
        Write-Output "TEST_ENGINE_EXIT=$engineExit"
        Write-Output "TEST_LOG=$runLog"
        Write-Output "TEST_STDOUT_LOG=$stdoutLog"
        Write-Output "TEST_STDERR_LOG=$stderrLog"
        $env:APPDATA = $previousAppData
        $env:LOCALAPPDATA = $previousLocalAppData
        $env:AMBUSH_TEST_DATA_ROOT = $previousDataRoot
        $env:AMBUSH_TEST_RUN_ID = $previousRunId
    }
}
exit $wrapperExit
