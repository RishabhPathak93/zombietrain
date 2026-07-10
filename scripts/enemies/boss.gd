class_name BossZombie
extends Zombie
## Configurable multi-attack boss. Every chapter's boss is this class with a
## different EnemyData + ability loadout set by the level:
##   Ch1 The Conductor    — charge, walker summons
##   Ch2 The Broadcaster  — charge, orb volleys, runner summons
##   Ch3 The Passenger    — blink-teleport, dense volleys, runner summons
##   Ch4 The Foreman      — shockwave rings, charge, heavy summons
## Shared phase logic: summons at 66% / 33% HP, enrage below 25%.

enum BState { DORMANT, FIGHT, CHARGE_WINDUP, CHARGING, STUNNED, SUMMONING, VOLLEY_WINDUP, SHOCK_WINDUP, BLINKING }

const CHARGE_SPEED := 520.0
const CHARGE_DAMAGE := 25
const ORB_SPEED := 340.0

# ---- ability loadout (set by the level right after setup()) ----
var can_charge := true
var can_volley := false
var can_shockwave := false
var can_blink := false
var volley_count := 5
var minion_data: EnemyData = preload("res://resources/enemies/walker.tres")
var minions_per_summon := 4

var bstate: int = BState.DORMANT
var _charge_timer := 6.0
var _volley_timer := 3.0
var _shock_timer := 4.0
var _blink_timer := 5.0
var _charge_dir := Vector2.ZERO
var _charge_left := 0.0
var _windup_timer := 0.0
var _stun_left := 0.0
var _summons_done: Array[float] = []
var _enraged := false
var _activated := false

func activate() -> void:
	if _activated:
		return
	_activated = true
	bstate = BState.FIGHT
	set_state(ZState.CHASE)
	AudioMan.play("boss_roar")
	AudioMan.music("boss")
	Fx.shake(10.0)
	Fx.zoom_punch(0.1, 0.5)
	EventBus.boss_spawned.emit(int(data.max_hp))
	EventBus.boss_health_changed.emit(int(hp), int(data.max_hp))

func _physics_process(delta: float) -> void:
	if zstate == ZState.DEAD or data == null:
		return
	if GameState.state != GameState.State.PLAYING:
		velocity = Vector2.ZERO
		return
	if not _activated:
		velocity = Vector2.ZERO
		_animate(delta)
		return
	_find_player()
	if _player == null or _player.hp <= 0:
		velocity = Vector2.ZERO
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_anim_time += delta
	var dist := global_position.distance_to(_player.global_position)

	match bstate:
		BState.FIGHT:
			_fight(delta, dist)
		BState.CHARGE_WINDUP:
			velocity = Vector2.ZERO
			_windup_timer -= delta
			if _windup_timer <= 0.0:
				bstate = BState.CHARGING
				_charge_left = 0.65
				AudioMan.play("dash")
		BState.CHARGING:
			_charging(delta, dist)
		BState.STUNNED:
			velocity = Vector2.ZERO
			_stun_left -= delta
			body_sprite.rotation += sin(_anim_time * 20.0) * 0.02
			if _stun_left <= 0.0:
				bstate = BState.FIGHT
		BState.VOLLEY_WINDUP:
			velocity = Vector2.ZERO
			_face((_player.global_position - global_position).normalized(), delta)
			_windup_timer -= delta
			if _windup_timer <= 0.0:
				_fire_volley()
				bstate = BState.FIGHT
		BState.SHOCK_WINDUP:
			velocity = Vector2.ZERO
			_windup_timer -= delta
			if _windup_timer <= 0.0:
				_fire_shockwave()
				bstate = BState.FIGHT
		BState.SUMMONING, BState.BLINKING:
			velocity = Vector2.ZERO
	_animate(delta)
	_ambient_growl(delta)

func _cool(rate_mult: float) -> float:
	return rate_mult * (0.7 if _enraged else 1.0)

