class_name HUD
extends CanvasLayer
## In-game interface: joystick, health/ammo/coins, timer, objectives,
## boss bar, wave banner, damage vignette, pause + weapon buttons.

signal pause_pressed
signal switch_pressed
signal reload_pressed
signal dash_pressed
signal grenade_pressed
signal fire_down
signal fire_up

var joystick: FloatingJoystick

var _hp_bar: ProgressBar
var _coin_label: Label
var _timer_label: Label
var _objective_label: Label
var _ammo_label: Label
var _weapon_button: Button
var _reload_bar: ProgressBar
var _dash_button: Button
var _grenade_button: Button
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _banner: Label
var _flash: ColorRect
var _last_hp := 100
var _comm_box: PanelContainer
var _comm_portrait: TextureRect
var _comm_label: Label
var _comm_queue: Array = []
var _comm_busy := false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Damage / low-time flash under everything
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 0.15, 0.1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# Vignette
	var vignette := TextureRect.new()
	vignette.texture = preload("res://assets/textures/vignette_hole.png")
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	joystick = FloatingJoystick.new()
	add_child(joystick)

	# ---- top-left: health + coins
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(24, 20)
	top_left.add_theme_constant_override("separation", 8)
	add_child(top_left)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	top_left.add_child(hp_row)
	var heart_icon := TextureRect.new()
	heart_icon.texture = preload("res://assets/textures/medkit.png")
	heart_icon.modulate = Color(1.0, 0.6, 0.65)
	heart_icon.custom_minimum_size = Vector2(34, 34)
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hp_row.add_child(heart_icon)
	_hp_bar = UITheme.bar(UITheme.COL_GOOD, Vector2(240, 26))
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	hp_row.add_child(_hp_bar)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 10)
	top_left.add_child(coin_row)
	var coin_icon := TextureRect.new()
	coin_icon.texture = preload("res://assets/textures/coin.png")
	coin_icon.custom_minimum_size = Vector2(30, 30)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	_coin_label = UITheme.label("0", 26, UITheme.COL_ACCENT)
	coin_row.add_child(_coin_label)

	# ---- top-center: timer + objective
	var top_center := VBoxContainer.new()
	top_center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_center.anchor_left = 0.5
	top_center.anchor_right = 0.5
	top_center.offset_left = -320
	top_center.offset_right = 320
	top_center.offset_top = 14
	top_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(top_center)
	_timer_label = UITheme.label("4:00", 40, UITheme.COL_TEXT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_center.add_child(_timer_label)
	_objective_label = UITheme.label("", 20, UITheme.COL_DIM)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_center.add_child(_objective_label)

	# ---- top-right: pause
	var pause_button := UITheme.button("II", 30, Vector2(72, 72))
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -96
	pause_button.offset_right = -24
	pause_button.offset_top = 18
	pause_button.offset_bottom = 90
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(pause_button)

	# ---- bottom-right: weapon + reload
	var br := VBoxContainer.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.offset_left = -254
	br.offset_right = -30
	br.offset_top = -392
	br.offset_bottom = -24
	br.add_theme_constant_override("separation", 10)
	add_child(br)
	_ammo_label = UITheme.label("12 / 12", 30)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	br.add_child(_ammo_label)
	_reload_bar = UITheme.bar(UITheme.COL_ACCENT, Vector2(220, 12))
	_reload_bar.max_value = 1.0
	_reload_bar.value = 0.0
	_reload_bar.visible = false
	br.add_child(_reload_bar)
	_weapon_button = UITheme.button("PISTOL", 24, Vector2(220, 70))
	_weapon_button.pressed.connect(func() -> void: switch_pressed.emit())
	br.add_child(_weapon_button)
	var reload_button := UITheme.button("RELOAD", 20, Vector2(220, 56))
	reload_button.pressed.connect(func() -> void: reload_pressed.emit())
	br.add_child(reload_button)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	br.add_child(action_row)
	_dash_button = UITheme.button("DASH", 18, Vector2(106, 58))
	_dash_button.pressed.connect(func() -> void: dash_pressed.emit())
	action_row.add_child(_dash_button)
	_grenade_button = UITheme.button("GRND x2", 18, Vector2(106, 58))
	_grenade_button.pressed.connect(func() -> void: grenade_pressed.emit())
	action_row.add_child(_grenade_button)
	var fire_button := Button.new()
	fire_button.text = "FIRE"
	fire_button.theme = UITheme.theme()
	fire_button.add_theme_font_size_override("font_size", 24)
	fire_button.custom_minimum_size = Vector2(220, 64)
	fire_button.button_down.connect(func() -> void: fire_down.emit())
	fire_button.button_up.connect(func() -> void: fire_up.emit())
	br.add_child(fire_button)

	# ---- boss bar
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -260
	_boss_box.offset_right = 260
	_boss_box.offset_top = -96
	_boss_box.visible = false
	add_child(_boss_box)
	_boss_name = UITheme.label("THE CONDUCTOR", 20, UITheme.COL_BAD)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = UITheme.bar(UITheme.COL_BAD, Vector2(520, 20))
	_boss_box.add_child(_boss_bar)

	# ---- wave banner
	_banner = UITheme.label("", 34, UITheme.COL_BAD)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 0.32
	_banner.anchor_bottom = 0.32
	_banner.offset_left = -300
	_banner.offset_right = 300
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)

	# ---- signals
	EventBus.player_health_changed.connect(_on_hp)
	EventBus.coins_changed.connect(func(total: int) -> void: _coin_label.text = str(total))
	EventBus.ammo_changed.connect(_on_ammo)
	EventBus.weapon_changed.connect(_on_weapon)
	EventBus.reload_started.connect(_on_reload)
	EventBus.objective_changed.connect(_refresh_objective)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_hp)
	EventBus.boss_defeated.connect(func() -> void: _boss_box.visible = false)
	EventBus.wave_incoming.connect(func() -> void: banner("HORDE INCOMING!"))
	EventBus.grenades_changed.connect(_on_grenades)
	EventBus.dash_used.connect(_on_dash_used)
	EventBus.comm.connect(_on_comm)
	_comm_box = UITheme.panel()
	_comm_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_comm_box.anchor_left = 0.5
	_comm_box.anchor_right = 0.5
	_comm_box.offset_left = -300
	_comm_box.offset_right = 300
	_comm_box.offset_top = 96
	_comm_box.visible = false
	add_child(_comm_box)
	var comm_row := HBoxContainer.new()
	comm_row.add_theme_constant_override("separation", 12)
	_comm_box.add_child(comm_row)
	_comm_portrait = TextureRect.new()
	_comm_portrait.custom_minimum_size = Vector2(56, 56)
	_comm_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	comm_row.add_child(_comm_portrait)
	_comm_label = UITheme.label("", 19)
	_comm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	comm_row.add_child(_comm_label)
	EventBus.time_low.connect(func() -> void: banner("30 SECONDS LEFT!"))
	_refresh_objective()

