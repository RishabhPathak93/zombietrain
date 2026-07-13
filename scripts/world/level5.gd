class_name Level5
extends Level
## Chapter 5 — Project EMBER. The underground lab beneath Depot 12 where
## the signal was born. Destroy 3 echo conduits, override the vault, and
## silence The Voice — the finale.

const TEX_LABFLOOR := preload("res://assets/textures/trainfloor.png")
const TEX_LABWALL := preload("res://assets/textures/trainwall.png")
const BOSS5 := preload("res://resources/enemies/boss5.tres")

var _conduits: Array[Relay] = []
var _pulse_timer := 5.0

func _ready() -> void:
	intro_focus = Vector2(1600, 420)
	wave_spawn_points = [
		Vector2(320, 1470), Vector2(2850, 1470), Vector2(800, 700),
		Vector2(2400, 700), Vector2(1600, 950),
	]
	_common_init()
	_build_ground_lab()
	_build_walls_lab()
	_build_train()
	_build_vault()
	_build_conduits()
	_build_props_lab()
	_build_loot_lab()
	_build_zombies_lab()
	_build_atmosphere(Color(0.42, 0.5, 0.62), [
		Vector2(600, 650), Vector2(2600, 650), Vector2(1600, 1150),
		Vector2(1000, 1470), Vector2(2200, 1470),
	])
	build_gate(1450, 672, 300, 56)
	build_console(Vector2(1200, 800), "simon5")
	spawn_note(Vector2(550, 400), "Vale Recording #1",
		"Personal log, E. Vale. The board wants EMBER as a broadcast weapon. I designed it as a shepherd's whistle.\nIf it ever slips its leash... it will look for my key. My blood.")
	spawn_note(Vector2(2650, 1150), "Vale Recording #2",
		"Mara — if you ever stand in this room, I am already gone.\nThe heart of EMBER is behind the vault. Burn it. Don't listen to it. BE FREE.")
	EventBus.objective_changed.connect(_check_boss_wake)

func _build_ground_lab() -> void:
	var void_bg := ColorRect.new()
	void_bg.color = Color(0.015, 0.02, 0.035)
	void_bg.size = world_rect.size
	void_bg.z_index = -20
	add_child(void_bg)
	_tiled(TEX_LABFLOOR, Rect2(200, 200, 2772, 1180), -10)
	_tiled(TEX_PLATFORM, Rect2(200, 1380, 2772, 180), -10)
	_tiled(TEX_RAIL, Rect2(30, 1580, 3140, 64), -9)
	_tiled(TEX_RAIL, Rect2(30, 1660, 3140, 64), -9)
	for info in [
		[Vector2(1600, 620), "THE VAULT"], [Vector2(560, 620), "CONDUIT A"],
		[Vector2(2620, 620), "CONDUIT B"], [Vector2(1600, 1160), "CONDUIT C"],
		[Vector2(1560, 1470), "FREIGHT ELEVATOR — EMBER LINE"],
	]:
		var label := UITheme.label(info[1], 30, Color(0.6, 1.0, 0.95, 0.16))
		label.position = info[0] - Vector2(110, 14)
		label.z_index = -8
		add_child(label)

func _build_walls_lab() -> void:
	_wall(30, 30, 3140, WALL_T, TEX_LABWALL)
	_wall(30, 1742, 3140, WALL_T, TEX_LABWALL)
	_wall(30, 30, WALL_T, 1740, TEX_LABWALL)
	_wall(3142, 30, WALL_T, 1740, TEX_LABWALL)
	_wall(200, 1380, 320, WALL_T, TEX_LABWALL)
	_wall(680, 1380, 700, WALL_T, TEX_LABWALL)
	_wall(1820, 1380, 700, WALL_T, TEX_LABWALL)
	_wall(2680, 1380, 292, WALL_T, TEX_LABWALL)
	# Lab blocks (server rooms / tanks)
	for block in [
		Rect2(300, 260, 460, 300), Rect2(1000, 240, 360, 280),
		Rect2(1840, 240, 360, 280), Rect2(2500, 260, 460, 300),
		Rect2(320, 860, 420, 300), Rect2(2460, 860, 420, 300),
		Rect2(1220, 1020, 300, 220), Rect2(1680, 1020, 300, 220),
	]:
		_wall(block.position.x, block.position.y, block.size.x, block.size.y, TEX_LABWALL)
	# Vault chamber (final arena)
	_wall(1400, 200, 400, WALL_T, TEX_LABWALL)
	_wall(1400, 228, WALL_T, 444, TEX_LABWALL)
	_wall(1772, 228, WALL_T, 444, TEX_LABWALL)

