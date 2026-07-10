class_name SettingsPanel
extends PanelContainer
## Reusable settings UI (main menu + pause). Music/SFX sliders and
## gameplay toggles, persisted immediately.

signal closed

func _ready() -> void:
	theme = UITheme.theme()
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	var title := UITheme.title("SETTINGS", 36)
	box.add_child(title)
	box.add_child(_slider_row("Music", "music"))
	box.add_child(_slider_row("Sound FX", "sfx"))
	box.add_child(_toggle_row("Screen Shake", "shake"))
	box.add_child(_toggle_row("Vibration", "haptics"))
	box.add_child(_toggle_row("Auto-Fire", "auto_fire"))
	var close_button := UITheme.button("DONE", 24, Vector2(200, 60))
	close_button.pressed.connect(func() -> void: closed.emit())
	var center := CenterContainer.new()
	center.add_child(close_button)
	box.add_child(center)

func _slider_row(label_text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := UITheme.label(label_text, 24)
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SaveGame.setting(key))
	slider.custom_minimum_size = Vector2(280, 44)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float) -> void:
		SaveGame.set_setting(key, v)
		AudioMan.apply_settings()
	)
	row.add_child(slider)
	return row

func _toggle_row(label_text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := UITheme.label(label_text, 24)
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)
	var check := CheckButton.new()
	check.button_pressed = bool(SaveGame.setting(key))
	check.custom_minimum_size = Vector2(80, 44)
	check.toggled.connect(func(on: bool) -> void:
		SaveGame.set_setting(key, on)
		AudioMan.play("ui_click")
	)
	row.add_child(check)
	return row
