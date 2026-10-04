# a44 runtime hot-path source audit (read-only)

Source a44a33ee348fa53e1b1c6d539d7ffcf114e4283c. No engine, profiling, source edits or asset operations. Parent raw medians differ substantially between automatic SCOUT/ALERT and stationary terminal views, but that does not identify a CPU/GPU or single-function bottleneck. All costs below are source hypotheses, not measured timings.

## Actual repeating work

Presenter._process -> refresh every render frame (presenter_3d.gd:241-259). ViewState.capture calls host._snapshot_data for live presentation (view_state.gd:10-13). Main._snapshot_data (main.gd:5836) delegates VisualSnapshot.capture. Independent recorded snapshots also call it at command cadence (5542), simulation cadence/terminal (5717), and original shot confirmation (shot_fx_recording.gd:50). Thus the presentation frame is not simply reading the last recorded snapshot; live capture can repeat within a display frame/tick.

VisualSnapshot.capture duplicates blocked data, inventory/ammo/cones/environment arrays, computes corpse state and scans actor lists (visual_snapshot.gd:104-145,208-240). It deep-copies each actor as intent_item, then firearm state and utility state. Capture owns stateful cancellation/pose anchors and tool recent pruning, so blindly memoizing or moving capture changes semantics unless these recording seams are preserved.

ViewState copies all group arrays deeply and recursively freezes them (view_state.gd:95-101); events are also deep-copied before frame sampling. Historical replay additionally scans snapshots/events to select the source. ActorPose._last_event (actor_pose.gd:147-157) scans the event list for each requested actor/type; firearm and death sampling can request several scans. Shot FX independently visits events; tool/movement readers duplicate selected records. These are allocation/traversal candidates, not disk loading evidence.

Presenter._sync_body (presenter_3d.gd:420-446) calls Assets.has_asset and asset_record for each actor every refresh, then has_asset for equipment. asset_library.gd:28 deep-copies the entire catalog entry, including all64 character animation dictionaries, even when only category/path is needed. model_path:39 also obtains this full deep copy. Catalog loading itself is guarded, but catalog entry copies are repeated.

ActorVisual.set_asset early-outs for same model/LOD/revision (actor_visual.gd:24-25); mount_item also early-outs for same equipment. Therefore source does NOT demonstrate GLBs instantiated every frame. instantiate/load happens on creation/model/LOD/revision/item changes; persistent actor scope or hysteresis normally avoids it. Count actual set_asset misses, mount_item misses, instantiate calls and resource IDs before claiming repeated loads. Godot load(path) at asset_library.gd:129 alone does not imply repeated disk IO.

For changed layered poses, ActorVisual.sample_layers (95-134) samples base then upper clips, captures all20 bone transforms into a new Array, restores lower bones and corrects the spine. Each sample_pose scans up to64 clip records, resets bone poses, seeks AnimationPlayer and forces bone transforms (74-87). A changed layered call has four explicit force_update_all_bone_transforms calls (86 twice,122,130) plus attachment synchronization; spine/bone name lookups repeat. The unchanged-pose early-out at98 works for identical saved time/pose, but advancing SCOUT/ALERT pose clocks normally defeats it. Stationary command terminal pose clocks can still advance for live terminal presentation, so timing differences cannot be attributed to this early-out alone.

Presenter also synchronizes corpses, all objects, three FX pools and cones every frame (277-283), and runs occlusion periodically/on camera change. Corpse pairing has its own explicit bone resets/restores/forces and reference samplers; corpse_visual.gd has reference/palm caches. These branches and GPU skinning/transparent overdraw may vary by actual workload. Need counters/scoped timings before prioritizing.

## Minimal independently verifiable candidates

1. Cache immutable asset category/path metadata without deep-copying64 clips for category/has_asset checks. Keep public asset_record copy semantics; add narrow private/read-only accessors or per-presenter immutable metadata cache, reset on accepted catalog release. Verify identical asset revision/path/material selection, unknown/legacy fallbacks, no mutable catalog escape and same actor/gun resource IDs. This avoids changing bones, simulation or sampling cadence.

2. Build per-ActorVisual clip lookup and fixed bone indices/upper-mask membership at successful set_asset, invalidate on model/LOD/revision replacement. Reuse fixed-size base-pose storage instead of allocating20 values each changed layered sample. Verify exact sampled bone/weapon-hand/support-hand/muzzle transforms over ordinary layers, crouch/run, utility/corpse modifications, arbitrary seek, same-time resample and LOD changes.

3. Build a frame-local latest-event index once, keyed by original attempt/wave/actor/type and original tick/seq ordering. Preserve schema/identity validation and no future events; do not reuse between bound sources or mutate recorded events. Verify all poses and event identities before/after, including repack/last-pistol/death and old neutral records. Savings likely depend on event count, so measure scaling.

4. Only after measuring capture allocations, introduce an explicit read-only live presentation capture reuse seam for a precisely frozen source state. Clock, phase, equipment, utility cancellation, corpse action, late damage completion, source/wave/reset/focus and selected UI changes must invalidate it. Do not replace historical source data with live cache. This is higher-risk than1-3 and should be its own slice.

5. Defer reducing force-update passes/animation seeks until instrumentation proves relevance. Some forces support explicit seek/LOD attachment correctness and R5 spine/palm/socket contact; removing them can resurrect the previously fixed stale muzzle or contact problems. A low-risk first step is call counting, not changing update ordering.

## Evidence required for any optimization claim

Keep the current frozen all-run intact. Subsequent fixed-source single-slice comparison should collect CPU function timing/counters, allocation/resource residency and GPU/render workload separately; pair identical source/input/history/camera/speed/backend/warm inventory and instrumentation controls. Record full raw distributions, process/source IDs, actual exits and scene-specific scope. Retain existing simulation/log/HP/ammo/identity equality and exact pose/socket/geometry comparisons. Cloud llvmpipe results do not certify Android FPS or art quality. No proposed optimization is implemented or accepted by this report.
