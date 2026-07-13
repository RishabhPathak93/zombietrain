class_name Relay
extends StaticBody2D
## Chapter 2 objective: a signal relay pylon. Shoot it until it dies —
## its red beacon goes dark and the tower loses one feed.

signal destroyed

var hp := 60.0
var label_text := "RELAY DOWN"
var _sprite: Sprite2D
var _beacon: Sprite2D
var _dead := false

func _init() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("breakable")
	add_to_group("aim_assist")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/textures/relay.png")
	_sprite.scale = Vector2(1.3, 1.3)
	add_child(_sprite)
	_beacon = Sprite2D.new()
	_beacon.texture = preload("res://assets/textures/glow.png")
	_beacon.modulate = Color(1.0, 0.25, 0.2, 0.4)
	_beacon.scale = Vector2(1.6, 1.6)
	add_child(_beacon)
	z_index = 8

func _ready() -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(_beacon, "modulate:a", 0.1, 0.5)
	tw.tween_property(_beacon, "modulate:a", 0.45, 0.5)

func take_damage(amount: float, _from_dir: Vector2) -> void:
	if _dead:
		return
	hp -= amount
	AudioMan.play("zombie_hit", -10.0, 0.25)
	Fx.hit_spark(global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16)))
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.4, 1.2), 0.05)
	tw.tween_property(_sprite, "scale", Vector2(1.3, 1.3), 0.1)
	if hp <= 0.0:
		_shut_down()

func _shut_down() -> void:
	_dead = true
	remove_from_group("breakable")
	remove_from_group("aim_assist")
	AudioMan.play("power_down")
	Fx.shake(5.0)
	Fx.vibrate(40)
	Fx.burst(global_position, Color(1.0, 0.5, 0.3), 16, 220.0, 0.5)
	Fx.float_text(global_position, label_text, UITheme.COL_ACCENT, 24)
	_beacon.visible = false
	_sprite.modulate = Color(0.45, 0.45, 0.5)
	GameState.add_relay()
	destroyed.emit()
