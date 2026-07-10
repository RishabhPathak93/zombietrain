class_name CutsceneDirector
extends Node
## Drives all in-engine cinematics with camera tweens, fades, SFX and the
## Subtitles layer. Every cutscene is skippable.
##
## Each chapter opens with a side-view "rolling train" city cinematic:
## gradient night sky, moon, two parallax skyline layers, scrolling rails
## and the armored Ember Line in the foreground — then hands off to a
## top-down ground intro at the level itself.

var subtitles: Subtitles
var camera: Camera2D
var player: Player
var level: Level

var _skipped := false
var _active := false

func _ready() -> void:
	subtitles = Subtitles.new()
	add_child(subtitles)
	subtitles.skip_requested.connect(func() -> void: _skipped = true)

func _begin() -> void:
	_active = true
	_skipped = false
	GameState.enter_cutscene()
	EventBus.cutscene_started.emit()
	player.move_enabled = false
	player._iframes = 9999.0
	camera.position_smoothing_enabled = false
	subtitles.open()

func _end() -> void:
	subtitles.close()
	_restore_camera()
	player._iframes = 1.0
	player.move_enabled = true
	camera.position_smoothing_enabled = true
	GameState.begin_play()
	EventBus.cutscene_finished.emit()
	_active = false

func _restore_camera() -> void:
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE

func _say(speaker: String, text: String, hold_time: float = 1.2) -> void:
	if _skipped:
		return
	await subtitles.line(speaker, text, hold_time)

func _pan(to: Vector2, duration: float, zoom: float = 1.0) -> void:
	if _skipped:
		return
	camera.top_level = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(camera, "global_position", to, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "zoom", Vector2.ONE * zoom, duration).set_trans(Tween.TRANS_SINE)
	await tw.finished

func _beat(duration: float) -> void:
	if _skipped:
		return
	await get_tree().create_timer(duration).timeout

# ================================================================ city cinematic
## Builds the side-view night city + rolling train scene on a CanvasLayer.
func _build_city_scene() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)

	# Night sky gradient
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.02, 0.02, 0.07), Color(0.09, 0.05, 0.14), Color(0.16, 0.08, 0.15),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	var sky_tex := GradientTexture2D.new()
	sky_tex.gradient = gradient
	sky_tex.fill_from = Vector2(0, 0)
	sky_tex.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = sky_tex
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sky)

	# Moon + halo
	var halo := Sprite2D.new()
	halo.texture = preload("res://assets/textures/glow.png")
	halo.position = Vector2(1010, 130)
	halo.scale = Vector2(3.4, 3.4)
	halo.modulate = Color(0.9, 0.92, 1.0, 0.25)
	layer.add_child(halo)
	var moon := Sprite2D.new()
	moon.texture = preload("res://assets/textures/moon.png")
	moon.position = Vector2(1010, 130)
	layer.add_child(moon)

	# Parallax skylines (scrolled by animating the texture region)
	var far := _scrolling_strip(layer, preload("res://assets/textures/city_far.png"), 960, 300, Vector2(640, 330), 18.0, Color(0.8, 0.85, 1.0))
	var near := _scrolling_strip(layer, preload("res://assets/textures/city_near.png"), 960, 380, Vector2(640, 420), 7.0, Color.WHITE)
	# Chapter 2: the broadcast tower looms in the skyline with a red beacon
	if GameState.chapter == 2:
		var tower_glow := Sprite2D.new()
		tower_glow.texture = preload("res://assets/textures/glow.png")
		tower_glow.position = Vector2(980, 300)
		tower_glow.scale = Vector2(2.4, 2.4)
		tower_glow.modulate = Color(1.0, 0.2, 0.15, 0.0)
		layer.add_child(tower_glow)
		var blink := tower_glow.create_tween()
		blink.set_loops()
		blink.tween_property(tower_glow, "modulate:a", 0.5, 0.6)
		blink.tween_property(tower_glow, "modulate:a", 0.05, 0.6)

	# Ground + scrolling rails
	var ground := ColorRect.new()
	ground.color = Color(0.05, 0.05, 0.09)
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -130
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ground)
	_scrolling_strip(layer, preload("res://assets/textures/rail.png"), 128, 64, Vector2(640, 640), 0.35, Color(0.75, 0.8, 0.95))

	# The Ember Line
	var train := Sprite2D.new()
	train.texture = preload("res://assets/textures/train_side.png")
	train.position = Vector2(430, 560)
	layer.add_child(train)
	var bob := train.create_tween()
	bob.set_loops()
	bob.tween_property(train, "position:y", 557.0, 0.35).set_trans(Tween.TRANS_SINE)
	bob.tween_property(train, "position:y", 560.0, 0.3).set_trans(Tween.TRANS_SINE)
	var headlight := Sprite2D.new()
	headlight.texture = preload("res://assets/textures/glow.png")
	headlight.position = Vector2(830, 560)
	headlight.scale = Vector2(3.2, 1.6)
	headlight.modulate = Color(1.0, 0.9, 0.6, 0.3)
	layer.add_child(headlight)
	var sparks := CPUParticles2D.new()
	sparks.texture = preload("res://assets/textures/spark.png")
	sparks.position = Vector2(300, 630)
	sparks.amount = 14
	sparks.lifetime = 0.5
	sparks.direction = Vector2(-1, -0.3)
	sparks.spread = 25.0
	sparks.initial_velocity_min = 180.0
	sparks.initial_velocity_max = 380.0
	sparks.gravity = Vector2(0, 500)
	sparks.scale_amount_min = 0.3
	sparks.scale_amount_max = 0.7
	sparks.color = Color(1.0, 0.85, 0.5)
	layer.add_child(sparks)

	# Rushing fog streaks
	for i in 5:
		var fog := Sprite2D.new()
		fog.texture = preload("res://assets/textures/softdot.png")
		fog.position = Vector2(200.0 + i * 260.0, randf_range(360, 560))
		fog.scale = Vector2(randf_range(5, 9), randf_range(2, 3))
		fog.modulate = Color(0.7, 0.75, 0.95, 0.07)
		layer.add_child(fog)
		var drift := fog.create_tween()
		drift.set_loops()
		drift.tween_property(fog, "position:x", fog.position.x - 1500.0, randf_range(1.6, 2.6))
		drift.tween_callback(func() -> void: fog.position.x = 1500.0)
	# Keep references alive
	far.set_meta("keep", true)
	near.set_meta("keep", true)
	return layer

