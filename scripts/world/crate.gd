class_name Crate
extends StaticBody2D
## Breakable loot crate. Shoot it: coins, ammo, or a heart pop out.

var hp := 20.0
var _sprite: Sprite2D

func _init() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("breakable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 52)
	shape.shape = rect
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/textures/crate.png")
	add_child(_sprite)
	_sprite.rotation = randf_range(-0.15, 0.15)
	z_index = 4

func take_damage(amount: float, _from_dir: Vector2) -> void:
	hp -= amount
	AudioMan.play("crate", -8.0, 0.2)
	_sprite.rotation += randf_range(-0.08, 0.08)
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.12, 0.9), 0.06)
	tw.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	if hp <= 0.0:
		_break_open()

func _break_open() -> void:
	AudioMan.play("crate", 0.0)
	Fx.burst(global_position, Color(0.75, 0.55, 0.3), 12, 180.0, 0.5)
	var level := get_parent()
	if level and level.has_method("spawn_crate_loot"):
		level.spawn_crate_loot(global_position)
	queue_free()
