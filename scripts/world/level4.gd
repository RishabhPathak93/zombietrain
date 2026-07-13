class_name Level4
extends Level
## Chapter 4 — Depot 12. The freight yard where the Ember Line was built.
## Objectives: destroy 3 recall amplifiers, bring down The Foreman, escape.

const TEX_CONTAINER := preload("res://assets/textures/container.png")
const BOSS4 := preload("res://resources/enemies/boss4.tres")

var _amps: Array[Relay] = []

func _ready() -> void:
	intro_focus = Vector2(1550, 420)
	wave_spawn_points = [
		Vector2(320, 1470), Vector2(2850, 1470), Vector2(700, 700),
		Vector2(2500, 700), Vector2(1550, 950),
	]
	_common_init()
	_build_ground_depot()
	_build_walls_depot()
	_build_train()
	_build_warehouse()
	_build_amplifiers()
	_build_props_depot()
	_build_loot_depot()
	_build_zombies_depot()
	_build_atmosphere(Color(0.52, 0.47, 0.68), [
		Vector2(600, 500), Vector2(2500, 500), Vector2(1550, 1200),
		Vector2(1000, 1470), Vector2(2200, 1470),
	])
	build_gate(1274, 524, 548, 28)
	build_console(Vector2(1050, 620), "simon5")
	spawn_note(Vector2(600, 350), "Ember Memo #77",
		"Recall protocol is NOT a weapon. It is a leash.\nIf the field engineer's line is compromised, the assets walk home. — Dir. R.")
	spawn_note(Vector2(2700, 1250), "Locker Tag",
		"VALE, E. — Locker 9.\nContents transferred to the Ember Line, car 4. Do not log this transfer.")
	EventBus.objective_changed.connect(_check_boss_wake)

func _build_ground_depot() -> void:
	_tiled(TEX_GRASS, world_rect, -12)
	_tiled(preload("res://assets/textures/road.png"), Rect2(200, 200, 2772, 1180), -10)
	_tiled(TEX_PLATFORM, Rect2(200, 1380, 2772, 180), -10)
	_tiled(TEX_RAIL, Rect2(30, 1580, 3140, 64), -9)
	_tiled(TEX_RAIL, Rect2(30, 1660, 3140, 64), -9)
	for info in [
		[Vector2(1550, 700), "ASSEMBLY YARD"], [Vector2(480, 640), "AMP 1"],
		[Vector2(2620, 640), "AMP 2"], [Vector2(1550, 1180), "AMP 3"],
		[Vector2(1560, 1470), "DEPOT 12 — LOADING DOCK"],
	]:
		var label := UITheme.label(info[1], 30, Color(1, 1, 1, 0.15))
		label.position = info[0] - Vector2(100, 14)
		label.z_index = -8
		add_child(label)

func _build_walls_depot() -> void:
	_wall(30, 30, 3140, WALL_T)
	_wall(30, 1742, 3140, WALL_T)
	_wall(30, 30, WALL_T, 1740)
	_wall(3142, 30, WALL_T, 1740)
	# Yard fence with dock exits
	_wall(200, 1380, 320, WALL_T)
	_wall(680, 1380, 700, WALL_T)
	_wall(1820, 1380, 700, WALL_T)
	_wall(2680, 1380, 292, WALL_T)
	# Container stacks (solid) forming lanes
	for block in [
		Rect2(300, 240, 420, 220), Rect2(880, 240, 280, 360),
		Rect2(2040, 240, 280, 360), Rect2(2480, 240, 460, 220),
		Rect2(340, 820, 380, 240), Rect2(2460, 820, 380, 240),
		Rect2(1180, 1060, 300, 200), Rect2(1720, 1060, 300, 200),
	]:
		_wall(block.position.x, block.position.y, block.size.x, block.size.y, TEX_CONTAINER)

func _build_warehouse() -> void:
	# Open-front boss shed, center-north
	_wall(1250, 200, 600, WALL_T)
	_wall(1250, 228, WALL_T, 320)
	_wall(1822, 228, WALL_T, 320)
	boss = BossZombie.new()
	add_child(boss)
	boss.global_position = Vector2(1550, 400)
	boss.setup(BOSS4)
	boss.set_state(Zombie.ZState.IDLE)
	boss.can_charge = true
	boss.can_shockwave = true
	boss.can_volley = false
	boss.minion_data = HEAVY
	boss.minions_per_summon = 2
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var tshape := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(560, 340)
	tshape.shape = trect
	trigger.add_child(tshape)
	trigger.position = Vector2(1550, 400)
	trigger.body_entered.connect(_on_boss_zone)
	add_child(trigger)
	# Recall engine glow inside the shed
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.position = Vector2(1550, 300)
	glow.scale = Vector2(6, 6)
	glow.modulate = Color(1.0, 0.5, 0.2, 0.14)
	glow.z_index = 30
	add_child(glow)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(glow, "modulate:a", 0.24, 0.8)
	tw.tween_property(glow, "modulate:a", 0.1, 0.8)

