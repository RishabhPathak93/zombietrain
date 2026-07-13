extends Node2D
## Main menu: animated station backdrop, title, Play / Armory / Settings,
## profile stats.

var _ui: CanvasLayer
var _menu_box: VBoxContainer
var _armory: Armory
var _settings: SettingsPanel
var _chapters: PanelContainer
var _confirm: PanelContainer
var _stats_label: Label

func _ready() -> void:
	GameState.state = GameState.State.MENU
	AudioMan.music("menu")
	_build_backdrop()
	_build_ui()

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.13)
	bg.size = Vector2(4000, 4000)
	bg.position = Vector2(-1000, -1000)
	add_child(bg)
	# Rails + train silhouette rolling slowly
	var rail := Sprite2D.new()
	rail.texture = preload("res://assets/textures/rail.png")
	rail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rail.region_enabled = true
	rail.region_rect = Rect2(0, 0, 3000, 64)
	rail.position = Vector2(640, 560)
	rail.modulate = Color(0.5, 0.55, 0.7)
	add_child(rail)
	var train := Sprite2D.new()
	train.texture = preload("res://assets/textures/train.png")
	train.position = Vector2(400, 520)
	train.modulate = Color(0.55, 0.6, 0.75)
	add_child(train)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(train, "position:x", 480.0, 6.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(train, "position:x", 400.0, 6.0).set_trans(Tween.TRANS_SINE)
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/textures/glow.png")
	glow.position = Vector2(700, 520)
	glow.scale = Vector2(5, 3)
	glow.modulate = Color(1.0, 0.9, 0.6, 0.2)
	add_child(glow)
	# Fog
	for i in 8:
		var fog := Sprite2D.new()
		fog.texture = preload("res://assets/textures/softdot.png")
		fog.position = Vector2(randf_range(0, 1280), randf_range(300, 720))
		fog.scale = Vector2.ONE * randf_range(8, 14)
		fog.modulate = Color(0.7, 0.75, 0.95, randf_range(0.04, 0.08))
		add_child(fog)
		var fog_tween := create_tween()
		fog_tween.set_loops()
		fog_tween.tween_property(fog, "position:x", fog.position.x + randf_range(-100, 100), randf_range(5, 10)).set_trans(Tween.TRANS_SINE)
		fog_tween.tween_property(fog, "position:x", fog.position.x, randf_range(5, 10)).set_trans(Tween.TRANS_SINE)
	# Wandering zombie silhouettes
	for i in 4:
		var zombie := Sprite2D.new()
		zombie.texture = preload("res://assets/textures/zombie_walker.png")
		zombie.position = Vector2(randf_range(100, 1180), randf_range(80, 300))
		zombie.modulate = Color(0.35, 0.45, 0.4, 0.6)
		zombie.flip_h = randf() < 0.5
		add_child(zombie)
		var zombie_tween := create_tween()
		zombie_tween.set_loops()
		var target := zombie.position + Vector2(randf_range(-150, 150), randf_range(-60, 60))
		zombie_tween.tween_property(zombie, "position", target, randf_range(6, 12))
		zombie_tween.tween_property(zombie, "position", zombie.position, randf_range(6, 12))

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var title := UITheme.title("ZOMBIE TRAIN ESCAPE", 64)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 60
	_ui.add_child(title)
	var subtitle := UITheme.label("EPISODE 1 — JUNCTION NINE", 22, UITheme.COL_DIM)
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_left = -300
	subtitle.offset_right = 300
	subtitle.offset_top = 140
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(subtitle)

	_menu_box = VBoxContainer.new()
	_menu_box.set_anchors_preset(Control.PRESET_CENTER)
	_menu_box.anchor_left = 0.5
	_menu_box.anchor_right = 0.5
	_menu_box.anchor_top = 0.5
	_menu_box.anchor_bottom = 0.5
	_menu_box.offset_left = -150
	_menu_box.offset_right = 150
	_menu_box.offset_top = -120
	_menu_box.add_theme_constant_override("separation", 12)
	_ui.add_child(_menu_box)
	var has_save := SaveGame.has_progress()
	if has_save:
		var continue_button := UITheme.button("CONTINUE", 30, Vector2(320, 72))
		continue_button.pressed.connect(_on_continue)
		_menu_box.add_child(continue_button)
	var new_button := UITheme.button("NEW GAME", 26 if has_save else 30, Vector2(320, 64 if has_save else 72))
	new_button.pressed.connect(_on_new_game)
	_menu_box.add_child(new_button)
	if has_save:
		var chapters_button := UITheme.button("CHAPTERS", 24, Vector2(320, 60))
		chapters_button.pressed.connect(_show_chapters)
		_menu_box.add_child(chapters_button)
	var fps_button := UITheme.button("3D MODE (BETA)", 22, Vector2(320, 58))
	fps_button.pressed.connect(func() -> void:
		AudioMan.stop_music(0.5)
		Router.go("res://scenes/game3d.tscn")
	)
	_menu_box.add_child(fps_button)
	var armory_button := UITheme.button("ARMORY", 24, Vector2(320, 60))
	armory_button.pressed.connect(_show_armory)
	_menu_box.add_child(armory_button)
	var settings_button := UITheme.button("SETTINGS", 24, Vector2(320, 60))
	settings_button.pressed.connect(_show_settings)
	_menu_box.add_child(settings_button)
	var quit_button := UITheme.button("QUIT", 20, Vector2(320, 52))
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	_menu_box.add_child(quit_button)

	_stats_label = UITheme.label("", 20, UITheme.COL_DIM)
	_stats_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stats_label.offset_left = 24
	_stats_label.offset_top = -40
	_ui.add_child(_stats_label)
	_refresh_stats()

	var overlay_center := CenterContainer.new()
	overlay_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(overlay_center)
	_armory = Armory.new()
	_armory.visible = false
	_armory.closed.connect(func() -> void:
		_armory.visible = false
		_menu_box.visible = true
		_refresh_stats()
	)
	overlay_center.add_child(_armory)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_menu_box.visible = true
	)
	overlay_center.add_child(_settings)
	_chapters = _build_chapter_panel()
	_chapters.visible = false
	overlay_center.add_child(_chapters)
	_confirm = _build_confirm_panel()
	_confirm.visible = false
	overlay_center.add_child(_confirm)

