class_name Zombie
extends CharacterBody2D
## Base zombie. Variants (Walker / Runner / Heavy) are configured entirely
## by EnemyData; unique behavior comes from the `special` flag and
## per-variant procedural animation. The Boss subclasses this.

enum ZState { IDLE, WANDER, CHASE, WINDUP, SPECIAL, DEAD }

var data: EnemyData
var hp := 30.0
var zstate: int = ZState.IDLE
var body_sprite: Sprite2D

var _player: Player = null
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _attack_cd := 0.0
var _special_cd := 0.0
var _windup_left := 0.0
var _windup_is_special := false
var _lunge_dir := Vector2.ZERO
var _lunge_left := 0.0
var _growl_timer := 0.0
var _anim_time := 0.0
var _think_timer := 0.0

func _init() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	hp = data.max_hp
	add_to_group("enemies")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0 * data.sprite_scale * (data.texture.get_width() / 64.0)
	shape.shape = circle
	add_child(shape)

	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/textures/shadow.png")
	shadow.scale = Vector2(1.2, 0.9) * data.sprite_scale * (data.texture.get_width() / 64.0)
	shadow.position = Vector2(0, 8)
	shadow.z_index = -1
	add_child(shadow)

	body_sprite = Sprite2D.new()
	body_sprite.texture = data.texture
	body_sprite.scale = Vector2.ONE * data.sprite_scale
	body_sprite.self_modulate = data.tint
	add_child(body_sprite)
	z_index = 9

	_growl_timer = randf_range(2.0, 6.0)
	_anim_time = randf() * TAU
	EventBus.gunshot.connect(_on_gunshot)
	set_state(ZState.WANDER)

func is_dead() -> bool:
	return zstate == ZState.DEAD

func set_state(new_state: int) -> void:
	zstate = new_state

func _find_player() -> void:
	if _player and is_instance_valid(_player):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _on_gunshot(pos: Vector2) -> void:
	if zstate == ZState.DEAD:
		return
	if global_position.distance_to(pos) <= data.hearing_range:
		if zstate == ZState.IDLE or zstate == ZState.WANDER:
			set_state(ZState.CHASE)

func _physics_process(delta: float) -> void:
	if zstate == ZState.DEAD or data == null:
		return
	if GameState.state != GameState.State.PLAYING:
		velocity = Vector2.ZERO
		return
	_find_player()
	if _player == null or _player.hp <= 0:
		velocity = Vector2.ZERO
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_special_cd = maxf(0.0, _special_cd - delta)
	_anim_time += delta
	var dist := global_position.distance_to(_player.global_position)

	match zstate:
		ZState.IDLE, ZState.WANDER:
			_wander(delta)
			if dist <= data.aggro_range:
				set_state(ZState.CHASE)
				_growl()
		ZState.CHASE:
			_chase(delta, dist)
		ZState.WINDUP:
			velocity = Vector2.ZERO
			_windup_left -= delta
			if _windup_left <= 0.0:
				_resolve_windup(dist)
		ZState.SPECIAL:
			_special_move(delta)
	_animate(delta)
	_ambient_growl(delta)

func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU) if randf() > 0.3 else Vector2.ZERO
	velocity = _wander_dir * data.speed * 0.4
	move_and_slide()

func _chase(delta: float, dist: float) -> void:
	var to_player := (_player.global_position - global_position).normalized()
	# Trigger special ability when in its range band.
	if data.special != "none" and _special_cd <= 0.0 and dist <= data.special_range and dist > data.attack_range:
		_start_windup(true)
		return
	if dist <= data.attack_range and _attack_cd <= 0.0:
		_start_windup(false)
		return
	# Light weave so groups do not stack into a line.
	var weave := to_player.orthogonal() * sin(_anim_time * 2.0 + get_instance_id() % 10) * 0.25
	velocity = (to_player + weave).normalized() * data.speed
	move_and_slide()
	_face(to_player, delta)

func _start_windup(special: bool) -> void:
	_windup_is_special = special
	_windup_left = data.attack_windup if not special else (0.4 if data.special == "lunge" else 0.6)
	set_state(ZState.WINDUP)
	var flash_col := Color(1.5, 1.3, 0.7) if special else Color(1.4, 0.9, 0.9)
	body_sprite.modulate = flash_col
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color.WHITE, _windup_left)
	if special and data.special == "slam":
		var tw2 := create_tween()
		tw2.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale * 1.25, _windup_left)

