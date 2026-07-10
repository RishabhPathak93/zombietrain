class_name Level
extends Node2D
## Junction Nine — abandoned railway station. Builds the whole map
## procedurally from primitives + generated textures: rooms, props, loot,
## zombies, the caged survivor, the boss hall, and the train.

signal boss_zone_entered

var world_rect := Rect2(0, 0, 3200, 1800)
const WALL_T := 28.0
const ZOMBIE_CAP := 26

const WALKER := preload("res://resources/enemies/walker.tres")
const RUNNER := preload("res://resources/enemies/runner.tres")
const HEAVY := preload("res://resources/enemies/heavy.tres")
const BOSS := preload("res://resources/enemies/boss.tres")

const TEX_FLOOR := preload("res://assets/textures/floor.png")
const TEX_PLATFORM := preload("res://assets/textures/platform.png")
const TEX_GRASS := preload("res://assets/textures/grass.png")
const TEX_WALL := preload("res://assets/textures/wall.png")
const TEX_RAIL := preload("res://assets/textures/rail.png")
const TEX_TRAIN := preload("res://assets/textures/train.png")
const TEX_CAGE := preload("res://assets/textures/cage.png")
const TEX_BENCH := preload("res://assets/textures/bench.png")
const TEX_BARREL := preload("res://assets/textures/barrel.png")
const TEX_GLOW := preload("res://assets/textures/glow.png")
const TEX_SOFT := preload("res://assets/textures/softdot.png")

var boss: BossZombie
var survivor: Survivor
var cage: StaticBody2D
var train_door_pos := Vector2(1560, 1460)
var player_start := Vector2(1560, 1480)
var intro_focus := Vector2(1600, 500)

var _fuel_pickups: Array[Pickup] = []
var _med_pickups: Array[Pickup] = []
var _target_timer := 0.0
var _wave_timer := 0.0
var _escape_active := false
var _boss_triggered := false
var _rng := RandomNumberGenerator.new()

var wave_spawn_points: Array[Vector2] = [
	Vector2(300, 1470), Vector2(2850, 1470), Vector2(1100, 1050),
	Vector2(2100, 1050), Vector2(1600, 750),
]

func _ready() -> void:
	_common_init()
	_build_ground()
	_build_walls()
	_build_train()
	_build_props()
	_build_loot()
	_build_zombies()
	_build_boss_hall()
	_build_atmosphere()

func _common_init() -> void:
	_rng.randomize()
	Pool.register("coin", _make_coin)
	EventBus.escape_phase_started.connect(_on_escape_phase)

# ---------------------------------------------------------------- ground
func _tiled(tex: Texture2D, rect: Rect2, z: int = -10, tint := Color.WHITE) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, rect.size)
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_index = z
	sprite.modulate = tint
	add_child(sprite)

func _build_ground() -> void:
	_tiled(TEX_GRASS, world_rect, -12)
	# Station interior floor
	_tiled(TEX_FLOOR, Rect2(200, 200, 2772, 1180), -10)
	# Platform strip
	_tiled(TEX_PLATFORM, Rect2(200, 1380, 2772, 180), -10)
	# Rails
	_tiled(TEX_RAIL, Rect2(30, 1580, 3140, 64), -9)
	_tiled(TEX_RAIL, Rect2(30, 1660, 3140, 64), -9)
	# Room name stencils
	for info in [
		[Vector2(650, 1040), "WAREHOUSE"], [Vector2(1600, 1040), "MAIN HALL"],
		[Vector2(2550, 1040), "WAITING ROOM"], [Vector2(600, 450), "FUEL DEPOT"],
		[Vector2(1600, 640), "NORTH HALL"], [Vector2(2600, 450), "CLINIC"],
		[Vector2(1560, 1470), "PLATFORM 1"],
	]:
		var label := UITheme.label(info[1], 30, Color(1, 1, 1, 0.15))
		label.position = info[0] - Vector2(90, 14)
		label.z_index = -8
		add_child(label)

