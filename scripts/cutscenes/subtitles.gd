class_name Subtitles
extends CanvasLayer
## Cinematic letterbox + portrait + typewriter subtitles + skip button.

signal skip_requested
signal advance_requested

const PORTRAITS := {
	"mara": preload("res://assets/textures/port_mara.png"),
	"redd": preload("res://assets/textures/port_redd.png"),
	"iris": preload("res://assets/textures/port_iris.png"),
	"radio": preload("res://assets/textures/port_radio.png"),
}
const NAMES := {
	"mara": "MARA", "redd": "CMDR. REDD", "iris": "DR. IRIS CHEN", "radio": "RADIO",
}

var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _portrait: TextureRect
var _name_label: Label
var _text_label: Label
var _hint: Label
var _line_tween: Tween
var _hint_tween: Tween
var _awaiting := false

func _ready() -> void:
	layer = 15
	visible = false
	_top_bar = ColorRect.new()
	_top_bar.color = Color(0.02, 0.02, 0.04)
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 70
	add_child(_top_bar)
	_bottom_bar = ColorRect.new()
	_bottom_bar.color = Color(0.02, 0.02, 0.04)
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = -150
	add_child(_bottom_bar)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -140
	row.offset_left = 40
	row.offset_right = -40
	row.offset_bottom = -14
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)
	_name_label = UITheme.label("", 20, UITheme.COL_ACCENT)
	text_box.add_child(_name_label)
	_text_label = UITheme.label("", 26)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(_text_label)
	var skip_button := UITheme.button("SKIP >>", 18, Vector2(130, 50))
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -156
	skip_button.offset_right = -26
	skip_button.offset_top = 10
	skip_button.offset_bottom = 60
	skip_button.pressed.connect(func() -> void:
		skip_requested.emit()
		_awaiting = false
		advance_requested.emit()
	)
	add_child(skip_button)
	_hint = UITheme.label("TAP or SPACE to continue  >", 16, UITheme.COL_ACCENT)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -320
	_hint.offset_right = -30
	_hint.offset_top = -180
	_hint.offset_bottom = -152
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.visible = false
	add_child(_hint)

func open() -> void:
	visible = true
	_name_label.text = ""
	_text_label.text = ""
	_portrait.texture = null

func close() -> void:
	visible = false
	_awaiting = false
	_hint.visible = false
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _awaiting:
		return
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = event.pressed
	var keyed := event.is_action_pressed("ui_accept")
	if tapped or keyed:
		get_viewport().set_input_as_handled()
		advance_requested.emit()

## Displays one dialogue line with a typewriter effect, then waits for the
## player to tap the screen / press Space. First tap finishes the typing,
## the next one advances. Awaitable.
func line(speaker: String, text: String, _hold_time: float = 1.4) -> void:
	_portrait.texture = PORTRAITS.get(speaker)
	_name_label.text = NAMES.get(speaker, speaker.to_upper())
	_text_label.text = text
	_text_label.visible_ratio = 0.0
	_hint.visible = false
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	_line_tween = create_tween()
	var type_time := clampf(text.length() * 0.028, 0.4, 1.8)
	_line_tween.tween_property(_text_label, "visible_ratio", 1.0, type_time)
	_line_tween.tween_callback(_show_hint)
	_awaiting = true
	while _awaiting:
		await advance_requested
		if _text_label.visible_ratio < 1.0:
			# First tap: reveal the full line instantly.
			if _line_tween and _line_tween.is_valid():
				_line_tween.kill()
			_text_label.visible_ratio = 1.0
			_show_hint()
		else:
			break
	_awaiting = false
	_hint.visible = false

func _show_hint() -> void:
	_hint.visible = true
	_hint.modulate.a = 1.0
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.set_loops()
	_hint_tween.tween_property(_hint, "modulate:a", 0.25, 0.5)
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.5)
