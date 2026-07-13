class_name Level3D
extends Node3D
## Junction Nine rebuilt in true 3D (1 unit = 64 px of the 2D map).
## Real walls, fog, neon lights; billboard pickups; box-built props.

signal puzzle_requested(kind: String)
signal boss_zone_entered

const M := 1.0 / 64.0

var boss: Zombie3D
var survivor: Sprite3D
var _gate: StaticBody3D
var _cage: StaticBody3D
var _console_used := false
var _boss_triggered := false
var _fuel_positions: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_build_environment()
	_build_floor()
	_build_walls()
	_build_lights()
	_build_pickups()
	_build_zombies()
	_build_boss_area()
	_build_train()
	EventBus.escape_phase_started.connect(_on_escape)

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.42)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.1, 0.2)
	env.fog_density = 0.028
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _tex_mat(tex: Texture2D, scale := Vector3(4, 4, 4), tint := Color.WHITE) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = tint
	mat.uv1_scale = scale
	mat.roughness = 0.95
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat

func _build_floor() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(52, 30)
	mesh.mesh = plane
	mesh.material_override = _tex_mat(preload("res://assets/textures/mc_stone.png"), Vector3(52, 30, 1), Color(0.62, 0.64, 0.8))
	mesh.position = Vector3(25, 0, 14)
	add_child(mesh)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 40)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(25, -0.1, 14)
	add_child(body)

func _wall_box(x: float, y: float, w: float, h: float, tex: Texture2D = null, height := 2.8) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w * M, height, h * M)
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(w * M, height, h * M)
	mesh.mesh = box_mesh
	var texture := tex if tex else preload("res://assets/textures/mc_brick.png")
	mesh.material_override = _tex_mat(texture, Vector3(maxf(w * M, 1.0), 2.8, maxf(h * M, 1.0)), Color(0.72, 0.72, 0.85))
	body.add_child(mesh)
	body.position = Vector3((x + w / 2.0) * M, height / 2.0, (y + h / 2.0) * M)
	add_child(body)
	return body

func _build_walls() -> void:
	for r in [
		[30, 30, 3140, 28], [30, 1742, 3140, 28], [30, 30, 28, 1740], [3142, 30, 28, 1740],
		[200, 200, 2772, 28], [200, 200, 28, 1208], [2944, 200, 28, 1208],
		[200, 1380, 300, 28], [620, 1380, 830, 28], [1670, 1380, 830, 28], [2620, 1380, 352, 28],
		[200, 700, 360, 28], [700, 700, 830, 28], [1670, 700, 860, 28], [2670, 700, 302, 28],
		[1100, 728, 28, 252], [1100, 1120, 28, 260], [2100, 728, 28, 252], [2100, 1120, 28, 260],
		[1000, 228, 28, 172], [1000, 540, 28, 160], [2200, 228, 28, 172], [2200, 540, 28, 160],
	]:
		_wall_box(r[0], r[1], r[2], r[3])
	# Gate blocking the North Hall
	_gate = _wall_box(1530, 686, 140, 56, preload("res://assets/textures/mc_planks.png"))

func open_gate_visual() -> void:
	if _gate == null:
		return
	AudioMan.play("cage_open")
	var tw := create_tween()
	tw.tween_property(_gate, "position:y", -3.2, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_gate.queue_free)
	_gate = null

func mark_console_used() -> void:
	_console_used = true

func _build_lights() -> void:
	var palette := [Color(1.0, 0.8, 0.5), Color(0.35, 0.85, 1.0), Color(1.0, 0.4, 0.7)]
	var i := 0
	for pos2 in [
		Vector2(1600, 850), Vector2(650, 950), Vector2(2550, 950),
		Vector2(600, 450), Vector2(2600, 450), Vector2(1600, 400),
		Vector2(700, 1470), Vector2(2400, 1470), Vector2(1560, 1470),
	]:
		var light := OmniLight3D.new()
		light.light_color = palette[i % 3]
		light.omni_range = 8.0
		light.light_energy = 1.3
		light.position = Vector3(pos2.x * M, 2.4, pos2.y * M)
		add_child(light)
		var tube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.5, 0.5)
		tube.mesh = box
		var mat := _tex_mat(preload("res://assets/textures/mc_lamp.png"), Vector3(1, 1, 1), palette[i % 3])
		mat.emission_enabled = true
		mat.emission = palette[i % 3] * 0.8
		mat.emission_energy_multiplier = 2.2
		tube.material_override = mat
		tube.position = Vector3(pos2.x * M, 2.5, pos2.y * M)
		add_child(tube)
		i += 1

