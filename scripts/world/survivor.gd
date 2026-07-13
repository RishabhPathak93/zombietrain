class_name Survivor
extends CharacterBody2D
## Dr. Iris Chen. Waits in the cage; after rescue she shadows the player
## back to the train, keeping low and out of the fight.

const FOLLOW_SPEED := 235.0
const FOLLOW_DISTANCE := 70.0
const TELEPORT_DISTANCE := 640.0

var following := false
var _player: Player = null
var _body: Sprite2D
var _anim_time := 0.0
var _walk_frames: Array[Texture2D] = []
var _frame_clock := 0.0
const TEX_IDLE := preload("res://assets/textures/survivor.png")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/textures/shadow.png")
	shadow.scale = Vector2(1.3, 0.8)
	shadow.position = Vector2(0, TEX_IDLE.get_height() * 0.40)
	shadow.z_index = -1
	add_child(shadow)
	_body = Sprite2D.new()
	_body.texture = TEX_IDLE
	_body.position = Vector2(0, -8)
	add_child(_body)
	for i in 4:
		_walk_frames.append(load("res://assets/textures/survivor_w%d.png" % i))
	z_index = 10

func start_following(player: Player) -> void:
	following = true
	_player = player
	add_to_group("survivor")

func _physics_process(delta: float) -> void:
	_anim_time += delta
	if not following or _player == null or not is_instance_valid(_player):
		_body.rotation = sin(_anim_time * 1.5) * 0.04
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist > TELEPORT_DISTANCE:
		global_position = _player.global_position + Vector2(0, 40)
		return
	if dist > FOLLOW_DISTANCE:
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * FOLLOW_SPEED
		move_and_slide()
		if absf(dir.x) > 0.05:
			_body.flip_h = dir.x < 0.0
		_frame_clock += get_physics_process_delta_time() * 11.0
		_body.texture = _walk_frames[int(_frame_clock) % 4]
	else:
		velocity = Vector2.ZERO
		_body.texture = TEX_IDLE
		_body.scale = _body.scale.lerp(Vector2.ONE, minf(8.0 * delta, 1.0))
