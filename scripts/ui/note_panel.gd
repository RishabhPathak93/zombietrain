class_name NotePanel
extends CanvasLayer
## Full-screen lore note reader. Freezes gameplay while open.

var _panel: PanelContainer
var _title_label: Label
var _text_label: Label

func _ready() -> void:
	layer = 25
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = UITheme.panel()
	_panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = preload("res://assets/textures/note.png")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 52)
	box.add_child(icon)
	_title_label = UITheme.title("", 28)
	box.add_child(_title_label)
	_text_label = UITheme.label("", 22)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(560, 0)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_text_label)
	var ok := UITheme.button("CLOSE", 20, Vector2(180, 54))
	ok.pressed.connect(_close)
	var ok_center := CenterContainer.new()
	ok_center.add_child(ok)
	box.add_child(ok_center)
	EventBus.note_found.connect(_open)

func _open(title: String, text: String) -> void:
	_title_label.text = title
	_text_label.text = text
	visible = true
	GameState.state = GameState.State.PUZZLE
	AudioMan.play("pickup_item", -4.0)

func _close() -> void:
	visible = false
	GameState.begin_play()
