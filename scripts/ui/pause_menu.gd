class_name PauseMenu
extends CanvasLayer
## Pause overlay. Pauses the tree while visible.

signal resumed
signal quit_to_menu

var _settings: SettingsPanel
var _main_box: VBoxContainer

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 18)
	center.add_child(_main_box)
	_main_box.add_child(UITheme.title("PAUSED", 48))
	var resume_button := UITheme.button("RESUME", 28)
	resume_button.pressed.connect(_on_resume)
	_main_box.add_child(resume_button)
	var settings_button := UITheme.button("SETTINGS", 24)
	settings_button.pressed.connect(_show_settings)
	_main_box.add_child(settings_button)
	var quit_button := UITheme.button("QUIT TO MENU", 24)
	quit_button.pressed.connect(_on_quit)
	_main_box.add_child(quit_button)
	var settings_center := CenterContainer.new()
	settings_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_center)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_main_box.visible = true
	)
	settings_center.add_child(_settings)

func open() -> void:
	visible = true
	_main_box.visible = true
	_settings.visible = false
	get_tree().paused = true
	GameState.state = GameState.State.PAUSED

func close() -> void:
	visible = false
	get_tree().paused = false
	GameState.begin_play()

func _on_resume() -> void:
	close()
	resumed.emit()

func _on_quit() -> void:
	close()
	quit_to_menu.emit()

func _show_settings() -> void:
	_main_box.visible = false
	_settings.visible = true
