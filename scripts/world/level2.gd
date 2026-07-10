class_name Level2
extends Level
## Chapter 2 — Sector Seven. Ruined city blocks around the broadcast tower.
## Objectives: destroy 3 signal relays, kill The Broadcaster, escape.

const TEX_ROAD := preload("res://assets/textures/road.png")
const TEX_ROOF := preload("res://assets/textures/roof.png")
const TEX_TOWER := preload("res://assets/textures/tower.png")
const BOSS2 := preload("res://resources/enemies/boss2.tres")

var _relays: Array[Relay] = []
var _tower_pos := Vector2(1600, 430)
var _signal_timer := 4.0

func _ready() -> void:
	_common_init()
	intro_focus = _tower_pos
	wave_spawn_points = [
		Vector2(320, 1470), Vector2(2850, 1470), Vector2(850, 700),
		Vector2(2350, 700), Vector2(1600, 900),
	]
	_build_ground_city()
	_build_walls_city()
	_build_train()
	_build_tower()
	_build_relays()
	_build_props_city()
	_build_loot_city()
	_build_zombies_city()
	_build_atmosphere(Color(0.72, 0.75, 0.95), [
		Vector2(550, 700), Vector2(2650, 700), Vector2(1600, 1250),
		Vector2(1000, 1470), Vector2(2200, 1470),
	])
	EventBus.objective_changed.connect(_check_boss_wake)

# ---------------------------------------------------------------- ground
func _build_ground_city() -> void:
	_tiled(TEX_GRASS, world_rect, -12)
	_tiled(TEX_ROAD, Rect2(200, 200, 2772, 1180), -10)
	_tiled(TEX_PLATFORM, Rect2(200, 1380, 2772, 180), -10)
	_tiled(TEX_RAIL, Rect2(30, 1580, 3140, 64), -9)
	_tiled(TEX_RAIL, Rect2(30, 1660, 3140, 64), -9)
	for info in [
		[Vector2(1600, 640), "BROADCAST TOWER"], [Vector2(520, 640), "RELAY A"],
		[Vector2(2560, 640), "RELAY B"], [Vector2(1600, 1200), "RELAY C"],
		[Vector2(1560, 1470), "SECTOR SEVEN — PLATFORM"],
	]:
		var label := UITheme.label(info[1], 30, Color(1, 1, 1, 0.15))
		label.position = info[0] - Vector2(110, 14)
		label.z_index = -8
		add_child(label)

# ---------------------------------------------------------------- layout
func _build_walls_city() -> void:
	# World border
	_wall(30, 30, 3140, WALL_T)
	_wall(30, 1742, 3140, WALL_T)
	_wall(30, 30, WALL_T, 1740)
	_wall(3142, 30, WALL_T, 1740)
	# Fence between city and platform, with three street exits
	_wall(200, 1380, 320, WALL_T)
	_wall(680, 1380, 700, WALL_T)
	_wall(1820, 1380, 700, WALL_T)
	_wall(2680, 1380, 292, WALL_T)
	# City blocks (solid buildings, roof texture)
	for block in [
		Rect2(280, 260, 480, 320), Rect2(1020, 240, 400, 300),
		Rect2(2040, 240, 380, 320), Rect2(2660, 260, 320, 340),
		Rect2(280, 840, 420, 340), Rect2(1060, 920, 360, 300),
		Rect2(1960, 920, 400, 300), Rect2(2620, 840, 360, 340),
	]:
		_wall(block.position.x, block.position.y, block.size.x, block.size.y, TEX_ROOF)

# ---------------------------------------------------------------- tower & boss
func _build_tower() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEX_TOWER
	sprite.position = _tower_pos
	sprite.z_index = 16
	add_child(sprite)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 96.0
	shape.shape = circle
	body.add_child(shape)
	body.position = _tower_pos
	add_child(body)
	# Menacing red pulse over the whole compound
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.position = _tower_pos
	glow.scale = Vector2(9, 9)
	glow.modulate = Color(1.0, 0.2, 0.18, 0.1)
	glow.z_index = 30
	add_child(glow)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(glow, "modulate:a", 0.22, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 0.08, 0.9).set_trans(Tween.TRANS_SINE)
	# The Broadcaster, dormant at the tower's foot
	boss = BossZombie.new()
	add_child(boss)
	boss.global_position = _tower_pos + Vector2(0, 190)
	boss.setup(BOSS2)
	boss.set_state(Zombie.ZState.IDLE)
	boss.can_charge = true
	boss.can_volley = true
	boss.volley_count = 5
	boss.minion_data = RUNNER
	# Early wake-up if the player strolls into the compound
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var tshape := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(560, 480)
	tshape.shape = trect
	trigger.add_child(tshape)
	trigger.position = _tower_pos + Vector2(0, 80)
	trigger.body_entered.connect(_on_boss_zone)
	add_child(trigger)

