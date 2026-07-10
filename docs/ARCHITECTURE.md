# Architecture

## Philosophy
Code-first scenes: `.tscn` files are thin roots; all content is constructed in `_ready()`.
This keeps the project 100% diffable/reviewable, avoids editor-state drift, and makes the
generated-asset pipeline reproducible. Data (weapons, enemies) lives in `.tres` Resources.

## Autoload singletons (order matters)
| Autoload | Role |
|---|---|
| `EventBus` | Every cross-system signal. No system references another directly for events. |
| `SaveGame` | JSON profile in `user://save.json`: coins, upgrades, records, settings. Deep-merged on load for forward compatibility. |
| `AudioMan` | 10 pooled SFX voices + 2 crossfading music players on dedicated buses. |
| `GameState` | Run state machine (MENU/CUTSCENE/PLAYING/PAUSED/WON/LOST), objectives, escape timer, run economy. |
| `Fx` | Screen shake, hit-stop, zoom punch, pooled floating text & particle bursts, haptics. |
| `Pool` | Generic factory-based object pool (bullets, coins, labels, bursts). |
| `Router` | Scene changes behind a fade overlay; owns the global fade rect used by cutscenes. |
| `UITheme` | Runtime-built Theme + widget factories (buttons, bars, panels) for consistent mobile UI. |

## Gameplay composition (scenes/game.tscn)
```
Game (game.gd — orchestrator)
├── Level (level.gd)          # map, walls, props, loot, zombies, boss hall, atmosphere
│   ├── Player (player.gd)    # + Camera2D (limits, smoothing)
│   ├── Zombie × N (zombie.gd)  BossZombie (boss.gd)
│   ├── Pickup / Crate / Survivor / train zone
├── HUD (hud.gd)              # joystick, bars, timer, objectives, boss bar, banners
├── PauseMenu / ResultsScreen
└── CutsceneDirector (+ Subtitles layer)
```

## Signal flow examples
- `Player.fire()` → `EventBus.gunshot` → zombies within hearing aggro.
- `Zombie._die()` → `EventBus.enemy_died` + `Level.spawn_coin_burst()`.
- `BossZombie._on_death()` → `EventBus.boss_defeated` → `Game` schedules rescue cutscene →
  `GameState.on_survivor_rescued()` → `EventBus.escape_phase_started` → `Level` starts waves.
- Train zone + objective `escape` → `Game.start_ending()` → ending cutscene → `GameState.win()`.

## AI
Zombies: enum state machine (IDLE/WANDER/CHASE/WINDUP/SPECIAL/DEAD) with direct steering +
sine weave (no pathfinding needed in the open station layout), staggered player scans,
telegraphed attacks (windup flash) for fairness. Boss: separate machine layered on the same
base (FIGHT/CHARGE_WINDUP/CHARGING/STUNNED/SUMMONING) with HP-threshold phase triggers.

## Performance budget (mid-range Android @60fps)
- GL Compatibility renderer, ETC2/ASTC compression, MSAA off.
- Zero per-frame allocations in combat: bullets/coins/text/bursts pooled.
- ≤26 live zombies; AI scans throttled (0.12 s aim scan, 0.4 s objective targets).
- Physics: 60 tps, simple circle/rect shapes only, 5 collision layers.
- Audio: 22 kHz mono OGG; total audio < 1 MB.

## Extending
- New enemy: add a `.tres` EnemyData (+ texture), reference in `Level`.
- New weapon: add `.tres` WeaponData + upgrade keys in `SaveGame.UPGRADE_DEFS`.
- New episode/level: subclass or replace `Level`; `GameState` objectives are string-keyed.
