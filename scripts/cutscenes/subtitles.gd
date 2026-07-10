class_name Subtitles
extends CanvasLayer
## Cinematic letterbox + portrait + typewriter subtitles + skip button.

signal skip_requested

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
var _line_tween: Tween

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
	skip_button.pressed.connect(func() -> void: skip_requested.emit())
	add_child(skip_button)

func open() -> void:
	visible = true
	_name_label.text = ""
	_text_label.text = ""
	_portrait.texture = null

func close() -> void:
	visible = false
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()

## Displays one dialogue line with a typewriter effect; awaitable.
func line(speaker: String, text: String, hold_time: float = 1.4) -> void:
	_portrait.texture = PORTRAITS.get(speaker)
	_name_label.text = NAMES.get(speaker, speaker.to_upper())
	_text_label.text = text
	_text_label.visible_ratio = 0.0
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	_line_tween = create_tween()
	var type_time := clampf(text.length() * 0.025, 0.4, 1.6)
	_line_tween.tween_property(_text_label, "visible_ratio", 1.0, type_time)
	_line_tween.tween_interval(hold_time)
	await _line_tween.finished