func _scrolling_strip(layer: CanvasLayer, tex: Texture2D, tile_w: int, tile_h: int, pos: Vector2, loop_time: float, tint: Color) -> Sprite2D:
	var strip := Sprite2D.new()
	strip.texture = tex
	strip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	strip.region_enabled = true
	strip.region_rect = Rect2(0, 0, 1600, tile_h)
	strip.position = pos
	strip.modulate = tint
	layer.add_child(strip)
	var tw := strip.create_tween()
	tw.set_loops()
	tw.tween_property(strip, "region_rect", Rect2(tile_w, 0, 1600, tile_h), loop_time).from(Rect2(0, 0, 1600, tile_h))
	return strip

func _play_city_prologue() -> void:
	var city := _build_city_scene()
	AudioMan.play("train_horn", -6.0)
	await Router.fade_in(1.2)
	match GameState.chapter:
		1:
			await _say("narrator", "The signal came first. Then the quiet.", 1.2)
			await _say("narrator", "Fifteen years on, one train still runs west — the Ember Line. Forty souls aboard.", 1.3)
			await _say("narrator", "Tonight, her tanks are dry.", 1.0)
			await _say("redd", "Junction Nine in sixty seconds. Scout to the forward hatch.", 0.9)
			await _say("mara", "Copy. Moving.", 0.6)
		2:
			await _say("narrator", "Sector Seven. Dead center of the quiet zone.", 1.2)
			await _say("iris", "The tower feeds on three relays. Break them all, and the signal dies.", 1.2)
			await _say("redd", "In and out, scout. Whatever knows your name — don't let it meet you.", 1.2)
			await _say("mara", "Too late for that.", 0.9)
		3:
			await _say("narrator", "The tower is behind them. The signal is not.", 1.2)
			await _say("iris", "It's broadcasting from INSIDE. Somewhere on this train.", 1.2)
			await _say("redd", "Six cars. Forty souls. Find it before it finds them.", 1.2)
			await _say("mara", "Seal the doors behind me. Nobody moves between cars.", 1.0)
		4:
			await _say("narrator", "Depot 12. The yard where the Ember Line was built.", 1.2)
			await _say("iris", "The recall engine is here. Three amplifiers keep it alive.", 1.2)
			await _say("redd", "This place built our train, Mara. Maybe the signal, too.", 1.2)
			await _say("mara", "Then we end it where it started.", 0.9)
	await Router.fade_out(0.9)
	city.queue_free()

