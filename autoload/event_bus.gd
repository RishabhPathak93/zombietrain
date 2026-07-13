extends Node
## Global signal hub. All cross-system communication flows through here
## so systems stay decoupled and individually replaceable.

# Player
signal player_health_changed(hp: int, max_hp: int)
signal player_died
signal ammo_changed(mag: int, mag_size: int, weapon_id: String, reloading: bool)
signal weapon_changed(weapon_id: String)
signal reload_started(duration: float)
signal gunshot(pos: Vector2)
signal grenades_changed(count: int)
signal dash_used(cooldown: float)

# Economy / loot
signal coins_changed(total: int)
signal pickup_collected(kind: String, amount: int)

# Enemies
signal enemy_died(kind: String, pos: Vector2)
signal boss_spawned(max_hp: int)
signal boss_health_changed(hp: int, max_hp: int)
signal boss_defeated

# Mission flow
signal objective_changed
signal survivor_rescued
signal escape_phase_started
signal wave_incoming
signal time_low
signal note_found(title: String, text: String)
signal comm(speaker: String, text: String)
signal game_won
signal game_lost(reason: String)

# Cutscenes
signal cutscene_started
signal cutscene_finished