func _fight(delta: float, dist: float) -> void:
	_charge_timer -= delta
	_volley_timer -= delta
	_shock_timer -= delta
	_blink_timer -= delta
	# Ability priority: shockwave (close) > blink (far) > volley (mid+) > charge (far)
	if can_shockwave and _shock_timer <= 0.0 and dist < 230.0:
		_shock_timer = _cool(6.5)
		bstate = BState.SHOCK_WINDUP
		_windup_timer = 0.7
		_telegraph(Color(1.8, 1.2, 0.5))
		var tw := create_tween()
		tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale * 1.3, 0.7)
		return
	if can_blink and _blink_timer <= 0.0 and dist > 320.0:
		_blink_timer = _cool(7.0)
		_do_blink()
		return
	if can_volley and _volley_timer <= 0.0 and dist > 200.0:
		_volley_timer = _cool(4.5)
		bstate = BState.VOLLEY_WINDUP
		_windup_timer = 0.55
		_telegraph(Color(1.6, 0.9, 1.8))
		return
	if can_charge and _charge_timer <= 0.0 and dist > 160.0:
		_charge_timer = _cool(6.0)
		bstate = BState.CHARGE_WINDUP
		_windup_timer = 0.7
		_charge_dir = (_player.global_position - global_position).normalized()
		_telegraph(Color(1.8, 0.7, 0.7))
		Fx.shake(3.0)
		return
	if dist <= data.attack_range and _attack_cd <= 0.0:
		_attack_cd = data.attack_cooldown
		_player.take_damage(data.damage, global_position)
		var to_player := (_player.global_position - global_position).normalized()
		var tw := create_tween()
		tw.tween_property(body_sprite, "position", to_player * 22.0, 0.08)
		tw.tween_property(body_sprite, "position", Vector2.ZERO, 0.2)
		return
	var to_player := (_player.global_position - global_position).normalized()
	velocity = to_player * data.speed * (1.35 if _enraged else 1.0)
	move_and_slide()
	_face(to_player, delta)

func _telegraph(color: Color) -> void:
	body_sprite.modulate = color
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color.WHITE, maxf(_windup_timer, 0.4))

# ---------------------------------------------------------------- charge
func _charging(delta: float, dist: float) -> void:
	_charge_left -= delta
	velocity = _charge_dir * CHARGE_SPEED
	var collided := move_and_slide()
	if dist < 60.0:
		_player.take_damage(CHARGE_DAMAGE, global_position)
		_end_charge(false)
		return
	if collided and get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			if get_slide_collision(i).get_collider() is StaticBody2D:
				_end_charge(true)
				return
	if _charge_left <= 0.0:
		_end_charge(false)

func _end_charge(crashed: bool) -> void:
	if crashed:
		AudioMan.play("slam")
		Fx.shake(9.0)
		Fx.burst(global_position, Color(0.8, 0.75, 0.65), 14, 200.0, 0.4, Fx.SOFTDOT)
		bstate = BState.STUNNED
		_stun_left = 1.4
		Fx.float_text(global_position, "STUNNED!", UITheme.COL_ACCENT)
	else:
		bstate = BState.FIGHT

# ---------------------------------------------------------------- volley
func _fire_volley() -> void:
	AudioMan.play("signal", -2.0, 0.1)
	var count := volley_count + (2 if _enraged else 0)
	var aim := (_player.global_position - global_position).angle()
	var spread := deg_to_rad(56.0)
	for i in count:
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var ang := aim + lerpf(-spread / 2.0, spread / 2.0, t)
		var orb: BossProjectile = Pool.acquire("boss_orb")
		if orb.get_parent() == null:
			get_parent().add_child(orb)
		orb.launch(global_position + Vector2.RIGHT.rotated(ang) * 50.0, Vector2.RIGHT.rotated(ang), ORB_SPEED, int(data.damage * 0.55))
	var tw := create_tween()
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale * 0.9, 0.08)
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale, 0.15)