func _billboard(tex: Texture2D, pos: Vector3, scale := 1.0) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.014 * scale
	sprite.position = pos
	sprite.shaded = false
	add_child(sprite)
	return sprite

func _item(kind: String, pos2: Vector2, tex: Texture2D, note_data := []) -> void:
	var pos := Vector3(pos2.x * M, 0.6, pos2.y * M)
	var sprite := _billboard(tex, pos)
	var bob := sprite.create_tween()
	bob.set_loops()
	bob.tween_property(sprite, "position:y", 0.75, 0.7).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "position:y", 0.6, 0.7).set_trans(Tween.TRANS_SINE)
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	shape.shape = sphere
	zone.add_child(shape)
	zone.position = pos
	add_child(zone)
	zone.body_entered.connect(func(body: Node3D) -> void:
		if not body is PlayerFPS:
			return
		match kind:
			"fuel":
				GameState.add_fuel()
				AudioMan.play("pickup_item")
			"med":
				GameState.add_meds()
				AudioMan.play("pickup_item")
			"heart":
				body.heal(30)
			"ammo":
				body.instant_refill()
				AudioMan.play("reload")
			"note":
				EventBus.note_found.emit(note_data[0], note_data[1])
		EventBus.pickup_collected.emit(kind, 1)
		sprite.queue_free()
		zone.queue_free()
	)

func _build_pickups() -> void:
	var fuel_spots: Array[Vector2] = [
		Vector2(350, 350), Vector2(700, 550), Vector2(400, 900), Vector2(850, 1250), Vector2(600, 260),
	]
	fuel_spots.shuffle()
	for i in GameState.FUEL_NEEDED:
		_item("fuel", fuel_spots[i], preload("res://assets/textures/fuel.png"))
	var med_spots: Array[Vector2] = [
		Vector2(2400, 350), Vector2(2820, 550), Vector2(2870, 260), Vector2(2500, 1000),
	]
	med_spots.shuffle()
	for i in GameState.MEDS_NEEDED:
		_item("med", med_spots[i], preload("res://assets/textures/medkit.png"))
	for pos in [Vector2(900, 350), Vector2(1600, 1050), Vector2(2600, 1250)]:
		_item("heart", pos, preload("res://assets/textures/medkit.png"))
	for pos in [Vector2(500, 760), Vector2(1400, 900), Vector2(2300, 820)]:
		_item("ammo", pos, preload("res://assets/textures/ammo.png"))
	_item("note", Vector2(750, 1150), preload("res://assets/textures/note.png"),
		["Stationmaster's Log", "Day 400. The lights stay on. It was never the light they feared.\nIt's the frequency."])
	# Puzzle console
	_billboard(preload("res://assets/textures/console.png"), Vector3(1400 * M, 0.7, 800 * M), 1.2)
	var console_zone := Area3D.new()
	console_zone.collision_layer = 0
	console_zone.collision_mask = 2
	var cshape := CollisionShape3D.new()
	var csphere := SphereShape3D.new()
	csphere.radius = 1.3
	cshape.shape = csphere
	console_zone.add_child(cshape)
	console_zone.position = Vector3(1400 * M, 0.8, 800 * M)
	add_child(console_zone)
	console_zone.body_entered.connect(func(body: Node3D) -> void:
		if body is PlayerFPS and not _console_used and GameState.objective_id() == "gate":
			puzzle_requested.emit("wires")
	)

