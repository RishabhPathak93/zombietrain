extends Node2D
## Game orchestrator: builds the run (level, player, camera, HUD, menus,
## cutscenes) and routes top-level flow between them.

var level: Level
var player: Player
var camera: Camera2D
var hud: HUD
var pause_menu: PauseMenu
var results: ResultsScreen
var director: CutsceneDirector
var compass: Sprite2D

var _ending_started := false

func _ready() -> void:
	GameState.start_run(GameState.chapter)
	Pool.register("bullet", func() -> Bullet: return Bullet.new())
	Pool.register("boss_orb", func() -> BossProjectile: return BossProjectile.new())

	match GameState.chapter:
		2: level = Level2.new()
		3: level = Level3.new()
		4: level = Level4.new()
		_: level = Level.new()
	add_child(level)

	player = Player.new()
	level.add_child(player)
	player.global_position = level.player_start

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level.world_rect.size.x)
	camera.limit_bottom = int(level.world_rect.size.y)
	player.add_child(camera)
	camera.make_current()
	Fx.register_camera(camera)

	compass = Sprite2D.new()
	compass.texture = preload("res://assets/textures/arrow.png")
	compass.z_index = 45
	compass.visible = false
	level.add_child(compass)

	hud = HUD.new()
	add_child(hud)
	hud.joystick.vector_changed.connect(func(v: Vector2) -> void: player.input_vector = v)
	hud.pause_pressed.connect(_toggle_pause)
	hud.switch_pressed.connect(player.switch_weapon)
	hud.reload_pressed.connect(player.reload)

	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.quit_to_menu.connect(func() -> void: Router.go("res://scenes/main_menu.tscn"))

	results = ResultsScreen.new()
	add_child(results)
	results.retry.connect(func() -> void: Router.go("res://scenes/game.tscn"))
	results.to_menu.connect(func() -> void: Router.go("res://scenes/main_menu.tscn"))
	results.next_chapter.connect(_go_next_chapter)

	director = CutsceneDirector.new()
	add_child(director)
	director.camera = camera
	director.player = player
	director.level = level

	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_lost.connect(_on_game_lost)

	await director.play_intro()
	AudioMan.music("game")

func _process(_delta: float) -> void:
	_update_compass()

func _update_compass() -> void:
	if GameState.state != GameState.State.PLAYING or player == null or player.hp <= 0:
		compass.visible = false
		return
	var target := GameState.current_target()
	if target == Vector2.ZERO or player.global_position.distance_to(target) < 140.0:
		compass.visible = false
		return
	compass.visible = true
	var dir := (target - player.global_position).normalized()
	compass.global_position = player.global_position + dir * 78.0
	compass.rotation = dir.angle()
	compass.modulate.a = 0.5 + 0.4 * sin(Time.get_ticks_msec() * 0.006)

func _toggle_pause() -> void:
	if GameState.state == GameState.State.PLAYING:
		pause_menu.open()
	elif GameState.state == GameState.State.PAUSED:
		pause_menu.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	GameState.lose("Mara went down in the station.")

func _on_boss_defeated() -> void:
	GameState.on_boss_defeated()
	if GameState.chapter >= 2:
		AudioMan.play("power_down", 2.0)
		if GameState.objective_id() == "escape":
			hud.banner("GET BACK TO THE PASSENGER CAR!" if GameState.chapter == 3 else "RUN FOR THE TRAIN!")
		else:
			hud.banner(GameState.BOSS_NAMES[GameState.chapter] + " FALLS — FINISH THE OBJECTIVES!")
		return
	await get_tree().create_timer(1.1).timeout
	if GameState.state == GameState.State.PLAYING or GameState.state == GameState.State.CUTSCENE:
		await director.play_rescue()
		hud.banner("GET BACK TO THE TRAIN!")

func _go_next_chapter() -> void:
	GameState.chapter = mini(GameState.chapter + 1, GameState.MAX_CHAPTER)
	Router.go("res://scenes/game.tscn")

func start_ending() -> void:
	if _ending_started:
		return
	_ending_started = true
	director.play_ending()

func _on_game_won() -> void:
	hud.set_gameplay_visible(false)
	await Router.fade_in(0.8)
	results.show_victory()

func _on_game_lost(reason: String) -> void:
	results.show_defeat(reason)
