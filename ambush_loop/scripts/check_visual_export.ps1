param([Parameter(Mandatory = $true)][string]$Archive)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($Archive))
try {
    $names = @($zip.Entries | ForEach-Object { $_.FullName })
    $banned = @($names | Where-Object { $_ -match '(^|/)(build|docs|ArtSource|review_packets)/|_gate\.gd|eval_dump_|_probe\.gd|smoke_test\.gd|playable_dump\.gd|visual_dump\.gd|v1-(compact|expanded|low)-|m2_i0_yard_preview|3d-terminal-' })
    if ($banned.Count -ne 0) { throw "Development resources leaked into export: $($banned -join ', ')" }
    foreach ($required in @('scenes/main.tscn', 'scripts/main.gd', 'scripts/m2_i0_yard_presentation.gd', 'scripts/presentation/yard_visual_style.gd', 'scripts/presentation/yard_unit_silhouette.gd', 'art/yard_v1/concrete.gdshader', 'art/yard_v1/brick.gdshader', 'art/environment_v2/materials/environment_v2_atlas.tres', 'art/environment_v2/models/env_yard_crate_lod0.glb')) {
        if (-not ($names -contains $required -or $names -contains "$required.remap" -or $names -contains "$required.import")) { throw "Missing production resource: $required" }
    }
    Write-Output "VISUAL_EXPORT_OK entries=$($names.Count) banned=0 runtime_required=9"
    Write-Output "ARCHIVE_SHA256=$((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash)"
}
finally { $zip.Dispose() }
