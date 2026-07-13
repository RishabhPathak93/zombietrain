class_name PlayerFPS
extends CharacterBody3D
## First-person Mara. Left thumb: virtual joystick (HUD). Right side of the
## screen: drag to look. Auto-fire hitscan at the crosshair target.

signal died

const EYE_HEIGHT := 1.6
const GRAVITY := 18.0
const LOOK_SPEED := 0.0042

var camera: Camera3D
var max_hp := 100
var hp := 100
var input_vector := Vector2.ZERO
var move_enabled := true
var speed := 4.6

var weapons: Array[WeaponData] = []
var weapon_index := 0
var mag := 0
var reloading := false
var _mags: Array[int] = []
var _fire_cd := 0.0
var _iframes := 0.0
var _pitch := 0.0
var _look_touch := -1
var _reload_tween: Tween
var _gun_view: TextureRect
var _muzzle_light: OmniLight3D
var _shake := 0.0
var _trigger_held := false
var _dash_cd := 0.0
var _dash_left := 0.0
var _dash_dir := Vector3.ZERO
var _bob := 0.0

const GUN_TEX := {
	"pistol": preload("res://assets/textures/gun_pistol.png"),
	"shotgun": preload("res://assets/textures/gun_shotgun.png"),
	"smg": preload("res://assets/textures/gun_smg.png"),
	"rifle": preload("res://assets/textures/gun_rifle.png"),
}

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = EYE_HEIGHT
	camera.fov = 80.0
	add_child(camera)
	camera.make_current()
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.light_color = Color(1.0, 0.85, 0.55)
	_muzzle_light.omni_range = 7.0
	_muzzle_light.light_energy = 0.0
	camera.add_child(_muzzle_light)
	_muzzle_light.position = Vector3(0.2, -0.2, -0.6)
	# Player torch
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.93, 0.8)
	torch.omni_range = 9.0
	torch.light_energy = 1.1
	camera.add_child(torch)
	# Viewmodel (2D overlay gun)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_gun_view = TextureRect.new()
	_gun_view.texture = GUN_TEX["pistol"]
	_gun_view.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_gun_view.offset_left = -420
	_gun_view.offset_right = -60
	_gun_view.offset_top = -240
	_gun_view.offset_bottom = -48
	_gun_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_gun_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_gun_view)
	# Weapons from profile
	var all := {
		"pistol": preload("res://resources/weapons/pistol.tres"),
		"shotgun": preload("res://resources/weapons/shotgun.tres"),
		"smg": preload("res://resources/weapons/smg.tres"),
		"rifle": preload("res://resources/weapons/rifle.tres"),
	}
	for id in ["pistol", "shotgun", "smg", "rifle"]:
		if SaveGame.owns_weapon(id):
			weapons.append(all[id])
	max_hp = 100 + int(SaveGame.upgrade_bonus("vest"))
	hp = max_hp
	for w in weapons:
		_mags.append(w.mag_size_now())
	mag = _mags[0]
	EventBus.player_health_changed.emit(hp, max_hp)
	_emit_ammo()
	EventBus.weapon_changed.emit(current_weapon().id)
	EventBus.grenades_changed.emit(0)

func current_weapon() -> WeaponData:
	return weapons[weapon_index]

