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
var _trigger_held := false

var _fire_cooldown := 0.0
var _iframes := 0.0
var _target: Node2D = null
var _aim_timer := 0.0
var _step_timer := 0.0
var _reload_tween: Tween
var _body: Sprite2D
var _gun: Sprite2D
var _light: PointLight2D
var _muzzle: Sprite2D
var aim_angle := 0.0
var _bob_time := 0.0
var _heartbeat_timer := 0.0
var _walk_frames: Array[Texture2D] = []
var _frame_clock := 0.0
var grenades := 2
var _dash_cd := 0.0
var _dash_left := 0.0
var _dash_dir := Vector2.RIGHT
var _ghost_timer := 0.0
const TEX_IDLE := preload("res://assets/textures/player.png")
const GUN_TEX := {
	"pistol": preload("res://assets/textures/gun_pistol.png"),
	"shotgun": preload("res://assets/textures/gun_shotgun.png"),
	"smg": preload("res://assets/textures/gun_smg.png"),
	"rifle": preload("res://assets/textures/gun_rifle.png"),
}
const DASH_COOLDOWN := 3.0

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
	shadow.scale = Vector2(1.4, 0.8)
	shadow.position = Vector2(0, TEX_IDLE.get_height() * 0.40)
	shadow.z_index = -1
	add_child(shadow)

	_body = Sprite2D.new()
	_body.texture = TEX_IDLE
	_body.position = Vector2(0, -8)
	add_child(_body)
	for i in 4:
		_walk_frames.append(load("res://assets/textures/player_w%d.png" % i))

	_gun = Sprite2D.new()
	_gun.texture = preload("res://assets/textures/gun_pistol.png")
	_gun.position = Vector2(4, 6)
	_gun.offset = Vector2(12, 0)
	add_child(_gun)

	_muzzle = Sprite2D.new()
	_muzzle.texture = preload("res://assets/textures/muzzle.png")
	_muzzle.position = Vector2(30, 0)
	_muzzle.visible = false
	_gun.add_child(_muzzle)

	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.modulate = Color(1.0, 0.95, 0.8, 0.13)
	glow.scale = Vector2(4.5, 4.5)
	glow.z_index = 30
	add_child(glow)

	_light = PointLight2D.new()
	_light.texture = preload("res://assets/textures/glow.png")
	_light.texture_scale = 6.0
	_light.energy = 1.0
	_light.color = Color(1.0, 0.93, 0.8)
	add_child(_light)

	z_index = 10
	var all_weapons := {
		"pistol": preload("res://resources/weapons/pistol.tres"),
		"shotgun": preload("res://resources/weapons/shotgun.tres"),
		"smg": preload("res://resources/weapons/smg.tres"),
		"rifle": preload("res://resources/weapons/rifle.tres"),
	}
	for id in ["pistol", "shotgun", "smg", "rifle"]:
		if SaveGame.owns_weapon(id):
			weapons.append(all_weapons[id])
	max_hp = BASE_MAX_HP + int(SaveGame.upgrade_bonus("vest"))
	hp = max_hp
	auto_fire = bool(SaveGame.setting("auto_fire"))
	for w in weapons:
		_mags.append(w.mag_size_now())
	mag = _mags[weapon_index]
	EventBus.player_health_changed.emit(hp, max_hp)
	_emit_ammo()
	EventBus.weapon_changed.emit(current_weapon().id)
	EventBus.grenades_changed.emit(grenades)

func current_weapon() -> WeaponData:
	return weapons[weapon_index]

func speed_now() -> float:
	return BASE_SPEED * (1.0 + SaveGame.upgrade_bonus("boots"))

func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_iframes = maxf(0.0, _iframes - delta)
	if not move_enabled or GameState.state == GameState.State.PUZZLE:
		velocity = Vector2.ZERO
		return
	_dash_cd = maxf(0.0, _dash_cd - delta)
	var input_dir := input_vector.limit_length(1.0)
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * 880.0
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.04
			_spawn_ghost()
	else:
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
		desired = aim_angle
	aim_angle = lerp_angle(aim_angle, desired, minf(14.0 * delta, 1.0))
	_gun.rotation = aim_angle
	var facing_left := absf(aim_angle) > PI / 2.0
	_body.flip_h = facing_left
	_gun.scale.y = -1.0 if facing_left else 1.0

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
	if best:
		return best
	# No zombies around: aim at shootable objectives (signal relays etc.)
	best_dist = AIM_RANGE
	for objective in get_tree().get_nodes_in_group("aim_assist"):
		if not is_instance_valid(objective):
			continue
		var dist := global_position.distance_to(objective.global_position)
		if dist >= best_dist:
			continue
		best = objective
		best_dist = dist
	return best

