param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExe,
    [ValidateSet(
        'first_visit_journey_test.gd', 'title_focus_keyboard_test.gd', 'title_menu_viewport_test.gd',
        'replay_autoplay_test.gd', 'replay_event_text_source_test.gd', 'cover_command_test.gd',
        'escape_intel_source_test.gd', 'static_teaching_context_test.gd', 'loot_event_text_test.gd', 'live_wave_timeline_test.gd', 'current_wave_hint_test.gd', 'campaign_result_copy_test.gd', 'result_highlight_test.gd',
        'a3_collector_contract_test.gd', 'a3_collector_probe_test.gd', 'movement_dust_source_boundary_test.gd', 'movement_dust_test.gd', 'tool_fx_visible_test.gd', 'tool_fx_mine_reference_test.gd', 'tool_fx_pool_test.gd', 'tool_fx_source_boundary_test.gd', 'tool_fx_source_test.gd', 'grenade_flight_height_test.gd', 'shot_fx_shooter_binding_test.gd', 'shot_fx_visible_test.gd', 'shot_fx_pool_test.gd', 'shot_fx_frame_test.gd', 'escape_context_boundary_test.gd', 'shot_fx_boundary_test.gd', 'shot_fx_source_test.gd', 'replay_arrow_input_test.gd', 'smoke_contract_test.gd',
        'replay_timeline_test.gd',
        'equipment_freeze_test.gd',
        'phase_tools_test.gd',
        'presentation_lifecycle_test.gd',
        'campaign_replay_test.gd',
        'visual_snapshot_test.gd',
        'asset_library_test.gd',
        'asset_pack_test.gd',
        'actor_visual_test.gd',
        'c2_history_hint_test.gd',
        'actor_battle_test.gd',
        'audio_runtime_test.gd',
        'firearm_runtime_test.gd',
        'environment_assets_test.gd',
        'environment_battle_test.gd',
        'replay_fx_lifecycle_test.gd',
        'command_pose_clock_test.gd',
        'command_record_replay_test.gd',
        'full_command_record_replay_test.gd',
        'utility_runtime_test.gd',
        'corpse_runtime_test.gd',
        'corpse_pose_quality_test.gd',
        'corpse_contact_test.gd',
        'presentation_quality_test.gd',
        'result_viewport_test.gd',
        'radio_credits_viewport_test.gd',
        'viewport_hud_test.gd',
        'corpse_pairing_boundary_test.gd',
        'smoke_test.gd',
        'presentation_contract_test.gd',
        'presentation_interaction_test.gd',
        'camera_input_test.gd',
        'presentation_capture.gd',
        'asset_review_capture.gd',
        'presentation_preview.gd',
        'pathfinder_test.gd',
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
    [switch]$Rendered,
    [string]$TestPack = ''
)

$ErrorActionPreference = 'Stop'
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
New-Item -ItemType File -Path (Join-Path $projectRoot 'build/.gdignore') -Force | Out-Null
$dataRoot = [IO.Path]::GetFullPath($dataRoot)
$runLog = Join-Path $runDir 'run.log'

# Godot resolves user:// from APPDATA on Windows. Set it before the engine
# process starts so autoloads and the SceneTree script share one private dir.
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousDataRoot = $env:AMBUSH_TEST_DATA_ROOT
$previousRunId = $env:AMBUSH_TEST_RUN_ID
$previousPackRoot = $env:AMBUSH_ASSET_PACK_ROOT
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
        $engineFlags = if ($Rendered) { @('--rendering-method', 'gl_compatibility') } else { @('--headless') }
        if ($Entry -like '*capture.gd' -or $Entry -in @('a3_collector_contract_test.gd', 'a3_collector_probe_test.gd', 'movement_dust_source_boundary_test.gd', 'movement_dust_test.gd', 'tool_fx_visible_test.gd', 'tool_fx_mine_reference_test.gd', 'tool_fx_pool_test.gd', 'tool_fx_source_boundary_test.gd', 'tool_fx_source_test.gd', 'grenade_flight_height_test.gd', 'shot_fx_shooter_binding_test.gd', 'shot_fx_visible_test.gd', 'shot_fx_pool_test.gd', 'shot_fx_frame_test.gd', 'escape_context_boundary_test.gd', 'escape_intel_source_test.gd')) { $engineFlags += @('--audio-driver', 'Dummy') }
        $launchRoot = $projectRoot
        if ($Entry -eq 'asset_pack_test.gd') {
            if (-not (Test-Path -LiteralPath $TestPack -PathType Leaf)) {
                throw 'Pass an exported PCK in -TestPack.'
            }
            $packPath = [IO.Path]::GetFullPath($TestPack)
            $launchRoot = Join-Path $runDir 'packed-project'
            New-Item -ItemType Directory -Path $launchRoot -Force | Out-Null
            $env:AMBUSH_ASSET_PACK_ROOT = $launchRoot.Replace('\', '/')
            $engineFlags += @('--main-pack', $packPath, '--audio-driver', 'Dummy')
        }
        & $enginePath @engineFlags --path $launchRoot -s "res://scripts/$Entry" 2>&1 |
            Tee-Object -FilePath $runLog
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
    $env:AMBUSH_ASSET_PACK_ROOT = $previousPackRoot
}