func _input(event: InputEvent) -> void:
	if get_tree().paused or not move_enabled:
		return
	var vp := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x >= vp.x * 0.6 and _look_touch == -1:
			_look_touch = event.index
		elif not event.pressed and event.index == _look_touch:
			_look_touch = -1
	elif event is InputEventScreenDrag and event.index == _look_touch:
		rotation.y -= event.relative.x * LOOK_SPEED
		_pitch = clampf(_pitch - event.relative.y * LOOK_SPEED, -1.2, 1.2)
		camera.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_iframes = maxf(0.0, _iframes - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if not move_enabled or GameState.state != GameState.State.PLAYING:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	# Keyboard fallback for desktop testing (WASD / arrows)
	var kb := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	var move_input := kb.normalized() if kb.length() > 0.1 else input_vector
	var dir3 := (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized() * minf(move_input.length(), 1.0)
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity.x = _dash_dir.x * 12.0
		velocity.z = _dash_dir.z * 12.0
	else:
		velocity.x = dir3.x * speed
		velocity.z = dir3.z * speed
	move_and_slide()
	# head bob + camera shake
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		_bob += delta * 9.0
		camera.position.y = EYE_HEIGHT + sin(_bob) * 0.045
	if _shake > 0.005:
		camera.h_offset = randf_range(-_shake, _shake) * 0.06
		camera.v_offset = randf_range(-_shake, _shake) * 0.06
		_shake = lerpf(_shake, 0.0, minf(9.0 * delta, 1.0))
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
	if _trigger_held:
		fire(true)
	elif bool(SaveGame.setting("auto_fire")):
		fire()

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func dash() -> void:
	if _dash_cd > 0.0 or not move_enabled:
		return
	_dash_cd = 3.0
	_dash_left = 0.16
	var flat := (transform.basis * Vector3(input_vector.x, 0, input_vector.y))
	_dash_dir = flat.normalized() if flat.length() > 0.2 else -camera.global_transform.basis.z
	_iframes = maxf(_iframes, 0.35)
	AudioMan.play("dash")
	EventBus.dash_used.emit(3.0)

func set_trigger(held: bool) -> void:
	_trigger_held = held

## Aim assist: nearest living enemy inside a 16-degree cone in front of
## the camera, within weapon range and with a clear line of fire.
func _cone_target() -> Node3D:
	var weapon := current_weapon()
	var max_dist := weapon.bullet_range / 64.0 * 1.6
	var forward := -camera.global_transform.basis.z
	var from := camera.global_position
	var space := get_world_3d().direct_space_state
	var best: Node3D = null
	var best_dist := max_dist
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var chest: Vector3 = enemy.global_position + Vector3(0, 1.1, 0)
		var to_enemy := chest - from
		var dist := to_enemy.length()
		if dist >= best_dist:
			continue
		if forward.angle_to(to_enemy.normalized()) > deg_to_rad(16.0):
			continue
		var query := PhysicsRayQueryParameters3D.create(from, chest, 1 | 4)
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if hit and hit.collider == enemy:
			best = enemy
			best_dist = dist
	return best

func fire(manual := false) -> void:
	if reloading or _fire_cd > 0.0 or not move_enabled or GameState.state != GameState.State.PLAYING:
		return
	var target := _cone_target()
	if target == null and not manual:
		return
	if mag <= 0:
		reload()
		return
	var weapon := current_weapon()
	_fire_cd = 1.0 / weapon.fire_rate_now()
	mag -= 1
	AudioMan.play(weapon.sfx)
	shake(weapon.shake)
	Fx.vibrate(15)
	_muzzle_light.light_energy = 2.4
	var lt := create_tween()
	lt.tween_property(_muzzle_light, "light_energy", 0.0, 0.1)
	var kick_tw := create_tween()
	kick_tw.tween_property(_gun_view, "offset_top", -218.0, 0.04)
	kick_tw.tween_property(_gun_view, "offset_top", -240.0, 0.1)
	var from := camera.global_position
	var base_dir: Vector3
	if target:
		base_dir = (target.global_position + Vector3(0, 1.1, 0) - from).normalized()
	else:
		base_dir = -camera.global_transform.basis.z
	for i in weapon.pellets:
		var spread := deg_to_rad(weapon.spread_deg)
		var dir := base_dir
		dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
		var query := PhysicsRayQueryParameters3D.create(from, from + dir * (weapon.bullet_range / 64.0 * 1.6), 1 | 4)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit and hit.collider and hit.collider.has_method("take_damage"):
			hit.collider.take_damage(weapon.damage_now(), dir)
	_emit_ammo()
	if mag <= 0:
		reload()

func reload() -> void:
	if reloading or mag >= current_weapon().mag_size_now():
		return
	reloading = true
	AudioMan.play("reload")
	EventBus.reload_started.emit(current_weapon().reload_time)
	_emit_ammo()
	_reload_tween = create_tween()
	_reload_tween.tween_interval(current_weapon().reload_time)
	_reload_tween.tween_callback(_finish_reload)

func _finish_reload() -> void:
	reloading = false
	mag = current_weapon().mag_size_now()
	_emit_ammo()

func instant_refill() -> void:
	if _reload_tween and _reload_tween.is_valid():
		_reload_tween.kill()
	_finish_reload()

func switch_weapon() -> void:
	if _reload_tween and _reload_tween.is_valid():
		_reload_tween.kill()
	reloading = false
	_mags[weapon_index] = mag
	weapon_index = (weapon_index + 1) % weapons.size()
	mag = _mags[weapon_index]
	_gun_view.texture = GUN_TEX[current_weapon().id]
	AudioMan.play("reload", -6.0)
	EventBus.weapon_changed.emit(current_weapon().id)
	_emit_ammo()

func _emit_ammo() -> void:
	EventBus.ammo_changed.emit(mag, current_weapon().mag_size_now(), current_weapon().id, reloading)

func take_damage(amount: int, _from: Vector3) -> void:
	if _iframes > 0.0 or hp <= 0:
		return
	_iframes = 0.7
	hp = maxi(0, hp - amount)
	EventBus.player_health_changed.emit(hp, max_hp)
	AudioMan.play("hurt")
	shake(8.0)
	Fx.vibrate(60)
	if hp <= 0:
		move_enabled = false
		died.emit()
		EventBus.player_died.emit()

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	AudioMan.play("heal")
	EventBus.player_health_changed.emit(hp, max_hp)