# ---------------------------------------------------------------- walls
func _wall(x: float, y: float, w: float, h: float, tex: Texture2D = TEX_WALL) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2(x + w / 2.0, y + h / 2.0)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, w, h)
	sprite.z_index = 15
	body.add_child(sprite)
	add_child(body)

func _build_walls() -> void:
	# World border
	_wall(30, 30, 3140, WALL_T)
	_wall(30, 1742, 3140, WALL_T)
	_wall(30, 30, WALL_T, 1740)
	_wall(3142, 30, WALL_T, 1740)
	# Station shell
	_wall(200, 200, 2772, WALL_T)
	_wall(200, 200, WALL_T, 1208)
	_wall(2944, 200, WALL_T, 1208)
	# South wall (platform side) with doors
	_wall(200, 1380, 300, WALL_T)
	_wall(620, 1380, 830, WALL_T)
	_wall(1670, 1380, 830, WALL_T)
	_wall(2620, 1380, 352, WALL_T)
	# Mid wall y=700 with doors (depot / boss hall / clinic)
	_wall(200, 700, 360, WALL_T)
	_wall(700, 700, 830, WALL_T)
	_wall(1670, 700, 860, WALL_T)
	_wall(2670, 700, 302, WALL_T)
	# Vertical partitions, lower floor
	_wall(1100, 728, WALL_T, 252)
	_wall(1100, 1120, WALL_T, 260)
	_wall(2100, 728, WALL_T, 252)
	_wall(2100, 1120, WALL_T, 260)
	# Vertical partitions, upper floor
	_wall(1000, 228, WALL_T, 172)
	_wall(1000, 540, WALL_T, 160)
	_wall(2200, 228, WALL_T, 172)
	_wall(2200, 540, WALL_T, 160)

# ---------------------------------------------------------------- train
func _build_train() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEX_TRAIN
	sprite.position = Vector2(1560, 1620)
	sprite.z_index = 14
	add_child(sprite)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(520, 120)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2(1560, 1620)
	add_child(body)
	# Headlight cone
	var glow := Sprite2D.new()
	glow.texture = TEX_GLOW
	glow.position = Vector2(1880, 1620)
	glow.scale = Vector2(4, 2)
	glow.modulate = Color(1.0, 0.9, 0.6, 0.25)
	glow.z_index = 13
	add_child(glow)
	# Exit zone
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var zshape := CollisionShape2D.new()
	var zrect := RectangleShape2D.new()
	zrect.size = Vector2(340, 130)
	zshape.shape = zrect
	zone.add_child(zshape)
	zone.position = train_door_pos
	zone.body_entered.connect(_on_train_zone)
	add_child(zone)

func _on_train_zone(body: Node2D) -> void:
	if not body is Player or GameState.state != GameState.State.PLAYING:
		return
	if GameState.objective_id() == "escape":
		get_parent().start_ending()
	else:
		Fx.float_text(train_door_pos + Vector2(0, -40), GameState.objective_text(), UITheme.COL_ACCENT, 20)

# ---------------------------------------------------------------- props
func _prop(tex: Texture2D, pos: Vector2, solid: bool, size := Vector2.ZERO, rot := 0.0) -> void:
	if solid:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size if size != Vector2.ZERO else Vector2(tex.get_width(), tex.get_height())
		shape.shape = rect
		body.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.rotation = rot
		sprite.z_index = 4
		body.add_child(sprite)
		body.position = pos
		add_child(body)
	else:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.position = pos
		sprite.rotation = rot
		sprite.z_index = 4
		add_child(sprite)

