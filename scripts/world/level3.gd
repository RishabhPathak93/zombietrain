class_name Level3
extends Level
## Chapter 3 — The Passenger. Inside the moving Ember Line: six train cars,
## searchable luggage, and a blinking boss in the engine car. The escape
## backtracks the whole train.

const TEX_TRAINFLOOR := preload("res://assets/textures/trainfloor.png")
const TEX_TRAINWALL := preload("res://assets/textures/trainwall.png")
const BOSS3 := preload("res://resources/enemies/boss3.tres")

const CAR_XS := [860.0, 1570.0, 2280.0, 2990.0, 3700.0] # partition positions

var _search_points: Array[SearchPoint] = []
var _rumble_timer := 3.0

func _ready() -> void:
	world_rect = Rect2(0, 0, 4600, 1000)
	player_start = Vector2(350, 500)
	train_door_pos = Vector2(300, 500)
	intro_focus = Vector2(1215, 500)
	wave_spawn_points = [
		Vector2(860, 500), Vector2(1570, 500), Vector2(2280, 500),
		Vector2(2990, 500), Vector2(3700, 500),
	]
	_common_init()
	_build_interior()
	_build_furniture()
	_build_search_points()
	_build_engine_car()
	_build_exit()
	_build_loot_train()
	_build_zombies_train()
	_build_atmosphere_train()

# ---------------------------------------------------------------- structure
func _build_interior() -> void:
	# The world outside the windows is a dark blur
	var void_bg := ColorRect.new()
	void_bg.color = Color(0.03, 0.03, 0.06)
	void_bg.size = world_rect.size
	void_bg.z_index = -20
	add_child(void_bg)
	_tiled(TEX_TRAINFLOOR, Rect2(150, 260, 4300, 480), -10)
	# Hull
	_wall(150, 236, 4300, 24, TEX_TRAINWALL)
	_wall(150, 740, 4300, 24, TEX_TRAINWALL)
	_wall(150, 236, 24, 528, TEX_TRAINWALL)
	_wall(4426, 236, 24, 528, TEX_TRAINWALL)
	# Car partitions with center doorways
	for x in CAR_XS:
		_wall(x, 260, 24, 180, TEX_TRAINWALL)
		_wall(x, 560, 24, 180, TEX_TRAINWALL)
	# Car labels
	var names := ["CAR 1 — REAR", "CAR 2", "CAR 3", "CAR 4", "CAR 5", "ENGINE CAR"]
	var centers := [505.0, 1215.0, 1925.0, 2635.0, 3345.0, 4075.0]
	for i in names.size():
		var label := UITheme.label(names[i], 26, Color(1, 1, 1, 0.14))
		label.position = Vector2(centers[i] - 80, 486)
		label.z_index = -8
		add_child(label)

func _build_furniture() -> void:
	# Seat rows against both hull walls in cars 1-5
	for car in 5:
		var x0 := 220.0 + car * 710.0
		for i in 3:
			var x := x0 + i * 200.0
			if x > 4300:
				continue
			_prop(preload("res://assets/textures/bench.png"), Vector2(x, 318), true)
			_prop(preload("res://assets/textures/bench.png"), Vector2(x + 90, 682), true)
	# Luggage crates in the aisles
	for pos in [
		Vector2(700, 500), Vector2(1420, 380), Vector2(2100, 620),
		Vector2(2800, 400), Vector2(3500, 600), Vector2(3200, 420),
	]:
		var crate := Crate.new()
		crate.position = pos
		add_child(crate)

func _build_search_points() -> void:
	for pos in [Vector2(1215, 390), Vector2(1925, 610), Vector2(3345, 390)]:
		var point := SearchPoint.new()
		point.position = pos
		add_child(point)
		_search_points.append(point)

func _build_engine_car() -> void:
	boss = BossZombie.new()
	add_child(boss)
	boss.global_position = Vector2(4120, 500)
	boss.setup(BOSS3)
	boss.set_state(Zombie.ZState.IDLE)
	boss.can_charge = false
	boss.can_volley = true
	boss.can_blink = true
	boss.volley_count = 7
	boss.minion_data = RUNNER
	boss.minions_per_summon = 3
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var tshape := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(700, 460)
	tshape.shape = trect
	trigger.add_child(tshape)
	trigger.position = Vector2(4075, 500)
	trigger.body_entered.connect(_on_boss_zone)
	add_child(trigger)
	# Engine glow
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.position = Vector2(4380, 500)
	glow.scale = Vector2(4, 4)
	glow.modulate = Color(0.4, 0.95, 0.85, 0.16)
	glow.z_index = 30
	add_child(glow)

