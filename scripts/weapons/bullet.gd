class_name Bullet
extends Area2D
## Pooled projectile. Straight flight, range-limited, hits enemies and walls.

var _velocity := Vector2.ZERO
var _damage := 10.0
var _travelled := 0.0
var _max_range := 500.0
var _active := false
var _sprite: Sprite2D

func _init() -> void:
	collision_layer = 8
	collision_mask = 1 | 4 # world + enemies
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/textures/bullet.png")
	_sprite.scale = Vector2(1.4, 1.4)
	add_child(_sprite)
	z_index = 20
	body_entered.connect(_on_body_entered)

func launch(pos: Vector2, dir: Vector2, speed: float, damage: float, max_range: float) -> void:
	global_position = pos
	rotation = dir.angle()
	_velocity = dir * speed
	_damage = damage
	_max_range = max_range
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
		_despawn(false)

func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body is Zombie:
		body.take_damage(_damage, _velocity.normalized())
		_despawn(true)
	elif body.is_in_group("breakable") and body.has_method("take_damage"):
		body.take_damage(_damage, _velocity.normalized())
		_despawn(true)
	elif body is StaticBody2D:
		Fx.hit_spark(global_position)
		_despawn(false)

func _despawn(_hit: bool) -> void:
	_active = false
	set_physics_process(false)
	Pool.release(self)
