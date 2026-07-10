class_name SearchPoint
extends Area2D
## Chapter 3: glowing luggage the player searches by standing close.
## Progress fills while in range, drains slowly when leaving.

signal searched

const SEARCH_TIME := 1.6

var progress := 0.0
var done := false
var _player_in := false
var _sprite: Sprite2D
var _glow: Sprite2D
var _bar: ProgressBar

func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 64.0
	shape.shape = circle
	add_child(shape)
	_glow = Sprite2D.new()
	_glow.texture = preload("res://assets/textures/glow.png")
	_glow.modulate = Color(0.45, 0.95, 0.85, 0.3)
	_glow.scale = Vector2(1.6, 1.6)
	add_child(_glow)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/textures/luggage.png")
	add_child(_sprite)
	z_index = 8
	body_entered.connect(func(b: Node2D) -> void:
		if b is Player:
			_player_in = true
	)
	body_exited.connect(func(b: Node2D) -> void:
		if b is Player:
			_player_in = false
	)

func _ready() -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(_glow, "modulate:a", 0.12, 0.55)
	tw.tween_property(_glow, "modulate:a", 0.35, 0.55)
	_bar = UITheme.bar(UITheme.COL_GOOD, Vector2(72, 10))
	_bar.max_value = 1.0
	_bar.position = Vector2(-36, -52)
	_bar.visible = false
	add_child(_bar)

func _process(delta: float) -> void:
	if done or GameState.state != GameState.State.PLAYING:
		return
	if _player_in:
		progress += delta / SEARCH_TIME
		if not _bar.visible:
			_bar.visible = true
		if progress >= 1.0:
			_complete()
	else:
		progress = maxf(0.0, progress - delta * 0.4)
		if progress <= 0.0:
			_bar.visible = false
	_bar.value = progress

func _complete() -> void:
	done = true
	_bar.visible = false
	_glow.visible = false
	_sprite.modulate = Color(0.55, 0.55, 0.6)
	AudioMan.play("pickup_item")
	Fx.vibrate(30)
	Fx.float_text(global_position, "CAR SEARCHED", UITheme.COL_GOOD, 24)
	Fx.burst(global_position, Color(0.45, 0.95, 0.85), 10, 130.0, 0.4)
	GameState.add_search()
	searched.emit()
