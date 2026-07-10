extends Node
## Scene transitions with a fade overlay. Also owns the global fade rect
## used by cutscenes.

var _layer: CanvasLayer
var fade_rect: ColorRect
var _busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0.03, 0.03, 0.06, 1.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	_layer.add_child(fade_rect)

func go(scene_path: String, fade_time: float = 0.35) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	await fade_out(fade_time)
	Pool.clear_all()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in(fade_time)
	_busy = false

func fade_out(fade_time: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await tw.finished

func fade_in(fade_time: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
	await tw.finished
