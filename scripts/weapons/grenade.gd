class_name Grenade
extends Node2D
## Thrown explosive: arcs to the target point, then a damaging shockwave
## hits zombies and crates alike.

const RADIUS := 150.0
const DAMAGE := 65.0

func throw_to(from: Vector2, to: Vector2) -> void:
	global_position = from
	z_index = 30
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/textures/grenade.png")
	add_child(sprite)
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/textures/shadow.png")
	shadow.scale = Vector2(0.5, 0.35)
	shadow.z_index = -1
	add_child(shadow)
	AudioMan.play("dash", -8.0, 0.2)
	var flight := 0.62
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", to, flight)
	tw.tween_property(sprite, "rotation", TAU * 2.0, flight)
	var arc := create_tween()
	arc.tween_property(sprite, "position:y", -56.0, flight * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	arc.tween_property(sprite, "position:y", 0.0, flight * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	arc.tween_callback(_explode)

func _explode() -> void:
	AudioMan.play("shotgun", 2.0, 0.05)
	AudioMan.play("slam", 0.0)
	Fx.shake(10.0)
	Fx.vibrate(60)
	Fx.zoom_punch(0.05, 0.3)
	Fx.burst(global_position, Color(1.0, 0.8, 0.4), 22, 320.0, 0.5)
	Fx.burst(global_position, Color(0.4, 0.4, 0.4, 0.7), 12, 140.0, 0.8, Fx.SOFTDOT)
	var ring := Sprite2D.new()
	ring.texture = preload("res://assets/textures/joy_base.png")
	ring.modulate = Color(1.0, 0.85, 0.5, 0.9)
	ring.z_index = 35
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.scale = Vector2(0.3, 0.3)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.3)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_tw.chain().tween_callback(ring.queue_free)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_dead():
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= RADIUS:
				var falloff := 1.0 - (dist / RADIUS) * 0.5
				enemy.take_damage(DAMAGE * falloff, (enemy.global_position - global_position).normalized())
	for crate in get_tree().get_nodes_in_group("breakable"):
		if is_instance_valid(crate) and global_position.distance_to(crate.global_position) <= RADIUS:
			crate.take_damage(DAMAGE, Vector2.ZERO)
	queue_free()