# ================================================================ intros
func play_intro() -> void:
	_begin()
	Router.fade_rect.modulate.a = 1.0
	await _play_city_prologue()
	match GameState.chapter:
		1: await _ground_intro_ch1()
		2: await _ground_intro_ch2()
		3: await _ground_intro_ch3()
		4: await _ground_intro_ch4()
	_end()
	if not SaveGame.data["seen_intro"]:
		SaveGame.data["seen_intro"] = true
		SaveGame.save_data()

func _ground_intro_ch1() -> void:
	camera.top_level = true
	camera.global_position = level.intro_focus
	camera.zoom = Vector2.ONE * 0.85
	AudioMan.play("train_horn", -4.0)
	await Router.fade_in(1.0)
	await _say("redd", "Junction Nine. Last fuel stop before the mountains.", 0.8)
	await _pan(Vector2(1600, 900), 2.2, 0.9)
	await _say("redd", "Mara — tanks are dry, and little Pip's fever is getting worse.", 1.0)
	await _say("redd", "We need fuel and medicine. Four minutes. That's all the horde will give us.", 1.0)
	await _pan(player.global_position, 1.6, 1.0)
	await _say("mara", "On it, Commander.", 0.6)
	await _pan(Vector2(1600, 500), 1.4, 0.95)
	await _say("mara", "...The station lights are still on. Someone kept the generator running.", 1.2)
	await _say("redd", "Then someone's alive in there. Eyes open, scout.", 1.0)
	await _pan(player.global_position, 1.0, 1.0)

func _ground_intro_ch2() -> void:
	camera.top_level = true
	camera.global_position = level.intro_focus
	camera.zoom = Vector2.ONE * 0.8
	AudioMan.play("signal", -6.0, 0.0)
	await Router.fade_in(1.0)
	await _say("iris", "There it is. The Broadcaster's tower.", 1.0)
	await _pan(Vector2(520, 700), 1.8, 0.95)
	await _say("iris", "Relay A... B is across the plaza, C is by the south street.", 1.0)
	await _pan(player.global_position, 1.6, 1.0)
	await _say("redd", "Four and a half minutes of fuel, Mara. Make them count.", 1.0)
	await _say("mara", "Kill the relays. Kill the signal. Got it.", 0.8)

func _ground_intro_ch3() -> void:
	camera.top_level = true
	camera.global_position = level.intro_focus
	camera.zoom = Vector2.ONE * 0.95
	await Router.fade_in(1.0)
	await _say("iris", "The beacon's signature is strongest toward the engine.", 1.0)
	await _pan(Vector2(4075, 500), 2.4, 0.85)
	await _say("mara", "Then that's where it's hiding. Engine car.", 0.9)
	await _pan(player.global_position, 2.0, 1.0)
	await _say("redd", "Search every car on your way up. And Mara — the passengers... some didn't make it.", 1.3)
	await _say("mara", "I know. I'll be quick.", 0.8)

func _ground_intro_ch4() -> void:
	camera.top_level = true
	camera.global_position = level.intro_focus
	camera.zoom = Vector2.ONE * 0.85
	AudioMan.play("signal", -6.0, 0.0)
	await Router.fade_in(1.0)
	await _say("iris", "There. The assembly shed. The recall engine is inside.", 1.1)
	await _pan(Vector2(480, 700), 1.6, 0.95)
	await _say("iris", "Amplifiers — one west, one east, one by the dock.", 1.0)
	await _pan(player.global_position, 1.6, 1.0)
	await _say("redd", "Something big is guarding that shed. Yard-boss big.", 1.0)
	await _say("mara", "Good. I owe this place a wrecking.", 0.9)