func _build_props() -> void:
	# Platform benches
	for x in [700.0, 2400.0, 2750.0]:
		_prop(TEX_BENCH, Vector2(x, 1470), true)
	# Waiting room
	for pos in [Vector2(2350, 1150), Vector2(2650, 950), Vector2(2400, 850)]:
		_prop(TEX_BENCH, pos, true, Vector2.ZERO, _rng.randf_range(-0.3, 0.3))
	# Crates (breakable)
	var crate_spots := [
		Vector2(420, 820), Vector2(480, 880), Vector2(420, 940), Vector2(760, 1240),
		Vector2(940, 780), Vector2(650, 1100), Vector2(880, 1000), Vector2(340, 1250),
		Vector2(1250, 800), Vector2(1900, 1250), Vector2(1350, 1280),
		Vector2(2850, 1150), Vector2(2250, 780),
		Vector2(320, 300), Vector2(860, 620), Vector2(520, 560),
		Vector2(2350, 300), Vector2(2900, 620),
	]
	for pos in crate_spots:
		var crate := Crate.new()
		crate.position = pos + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-10, 10))
		add_child(crate)
	# Barrels (solid decor)
	for pos in [Vector2(250, 1330), Vector2(1050, 750), Vector2(2920, 760), Vector2(1150, 250), Vector2(2150, 650)]:
		_prop(TEX_BARREL, pos, true, Vector2(40, 40))

# ---------------------------------------------------------------- loot
func _spawn_pickup(kind: String, pos: Vector2, amount: int = 1) -> Pickup:
	var pickup := Pickup.new()
	add_child(pickup)
	pickup.global_position = pos
	pickup.setup(kind, amount)
	return pickup

func _make_coin() -> Pickup:
	return Pickup.new()

func spawn_coin(pos: Vector2) -> void:
	var coin: Pickup = Pool.acquire("coin")
	if coin.get_parent() == null:
		add_child(coin)
	coin.global_position = pos
	coin.setup("coin", 1)

func spawn_coin_burst(pos: Vector2, count: int) -> void:
	for i in count:
		var offset := Vector2(_rng.randf_range(-34, 34), _rng.randf_range(-34, 34))
		spawn_coin(pos + offset)

func spawn_crate_loot(pos: Vector2) -> void:
	var roll := _rng.randf()
	if roll < 0.6:
		spawn_coin_burst(pos, _rng.randi_range(3, 5))
	elif roll < 0.85:
		_spawn_pickup("ammo", pos)
	else:
		_spawn_pickup("heart", pos)

func _build_loot() -> void:
	# Key items: randomized among candidate spots each run (replayability).
	var fuel_spots: Array[Vector2] = [
		Vector2(350, 350), Vector2(700, 550), Vector2(400, 900),
		Vector2(850, 1250), Vector2(600, 260),
	]
	var med_spots: Array[Vector2] = [
		Vector2(2400, 350), Vector2(2820, 550), Vector2(2870, 260), Vector2(2500, 1000),
	]
	fuel_spots.shuffle()
	med_spots.shuffle()
	for i in GameState.FUEL_NEEDED:
		_fuel_pickups.append(_spawn_pickup("fuel", fuel_spots[i]))
	for i in GameState.MEDS_NEEDED:
		_med_pickups.append(_spawn_pickup("med", med_spots[i]))
	# Static aid + ammo
	for pos in [Vector2(900, 350), Vector2(1600, 1050), Vector2(2600, 1250)]:
		_spawn_pickup("heart", pos)
	for pos in [Vector2(500, 760), Vector2(1400, 900), Vector2(2300, 820)]:
		_spawn_pickup("ammo", pos)
	# Loose coins at curated spots (jittered so runs differ)
	var coin_spots: Array[Vector2] = [
		Vector2(1450, 1200), Vector2(1750, 1000), Vector2(1300, 850),
		Vector2(600, 1050), Vector2(900, 900), Vector2(450, 1200),
		Vector2(2400, 1250), Vector2(2700, 1050), Vector2(2300, 900),
		Vector2(450, 550), Vector2(800, 300), Vector2(2500, 550),
		Vector2(2750, 300), Vector2(1200, 400), Vector2(2000, 400),
		Vector2(1000, 1470), Vector2(2100, 1470),
	]
	for spot in coin_spots:
		spawn_coin(spot + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30)))

# ---------------------------------------------------------------- enemies
func alive_zombies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_dead():
			count += 1
	return count

func spawn_zombie(data: EnemyData, pos: Vector2) -> Zombie:
	var zombie := Zombie.new()
	add_child(zombie)
	zombie.global_position = pos
	zombie.setup(data)
	return zombie