func _check_boss_wake() -> void:
	if not _boss_triggered and GameState.gate_open:
		_boss_triggered = true
		Fx.float_text(Vector2(1550, 520), "THE YARD SHAKES", UITheme.COL_BAD, 26)
		boss.activate()

func _build_amplifiers() -> void:
	for pos in [Vector2(480, 700), Vector2(2620, 700), Vector2(1550, 1140)]:
		var amp := Relay.new()
		amp.position = pos
		amp.label_text = "AMPLIFIER DOWN"
		amp.hp = 80.0
		add_child(amp)
		_amps.append(amp)
		spawn_zombie(HEAVY, pos + Vector2(80, 30))
		spawn_zombie(WALKER, pos + Vector2(-80, -40))

func _build_props_depot() -> void:
	var crate_spots := [
		Vector2(800, 700), Vector2(1350, 800), Vector2(1750, 800), Vector2(2300, 700),
		Vector2(500, 1150), Vector2(2500, 1150), Vector2(1000, 950), Vector2(2100, 950),
		Vector2(700, 350), Vector2(2400, 550), Vector2(2900, 1250), Vector2(300, 1250),
	]
	for pos in crate_spots:
		var crate := Crate.new()
		crate.position = pos + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-10, 10))
		add_child(crate)
	for pos in [Vector2(760, 1470), Vector2(2350, 1470), Vector2(1250, 620), Vector2(1850, 620)]:
		_prop(preload("res://assets/textures/barrel.png"), pos, true, Vector2(40, 40))

func _build_loot_depot() -> void:
	for pos in [Vector2(1000, 620), Vector2(2150, 620), Vector2(1550, 950)]:
		_spawn_pickup("heart", pos)
	for pos in [Vector2(600, 950), Vector2(2450, 950), Vector2(1350, 500)]:
		_spawn_pickup("ammo", pos)
	var coin_spots: Array[Vector2] = [
		Vector2(850, 620), Vector2(1650, 700), Vector2(2350, 620),
		Vector2(500, 1000), Vector2(1550, 1000), Vector2(2600, 1000),
		Vector2(1200, 350), Vector2(2450, 400), Vector2(400, 500),
		Vector2(1000, 1470), Vector2(2100, 1470), Vector2(2900, 700),
		Vector2(300, 700), Vector2(1550, 850),
	]
	for spot in coin_spots:
		spawn_coin(spot + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30)))

func _build_zombies_depot() -> void:
	var placements := [
		[WALKER, Vector2(950, 1470)], [RUNNER, Vector2(2250, 1470)],
		[WALKER, Vector2(800, 620)], [HEAVY, Vector2(1150, 700)],
		[WALKER, Vector2(1950, 700)], [RUNNER, Vector2(2300, 620)],
		[HEAVY, Vector2(1550, 900)], [WALKER, Vector2(1350, 950)],
		[RUNNER, Vector2(1750, 950)],
		[WALKER, Vector2(500, 350)], [RUNNER, Vector2(780, 500)],
		[WALKER, Vector2(2400, 350)], [RUNNER, Vector2(2250, 500)],
		[HEAVY, Vector2(2900, 900)], [WALKER, Vector2(300, 950)],
		[WALKER, Vector2(2700, 1250)], [RUNNER, Vector2(450, 1200)],
	]
	for entry in placements:
		spawn_zombie(entry[0], entry[1])

func _update_targets() -> void:
	var targets := {}
	var live: Array[Relay] = []
	for amp in _amps:
		if is_instance_valid(amp) and not amp._dead:
			live.append(amp)
	_amps = live
	if not live.is_empty():
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var player_pos: Vector2 = players[0].global_position
			var best := live[0].global_position
			var best_dist := INF
			for amp in live:
				var d := player_pos.distance_squared_to(amp.global_position)
				if d < best_dist:
					best_dist = d
					best = amp.global_position
			targets["relays"] = best
	if boss and is_instance_valid(boss):
		targets["boss"] = boss.global_position
	targets["gate"] = gate_console_pos
	targets["escape"] = train_door_pos
	GameState.objective_targets = targets