func _resolve_windup(dist: float) -> void:
	if _windup_is_special:
		match data.special:
			"lunge":
				_lunge_dir = (_player.global_position - global_position).normalized()
				_lunge_left = 0.32
				_special_cd = data.special_cooldown
				AudioMan.play("dash", -4.0)
				set_state(ZState.SPECIAL)
			"slam":
				_do_slam()
		return
	# Basic melee swipe.
	_attack_cd = data.attack_cooldown
	if dist <= data.attack_range * 1.4:
		_player.take_damage(data.damage, global_position)
	var to_player := (_player.global_position - global_position).normalized()
	var tw := create_tween()
	tw.tween_property(body_sprite, "position", to_player * 14.0, 0.08)
	tw.tween_property(body_sprite, "position", Vector2.ZERO, 0.15)
	set_state(ZState.CHASE)

func _special_move(delta: float) -> void:
	# Runner lunge dash.
	_lunge_left -= delta
	velocity = _lunge_dir * data.speed * 3.4
	move_and_slide()
	if global_position.distance_to(_player.global_position) < data.attack_range + 8.0:
		_player.take_damage(data.damage, global_position)
		_lunge_left = 0.0
	if _lunge_left <= 0.0:
		set_state(ZState.CHASE)

func _do_slam() -> void:
	_special_cd = data.special_cooldown
	AudioMan.play("slam")
	Fx.shake(8.0)
	Fx.burst(global_position, Color(0.75, 0.7, 0.6), 16, 220.0, 0.5, Fx.SOFTDOT)
	var tw := create_tween()
	tw.tween_property(body_sprite, "scale", Vector2.ONE * data.sprite_scale, 0.2)
	if global_position.distance_to(_player.global_position) <= data.special_range + 20.0:
		_player.take_damage(data.damage, global_position)
	set_state(ZState.CHASE)

func _face(dir: Vector2, delta: float) -> void:
	body_sprite.rotation = lerp_angle(body_sprite.rotation, dir.angle(), minf(8.0 * delta, 1.0))

func _animate(_delta: float) -> void:
	if zstate == ZState.SPECIAL:
		return
	match data.anim:
		"sway":
			body_sprite.rotation += sin(_anim_time * 4.0) * 0.012
		"lean":
			body_sprite.skew = sin(_anim_time * 9.0) * 0.08
		"stomp":
			var pulse := absf(sin(_anim_time * 3.0))
			body_sprite.scale = Vector2.ONE * data.sprite_scale * (1.0 + pulse * 0.05)

func _ambient_growl(delta: float) -> void:
	_growl_timer -= delta
	if _growl_timer <= 0.0:
		_growl_timer = randf_range(3.0, 8.0)
		if global_position.distance_to(_player.global_position) < 420.0:
			_growl()

func _growl() -> void:
	AudioMan.play("zombie_growl%d" % (randi() % 3 + 1), -10.0, 0.15)

func take_damage(amount: float, from_dir: Vector2) -> void:
	if zstate == ZState.DEAD:
		return
	hp -= amount
	AudioMan.play("zombie_hit", -6.0)
	Fx.hit_spark(global_position)
	Fx.float_text(global_position, str(int(amount)), Color(1.0, 0.9, 0.5), 18)
	global_position += from_dir * 6.0
	body_sprite.modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color.WHITE, 0.15)
	if zstate == ZState.IDLE or zstate == ZState.WANDER:
		set_state(ZState.CHASE)
	if hp <= 0.0:
		_die()

func _die() -> void:
	set_state(ZState.DEAD)
	collision_layer = 0
	collision_mask = 1
	GameState.kills += 1
	AudioMan.play("zombie_die", -4.0)
	Fx.goo_splat(global_position)
	EventBus.enemy_died.emit(data.id, global_position)
	_drop_loot()
	_on_death()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(body_sprite, "scale", body_sprite.scale * Vector2(1.3, 0.2), 0.35)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(queue_free)

func _drop_loot() -> void:
	var coins := randi_range(data.coin_min, data.coin_max)
	var level := get_parent()
	if level and level.has_method("spawn_coin_burst"):
		level.spawn_coin_burst(global_position, coins)

func _on_death() -> void:
	pass # Overridden by the Boss.