func _check_boss_wake() -> void:
	if not _boss_triggered and GameState.relays >= GameState.RELAYS_NEEDED:
		_boss_triggered = true
		Fx.float_text(_tower_pos + Vector2(0, 160), "THE TOWER SCREAMS", UITheme.COL_BAD, 26)
		boss.activate()

# ---------------------------------------------------------------- relays
func _build_relays() -> void:
	for pos in [Vector2(520, 700), Vector2(2560, 700), Vector2(1600, 1260)]:
		var relay := Relay.new()
		relay.position = pos
		add_child(relay)
		_relays.append(relay)
		# Guards
		spawn_zombie(HEAVY, pos + Vector2(70, 40))
		spawn_zombie(RUNNER, pos + Vector2(-80, -40))

# ---------------------------------------------------------------- props & loot
func _build_props_city() -> void:
	var crate_spots := [
		Vector2(860, 420), Vector2(920, 480), Vector2(1550, 300), Vector2(2500, 450),
		Vector2(820, 1100), Vector2(1650, 1050), Vector2(2450, 1100), Vector2(380, 700),
		Vector2(1250, 700), Vector2(1950, 700), Vector2(2900, 500), Vector2(1450, 1300),
	]
	for pos in crate_spots:
		var crate := Crate.new()
		crate.position = pos + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-10, 10))
		add_child(crate)
	for pos in [Vector2(760, 1470), Vector2(2350, 1470), Vector2(1500, 620), Vector2(2900, 1200)]:
		_prop(preload("res://assets/textures/barrel.png"), pos, true, Vector2(40, 40))

func _build_loot_city() -> void:
	for pos in [Vector2(900, 620), Vector2(2300, 620), Vector2(1600, 820)]:
		_spawn_pickup("heart", pos)
	for pos in [Vector2(500, 1200), Vector2(2700, 1200), Vector2(1350, 450)]:
		_spawn_pickup("ammo", pos)
	var coin_spots: Array[Vector2] = [
		Vector2(850, 620), Vector2(1750, 620), Vector2(2450, 620),
		Vector2(500, 1100), Vector2(1600, 1120), Vector2(2650, 1100),
		Vector2(880, 900), Vector2(1500, 900), Vector2(2350, 900),
		Vector2(1200, 300), Vector2(2550, 350), Vector2(400, 620),
		Vector2(1000, 1470), Vector2(2100, 1470), Vector2(1600, 700),
		Vector2(2900, 620),
	]
	for spot in coin_spots:
		spawn_coin(spot + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30)))

func _build_zombies_city() -> void:
	var placements := [
		[WALKER, Vector2(900, 1470)], [WALKER, Vector2(2250, 1470)],
		[RUNNER, Vector2(1450, 1470)],
		[WALKER, Vector2(850, 680)], [RUNNER, Vector2(1250, 640)],
		[WALKER, Vector2(1900, 680)], [RUNNER, Vector2(2350, 640)],
		[WALKER, Vector2(500, 900)], [HEAVY, Vector2(900, 1050)],
		[WALKER, Vector2(1550, 1050)], [RUNNER, Vector2(2200, 1050)],
		[HEAVY, Vector2(2700, 950)],
		[WALKER, Vector2(900, 300)], [RUNNER, Vector2(1750, 320)],
		[WALKER, Vector2(2500, 320)], [RUNNER, Vector2(1350, 550)],
		[WALKER, Vector2(1850, 550)],
	]
	for entry in placements:
		spawn_zombie(entry[0], entry[1])

# ---------------------------------------------------------------- runtime
func _process(delta: float) -> void:
	super._process(delta)
	# The tower whispers while it is alive...
	if not GameState.boss_defeated and GameState.state == GameState.State.PLAYING:
		_signal_timer -= delta
		if _signal_timer <= 0.0:
			_signal_timer = _rng.randf_range(7.0, 12.0)
			AudioMan.play("signal", -16.0, 0.05)

func _update_targets() -> void:
	var targets := {}
	var live: Array[Relay] = []
	for relay in _relays:
		if is_instance_valid(relay) and not relay._dead:
			live.append(relay)
	_relays = live
	if not live.is_empty():
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var player_pos: Vector2 = players[0].global_position
			var best := live[0].global_position
			var best_dist := INF
			for relay in live:
				var d := player_pos.distance_squared_to(relay.global_position)
				if d < best_dist:
					best_dist = d
					best = relay.global_position
			targets["relays"] = best
	if boss and is_instance_valid(boss):
		targets["boss"] = boss.global_position
	targets["escape"] = train_door_pos
	GameState.objective_targets = targets