func set_trigger(held: bool) -> void:
	_trigger_held = held

func _try_fire() -> void:
	if auto_fire or _trigger_held:
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
	var aim_dir := Vector2.RIGHT.rotated(aim_angle)
	var muzzle_pos := global_position + Vector2(4, 6) + aim_dir * 30.0
	for i in weapon.pellets:
		var spread := deg_to_rad(weapon.spread_deg)
		var dir := aim_dir.rotated(randf_range(-spread, spread))
		var bullet: Bullet = Pool.acquire("bullet")
		if bullet.get_parent() == null:
			get_parent().add_child(bullet)
		bullet.launch(muzzle_pos, dir, weapon.bullet_speed, weapon.damage_now(), weapon.bullet_range, weapon.pierce)
	AudioMan.play(weapon.sfx)
	EventBus.gunshot.emit(global_position)
	Fx.shake(weapon.shake)
	global_position -= aim_dir * weapon.kick * 0.06
	_muzzle.visible = true
	_muzzle.rotation = randf_range(-0.2, 0.2)
	_light.energy = 1.6
	var light_tw := create_tween()
	light_tw.tween_property(_light, "energy", 1.0, 0.12)
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
	_gun.texture = GUN_TEX[current_weapon().id]
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
	tw.tween_property(_body, "scale", Vector2(1.25, 0.25), 0.5).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_body, "position:y", 18.0, 0.5)
	tw.tween_property(self, "modulate:a", 0.4, 0.5)
	died.emit()
	EventBus.player_died.emit()

func _animate(delta: float) -> void:
	var moving := velocity.length() > 12.0
	if moving:
		_bob_time += delta * 10.0
		_frame_clock += delta * 11.0
		_body.texture = _walk_frames[int(_frame_clock) % 4]
		_body.scale = Vector2.ONE + Vector2(0.02, -0.03) * sin(_bob_time * 2.0)
		_body.position.y = -8.0 - absf(sin(_bob_time)) * 2.0
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.32
			AudioMan.play("step", -14.0, 0.2)
	else:
		_body.texture = TEX_IDLE
		_body.scale = _body.scale.lerp(Vector2.ONE, minf(8.0 * delta, 1.0))
		_body.position.y = lerpf(_body.position.y, -8.0, minf(8.0 * delta, 1.0))

func dash() -> void:
	if _dash_cd > 0.0 or not move_enabled or hp <= 0:
		return
	_dash_cd = DASH_COOLDOWN
	_dash_left = 0.17
	_dash_dir = input_vector.normalized() if input_vector.length() > 0.2 else Vector2.RIGHT.rotated(aim_angle)
	_iframes = maxf(_iframes, 0.35)
	AudioMan.play("dash")
	Fx.vibrate(25)
	EventBus.dash_used.emit(DASH_COOLDOWN)

func _spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = _body.texture
	ghost.flip_h = _body.flip_h
	ghost.global_position = _body.global_position
	ghost.modulate = Color(0.6, 0.85, 1.0, 0.5)
	ghost.z_index = 9
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_callback(ghost.queue_free)

func throw_grenade() -> void:
	if grenades <= 0 or not move_enabled or hp <= 0:
		return
	grenades -= 1
	EventBus.grenades_changed.emit(grenades)
	var target: Vector2
	if _target and is_instance_valid(_target):
		target = _target.global_position
	else:
		target = global_position + Vector2.RIGHT.rotated(aim_angle) * 240.0
	var grenade := Grenade.new()
	get_parent().add_child(grenade)
	grenade.throw_to(global_position, target)

func add_grenade(count: int = 1) -> void:
	grenades = mini(grenades + count, 5)
	EventBus.grenades_changed.emit(grenades)

func _low_hp_pulse(delta: float) -> void:
	if hp > 0 and hp <= int(max_hp * 0.3):
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			_heartbeat_timer = 1.1
			AudioMan.play("heartbeat", -4.0, 0.02)
