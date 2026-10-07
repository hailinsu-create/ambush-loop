# PR15 APK toolchain read-only inspection — 2026-10-04

Inspected /workspace/ambush-pr15 at HEAD e3797c5994bacec56a858c580960fb0a44877aeb, tree 9ecf9e2f455ce6269c1e69485f93e51798fb5b37. Main author is the sole integration writer. No repository edits, installs/downloads, export, keys generated/read, adb/emulator/device actions or ArtSource generators. This report is the only owned write. No final-candidate, runtime, device or performance acceptance claimed.

Read AGENTS.md, root/project README, PLANNING_INDEX.md, export_presets.cfg, export_a0_preview.py, asset execution v2, same-candidate FX/A3 plan, SOURCE_PROVENANCE.md and historical A0 export report/manifest. Root requires fixed 4.7.2, explicit source/actual exits, no secrets in git, devices after all assets/six-level/cloud work. The final source must pass its own required gates before APK build; historical evidence cannot be combined into final acceptance.

## Actual commands and results

All grouped shell calls exited 0. File inventory included nonexistent optional locations (rg stderr suppressed); absence below is bounded to inspected roots, not a universal filesystem proof.

- `git rev-parse HEAD HEAD^{tree}`: the source/tree above.
- `/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --version`: `4.7.2.stable.official.ed1daf0bf`; fontconfig emitted repeated `No writable cache directories` on stderr. No import/export performed.
- `java -version`: OpenJDK `21.0.12.1`, runtime `21.0.12.1+1-1-deb13u1-Debian`, Debian OpenJDK 64-bit VM. This is not the exporter-required JDK 17.
- `command -v java javac keytool aapt apksigner sdkmanager unzip sha256sum`: returned `/usr/bin/java`, `/usr/bin/keytool`, `/usr/bin/unzip`, `/usr/bin/sha256sum`; javac/aapt/apksigner/sdkmanager absent from PATH.
- `readlink -f /usr/bin/java /usr/bin/keytool`: both resolve under `/usr/lib/jvm/java-21-openjdk-amd64/bin/`.
- Python `os.environ.get` limited to JAVA_HOME, ANDROID_HOME, ANDROID_SDK_ROOT, XDG_DATA_HOME: all unset; `Path.home()` is `/home/agent`.
- Python existence/list checks: `/home/agent/.local/share/godot/export_templates`, `/home/agent/Android`, `/opt/android-sdk`, `/opt/android`, `/usr/local/lib/android` absent. `/usr/lib/jvm` contains only Java 21 names/symlinks and its metadata entry.
- Python `os.walk('/workspace')`, pruning `.git,node_modules,.godot,ArtSource,source,asset_review`, searched names android_debug.apk/android_release.apk/sdkmanager/apksigner/aapt/java/javac and suffix .apk: no matches. Matching walk of `/home/agent`, `/opt`, `/usr/local`, `/tmp`, pruning `.git,node_modules,.godot,ArtSource,source,site-packages,.cache`, additionally searched android.jar: no matches. Old APK binaries not found in these scopes; old manifest remains in git.
- `sha256sum` results:
  - engine binary: `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`
  - `ambush_loop/scripts/export_a0_preview.py`: `52a88a21f6225af9e7b8e587ccab96d8b759a1a53a9f229045ccbca880328d34`
  - `ambush_loop/export_presets.cfg`: `63bb5c789596625d3ee7a094d66277d11ee7602cf6ebcb88763d7b439fe32587`

## Existing historical APK evidence (not current build)

`.cursor/docs/evidence/20261002-a0/apk-manifest.json` records clean source `1e9863ba0e9c007b0fb612d8dd5f705fa7f374d7`, Godot `4.7.2.stable.official.ed1daf0bf`, Java `17.0.20.1`, arm64, package `com.ambushloop.game.a0`, version code `2026100202`, APK 29,624,703 bytes, SHA256 `d5a4d33743c6d1ee1b20f237be3ff1a94384695ca56bf0a28e22956f00b09b83`, validation `export+aapt+apksigner; device pending`.

Historical A0 report says matching templates 4.7.2.stable, TPZ hash `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`, Temurin JDK 17.0.20.1+1, SDK platform 36/build-tools 36.0.0, export/aapt/signature actual exits 0. These are historical records, not installed toolchain facts today. Old M0 SDK34 fallback is also historical, not a current viable SDK. No old APK was rehashed or reverified because binary/tools were not found.

## Actionable remaining blockers and future build procedure

1. Install/provide explicit JDK 17 (`bin/java`, `bin/keytool`), Android SDK platform `android-36/android.jar`, build-tools `36.0.0/aapt` and `apksigner`, and official 4.7.2 templates (`version.txt` exactly `4.7.2.stable`, android_debug.apk; android_release.apk if needed). Current environment lacks these in inspected scopes. Main author must perform any setup under authorized scope; this package performed none.
2. Freeze the accepted final source/tree and source-copy hash manifest after FX/A3/final gates. Keep runtime/R5/environment revision and export-time source state in build provenance. Current e3797 checkpoint is not final acceptance.
3. Review or implement an isolated full-game nonproduction exporter. Existing `export_a0_preview.py` is only a preview builder: rewrites title main scene to `scenes/presentation/preview_boot.tscn`, changes rendering/stretch, package/version and exclusions, and generates/reuses a debug key in ignored build/a0_exports. Running it would produce graybox A0 rather than the final full-game candidate. Do not blindly use its command as the final build.
4. Current tracked Android preset is signed arm64, `com.ambushloop.game`, code77/name0.6.28, non-Gradle, mobile feature. It leaves min/target SDK fields empty (README says min24). Verify actual exported metadata; do not assume SDK level from prose. For nonproduction choose/record isolated package/version in staging to prevent accidentally masquerading as the old base package. Retain intended full-game boot scene and actual final R5/environment/runtime artifacts.
5. Use separate staging source and XDG data/config/cache for Godot; private debug signing material remains ignored/outside staged source. Record exact engine/JDK/templates/SDK tool versions and hashes, source SHA/tree/dirty status, project/preset staging transformations, source file hashes, and actual process exits.

Future command shapes (not executed; MAIN_AUTHOR fills absolute paths/preset):

```bash
"$JDK17/bin/java" -version
"$GODOT" --version
cat "$TEMPLATES/version.txt"
"$SDK/build-tools/36.0.0/aapt" version
"$SDK/build-tools/36.0.0/apksigner" version
# In isolated build environment configured with explicit SDK/JDK/debug-key paths:
"$GODOT" --headless --path "$STAGED_SOURCE" --editor --import
"$GODOT" --headless --path "$STAGED_SOURCE" --export-debug "$NONPRODUCTION_PRESET" "$APK"
"$SDK/build-tools/36.0.0/aapt" dump badging "$APK"
"$SDK/build-tools/36.0.0/apksigner" verify --verbose --print-certs "$APK"
sha256sum "$APK" "$FINAL_PCK"
unzip -l "$APK"
```

Require exit0 and verify package/version/min/target SDK/arm64 and intended entry point; retain badging and certificate fingerprint (public certificate only), export logs and source/config transformation manifest. Hash the actual exported embedded project/PCK as appropriate; the desktop PCK hash alone does not prove the Android payload. Existing A0 manifest does not record source tree, template/tool hashes, staged config hashes, explicit process-exit table or embedded PCK hash, so add them to final provenance. Preserve nonproduction artifact without production publishing/merge. Device installation/performance/ear-listening remain later independent gates.
