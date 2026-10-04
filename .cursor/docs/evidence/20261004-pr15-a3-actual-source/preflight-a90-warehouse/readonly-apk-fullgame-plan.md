# Read-only full-game APK plan

No download/extraction/install/export/signing/key access/adb/engine/import or repository/config modification performed. Parent current A3 Window is untouched. This is a future build plan, not APK or FINAL acceptance.

## Exact sources / correction

[Godot4.7.2 config.gradle](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/java/app/config.gradle) pins AGP8.6.1, compile/targetSDK36, minimum24, BuildTools36.1.0, Java source compatibility17 and NDK29.0.14206865. [Pinned wrapper](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/java/gradle/wrapper/gradle-wrapper.properties) selects Gradle8.11.1. These are build-source requirements; prebuilt non-Gradle APK export avoids compiling Java/native engine, so NDK/CMake/full compiler are not automatically mandatory for that route.

[Official Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) recommends JDK17 but explicitly supports higher versions. Its currently served SDK35 instructions differ from pinned4.7.2 source; use pinned source/template inventory for this build. Existing Java21 alone is NOT a hard blocker. Correction to earlier readonly APK report wording: calling Java21 incompatible solely because17 absent was too strong.

[Fixed exporter](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp) resolves keytool under configured Java path and signs using SDK apksigner. It selects installed build-tools candidates; no exact36.1.0 hard minimum was established for prebuilt non-Gradle export by this review. Missing/failing apksigner can return success while leaving APK unsigned, so independently require signature verification. It internally aligns uncompressed libraries/assets. Min/target override is restricted to Gradle mode. Debug verbose signing output can expose debug credentials: do not use verbose export or preserve unredacted credential output. This source finding is relevant to log handling, not evidence a key was accessed.

Official TPZ release metadata already sealed in toolchain-release-readonly.json: [release asset](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz),1281349702bytes,SHA256f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011. Metadata verified; TPZ bytes not downloaded/verified locally. Future check actual size/hash before installation and hash android_debug.apk/android_release.apk entries. Release metadata and tag URLs alone do not prove installed files.

## Actual current tools

`command -v java javac sdkmanager apksigner zipalign gradle`: only/usr/bin/java. `java -version`: DebianOpenJDK21.0.12.1. `command -v keytool jarsigner`: only/usr/bin/keytool. Java21 bin lists java,jpackage,keytool,rmiregistry; javac/jarsigner absent, so current installation is runtime-like, not full JDK. Inspected /home/agent/.local/share/godot/export_templates,/home/agent/Android,/opt/android-sdk,/opt/android,/usr/local/lib/android absent. Earlier owned report broader search found no SDK/templates/APK; this review refreshed these roots only. SDK/tools/templates absence in these scopes is an actual setup blocker, not global filesystem proof.

## Full-game isolation and source trace

Original project.godot boot is res://scenes/title.tscn, mobile renderer gl_compatibility. Existing export_a0_preview.py rewrites boot to preview_boot.tscn, stretch and light/shadow settings, adds a0_preview feature, package.a0 and preview filters. It also creates/reuses a debug key. Do not run it for the requested full game.

After accepted source gates, parent should create an owned isolated stage from exact committed source (git archive SOURCE_SHA into a new stage), preserving Title boot, full runtime scenes/resources/autoloads and current mobile rendering. Capture commit/game tree, archive hash and original file manifest. Copy only licensed runtime dependencies and required source-traceable assets; exclude ArtSource/test reports/test-only drivers with audited dependency checks. Prepare a dedicated nonproduction Android preset, arm64, Gradlefalse unless plugins require Gradle, unique package such as com.ambushloop.game.pr15test, explicit nonproduction version/name. Record every staged config/preset delta and staged payload/import manifest; never edit working production source. Isolated XDG config/data/cache paths avoid shared editor settings and active Window import/cache. Setup/import/export serialized after parent tool ownership allows it. Confirm staged main_scene exactly Title before export; preserve embedded project.binary/PCK identity afterward using a verified parser, not merely a desktop PCK hash.

Future commands (NOT executed):

```bash
sdkmanager --sdk_root="$APK_SDK" "platform-tools" "build-tools;36.1.0" "platforms;android-36"
"$APK_JAVA/bin/java" -version
"$APK_SDK/build-tools/36.1.0/apksigner" version
"$APK_GODOT" --headless --path "$APK_STAGE" --editor --import
"$APK_GODOT" --headless --path "$APK_STAGE" --export-debug "PR15 Nonproduction Fullgame" "$APK_OUTPUT"
"$APK_SDK/build-tools/36.1.0/apksigner" verify --verbose --print-certs "$APK_OUTPUT"
"$APK_SDK/build-tools/36.1.0/zipalign" -c -P 16 -v 4 "$APK_OUTPUT"
"$APK_SDK/build-tools/36.1.0/aapt" dump badging "$APK_OUTPUT"
sha256sum "$APK_OUTPUT"
```

All placeholders require explicit isolated paths; setup templates and editor Java/SDK/debug-signing settings in owned config first. Future nonproduction signing uses an explicitly owned debug certificate, no production keys. Do not print passwords/private key content or place credentials in tracked files/logs; public certificate fingerprint is appropriate provenance. Full JDK17 is optional compatibility fallback, not mandatory solely due Java21. Gradle route additionally requires compiler/wrapper/dependency validation and records exact resolved artifacts; NDK/CMake if that route actually compiles native/plugin code.

Require each actual exit separately, nonempty artifact, correct package/version/min-target/arm64/debuggable metadata, signature/certificate and alignment verification. Record engine/tool/template hashes, stage config/payload/import hashes, transforms and embedded boot proof. ZIP entry inventory alone cannot decode project.binary or establish runtime Title execution; a source-level/embedded-config proof plus later separately authorized runtime/device smoke is needed. No adb/install/device validation is included here.

Old A0 manifest SHA d5a4d33743c6d1ee1b20f237be3ff1a94384695ca56bf0a28e22956f00b09b83/source1e986/package.a0 is historical preview evidence only; its APK is absent in inspected locations, not newly reverified. Current A3 candidate is not yet accepted full-game APK source.
