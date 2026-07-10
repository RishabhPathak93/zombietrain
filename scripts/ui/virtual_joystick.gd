class_name FloatingJoystick
extends Control
## Floating one-thumb joystick. Appears wherever the thumb lands on the
## left 60% of the screen; emits a normalized direction vector.

signal vector_changed(vector: Vector2)

const RADIUS := 80.0

var _touch_index := -1
var _origin := Vector2.ZERO
var _vector := Vector2.ZERO
var _base: TextureRect
var _knob: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_base = TextureRect.new()
	_base.texture = preload("res://assets/textures/joy_base.png")
	_base.custom_minimum_size = Vector2(160, 160)
	_base.pivot_offset = Vector2(80, 80)
	_base.visible = false
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_base)
	_knob = TextureRect.new()
	_knob.texture = preload("res://assets/textures/joy_knob.png")
	_knob.custom_minimum_size = Vector2(80, 80)
	_knob.pivot_offset = Vector2(40, 40)
	_knob.visible = false
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_knob)

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _in_zone(event.position):
			_touch_index = event.index
			_origin = event.position
			_base.visible = true
			_knob.visible = true
			_base.global_position = _origin - Vector2(80, 80)
			_knob.global_position = _origin - Vector2(40, 40)
			_set_vector(Vector2.ZERO)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var offset: Vector2 = event.position - _origin
		if offset.length() > RADIUS:
			offset = offset.normalized() * RADIUS
		_knob.global_position = _origin + offset - Vector2(40, 40)
		_set_vector(offset / RADIUS)

func _in_zone(pos: Vector2) -> bool:
	var vp := get_viewport_rect().size
	return pos.x < vp.x * 0.6 and pos.y > vp.y * 0.15

func _release() -> void:
	_touch_index = -1
	_base.visible = false
	_knob.visible = false
	_set_vector(Vector2.ZERO)

func _set_vector(v: Vector2) -> void:
	_vector = v
	vector_changed.emit(v)

func vector() -> Vector2:
	return _vector
