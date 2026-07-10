class_name Player
extends CharacterBody2D
## Mara Vale. One-thumb design: the joystick moves her, aiming and firing
## are automatic against the nearest visible zombie.

signal died

const BASE_SPEED := 225.0
const BASE_MAX_HP := 100
const AIM_RANGE := 380.0
const IFRAME_TIME := 0.7

var weapons: Array[WeaponData] = []
var weapon_index := 0
var mag := 0
var _mags: Array[int] = []
var reloading := false
var max_hp := BASE_MAX_HP
var hp := BASE_MAX_HP
var input_vector := Vector2.ZERO ## set by the HUD joystick every frame
var move_enabled := true
var auto_fire := true

var _fire_cooldown := 0.0
var _iframes := 0.0
var _target: Node2D = null
var _aim_timer := 0.0
var _step_timer := 0.0
var _reload_tween: Tween
var _body: Sprite2D
var _muzzle: Sprite2D
var _bob_time := 0.0
var _heartbeat_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)

	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/textures/shadow.png")
	shadow.scale = Vector2(1.2, 0.9)
	shadow.position = Vector2(0, 10)
	shadow.z_index = -1
	add_child(shadow)

	_body = Sprite2D.new()
	_body.texture = preload("res://assets/textures/player.png")
	add_child(_body)

	_muzzle = Sprite2D.new()
	_muzzle.texture = preload("res://assets/textures/muzzle.png")
	_muzzle.position = Vector2(40, 6)
	_muzzle.visible = false
	_body.add_child(_muzzle)

	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.modulate = Color(1.0, 0.95, 0.8, 0.13)
	glow.scale = Vector2(4.5, 4.5)
	glow.z_index = 30
	add_child(glow)

	z_index = 10
	weapons = [
		preload("res://resources/weapons/pistol.tres"),
		preload("res://resources/weapons/shotgun.tres"),
	]
	max_hp = BASE_MAX_HP + int(SaveGame.upgrade_bonus("vest"))
	hp = max_hp
	auto_fire = bool(SaveGame.setting("auto_fire"))
	for w in weapons:
		_mags.append(w.mag_size_now())
	mag = _mags[weapon_index]
	EventBus.player_health_changed.emit(hp, max_hp)
	_emit_ammo()
	EventBus.weapon_changed.emit(current_weapon().id)

func current_weapon() -> WeaponData:
	return weapons[weapon_index]

func speed_now() -> float:
	return BASE_SPEED * (1.0 + SaveGame.upgrade_bonus("boots"))

func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_iframes = maxf(0.0, _iframes - delta)
	if not move_enabled:
		velocity = Vector2.ZERO
		return
	var input_dir := input_vector.limit_length(1.0)
	velocity = input_dir * speed_now()
	move_and_slide()
	_update_aim(delta)
	_animate(delta)
	_try_fire()
	_low_hp_pulse(delta)

func _update_aim(delta: float) -> void:
	_aim_timer -= delta
	if _aim_timer <= 0.0:
		_aim_timer = 0.12
		_target = _find_target()
	var desired: float
	if _target and is_instance_valid(_target):
		desired = (_target.global_position - global_position).angle()
	elif velocity.length() > 10.0:
		desired = velocity.angle()
	else:
		desired = _body.rotation
	_body.rotation = lerp_angle(_body.rotation, desired, minf(14.0 * delta, 1.0))

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist := AIM_RANGE
	var space := get_world_2d().direct_space_state
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_dead():
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist >= best_dist:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
		if space.intersect_ray(query).is_empty():
			best = enemy
			best_dist = dist
	return best

func _try_fire() -> void:
	if not auto_fire:
		return
	fire()

func fire() -> void:
	if reloading or _fire_cooldown > 0.0 or _target == null or not is_instance_valid(_target):
		return
	if mag <= 0:
		reload()
		return
	var weapon := current_weapon()
	_fire_cooldown = 1.0 / weapon.fire_rate_now()
	mag -= 1
	var aim_dir := Vector2.RIGHT.rotated(_body.rotation)
	var muzzle_pos := global_position + aim_dir * 34.0
	for i in weapon.pellets:
		var spread := deg_to_rad(weapon.spread_deg)
		var dir := aim_dir.rotated(randf_range(-spread, spread))
		var bullet: Bullet = Pool.acquire("bullet")
		if bullet.get_parent() == null:
			get_parent().add_child(bullet)
		bullet.launch(muzzle_pos, dir, weapon.bullet_speed, weapon.damage_now(), weapon.bullet_range)
	AudioMan.play(weapon.sfx)
	EventBus.gunshot.emit(global_position)
	Fx.shake(weapon.shake)
	global_position -= aim_dir * weapon.kick * 0.06
	_muzzle.visible = true
	_muzzle.rotation = randf_range(-0.2, 0.2)
	get_tree().create_timer(0.05).timeout.connect(func() -> void: _muzzle.visible = false)
	_emit_ammo()
	if mag <= 0:
		reload()

func reload() -> void:
	if reloading or mag >= current_weapon().mag_size_now():
		return
	reloading = true
	var duration := current_weapon().reload_time
	AudioMan.play("reload")
	EventBus.reload_started.emit(duration)
	_emit_ammo()
	_reload_tween = create_tween()
	_reload_tween.tween_interval(duration)
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
	AudioMan.play("reload", -6.0)
	EventBus.weapon_changed.emit(current_weapon().id)
	_emit_ammo()

func _emit_ammo() -> void:
	EventBus.ammo_changed.emit(mag, current_weapon().mag_size_now(), current_weapon().id, reloading)

func take_damage(amount: int, from_pos: Vector2) -> void:
	if _iframes > 0.0 or hp <= 0:
		return
	_iframes = IFRAME_TIME
	hp = maxi(0, hp - amount)
	EventBus.player_health_changed.emit(hp, max_hp)
	AudioMan.play("hurt")
	Fx.shake(7.0)
	Fx.vibrate(60)
	Fx.float_text(global_position, "-%d" % amount, UITheme.COL_BAD)
	var knock := (global_position - from_pos).normalized() * 60.0
	global_position += knock * 0.4
	_body.modulate = Color(1.6, 0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(_body, "modulate", Color.WHITE, 0.3)
	if hp <= 0:
		_die()

func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(max_hp, hp + amount)
	AudioMan.play("heal")
	Fx.float_text(global_position, "+%d" % amount, UITheme.COL_GOOD)
	Fx.burst(global_position, UITheme.COL_GOOD, 8, 100.0, 0.5, Fx.SOFTDOT)
	EventBus.player_health_changed.emit(hp, max_hp)

func _die() -> void:
	move_enabled = false
	set_physics_process(false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body, "rotation", _body.rotation + PI, 0.5)
	tw.tween_property(self, "scale", Vector2(0.6, 0.6), 0.5)
	tw.tween_property(self, "modulate:a", 0.4, 0.5)
	died.emit()
	EventBus.player_died.emit()

func _animate(delta: float) -> void:
	var moving := velocity.length() > 12.0
	if moving:
		_bob_time += delta * 10.0
		_body.scale = Vector2.ONE + Vector2(0.04, -0.04) * sin(_bob_time * 2.0)
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.32
			AudioMan.play("step", -14.0, 0.2)
	else:
		_body.scale = _body.scale.lerp(Vector2.ONE, minf(8.0 * delta, 1.0))

func _low_hp_pulse(delta: float) -> void:
	if hp > 0 and hp <= int(max_hp * 0.3):
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			_heartbeat_timer = 1.1
			AudioMan.play("heartbeat", -4.0, 0.02)