func _spawn_zombie(data: EnemyData, pos2: Vector2, boss := false) -> Zombie3D:
	var zombie := Zombie3D.new()
	add_child(zombie)
	zombie.position = Vector3(pos2.x * M, 0.1, pos2.y * M)
	zombie.setup(data, boss)
	return zombie

func _build_zombies() -> void:
	var walker := preload("res://resources/enemies/walker.tres")
	var runner := preload("res://resources/enemies/runner.tres")
	var heavy := preload("res://resources/enemies/heavy.tres")
	for entry in [
		[walker, Vector2(900, 1470)], [walker, Vector2(2200, 1470)],
		[walker, Vector2(1300, 950)], [walker, Vector2(1850, 1100)],
		[runner, Vector2(1750, 900)], [heavy, Vector2(1600, 1200)],
		[walker, Vector2(500, 1000)], [runner, Vector2(650, 1200)],
		[walker, Vector2(450, 450)], [heavy, Vector2(550, 500)],
		[walker, Vector2(2450, 1200)], [runner, Vector2(2550, 800)],
		[walker, Vector2(2500, 450)], [heavy, Vector2(2650, 500)],
	]:
		_spawn_zombie(entry[0], entry[1])

func summon_minions_3d(pos: Vector3, count: int) -> void:
	var walker := preload("res://resources/enemies/walker.tres")
	for i in count:
		var angle := TAU * i / count
		var spawn := pos + Vector3(cos(angle), 0, sin(angle)) * 2.0
		var zombie := Zombie3D.new()
		add_child(zombie)
		zombie.position = spawn
		zombie.setup(walker)

func _build_boss_area() -> void:
	boss = _spawn_zombie(preload("res://resources/enemies/boss.tres"), Vector2(1600, 480), true)
	boss.set_physics_process(false)
	_cage = _wall_box(1552, 252, 96, 96, preload("res://assets/textures/mc_metal.png"), 2.2)
	survivor = _billboard(preload("res://assets/textures/survivor.png"), Vector3(1600 * M, 0.85, 300 * M), 1.15)
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(17, 3, 7)
	shape.shape = box
	zone.add_child(shape)
	zone.position = Vector3(1600 * M, 1.5, 460 * M)
	add_child(zone)
	zone.body_entered.connect(func(body: Node3D) -> void:
		if _boss_triggered or not body is PlayerFPS or not GameState.gate_open:
			return
		_boss_triggered = true
		boss.set_physics_process(true)
		AudioMan.play("boss_roar")
		AudioMan.music("boss")
		EventBus.boss_spawned.emit(int(boss.data.max_hp))
		boss_zone_entered.emit()
	)

func open_cage() -> void:
	if _cage:
		AudioMan.play("cage_open")
		_cage.queue_free()
		_cage = null

func _build_train() -> void:
	var body := _wall_box(1300, 1560, 520, 130, preload("res://assets/textures/mc_metal.png"), 2.6)
	body.position.y = 1.3
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.5)
	light.omni_range = 10.0
	light.light_energy = 1.6
	light.position = Vector3(1850 * M, 2.0, 1620 * M)
	add_child(light)
	var zone := Area3D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.5, 3, 2.2)
	shape.shape = box
	zone.add_child(shape)
	zone.position = Vector3(1560 * M, 1.5, 1470 * M)
	add_child(zone)
	zone.body_entered.connect(func(body3: Node3D) -> void:
		if not body3 is PlayerFPS or GameState.state != GameState.State.PLAYING:
			return
		if GameState.objective_id() == "escape":
			get_parent().start_ending()
	)

func _process(_delta: float) -> void:
	# survivor follows after rescue
	if survivor and GameState.survivor_rescued:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var target: Vector3 = players[0].global_position + Vector3(0, 0.85, 0.6)
			survivor.global_position = survivor.global_position.lerp(target, 0.04)

func _on_escape() -> void:
	var runner := preload("res://resources/enemies/runner.tres")
	for pos in [Vector2(1100, 1050), Vector2(2100, 1050), Vector2(1600, 750), Vector2(300, 1470)]:
		_spawn_zombie(runner, pos)
	AudioMan.play("alert")
	EventBus.wave_incoming.emit()