func _build_vault() -> void:
	boss = BossZombie.new()
	add_child(boss)
	boss.global_position = Vector2(1600, 420)
	boss.setup(BOSS5)
	boss.set_state(Zombie.ZState.IDLE)
	# The Voice: every ability in the kit
	boss.can_charge = true
	boss.can_volley = true
	boss.can_shockwave = true
	boss.can_blink = true
	boss.volley_count = 6
	boss.minion_data = RUNNER
	boss.minions_per_summon = 3
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var tshape := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(360, 420)
	tshape.shape = trect
	trigger.add_child(tshape)
	trigger.position = Vector2(1600, 440)
	trigger.body_entered.connect(_on_boss_zone)
	add_child(trigger)
	# The heart of EMBER: pulsing teal core
	var core := Sprite2D.new()
	core.texture = preload("res://assets/textures/glow.png")
	core.position = Vector2(1600, 300)
	core.scale = Vector2(7, 7)
	core.modulate = Color(0.35, 1.0, 0.9, 0.12)
	core.z_index = 30
	add_child(core)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(core, "modulate:a", 0.28, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(core, "modulate:a", 0.08, 1.1).set_trans(Tween.TRANS_SINE)

func _check_boss_wake() -> void:
	if not _boss_triggered and GameState.gate_open:
		_boss_triggered = true
		Fx.float_text(Vector2(1600, 560), "THE VAULT OPENS", UITheme.COL_BAD, 26)
		boss.activate()

func _build_conduits() -> void:
	for pos in [Vector2(560, 680), Vector2(2620, 680), Vector2(1600, 1200)]:
		var conduit := Relay.new()
		conduit.position = pos
		conduit.label_text = "CONDUIT DOWN"
		conduit.hp = 90.0
		add_child(conduit)
		_conduits.append(conduit)
		spawn_zombie(HEAVY, pos + Vector2(80, 30))
		spawn_zombie(RUNNER, pos + Vector2(-80, -40))
		spawn_zombie(RUNNER, pos + Vector2(0, 80))

func _build_props_lab() -> void:
	for pos in [
		Vector2(850, 650), Vector2(2350, 650), Vector2(1600, 850),
		Vector2(500, 1200), Vector2(2700, 1200), Vector2(900, 1000),
		Vector2(2300, 1000), Vector2(1000, 350), Vector2(2200, 350),
	]:
		var crate := Crate.new()
		crate.position = pos + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-10, 10))
		add_child(crate)
	for pos in [Vector2(760, 1470), Vector2(2350, 1470), Vector2(1380, 720), Vector2(1820, 720)]:
		_prop(preload("res://assets/textures/barrel.png"), pos, true, Vector2(40, 40))

func _build_loot_lab() -> void:
	for pos in [Vector2(900, 620), Vector2(2300, 620), Vector2(1600, 950)]:
		_spawn_pickup("heart", pos)
	for pos in [Vector2(600, 950), Vector2(2500, 950), Vector2(1350, 480)]:
		_spawn_pickup("ammo", pos)
	for pos in [Vector2(1100, 700), Vector2(2100, 700)]:
		_spawn_pickup("grenade", pos)
	var coin_spots: Array[Vector2] = [
		Vector2(850, 700), Vector2(1750, 750), Vector2(2350, 700),
		Vector2(500, 1050), Vector2(1600, 1080), Vector2(2650, 1050),
		Vector2(1200, 350), Vector2(2400, 400), Vector2(400, 650),
		Vector2(1000, 1470), Vector2(2100, 1470), Vector2(2900, 700),
	]
	for spot in coin_spots:
		spawn_coin(spot + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30)))

func _build_zombies_lab() -> void:
	var placements := [
		[WALKER, Vector2(950, 1470)], [RUNNER, Vector2(2250, 1470)],
		[RUNNER, Vector2(850, 700)], [HEAVY, Vector2(1150, 750)],
		[WALKER, Vector2(1950, 750)], [RUNNER, Vector2(2300, 700)],
		[HEAVY, Vector2(1600, 900)], [RUNNER, Vector2(1400, 950)],
		[WALKER, Vector2(500, 400)], [RUNNER, Vector2(850, 500)],
		[WALKER, Vector2(2400, 400)], [RUNNER, Vector2(2200, 500)],
		[HEAVY, Vector2(2900, 950)], [WALKER, Vector2(300, 950)],
		[RUNNER, Vector2(2700, 1250)], [RUNNER, Vector2(450, 1250)],
	]
	for entry in placements:
		spawn_zombie(entry[0], entry[1])

func _process(delta: float) -> void:
	super._process(delta)
	if not GameState.boss_defeated and GameState.state == GameState.State.PLAYING:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = _rng.randf_range(6.0, 10.0)
			AudioMan.play("signal", -14.0, 0.0)
			Fx.shake(1.2)

func _update_targets() -> void:
	var targets := {}
	var live: Array[Relay] = []
	for conduit in _conduits:
		if is_instance_valid(conduit) and not conduit._dead:
			live.append(conduit)
	_conduits = live
	if not live.is_empty():
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var player_pos: Vector2 = players[0].global_position
			var best := live[0].global_position
			var best_dist := INF
			for conduit in live:
				var d := player_pos.distance_squared_to(conduit.global_position)
				if d < best_dist:
					best_dist = d
					best = conduit.global_position
			targets["relays"] = best
	if boss and is_instance_valid(boss):
		targets["boss"] = boss.global_position
	targets["gate"] = gate_console_pos
	targets["escape"] = train_door_pos
	GameState.objective_targets = targets