func _on_continue() -> void:
	var chapter := clampi(int(SaveGame.data["last_chapter"]), 1, int(SaveGame.data["unlocked_chapters"]))
	_start_chapter(chapter)

func _on_new_game() -> void:
	if SaveGame.has_progress():
		_menu_box.visible = false
		_confirm.visible = true
	else:
		_start_fresh()

func _start_fresh() -> void:
	SaveGame.reset()
	_start_chapter(1)

func _build_confirm_panel() -> PanelContainer:
	var panel := UITheme.panel()
	panel.custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UITheme.title("START A NEW GAME?", 32))
	var warning := UITheme.label("This erases your coins, upgrades,
records and unlocked chapters.", 22, UITheme.COL_DIM)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(warning)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var yes_button := UITheme.button("ERASE & START", 22, Vector2(240, 62))
	yes_button.add_theme_color_override("font_color", UITheme.COL_BAD)
	yes_button.pressed.connect(_start_fresh)
	row.add_child(yes_button)
	var cancel_button := UITheme.button("CANCEL", 22, Vector2(200, 62))
	cancel_button.pressed.connect(func() -> void:
		_confirm.visible = false
		_menu_box.visible = true
	)
	row.add_child(cancel_button)
	return panel

func _build_chapter_panel() -> PanelContainer:
	var panel := UITheme.panel()
	panel.custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UITheme.title("SELECT CHAPTER", 34))
	var unlocked: int = int(SaveGame.data["unlocked_chapters"])
	for i in GameState.MAX_CHAPTER:
		var chapter := i + 1
		var chapter_button := UITheme.button(
			"CHAPTER %d — %s" % [chapter, GameState.CHAPTER_NAMES[chapter]], 22, Vector2(500, 62))
		chapter_button.disabled = chapter > unlocked
		chapter_button.pressed.connect(_start_chapter.bind(chapter))
		box.add_child(chapter_button)
	if unlocked < GameState.MAX_CHAPTER:
		var hint := UITheme.label("Finish a chapter to unlock the next", 18, UITheme.COL_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)
	var back_button := UITheme.button("BACK", 22, Vector2(200, 56))
	back_button.pressed.connect(func() -> void:
		_chapters.visible = false
		_menu_box.visible = true
	)
	var center := CenterContainer.new()
	center.add_child(back_button)
	box.add_child(center)
	return panel

func _show_chapters() -> void:
	_menu_box.visible = false
	_chapters.visible = true

func _start_chapter(chapter: int) -> void:
	GameState.chapter = chapter
	_on_play()

func _refresh_stats() -> void:
	var best: float = float(SaveGame.data["best_time"])
	var best_text := "--:--" if best < 0.0 else GameState.format_time(best)
	_stats_label.text = "Coins: %d    Best time: %s    Runs: %d    Rescues: %d" % [
		SaveGame.coins(), best_text, int(SaveGame.data["runs"]), int(SaveGame.data["wins"])]

func _on_play() -> void:
	AudioMan.stop_music(0.5)
	Router.go("res://scenes/game.tscn")

func _show_armory() -> void:
	_menu_box.visible = false
	_armory.visible = true

func _show_settings() -> void:
	_menu_box.visible = false
	_settings.visible = true