func _process(_delta: float) -> void:
	_timer_label.text = GameState.format_time(GameState.time_left)
	var low := GameState.time_left <= 30.0 and GameState.state == GameState.State.PLAYING
	_timer_label.add_theme_color_override("font_color", UITheme.COL_BAD if low else UITheme.COL_TEXT)

func _on_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	var tw := create_tween()
	tw.tween_property(_hp_bar, "value", float(hp), 0.25)
	if hp < _last_hp:
		_flash.color.a = 0.35
		var tw2 := create_tween()
		tw2.tween_property(_flash, "color:a", 0.0, 0.4)
	_last_hp = hp

func _on_ammo(mag: int, mag_size: int, _weapon_id: String, reloading: bool) -> void:
	_ammo_label.text = ("..." if reloading else str(mag)) + " / " + str(mag_size)

func _on_weapon(weapon_id: String) -> void:
	_weapon_button.text = weapon_id.to_upper()

func _on_reload(duration: float) -> void:
	_reload_bar.visible = true
	_reload_bar.value = 0.0
	var tw := create_tween()
	tw.tween_property(_reload_bar, "value", 1.0, duration)
	tw.tween_callback(func() -> void: _reload_bar.visible = false)

func _refresh_objective() -> void:
	_objective_label.text = GameState.objective_text()
	var tw := create_tween()
	tw.tween_property(_objective_label, "scale", Vector2(1.1, 1.1), 0.12)
	tw.tween_property(_objective_label, "scale", Vector2.ONE, 0.15)

func _on_boss_spawned(max_hp: int) -> void:
	_boss_box.visible = true
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	var boss_title: String = GameState.BOSS_NAMES.get(GameState.chapter, "THE CONDUCTOR")
	_boss_name.text = boss_title
	banner(boss_title + " AWAKENS!")

func _on_boss_hp(hp: int, max_hp: int) -> void:
	_boss_bar.max_value = max_hp
	var tw := create_tween()
	tw.tween_property(_boss_bar, "value", float(hp), 0.15)

func _on_grenades(count: int) -> void:
	_grenade_button.text = "GRND x%d" % count
	_grenade_button.disabled = count <= 0

func _on_dash_used(cooldown: float) -> void:
	_dash_button.disabled = true
	var tw := create_tween()
	tw.tween_interval(cooldown)
	tw.tween_callback(func() -> void: _dash_button.disabled = false)

func _on_comm(speaker: String, text: String) -> void:
	_comm_queue.append([speaker, text])
	if not _comm_busy:
		_next_comm()

func _next_comm() -> void:
	if _comm_queue.is_empty():
		_comm_busy = false
		return
	_comm_busy = true
	var item: Array = _comm_queue.pop_front()
	_comm_portrait.texture = Subtitles.PORTRAITS.get(item[0])
	_comm_label.text = "%s:  %s" % [Subtitles.NAMES.get(item[0], str(item[0]).to_upper()), item[1]]
	_comm_box.visible = true
	_comm_box.modulate.a = 0.0
	AudioMan.play("radio", -14.0, 0.2)
	var tw := create_tween()
	tw.tween_property(_comm_box, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.4)
	tw.tween_property(_comm_box, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void:
		_comm_box.visible = false
		_next_comm()
	)

func banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.6)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)

func set_gameplay_visible(shown: bool) -> void:
	visible = shown
