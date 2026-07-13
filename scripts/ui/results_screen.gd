class_name ResultsScreen
extends CanvasLayer
## Victory / Game Over overlay with run stats.

signal retry
signal to_menu
signal next_chapter

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_victory() -> void:
	var title := "CHAPTER %d COMPLETE" % GameState.chapter
	var sub: String
	match GameState.chapter:
		1: sub = "Chapter 2 unlocked: Sector Seven."
		2: sub = "Chapter 3 unlocked: The Passenger."
		3: sub = "Chapter 4 unlocked: Depot 12."
		4: sub = "Chapter 5 unlocked: Project EMBER."
		_: sub = "The signal is gone. The world is quiet — the good kind."
	_build(true, title, sub)
	AudioMan.play("victory")
	AudioMan.stop_music()

func show_defeat(reason: String) -> void:
	_build(false, "GAME OVER", reason)
	AudioMan.play("defeat")
	AudioMan.stop_music()

func _build(won: bool, title_text: String, subtitle_text: String) -> void:
	for child in get_children():
		child.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.82, 0.6)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	var title := UITheme.title(title_text, 56)
	title.add_theme_color_override("font_color", UITheme.COL_GOOD if won else UITheme.COL_BAD)
	box.add_child(title)
	var subtitle := UITheme.label(subtitle_text, 24, UITheme.COL_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(_spacer(10))
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	box.add_child(stats)
	var time_line := "Time: %s" % GameState.format_time(GameState.run_time_used())
	if won and absf(float(SaveGame.data["best_time"]) - GameState.run_time_used()) < 0.01:
		time_line += "   NEW BEST!"
	for line in [time_line, "Zombies defeated: %d" % GameState.kills, "Coins earned: %d" % GameState.coins_run]:
		var stat_label := UITheme.label(line, 26)
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_child(stat_label)
	if won:
		var bonus_label := UITheme.label("(includes %d time bonus)" % int(GameState.time_left), 18, UITheme.COL_DIM)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_child(bonus_label)
	box.add_child(_spacer(16))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	if won and GameState.chapter < GameState.MAX_CHAPTER:
		var next_button := UITheme.button("CHAPTER %d >>" % (GameState.chapter + 1), 26)
		next_button.pressed.connect(func() -> void: next_chapter.emit())
		buttons.add_child(next_button)
	var retry_button := UITheme.button("PLAY AGAIN", 26)
	retry_button.pressed.connect(func() -> void: retry.emit())
	buttons.add_child(retry_button)
	var menu_button := UITheme.button("MAIN MENU", 26)
	menu_button.pressed.connect(func() -> void: to_menu.emit())
	buttons.add_child(menu_button)
	visible = true
	box.modulate.a = 0.0
	box.scale = Vector2(0.9, 0.9)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(box, "modulate:a", 1.0, 0.4).set_delay(0.3)
	tw2.tween_property(box, "scale", Vector2.ONE, 0.4).set_delay(0.3).set_trans(Tween.TRANS_BACK)

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
