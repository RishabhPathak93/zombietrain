# Building the Android APK / AAB

## One-time setup
1. **Godot 4.3+** editor.
2. Editor → *Manage Export Templates* → download templates for your version.
3. Install **OpenJDK 17** and **Android SDK** (or Android Studio).
   - In Godot: *Editor Settings → Export → Android*, set the SDK path and a
     debug keystore (Godot can generate one).
4. This repo already contains `export_presets.cfg` (preset "Android"):
   - arm64-v8a only (add armeabi-v7a if you need 32-bit devices)
   - immersive fullscreen, sensor-landscape orientation
   - `VIBRATE` permission (haptics), no other permissions — fully offline
   - package id `com.astracybertech.zombietrainescape` (change before publishing)

## Debug build
Project → Export… → Android → **Export Project** → `build/ZombieTrainEscape.apk`
(or `godot --headless --export-debug "Android" build/ZombieTrainEscape.apk`).

## Release for Google Play
1. Create a release keystore:
   `keytool -genkey -v -keystore release.keystore -alias zte -keyalg RSA -keysize 2048 -validity 10000`
2. Fill *Keystore → Release* fields in the export preset.
3. Switch **Gradle build ON** and export **AAB** (Play requires app bundles):
   preset → `gradle_build/use_gradle_build=true`, `gradle_build/export_format=1`.
4. Bump `version/code` for every upload.
5. Play Console checklist: content rating (mild fantasy violence, no gore),
   data safety = "no data collected" (game is fully offline, saves locally),
   testing track first.

## Performance flags already set
- `renderer/rendering_method="gl_compatibility"` (best mobile compatibility & battery)
- `textures/vram_compression/import_etc2_astc=true`
- stretch: `canvas_items` + `expand`, base 1280×720 landscape
- physics 60 tps; `emulate_touch_from_mouse` for desktop testing
