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
if ($Rendered -and ($ImportOnly -or $Entry -ne 'm1_height_coverage_gate.gd')) {
    throw 'Rendered mode is restricted to the C3 coverage gate.'
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
try {
    $env:APPDATA = $dataRoot
    $env:LOCALAPPDATA = $dataRoot
    $env:AMBUSH_TEST_DATA_ROOT = $dataRoot.Replace('\', '/')
    $env:AMBUSH_TEST_RUN_ID = $runId
    Write-Output "TEST_RUN_ID=$runId"
    Write-Output "TEST_DATA_ROOT=$dataRoot"
    if ($ImportOnly) {
        Write-Output 'TEST_ENTRY=editor_import'
        & $enginePath --headless --editor --path $projectRoot --import 2>&1 |
            Tee-Object -FilePath $runLog
    }
    else {
        Write-Output "TEST_ENTRY=$Entry"
        if ($Rendered) {
            & $enginePath --path $projectRoot -s "res://scripts/$Entry" 2>&1 |
                Tee-Object -FilePath $runLog
        }
        else {
            & $enginePath --headless --path $projectRoot -s "res://scripts/$Entry" 2>&1 |
                Tee-Object -FilePath $runLog
        }
    }
    $engineExit = $LASTEXITCODE
    if ((Get-ReadOnlyHash $realSave) -ne $beforeSave -or
        (Get-ReadOnlyHash $realSettings) -ne $beforeSettings) {
        throw 'The real user save or settings changed during the isolated test.'
    }
    Write-Output "PLAYER_DATA_UNCHANGED=1"
    Write-Output "TEST_LOG=$runLog"
    exit $engineExit
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:AMBUSH_TEST_DATA_ROOT = $previousDataRoot
    $env:AMBUSH_TEST_RUN_ID = $previousRunId
}