func _build_zombies() -> void:
	var placements := [
		# Platform + main hall
		[WALKER, Vector2(900, 1470)], [WALKER, Vector2(2200, 1470)],
		[WALKER, Vector2(1300, 950)], [WALKER, Vector2(1850, 1100)],
		[WALKER, Vector2(1500, 800)], [RUNNER, Vector2(1750, 900)],
		[HEAVY, Vector2(1600, 1200)],
		# Warehouse
		[WALKER, Vector2(500, 1000)], [WALKER, Vector2(800, 850)],
		[RUNNER, Vector2(650, 1200)], [RUNNER, Vector2(950, 1100)],
		# Fuel depot
		[WALKER, Vector2(450, 450)], [WALKER, Vector2(750, 350)],
		[HEAVY, Vector2(550, 500)],
		# Waiting room
		[WALKER, Vector2(2450, 1200)], [WALKER, Vector2(2750, 900)],
		[RUNNER, Vector2(2550, 800)],
		# Clinic
		[WALKER, Vector2(2500, 450)], [WALKER, Vector2(2800, 350)],
		[HEAVY, Vector2(2650, 500)],
	]
	for entry in placements:
		spawn_zombie(entry[0], entry[1])

func summon_minions(pos: Vector2, count: int) -> void:
	summon_minions_of(pos, count, WALKER)

func summon_minions_of(pos: Vector2, count: int, minion: EnemyData) -> void:
	for i in count:
		if alive_zombies() >= ZOMBIE_CAP:
			return
		var angle := TAU * i / count
		var spawn_pos: Vector2 = pos + Vector2.RIGHT.rotated(angle) * 120.0
		var zombie := spawn_zombie(minion, spawn_pos)
		zombie.set_state(Zombie.ZState.CHASE)
		Fx.burst(spawn_pos, Color(0.5, 0.8, 0.5), 8, 120.0, 0.4, TEX_SOFT)

# ---------------------------------------------------------------- boss hall
func _build_boss_hall() -> void:
	# Cage with the survivor
	survivor = Survivor.new()
	add_child(survivor)
	survivor.global_position = Vector2(1600, 300)
	cage = StaticBody2D.new()
	cage.collision_layer = 1
	cage.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(92, 92)
	shape.shape = rect
	cage.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = TEX_CAGE
	sprite.z_index = 16
	cage.add_child(sprite)
	cage.position = Vector2(1600, 300)
	add_child(cage)
	# The Conductor
	boss = BossZombie.new()
	add_child(boss)
	boss.global_position = Vector2(1600, 480)
	boss.setup(BOSS)
	boss.set_state(Zombie.ZState.IDLE)
	# Activation trigger: walking into the North Hall
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var tshape := CollisionShape2D.new()
	var trect := RectangleShape2D.new()
	trect.size = Vector2(1140, 440)
	tshape.shape = trect
	trigger.add_child(tshape)
	trigger.position = Vector2(1600, 460)
	trigger.body_entered.connect(_on_boss_zone)
	add_child(trigger)

func _on_boss_zone(body: Node2D) -> void:
	if _boss_triggered or not body is Player:
		return
	_boss_triggered = true
	boss.activate()
	boss_zone_entered.emit()

func open_cage() -> void:
	if cage == null:
		return
	AudioMan.play("cage_open")
	var sprite: Sprite2D = null
	for child in cage.get_children():
		if child is Sprite2D:
			sprite = child
	var tw := create_tween()
	if sprite:
		tw.tween_property(sprite, "position:y", -70.0, 0.7).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.7)
	tw.tween_callback(cage.queue_free)
	cage = null

