extends Node
## Shared mobile UI theme + widget factory helpers.
## Big touch targets, rounded panels, high contrast.

const COL_BG := Color(0.09, 0.10, 0.16, 0.92)
const COL_PANEL := Color(0.13, 0.15, 0.23, 0.96)
const COL_ACCENT := Color(0.98, 0.76, 0.25)
const COL_GOOD := Color(0.35, 0.85, 0.55)
const COL_BAD := Color(0.92, 0.34, 0.30)
const COL_TEXT := Color(0.95, 0.96, 1.0)
const COL_DIM := Color(0.62, 0.66, 0.78)

var _theme: Theme = null

func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	var normal := _stylebox(Color(0.18, 0.22, 0.34), 14)
	var hover := _stylebox(Color(0.24, 0.29, 0.44), 14)
	var pressed := _stylebox(Color(0.13, 0.16, 0.26), 14)
	pressed.content_margin_top = 14
	var disabled := _stylebox(Color(0.14, 0.15, 0.2, 0.6), 14)
	_theme.set_stylebox("normal", "Button", normal)
	_theme.set_stylebox("hover", "Button", hover)
	_theme.set_stylebox("pressed", "Button", pressed)
	_theme.set_stylebox("disabled", "Button", disabled)
	_theme.set_color("font_color", "Button", COL_TEXT)
	_theme.set_color("font_pressed_color", "Button", COL_ACCENT)
	_theme.set_color("font_hover_color", "Button", COL_TEXT)
	_theme.set_color("font_disabled_color", "Button", COL_DIM)
	_theme.set_font_size("font_size", "Button", 26)
	_theme.set_stylebox("panel", "PanelContainer", _stylebox(COL_PANEL, 18))
	_theme.set_font_size("font_size", "Label", 22)
	_theme.set_color("font_color", "Label", COL_TEXT)
	return _theme

func _stylebox(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.border_width_bottom = 3
	sb.border_color = Color(0, 0, 0, 0.35)
	return sb

func button(text: String, font_size: int = 26, min_size := Vector2(260, 64)) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = theme()
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(func() -> void: AudioMan.play("ui_click"))
	return b

func label(text: String, font_size: int = 22, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme = theme()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	return l

func title(text: String, font_size: int = 54) -> Label:
	var l := label(text, font_size, COL_ACCENT)
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = theme()
	return p

func bar(color: Color, size := Vector2(240, 22)) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.show_percentage = false
	var bg := _stylebox(Color(0, 0, 0, 0.45), 8)
	bg.content_margin_left = 3
	bg.content_margin_right = 3
	bg.content_margin_top = 3
	bg.content_margin_bottom = 3
	var fill := _stylebox(color, 6)
	fill.border_width_bottom = 0
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	return b
