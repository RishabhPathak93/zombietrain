# Zombie Train Escape

Top-down stylized zombie survival for Android, built with **Godot 4.3+** and pure GDScript.
One thumb. Four minutes. Refuel the train, grab the medicine, rescue the survivor, beat the
Conductor — and get out before the horde closes in.

![Genre](https://img.shields.io/badge/genre-top--down%20survival-green)
![Engine](https://img.shields.io/badge/engine-Godot%204.3-blue)
![Platform](https://img.shields.io/badge/platform-Android-brightgreen)

## Quick start

1. Install **Godot 4.3 or newer** (standard build).
2. Open this folder (`project.godot`) in Godot. First import takes a few seconds.
3. Press **F5**. Mouse emulates touch on desktop (drag on the left half of the
   screen = virtual joystick).

## The game

- **Story**: The Ember Line, the last armored train, stops at Junction Nine — an abandoned
  station whose lights are somehow still on. Scout **Mara Vale** has 4 minutes to find fuel
  and medicine, uncover who kept the generator running, and escape. Episode 1 ends on a
  cliffhanger: the horde is following a radio signal... and it knows Mara's name.
- **Controls**: one-thumb floating joystick (left 60% of screen). Aiming and firing are
  automatic (toggle in Settings). Buttons: weapon switch, reload, pause.
- **Enemies**: Walker (steady), Runner (lunging dash), Heavy (AoE slam), and boss
  **The Conductor** (charge attacks, minion summons, enrage phase).
- **Weapons**: Pistol and Shotgun, each with 3 upgrade tracks (damage / fire rate / mag),
  plus armor and speed gear — bought with coins in the Armory. Coins persist across runs;
  win to bank 100% + a time bonus, lose and keep half.
- **Chapters**: Ch. 1 *Junction Nine* (station, rescue, the Conductor) and Ch. 2
  *Sector Seven* (city, signal relays, the Broadcaster) — unlocked by finishing Ch. 1.
  Both open with a parallax city cinematic of the rolling Ember Line.
- **Replayability**: key item locations shuffle every run, randomized loot crates,
  best-time chase, permanent upgrade meta.

## Project layout

```
autoload/    Global systems: EventBus, SaveGame, GameState, AudioMan, Fx, Pool, Router, UITheme
scenes/      Thin scene roots (boot, main_menu, game) — content is built in code
scripts/     Gameplay code (player/, weapons/, enemies/, world/, ui/, cutscenes/)
resources/   Data-driven .tres definitions (weapons, enemies, audio bus layout)
assets/      Generated textures + procedurally synthesized OGG audio
tools/       Python generators for all placeholder art & audio (not exported)
docs/        GDD, architecture notes, Android build guide
```

## Building for Android

See **docs/BUILD_ANDROID.md**. Short version: install Android Build Template +
export templates in the Godot editor, plug in a keystore, and use the included
`export_presets.cfg` (arm64-v8a, immersive landscape, ETC2/ASTC).

## Asset licensing

Every texture and sound in this repository is **generated from scratch** by the scripts in
`tools/` (PIL drawings and numpy-synthesized audio). There are no third-party assets;
everything is safe for commercial release.

## Performance notes

- GL Compatibility renderer, single 2D scene, no runtime allocations in combat paths
  (bullets, particles, damage text are pooled).
- Zombie AI is state-machine based with staggered target scans (no NavMesh cost);
  hard cap on live zombies.
- All cutscenes are engine tweens — no video files. APK stays tiny (audio is short OGG loops,
  textures are small PNGs).
