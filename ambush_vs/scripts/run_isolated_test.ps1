# Isolated Godot test launcher for ambush_vs (Windows).
# Direct entry without this wrapper must exit 91.
param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBin,
    [string]$Entry = "empty_test.gd"
)

$ErrorActionPreference = "Stop"
$allowed = @("empty_test.gd", "w2_sim_test.gd", "w2_sim_cli.gd", "w3_greybox_test.gd", "w4_scout_test.gd", "w5_combat_fx_test.gd")
if ($allowed -notcontains $Entry) {
    Write-Error "Unsupported test entry for ambush_vs: $Entry"
    exit 2
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runId = [guid]::NewGuid().ToString("N")
$runDir = Join-Path $projectRoot "build/ambush_vs_test_runs/$runId"
$dataRoot = Join-Path $runDir "data"
New-Item -ItemType Directory -Force -Path $dataRoot, (Join-Path $runDir "config"), (Join-Path $runDir "cache") | Out-Null

$previousDataRoot = $env:AMBUSH_TEST_DATA_ROOT
$previousRunId = $env:AMBUSH_TEST_RUN_ID
$previousXdgData = $env:XDG_DATA_HOME
$previousXdgConfig = $env:XDG_CONFIG_HOME
$previousXdgCache = $env:XDG_CACHE_HOME
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA

try {
    $env:AMBUSH_TEST_DATA_ROOT = $dataRoot.Replace('\', '/')
    $env:AMBUSH_TEST_RUN_ID = $runId
    $env:XDG_DATA_HOME = $dataRoot
    $env:XDG_CONFIG_HOME = (Join-Path $runDir "config")
    $env:XDG_CACHE_HOME = (Join-Path $runDir "cache")
    # Godot on Windows uses APPDATA/LOCALAPPDATA for user:// when set.
    $env:APPDATA = $dataRoot
    $env:LOCALAPPDATA = $dataRoot
    Write-Output "TEST_RUN_ID=$runId"
    Write-Output "TEST_DATA_ROOT=$($env:AMBUSH_TEST_DATA_ROOT)"
    Write-Output "TEST_ENTRY=$Entry"
    & $GodotBin --headless --path $projectRoot -s "res://scripts/$Entry" 2>&1 |
        Tee-Object -FilePath (Join-Path $runDir "run.log")
    $exitCode = $LASTEXITCODE
    Write-Output "TEST_LOG=$(Join-Path $runDir 'run.log')"
    Write-Output "TEST_EXIT=$exitCode"
    exit $exitCode
}
finally {
    $env:AMBUSH_TEST_DATA_ROOT = $previousDataRoot
    $env:AMBUSH_TEST_RUN_ID = $previousRunId
    $env:XDG_DATA_HOME = $previousXdgData
    $env:XDG_CONFIG_HOME = $previousXdgConfig
    $env:XDG_CACHE_HOME = $previousXdgCache
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