# ================================================================ rescue (ch1)
func play_rescue() -> void:
	_begin()
	await _beat(0.4)
	await _pan(Vector2(1600, 300), 1.2, 1.05)
	level.open_cage()
	await _beat(0.8)
	await _say("iris", "You— you actually beat it. I'm Dr. Chen. Iris.", 1.0)
	await _say("mara", "The one keeping the lights on?", 0.8)
	await _say("iris", "I had to. The dark isn't what draws them here. Get me to the train — I'll explain.", 1.2)
	level.survivor.start_following(player)
	EventBus.survivor_rescued.emit()
	GameState.on_survivor_rescued()
	_end()

# ================================================================ endings
func play_ending() -> void:
	_begin()
	AudioMan.stop_music(0.8)
	await _pan(level.train_door_pos + Vector2(0, 40), 1.4, 0.95)
	AudioMan.play("train_horn", -4.0)
	match GameState.chapter:
		1:
			await _say("redd", "All aboard! Nice work, scout.", 0.9)
			await _say("iris", "Commander... they weren't wandering. The horde is following a signal.", 1.1)
			await _say("redd", "A signal? From where?", 0.8)
			await _say("iris", "A broadcast tower in Sector Seven. And this morning, the broadcast changed.", 1.1)
			AudioMan.play("radio", 0.0, 0.0)
			await _say("radio", "...Ember Line... we know you have her... bring us... MARA VALE...", 1.6)
			await _say("mara", "...How do they know my name?", 1.4)
		2:
			await _say("redd", "Tower's dark! Get aboard, we're rolling!", 0.9)
			await _say("iris", "Wait. That's wrong. I'm still reading a signal...", 1.1)
			AudioMan.play("radio", 0.0, 0.0)
			await _say("radio", "...signal source reacquired... source is MOVING... sixty kilometers per hour...", 1.5)
			await _say("mara", "Sixty kilometers an hour. Iris... that's our speed.", 1.3)
			await _say("iris", "The signal isn't in the tower anymore. It's on the train.", 1.5)
		3:
			await _say("redd", "Is it done?", 0.7)
			await _say("mara", "The Passenger is down. Iris has its briefcase.", 1.0)
			await _say("iris", "It's not a transmitter, Commander. It's a RECALL beacon. Listen.", 1.2)
			AudioMan.play("radio", 0.0, 0.0)
			await _say("radio", "...asset located... VALE bloodline confirmed... initiating recall... destination: DEPOT 12...", 1.7)
			await _say("mara", "It isn't calling the horde to us. It's calling us... home.", 1.5)
		4:
			await _say("redd", "The engine's dead! That's it — it's over!", 0.9)
			await _say("iris", "Mara... I pulled the staff list from the depot terminal.", 1.2)
			await _say("iris", "Project EMBER. Lead field engineer... VALE, E.", 1.4)
			await _say("mara", "...My mother.", 1.4)
			AudioMan.play("radio", 0.0, 0.0)
			await _say("radio", "...recall complete... welcome home, Mara...", 1.6)
	await Router.fade_out(1.2)
	subtitles.close()
	if not _skipped:
		match GameState.chapter:
			1: await _title_card("TO BE CONTINUED", "NEXT STOP: SECTOR SEVEN")
			2: await _title_card("TO BE CONTINUED", "CHAPTER 3: THE PASSENGER")
			3: await _title_card("TO BE CONTINUED", "CHAPTER 4: DEPOT 12")
			4: await _title_card("TO BE CONTINUED", "CHAPTER 5: PROJECT EMBER")
	_active = false
	GameState.win()

func _title_card(title_text: String, sub_text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 110
	add_child(layer)
	var label := UITheme.title(title_text, 44)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.45
	label.anchor_bottom = 0.45
	label.offset_left = -400
	label.offset_right = 400
	label.modulate.a = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(label)
	var sub_label := UITheme.label(sub_text, 22, UITheme.COL_DIM)
	sub_label.set_anchors_preset(Control.PRESET_CENTER)
	sub_label.anchor_left = 0.5
	sub_label.anchor_right = 0.5
	sub_label.anchor_top = 0.56
	sub_label.anchor_bottom = 0.56
	sub_label.offset_left = -400
	sub_label.offset_right = 400
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.modulate.a = 0.0
	layer.add_child(sub_label)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.8)
	tw.tween_property(sub_label, "modulate:a", 1.0, 0.6)
	tw.tween_interval(2.0)
	await tw.finished
	layer.queue_free()
