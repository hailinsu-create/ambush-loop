# Read-only A3 budget evidence review

Scope: read existing strict/extra JSON and original CSV only; no analyzer, engine, benchmark, import or repository changes. This is evidence/source review, not independent render acceptance. Formal all a90 running elsewhere is outside this review.

## Frozen evidence and counts

| Ended slice | source / game tree | strict checks | raw / accepted | segments / matrix / captures |
|---|---|---:|---:|---:|
| yard | a44a33ee348fa53e1b1c6d539d7ffcf114e4283c / 4d2acd43abdb4b6b7d0189eed3e2f085e1ab9dac | 4220, zero failures | 1873 / 1465 | 108 / 96 / 10 |
| warehouse | a90eb0798914c023f5c8902303c72f2619abd7c2 / ec73ed78833b5608919ae98e39ba7a58c4e03f41 | 4064, zero failures | 1742 / 1350 | 108 / 96 / 10 |

Direct CSV reading independently agrees with row and measured=1 counts. Both have 59 columns. Raw phase counts (all rows, including exclusions and replay) are yard phase0:27,1:166,2:16,3:14,4:1640,5:10; warehouse 0:25,1:154,2:15,3:12,4:1526,5:10. Thus raw phase4 totals are not live ALERT sample counts; recorded_phase/replay/segment must remain in the interpretation.

Original raw paths:
- ambush_loop/build/asset_review/pr15-runtime/a3-campaign-182e94a8c5d2437aadaf72eeba8189c9/yard-actual-source-metrics/raw.csv; SHA256 9b60fc306cc4ef5b89280044d92e396740d04b102210ca835810816027bde446.
- ambush_loop/build/asset_review/pr15-runtime/a3-campaign-f82c7c15662d4846849e8845b23ef77a/warehouse-actual-source-metrics/raw.csv; SHA256 37bd00d82b86308ccb665f8c0abc81f8896eb4bd06e9c22237d6e44246afc622.

Strict status is valid_original_cloud_workload. These are controlled API/reference and representative recorded views, warm imports, not native fresh normal whole-campaign acceptance. Environment is Godot4.7.2 debug, compatibility OpenGL3 llvmpipe/Mesa, X11, 1280x720, CPU quota four cores. Limits do not establish exclusive host occupancy; GPU timing unavailable.

## What measurements support

Yard accepted live ALERT wave0 128 (phase rows127) has median interval834.717ms, p95 976.199ms, max1540.111ms; wave1 accepted28 (phase27) median325.089ms. Warehouse live waves have 34/108 samples, median857.263/743.756ms. Yard WON11 median164.038ms and abort FAILED13 median144.473ms; warehouse WON9 median201.317ms, abort FAILED12 median157.293ms. Slow live cadence is present in both ended workloads; this does not isolate a single component. Different actors, phase work, recorded clock, active FX, view and source prevent treating terminal/live or yard/warehouse contrast as an optimization effect.

TIME_PROCESS values require caution: yard ALERT entry's three rows share7.756511s while median interval is909.262ms; paused ALERT median interval834.739ms vs monitor477.496ms. Monitor update latency/cadence differs from raw postdraw interval, so it is not a per-row function CPU profile and must not be added/subtracted as component cost. Several command/entry/pause/replay windows have only three samples: no robust tail or generalized pause/replay conclusion.

Resources and memory: yard static memory266298393 first,273219847 last,max288202392; warehouse266307329,276982265,max294776015. Yard resource469→398,max614; warehouse469→395,max617. Nodes yard1278→1306,max1545; warehouse1278→1301,max1669. Orphans remain zero. Texture/buffer/video maxima respectively yard77867898/44665850/122533748; warehouse79178618/44903616/124078138. RSS ready/save yard263553024/973545472, warehouse263434240/985030656; collector and archived payload residency plus driver caching are included. Neither RSS growth nor zero orphans alone establishes or excludes leaks. Observed postdraw pool counts are bounded observed occupancy (e.g. yard live wave0 shot2/tool1/dust2), not proof of combat peak or between-frame allocation absence.

## Same-source policy comparisons

Confirmed-shot yaw0 yard standard12 vs saving11 samples: median158.619 vs172.483ms (saving slower). Both preserve backend SHA1c0a678d7f0d29a5fac53f24dcae26353a7fda8105156f51dc6b878abb15dfc5 and presenter-frame SHA082d21397bf051923a61c096a3655595548099af10765279c8d9e43b5d98f416.

Warehouse standard10 vs saving10:188.825 vs186.098ms (~1.4% lower). Backend SHA354de30cf175d324716148f942affe64cabf2fbe30ec4096cf9c1f38cc2484a4 and presenter frame436492d8c859c908ad7b31c8a428f46b625623794a84f0257edfb855dd75238f match.

Each pair controls original attempt and frame payload, camera, resolution/scale1, main/presenter auto processing, tree pause=false,maxfps0,vsync0; policy changes intended drawing. This is useful paired input evidence, but small ordered windows without repeated/interleaved trials do not establish significance or universal saving benefit. Opposite directions expressly prohibit the latter. Different source/tree/level pairs cannot establish a90 improvement over a44. No host wall-time comparison is valid.

## First optimization admission: narrow metadata access

Concrete source opportunity, not measured attribution: scripts/presentation/asset_library.gd:26–28 deep-copies the entire catalog entry; model_path:39 calls it; has_asset:31–32 calls model_path. presenter_3d.gd:420–446 calls has_asset plus asset_record for each character category, then weapon has_asset each refresh. Catalog load is already guarded at47–50, so this is repeated metadata copying, not established repeated disk/model loading. Character records include clip metadata. ActorVisual existing asset/item early-outs make model reconstruction a different, presently unproved culprit.

Admit one isolated accessor slice: return scalar category/path metadata directly from internal validated catalog, preserving public asset_record's detached deep-copy contract. Preserve exact revision allowlists, legacy_r3_lods selection, invalid/unknown/negative/out-of-range LOD empty-string behavior, resource paths and material ownership. Do not expose mutable dictionaries/arrays. release_materials:16–23 must invalidate any added cache. Do not change actor pose, source clocks, snapshot capture, action sampling, bone forces/socket placement, FX policy, records, manifests or simulation. Snapshot memoization and animation-force elimination carry substantially more semantic risk and lack attribution evidence here.

Required correctness gates (to be implemented/run by owner, not run here): metadata parity for every accepted asset/LOD/revision and all rejection boundaries; public copied-record mutation cannot modify internal catalog; release/reload parity; identical model/resource identity and body/item selection; saved-pose/socket transforms, animation fallback/legacy records and all policies remain identical. Instrumented counters can prove avoided entry copies without interpreting them as total CPU gain.

Performance design after correctness: freeze explicit baseline and candidate source/tree/PCK/import proofs; replay the SAME original record bytes, attempt/config/camera, fixed saved clock/pose and presenter payload hashes. Include live-equivalent advancing-pose workload separately, since a static frame omits animated costs. Preserve original payloads/statistics/event identity and output schema. On one controlled host/backend with equal warm-up, interleave repeated A/B or ABBA policy windows with adequate samples; record interval distributions, TIME_PROCESS with stated update semantics, RSS/resource/pool occupancy, driver/environment and collector bytes. Verify identical input/backend hashes before comparing each pair. Keep collector untouched and disclose host variance; do not subtract estimated collector cost. Compare within declared baseline/candidate versions, never call different sources 'same-source' or infer savings from previous yard/warehouse windows. No performance improvement or sole bottleneck is accepted until that experiment exists.
