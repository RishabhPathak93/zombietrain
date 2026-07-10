class_name BossProjectile
extends Area2D
## Pooled boss projectile (signal orb). Hurts the player, dies on walls.

var _velocity := Vector2.ZERO
var _damage := 12
var _travelled := 0.0
var _max_range := 700.0
var _active := false

func _init() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # world + player
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/textures/orb.png")
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.scale = Vector2(0.5, 0.5)
	glow.modulate = Color(0.8, 0.4, 1.0, 0.4)
	add_child(glow)
	z_index = 22
	body_entered.connect(_on_body_entered)

func launch(pos: Vector2, dir: Vector2, speed: float, damage: int) -> void:
	global_position = pos
	rotation = dir.angle()
	_velocity = dir * speed
	_damage = damage
	_travelled = 0.0
	_active = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	var step := _velocity * delta
	global_position += step
	_travelled += step.length()
	if _travelled >= _max_range:
		_despawn()

func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body is Player:
		body.take_damage(_damage, global_position)
		_despawn()
	elif body is StaticBody2D:
		Fx.burst(global_position, Color(0.8, 0.4, 1.0), 5, 110.0, 0.25)
		_despawn()

func _despawn() -> void:
	_active = false
	set_physics_process(false)
	Pool.release(self)
