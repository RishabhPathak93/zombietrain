class_name Zombie3D
extends CharacterBody3D
## Low-poly 3D zombie assembled from shaded boxes with glowing eyes and
## procedurally swinging limbs. Same stats/data as the 2D game.

const GRAVITY := 18.0

var data: EnemyData
var hp := 30.0
var is_boss := false
var _player: PlayerFPS
var _attack_cd := 0.0
var _windup := 0.0
var _anim := 0.0
var _dead := false
var _limbs: Array[MeshInstance3D] = []
var _torso: MeshInstance3D
var _summons_done: Array[float] = []

func setup(enemy_data: EnemyData, boss := false) -> void:
	data = enemy_data
	is_boss = boss
	hp = data.max_hp
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	var s := 1.9 if is_boss else (1.35 if data.id == "heavy" else 1.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36 * s
	capsule.height = 1.7 * s
	shape.shape = capsule
	shape.position.y = 0.85 * s
	add_child(shape)
	_build_body(s)

func _mat(color: Color, emissive := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat

func _box(size: Vector3, pos: Vector3, color: Color, emissive := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color, emissive)
	mesh.position = pos
	add_child(mesh)
	return mesh

func _build_body(s: float) -> void:
	var skin := Color(0.42, 0.66, 0.42)
	var cloth := Color(0.32, 0.3, 0.34)
	var accent := Color(0.5, 0.24, 0.3)
	if is_boss:
		cloth = Color(0.26, 0.2, 0.42)
		accent = Color(0.75, 0.62, 0.3)
	elif data.id == "runner":
		skin = Color(0.62, 0.7, 0.36); cloth = Color(0.5, 0.38, 0.24)
	elif data.id == "heavy":
		skin = Color(0.3, 0.5, 0.38); cloth = Color(0.28, 0.3, 0.38)
	# Minecraft-mob proportions: big cube head, slab body, straight limbs
	for side in [-1.0, 1.0]:
		_limbs.append(_box(Vector3(0.2, 0.72, 0.2) * s, Vector3(0.12 * side, 0.36, 0) * s, cloth.darkened(0.25)))
	_torso = _box(Vector3(0.5, 0.72, 0.26) * s, Vector3(0, 1.08, 0) * s, cloth)
	for side in [-1.0, 1.0]:
		_limbs.append(_box(Vector3(0.18, 0.18, 0.72) * s, Vector3(0.35 * side, 1.32, -0.34) * s, skin))
	# cube head with a pixel-art face
	_box(Vector3(0.5, 0.5, 0.5) * s, Vector3(0, 1.7, 0) * s, skin)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5) * s
	face.mesh = quad
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_texture = preload("res://assets/textures/mc_boss_face.png") if is_boss else preload("res://assets/textures/mc_zombie_face.png")
	face_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	face_mat.emission_enabled = true
	face_mat.emission = Color(0.3, 0.5, 0.3) if not is_boss else Color(0.5, 0.4, 0.15)
	face_mat.emission_energy_multiplier = 0.6
	face.material_override = face_mat
	face.position = Vector3(0, 1.7 * s, -0.26 * s)
	face.rotation.y = PI
	add_child(face)
	if is_boss:
		_box(Vector3(0.56, 0.14, 0.56) * s, Vector3(0, 2.0, 0) * s, Color(0.16, 0.14, 0.26))
		_box(Vector3(0.2, 0.12, 0.58) * s, Vector3(0.24, 1.94, 0) * s, Color(0.75, 0.62, 0.3))

func _physics_process(delta: float) -> void:
	if _dead or data == null:
		return
	if GameState.state != GameState.State.PLAYING:
		return
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		_player = players[0]
	if _player.hp <= 0:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_anim += delta
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var aggro := (data.aggro_range / 64.0) * 1.6
	if _windup > 0.0:
		_windup -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if _windup <= 0.0 and dist < (data.attack_range / 64.0) * 2.2 + 0.6:
			_player.take_damage(data.damage, global_position)
			AudioMan.play("zombie_hit", -8.0)
	elif dist <= aggro or is_boss:
		var speed := (data.speed / 64.0) * 1.7
		var dir := to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(_player.global_position.x, global_position.y, _player.global_position.z), Vector3.UP)
		# limb swing
		var swing := sin(_anim * 7.0) * 0.5
		if _limbs.size() >= 4:
			_limbs[0].rotation.x = swing
			_limbs[1].rotation.x = -swing
			_limbs[2].rotation.x = 0.15 * sin(_anim * 4.0)
			_limbs[3].rotation.x = -0.15 * sin(_anim * 4.0)
		if dist <= (data.attack_range / 64.0) * 2.2 and _attack_cd <= 0.0:
			_attack_cd = data.attack_cooldown
			_windup = data.attack_windup
			if _torso:
				var tw := create_tween()
				tw.tween_property(_torso, "scale", Vector3(1.15, 0.9, 1.15), _windup)
				tw.tween_property(_torso, "scale", Vector3.ONE, 0.15)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

func take_damage(amount: float, _dir: Vector3) -> void:
	if _dead:
		return
	hp -= amount
	AudioMan.play("zombie_hit", -6.0)
	if _torso:
		var flash := _torso.material_override as StandardMaterial3D
		if not flash.has_meta("base_color"):
			flash.set_meta("base_color", flash.albedo_color)
		flash.albedo_color = Color(flash.get_meta("base_color")).lightened(0.5)
		var tw := create_tween()
		tw.tween_property(flash, "albedo_color", Color(flash.get_meta("base_color")), 0.15)
	if is_boss:
		EventBus.boss_health_changed.emit(int(maxf(hp, 0)), int(data.max_hp))
		_check_phases()
	if hp <= 0.0:
		_die()

func _check_phases() -> void:
	var ratio := hp / data.max_hp
	for threshold in [0.66, 0.33]:
		if ratio <= threshold and not _summons_done.has(threshold):
			_summons_done.append(threshold)
			AudioMan.play("boss_roar", -3.0)
			var level := get_parent()
			if level and level.has_method("summon_minions_3d"):
				level.summon_minions_3d(global_position, 3)

func _die() -> void:
	_dead = true
	collision_layer = 0
	GameState.kills += 1
	AudioMan.play("zombie_die", -4.0)
	GameState.add_coins(randi_range(data.coin_min, data.coin_max))
	if is_boss:
		EventBus.boss_defeated.emit()
		AudioMan.play("boss_roar", 2.0, 0.0)
		AudioMan.music("game")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:x", -PI / 2.0, 0.5).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector3(1, 0.8, 1), 0.5)
	tw.chain().tween_interval(0.8)
	tw.chain().tween_callback(queue_free)
