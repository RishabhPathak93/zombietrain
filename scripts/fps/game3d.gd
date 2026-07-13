extends Node3D
## 3D Mode orchestrator (Chapter 1, first-person). Reuses the entire 2D
## meta layer: GameState objectives, SaveGame profile, HUD, puzzles, notes,
## pause and results.

var level: Level3D
var player: PlayerFPS
var hud: HUD
var pause_menu: PauseMenu
var results: ResultsScreen
var puzzle: PuzzlePanel
var notes: NotePanel

var _ending := false
var _rescued := false
var _comm_flags: Dictionary = {}

func _ready() -> void:
	GameState.chapter = 1
	GameState.start_run(1)

	hud = HUD.new()
	add_child(hud)

	level = Level3D.new()
	add_child(level)

	player = PlayerFPS.new()
	add_child(player)
	player.position = Vector3(24.4, 0.2, 22.6)

	hud.joystick.vector_changed.connect(func(v: Vector2) -> void: player.input_vector = v)
	hud.pause_pressed.connect(_toggle_pause)
	hud.switch_pressed.connect(player.switch_weapon)
	hud.reload_pressed.connect(player.reload)
	hud.dash_pressed.connect(player.dash)

	# crosshair
	var cross_layer := CanvasLayer.new()
	cross_layer.layer = 6
	add_child(cross_layer)
	var cross := UITheme.label("+", 34, Color(1, 1, 1, 0.7))
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.anchor_left = 0.5
	cross.anchor_right = 0.5
	cross.anchor_top = 0.5
	cross.anchor_bottom = 0.5
	cross.offset_left = -12
	cross.offset_top = -24
	cross_layer.add_child(cross)
	var fire_button := Button.new()
	fire_button.text = "FIRE"
	fire_button.theme = UITheme.theme()
	fire_button.add_theme_font_size_override("font_size", 26)
	fire_button.custom_minimum_size = Vector2(128, 128)
	fire_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	fire_button.anchor_top = 0.5
	fire_button.anchor_bottom = 0.5
	fire_button.offset_left = -170
	fire_button.offset_right = -36
	fire_button.offset_top = -40
	fire_button.offset_bottom = 94
	fire_button.button_down.connect(func() -> void: player.set_trigger(true))
	fire_button.button_up.connect(func() -> void: player.set_trigger(false))
	cross_layer.add_child(fire_button)

	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.quit_to_menu.connect(func() -> void: Router.go("res://scenes/main_menu.tscn"))

	results = ResultsScreen.new()
	add_child(results)
	results.retry.connect(func() -> void: Router.go("res://scenes/game3d.tscn"))
	results.to_menu.connect(func() -> void: Router.go("res://scenes/main_menu.tscn"))
	results.next_chapter.connect(func() -> void:
		GameState.chapter = 2
		Router.go("res://scenes/game.tscn"))

	puzzle = PuzzlePanel.new()
	add_child(puzzle)
	notes = NotePanel.new()
	add_child(notes)
	level.puzzle_requested.connect(puzzle.open)
	puzzle.completed.connect(_on_puzzle_done)

	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_lost.connect(_on_game_lost)
	EventBus.objective_changed.connect(_on_objective_comm)
	EventBus.time_low.connect(func() -> void: _comm_once("timelow", "redd", "Thirty seconds! MOVE!"))

	AudioMan.music("game")
	Router.fade_rect.modulate.a = 1.0
	await Router.fade_in(1.2)
	EventBus.comm.emit("redd", "Junction Nine, 3D sweep. Fuel, medicine, survivor — then back to the train.")
	EventBus.comm.emit("mara", "Going in. The lights are still on down here...")
	GameState.begin_play()
	hud.banner("LEFT THUMB: MOVE  •  RIGHT SIDE: DRAG TO LOOK  •  HOLD FIRE")
	await get_tree().create_timer(4.0).timeout
	hud.banner("AIM ASSIST IS ON — POINT ROUGHLY AND SHOOT")

func _toggle_pause() -> void:
	if GameState.state == GameState.State.PLAYING:
		pause_menu.open()
	elif GameState.state == GameState.State.PAUSED:
		pause_menu.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()

func _comm_once(flag: String, speaker: String, text: String) -> void:
	if _comm_flags.has(flag):
		return
	_comm_flags[flag] = true
	EventBus.comm.emit(speaker, text)

func _on_objective_comm() -> void:
	if GameState.objective_id() == "gate":
		_comm_once("gate", "redd", "North Hall's sealed. Find the generator panel — rewire it.")

func _on_puzzle_done() -> void:
	GameState.open_gate()
	level.mark_console_used()
	level.open_gate_visual()
	_comm_once("gateopen", "redd", "Power's back. The hall is open — and something heard it.")

func _on_boss_defeated() -> void:
	GameState.on_boss_defeated()
	if _rescued:
		return
	_rescued = true
	await get_tree().create_timer(1.2).timeout
	level.open_cage()
	EventBus.comm.emit("iris", "You beat it... I'm Iris. Get me to that train and I'll explain everything.")
	EventBus.survivor_rescued.emit()
	GameState.on_survivor_rescued()
	hud.banner("GET BACK TO THE TRAIN!")

func start_ending() -> void:
	if _ending:
		return
	_ending = true
	AudioMan.play("train_horn")
	await Router.fade_out(1.2)
	GameState.win()

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	GameState.lose("Mara went down in the station.")

func _on_game_won() -> void:
	hud.set_gameplay_visible(false)
	await Router.fade_in(0.8)
	results.show_victory()

func _on_game_lost(reason: String) -> void:
	results.show_defeat(reason)
