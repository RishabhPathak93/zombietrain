# Game Design Document — Zombie Train Escape

**Chapters**: 1 — Junction Nine (station) · 2 — Sector Seven (city/tower) · 3 — The Passenger (train interior) · 4 — Depot 12 (freight yard). Each unlocked by finishing the previous. Every chapter opens with a side-view cinematic: night skyline parallax, moon, the Ember Line rolling with sparks and narration.

## Pillars
1. **One thumb, full action** — move with one thumb; aim/fire are automatic. Every other
   input is a large, optional button.
2. **A complete story in 4 minutes** — every run is a full narrative arc: arrive, explore,
   rescue, boss, escape, cliffhanger.
3. **Fail forward** — losing still banks half your coins; the Armory always moves you ahead.

## Story
**Setting**: years after the outbreak, the armored train *Ember Line* carries the last
survivors west. **Mara Vale** (scout, protagonist) and **Commander Redd** (gruff, warm)
stop at Junction Nine for fuel and medicine for a sick child, Pip.

**Mystery**: the station lights are still on — someone kept the generator running.
That someone is **Dr. Iris Chen**, caged in the North Hall by the horde's keeper,
**The Conductor**. Iris knows the truth: the zombies aren't wandering, they follow a
*signal* broadcast from Sector Seven.

**Cliffhanger**: as the train departs, the radio crackles: the broadcast has changed.
It is calling for Mara by name.

## Mission flow (3–5 min)
| Phase | Objective | Beats |
|---|---|---|
| Intro | (cutscene) | train horn, camera pan, mission briefing, lights mystery |
| 1 | Collect 3 fuel + 2 medicine | free-order exploration, combat, loot |
| 2 | Defeat The Conductor | boss arena in North Hall, phases |
| 3 | Free the survivor | rescue cutscene, Iris follows |
| 4 | Return to the train | timed escape, horde waves every ~22s |
| Outro | (cutscene) | radio reveal, TO BE CONTINUED |

Timer: **240 s**. Time out or death = Game Over. Remaining seconds convert to bonus coins.

## Enemies
| Type | HP | Speed | Damage | Unique behavior |
|---|---|---|---|---|
| Walker | 30 | 62 | 10 | steady chase, weaving swarm motion |
| Runner | 20 | 150 | 8 | telegraphed lunge dash (240 px) |
| Heavy | 130 | 46 | 20 | wind-up ground slam, AoE + screen shake |
| The Conductor | 620 | 78 | 22–25 | charge (wall-crash stun window), summons walkers at 66%/33% HP, enrage <25% |

All zombies hear gunshots within ~520 px and investigate. Live-zombie cap: 26.

## Weapons & economy
- **Pistol** — 12 dmg, 3/s, 12 mag, 1.0 s reload. Reliable DPS at range.
- **Shotgun** — 6×7 dmg, 1.2/s, 5 mag, 1.8 s reload. Burst damage, boss/heavy killer.
- Upgrades (5 levels each): damage +15%/lvl, fire rate +10%/lvl, mag +2 (pistol) / +1
  (shotgun); gear: +15 HP vest, +6% speed boots. Costs scale linearly (base × next level).
- Sources of coins: zombie drops, crates, floor pickups, victory time bonus.

## Controls (landscape, one-thumb)
- Floating joystick spawns under the thumb on the left 60% of the screen.
- Auto-aim: nearest zombie with line of sight within 380 px; auto-fire (toggleable).
- Buttons: WEAPON switch, RELOAD (also automatic when empty), PAUSE. Android back = pause.

## Art & audio direction
Low-poly-style flat 2D: bright saturated character silhouettes over muted station palette,
outlined shapes, soft shadows, dusk CanvasModulate, drifting fog, warm flickering lamps
(diegetic mystery), vignette. Feedback: screen shake, hit-stop on boss kill, zoom punches,
floating damage numbers, goo splats. Audio is fully synthesized: 3 music loops
(menu/tension/boss), layered zombie growls, punchy weapon transients, UI ticks.

## Family-friendly guarantees
No blood — green goo bursts; zombies "pop" and fade. Bright colors, no gore textures,
no profanity, hopeful story tone.


## Chapter 2 — Sector Seven (4.5 min)
| Phase | Objective | Beats |
|---|---|---|
| Intro | (city cinematic + tower flyover) | Iris briefs the relay plan |
| 1 | Destroy 3 signal relays | breakable pylons guarded by Heavy+Runner pairs |
| 2 | Destroy The Broadcaster | crimson boss (760 HP, faster charges) at the tower |
| 3 | Return to the train | escape waves once relays AND boss are down |
| Outro | (cutscene) | the signal is still live — and moving at train speed. Chapter 3 hook: THE PASSENGER |

Map: ruined city blocks (solid roof buildings) around a central broadcast tower with a
pulsing red beacon; eerie "signal" beeps while the tower lives. Timer: 270 s.


## Chapter 3 — The Passenger (4.5 min)
Inside the moving Ember Line: six cars, rushing landscape outside the windows, periodic
carriage sway. Search 3 glowing luggage piles (stand-in-circle mechanic) → fight
**The Passenger** in the engine car (blink-teleports, 7-orb volleys, runner summons) →
backtrack the whole train to the rear car through wave spawns at every car door.
Reveal: the beacon is a *recall* device targeting the Vale bloodline. Destination: Depot 12.

## Chapter 4 — Depot 12 (5 min)
The freight yard that built the Ember Line. Container-stack lanes, assembly shed arena.
Destroy 3 recall amplifiers (armored relays, heavy guards) → **The Foreman** (shockwave
rings, charges, summons heavies) → escape to the loading dock.
Reveal: Project EMBER's lead engineer was E. Vale — Mara's mother. Hook: Chapter 5.

## Boss ability system
All bosses share one configurable kit (charge / orb volley / shockwave ring /
blink-teleport / minion summons at 66%+33% HP / enrage <25%), tuned per chapter:
Conductor = charge+walkers · Broadcaster = charge+volley+runners ·
Passenger = blink+dense volley+runners · Foreman = shockwave+charge+heavies.