func _build_exit() -> void:
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(240, 400)
	shape.shape = rect
	zone.add_child(shape)
	zone.position = train_door_pos
	zone.body_entered.connect(_on_train_zone)
	add_child(zone)
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.position = train_door_pos
	glow.scale = Vector2(3, 3)
	glow.modulate = Color(1.0, 0.9, 0.6, 0.14)
	glow.z_index = 30
	add_child(glow)

# ---------------------------------------------------------------- content
func _build_loot_train() -> void:
	for pos in [Vector2(1700, 400), Vector2(3100, 600)]:
		_spawn_pickup("heart", pos)
	for pos in [Vector2(1000, 600), Vector2(2500, 400), Vector2(3900, 500)]:
		_spawn_pickup("ammo", pos)
	var coin_spots: Array[Vector2] = [
		Vector2(600, 400), Vector2(950, 500), Vector2(1350, 620),
		Vector2(1800, 380), Vector2(2200, 500), Vector2(2550, 620),
		Vector2(2900, 380), Vector2(3250, 500), Vector2(3600, 400),
		Vector2(3950, 620),
	]
	for spot in coin_spots:
		spawn_coin(spot + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-20, 20)))

func _build_zombies_train() -> void:
	var placements := [
		[WALKER, Vector2(650, 380)], [WALKER, Vector2(780, 620)],
		[RUNNER, Vector2(1100, 500)], [WALKER, Vector2(1350, 380)],
		[HEAVY, Vector2(1570, 500)],
		[WALKER, Vector2(1800, 620)], [RUNNER, Vector2(2050, 400)],
		[WALKER, Vector2(2450, 620)], [RUNNER, Vector2(2700, 500)],
		[HEAVY, Vector2(2990, 500)],
		[WALKER, Vector2(3150, 380)], [WALKER, Vector2(3450, 620)],
		[RUNNER, Vector2(3600, 400)], [HEAVY, Vector2(3700, 500)],
	]
	for entry in placements:
		spawn_zombie(entry[0], entry[1])

func _build_atmosphere_train() -> void:
	var dusk := CanvasModulate.new()
	dusk.color = Color(0.7, 0.72, 0.9)
	add_child(dusk)
	# Cabin lamps
	for i in 6:
		var glow := Sprite2D.new()
		glow.texture = preload("res://assets/textures/glow.png")
		glow.position = Vector2(505 + i * 710.0, 500)
		glow.scale = Vector2(5, 5)
		glow.modulate = Color(1.0, 0.92, 0.7, 0.14)
		add_child(glow)
		glow.z_index = 30
	# Rushing landscape streaks outside the hull
	for i in 14:
		var streak := Sprite2D.new()
		streak.texture = preload("res://assets/textures/softdot.png")
		var top := i % 2 == 0
		streak.position = Vector2(randf_range(0, 4600), randf_range(60, 180) if top else randf_range(820, 940))
		streak.scale = Vector2(randf_range(4, 8), 0.7)
		streak.modulate = Color(0.55, 0.6, 0.85, 0.18)
		streak.z_index = -15
		add_child(streak)
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(streak, "position:x", streak.position.x - 2200.0, randf_range(0.9, 1.6))
		tw.tween_callback(func() -> void: streak.position.x = 4800.0)

# ---------------------------------------------------------------- runtime
func _process(delta: float) -> void:
	super._process(delta)
	# The train sways.
	if GameState.state == GameState.State.PLAYING:
		_rumble_timer -= delta
		if _rumble_timer <= 0.0:
			_rumble_timer = _rng.randf_range(4.0, 8.0)
			Fx.shake(1.6)

func _update_targets() -> void:
	var targets := {}
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player_pos: Vector2 = players[0].global_position
		var best := Vector2.ZERO
		var best_dist := INF
		for point in _search_points:
			if is_instance_valid(point) and not point.done:
				var d := player_pos.distance_squared_to(point.global_position)
				if d < best_dist:
					best_dist = d
					best = point.global_position
		if best != Vector2.ZERO:
			targets["search"] = best
	if boss and is_instance_valid(boss):
		targets["boss"] = boss.global_position
	targets["escape"] = train_door_pos
	GameState.objective_targets = targets