# ---------------------------------------------------------------- atmosphere
func _build_atmosphere(dusk_color := Color(0.82, 0.85, 1.0), lamp_positions: Array[Vector2] = []) -> void:
	var dusk := CanvasModulate.new()
	dusk.color = dusk_color
	add_child(dusk)
	if lamp_positions.is_empty():
		# Warm working lamps — someone kept the generator running...
		lamp_positions = [
			Vector2(1600, 850), Vector2(650, 950), Vector2(2550, 950),
			Vector2(600, 450), Vector2(2600, 450), Vector2(1600, 400),
			Vector2(700, 1470), Vector2(2400, 1470), Vector2(1560, 1470),
		]
	for pos in lamp_positions:
		var glow := Sprite2D.new()
		glow.texture = TEX_GLOW
		glow.position = pos
		glow.scale = Vector2(6, 6)
		glow.modulate = Color(1.0, 0.92, 0.7, 0.16)
		glow.z_index = 30
		add_child(glow)
		if _rng.randf() < 0.4:
			var tw := create_tween()
			tw.set_loops()
			tw.tween_property(glow, "modulate:a", 0.06, _rng.randf_range(0.8, 2.0))
			tw.tween_property(glow, "modulate:a", 0.16, _rng.randf_range(0.4, 1.2))
	# Drifting fog puffs
	for i in 12:
		var fog := Sprite2D.new()
		fog.texture = TEX_SOFT
		fog.position = Vector2(_rng.randf_range(200, 3000), _rng.randf_range(200, 1600))
		fog.scale = Vector2.ONE * _rng.randf_range(9.0, 16.0)
		fog.modulate = Color(0.75, 0.8, 0.95, _rng.randf_range(0.04, 0.08))
		fog.z_index = 60
		add_child(fog)
		var tw := create_tween()
		tw.set_loops()
		var drift := Vector2(_rng.randf_range(-120, 120), _rng.randf_range(-60, 60))
		tw.tween_property(fog, "position", fog.position + drift, _rng.randf_range(6.0, 12.0)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(fog, "position", fog.position, _rng.randf_range(6.0, 12.0)).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- runtime
func _process(delta: float) -> void:
	_target_timer -= delta
	if _target_timer <= 0.0:
		_target_timer = 0.4
		_update_targets()
	if _escape_active and GameState.state == GameState.State.PLAYING:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_wave_timer = 22.0
			_spawn_escape_wave()

func _update_targets() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_pos: Vector2 = players[0].global_position
	var live_fuel: Array[Pickup] = []
	for p in _fuel_pickups:
		if is_instance_valid(p):
			live_fuel.append(p)
	_fuel_pickups = live_fuel
	var live_meds: Array[Pickup] = []
	for p in _med_pickups:
		if is_instance_valid(p):
			live_meds.append(p)
	_med_pickups = live_meds
	var targets := {}
	if not _fuel_pickups.is_empty():
		targets["fuel"] = _nearest(_fuel_pickups, player_pos)
	if not _med_pickups.is_empty():
		targets["meds"] = _nearest(_med_pickups, player_pos)
	if boss and is_instance_valid(boss):
		targets["boss"] = boss.global_position
	targets["rescue"] = Vector2(1600, 300)
	targets["escape"] = train_door_pos
	GameState.objective_targets = targets

func _nearest(pickups: Array[Pickup], from_pos: Vector2) -> Vector2:
	var best_pos := pickups[0].global_position
	var best_dist := INF
	for p in pickups:
		var d := from_pos.distance_squared_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best_pos = p.global_position
	return best_pos

func _on_escape_phase() -> void:
	_escape_active = true
	_wave_timer = 8.0

func _spawn_escape_wave() -> void:
	if alive_zombies() >= ZOMBIE_CAP:
		return
	AudioMan.play("alert")
	EventBus.wave_incoming.emit()
	var spawn_points := wave_spawn_points.duplicate()
	spawn_points.shuffle()
	var count := _rng.randi_range(4, 6)
	for i in count:
		if alive_zombies() >= ZOMBIE_CAP:
			break
		var data: EnemyData = RUNNER if _rng.randf() < 0.5 else WALKER
		var pos: Vector2 = spawn_points[i % spawn_points.size()] + Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-60, 60))
		var zombie := spawn_zombie(data, pos)
		zombie.set_state(Zombie.ZState.CHASE)
		Fx.burst(pos, Color(0.5, 0.8, 0.5), 8, 120.0, 0.4, TEX_SOFT)
