# Remaining independent asset deliveries — read-only interface audit

Fixed game source: e8718380b56094512c54df6ed18e10828df6e236. No Godot, Blender, generator, repository edits or asset writes. This is inventory/source inspection, not artistic or normal-battle acceptance.

## Current inventory and evidence limits

Effective order: AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md lines 6-22: A1.2 actors/actions, complete yard A2, cloud A3, five other theme scenes A4, build, then devices. The plan's initial status and later appended bounded receipts are not a blanket art sign-off.

art/v2/actors_manifest.json schema2 records source_commit 29749157c5db064bfea626c3ed9d75d9a1791ece and evidence_commit ebedb829e3263abbeb6dd266905f24a3869fa281. Top status explicitly R5_TOOL_RUNTIME_INTEGRATION_IN_PROGRESS_CORPSE_AND_FINAL_ART_PENDING; entries say repaired candidate / acceptance report required. Inventory is 7 characters x 3 LODs, 10 guns x 2 LODs and 5 tools x 2 LODs: 51 GLBs plus 3 atlas textures. All 54 referenced files match their declared SHA256 in this read-only check. Each character declares 64 clips (12 original base + 40 firearm additions + 12 R5 optional utility/corpse additions). Byte hashes do not establish art quality, grip, visual animation or natural battle acceptance.

art/environment_v2/manifest.json schema1 records source_commit 50ef7883285c4419dbd8339b935433dc6bb5e3f8, 40 assets x 2 LODs and 3 textures. All 83 referenced files match declared SHA256. Top status says resource interface accepted / six-level scene integration cloud test pending; per-entry status still says exported candidate / shared runtime integration not implemented. Runtime environment_scene.gd already implements six-level assembly, so these status strings are stale inventory metadata, not evidence that integration is absent or art accepted.

Source provenance deliverable remains important: manifest actor source ArtSource/v2/build_actors.py and environment source ArtSource/environment_v2/build_environment.py are not present at those paths in this game checkout. ArtSource/v2 here contains the original build_yard_kit.py/yard_kit.blend pipeline. Independent author must provide/reconcile accepted editable source and deterministic export provenance from their source branch; main integration must not regenerate or overwrite them.

## A1.2 actor/weapon acceptance package

Deliver one independently reviewed R5-compatible package for operator_rifle, operator_mg, operator_scout, enemy_patrol, enemy_flank, enemy_sneak, enemy_radio. Include original base actions idle/walk/run/aim/fire/pickup/death/crouch/crouch_walk/deploy/hit/haul; ready/aim/fire/raise/lower firearm overlays; all ten reload_contact clips; utility_ready/knife_stab/grenade_throw/decoy_place and corpse grab/drag/release/prone/dragged/death_prone/lift/lower. Acceptance must inspect real original actions, phase changes, equipment cancellation, corpse contact, locomotion layering, arbitrary seek and all three actor LODs, with scoped findings rather than inferring acceptance from sample turnaround or test totals.

Ten gun IDs: m1911, luger, m1_garand, kar98k, thompson, mp40, bar, mg42, springfield, kar98k_zf. Gun LOD0/1 are mounted even on actor LOD2 (ActorVisual.mount_item uses min(actor_lod,1)). Review ready/aim/fire/raise/lower/reload contact for these guns and intended actors, including last-shot pack/pistol transition using original saved equipment. Five existing tools knife/grenade/mine/decoy/ammo_pack remain in the same equipment ownership package.

Preserve 20 named bones/rest/bind and character sockets weapon_hand(hand.R), support_hand(hand.L), sight_eye(head), their metre-local offsets/rotations. Weapons expose named GLB markers <weapon>__socket_grip and __socket_muzzle, plus manifest pose_support/sight/reload_contact values. ActorVisual.bone_socket returns position; item_socket returns full transform after explicit sampling/attachment sync. Preserve legacy R3/R4 geometry and clip semantics for old saved revisions. firearm_profiles.json schema1 supplies weapon_id/family/pose_group/roles/clips/sockets/contact-window/timing and the 12-bone upper mask; utility contract and corpse sampler expectations must accompany any new revision. Unknown/new action/revision requires an explicit main-author versioned loader/record contract, not silent replacement.

## A4 five theme-scene acceptance packages

Runtime environment_scene.gd revision 50ef..., layout six_level_grid_assembly_1 assembles current copied grid; preserve blocked880/grid routes and visual-only ownership. Deliver five scoped packages with all used common kit assets plus these actual landmark hooks:

| Theme | Existing interface / focus |
| --- | --- |
| warehouse | env_warehouse_gantry; crate filling, cobble/concrete, brick boundaries; roof/cutaway and target readability |
| pump | env_pump_skid + env_pipe_elbow; steel platform/concrete and low walls; pipe contact/readability |
| railcut | env_signal_mast + env_rail_2m; earth/gravel and low-wall assembly; narrow passage/landmark visibility |
| depot | env_depot_tank_pair; gravel/concrete, tank footprint/cutaway; three-route readable composition |
| radio | env_radio_antenna; cobble/concrete, explicit cutaway/display groups; all camera angles and antenna target occlusion |

Each package includes source author commit, editable scene/Blender source and exporter provenance, per-file hash inventory, actual Godot camera/action/battle frames (360 degrees, 35-65 degree pitch/zoom, LOD transitions, copied historical layout), lighting/material readability and scoped outstanding issues. Six-theme soundscape remains a separate actual listening deliverable; file existence or silent cloud output is not auditory acceptance. Existing shared atlas/geometry must stay under the asset author's ownership.

## Loader / manifest acceptance gates

Actor art paths remain art/v2/models/<id>_lod0-2.glb (characters) / lod0-1 (guns/tools), actors_manifest schema2. Environment art paths art/environment_v2/models/env_<id>_lod0-1.glb, manifest schema1. Manifest fields to reconcile: asset_id/category/source/editable_source or explicit equivalent/tool/provenance/unit/runtime_axes/origin/dimensions_m/lods(path,sha256,triangles,surfaces)/materials/collision/animations/sockets/status; actor skeleton/LOD budgets; environment logic_footprint/display_groups/moving_nodes/LOD policy. Textures list path+sha256 and correct atlas material slots. All models remain visual_only; no automatic gameplay collision/nav.

asset_library.gd uses an explicit revision allowlist and path/category/material boundary; it does not prove export hashes or artistic acceptance on instantiate. New asset revision requires main-author review of loader and recording compatibility. Candidate receipt must independently verify source/exporter/contract hashes, GLB/texture hashes, counts and actual render findings before main integration accepts it. Existing R5 source, build_yard_kit.py, GLBs, atlas and production manifests were untouched by this audit.

Remaining scope: final artistic acceptance for all actor/gun/actions/LOD and five full themes; scoped natural battle/history review, complete A3 and final single-source regression/build/device/listening gates. This report does not claim those have passed and does not prescribe recreating already delivered assets.