# ---------------------------------------------------------------- shockwave
func _fire_shockwave() -> void:
	AudioMan.play("slam")
	Fx.shake(10.0)
	Fx.vibrate(50)
	var tw := create_tween()
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale, 0.2)
	# Expanding ring visual
	var ring := Sprite2D.new()
	ring.texture = preload("res://assets/textures/joy_base.png")
	ring.modulate = Color(1.0, 0.7, 0.3, 0.9)
	ring.z_index = 35
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.scale = Vector2(0.4, 0.4)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2(5.5, 5.5), 0.55)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.55)
	ring_tw.chain().tween_callback(ring.queue_free)
	# Damage sweep: hit the player once when the ring reaches them
	_shock_sweep()

func _shock_sweep() -> void:
	var dealt := false
	var elapsed := 0.0
	var origin := global_position
	var tree := get_tree()
	while elapsed < 0.55:
		await tree.physics_frame
		if not is_instance_valid(self) or zstate == ZState.DEAD:
			return
		elapsed += get_physics_process_delta_time()
		if dealt or _player == null or not is_instance_valid(_player):
			continue
		var radius := 32.0 + (elapsed / 0.55) * 420.0
		var dist := origin.distance_to(_player.global_position)
		if absf(dist - radius) < 44.0:
			dealt = true
			_player.take_damage(int(data.damage * 0.9), origin)

# ---------------------------------------------------------------- blink
func _do_blink() -> void:
	bstate = BState.BLINKING
	AudioMan.play("radio", -8.0, 0.2)
	Fx.burst(global_position, Color(0.5, 0.9, 0.85), 10, 140.0, 0.35)
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(_blink_move)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_callback(_blink_done)

func _blink_move() -> void:
	if _player and is_instance_valid(_player):
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		global_position = _player.global_position + dir * 150.0
	Fx.burst(global_position, Color(0.5, 0.9, 0.85), 12, 160.0, 0.4)

func _blink_done() -> void:
	collision_layer = 4
	AudioMan.play("boss_roar", -8.0, 0.15)
	bstate = BState.FIGHT

# ---------------------------------------------------------------- damage & phases
func take_damage(amount: float, _from_dir: Vector2) -> void:
	if zstate == ZState.DEAD or not _activated or bstate == BState.BLINKING:
		return
	hp -= amount
	AudioMan.play("zombie_hit", -6.0)
	Fx.hit_spark(global_position)
	Fx.float_text(global_position, str(int(amount)), Color(1.0, 0.9, 0.5), 18)
	body_sprite.modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color.WHITE, 0.12)
	EventBus.boss_health_changed.emit(int(maxf(hp, 0.0)), int(data.max_hp))
	_check_phases()
	if hp <= 0.0:
		_die()

func _check_phases() -> void:
	var ratio := hp / data.max_hp
	for threshold in [0.66, 0.33]:
		if ratio <= threshold and not _summons_done.has(threshold):
			_summons_done.append(threshold)
			_summon_wave()
			return
	if ratio <= 0.25 and not _enraged:
		_enraged = true
		body_sprite.self_modulate = body_sprite.self_modulate * Color(1.25, 0.75, 0.75)
		AudioMan.play("boss_roar", -2.0)
		Fx.float_text(global_position, "ENRAGED!", UITheme.COL_BAD, 26)

func _summon_wave() -> void:
	bstate = BState.SUMMONING
	AudioMan.play("boss_roar", -3.0)
	Fx.shake(6.0)
	var tw := create_tween()
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale * 1.2, 0.3)
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale, 0.3)
	tw.tween_callback(func() -> void:
		var level := get_parent()
		if level and level.has_method("summon_minions_of"):
			level.summon_minions_of(global_position, minions_per_summon, minion_data)
		bstate = BState.FIGHT
	)

func _on_death() -> void:
	EventBus.boss_defeated.emit()
	Fx.shake(14.0)
	Fx.zoom_punch(0.12, 0.7)
	Fx.hitstop(0.35, 0.05)
	AudioMan.play("boss_roar", 2.0, 0.0)
	AudioMan.music("game")
