class_name PuzzlePanel
extends CanvasLayer
## Mini-game console panel. Three games: WIRES (match colored terminals),
## CODE (keypad using digits found in the world), SIMON (repeat the light
## sequence). Gameplay freezes (State.PUZZLE) while open.

signal completed
signal closed

const WIRE_COLORS := [Color(0.95, 0.4, 0.4), Color(0.4, 0.85, 1.0), Color(1.0, 0.85, 0.4)]

var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer
var _kind := ""
var _done := false
# wires
var _left_pick := -1
var _matched: Array[int] = []
var _left_buttons: Array[Button] = []
var _right_buttons: Array[Button] = []
var _right_map: Array[int] = []
# code
var _entry := ""
var _entry_label: Label
# simon
var _sequence: Array[int] = []
var _step := 0
var _simon_buttons: Array[Button] = []
var _accepting := false

func _ready() -> void:
	layer = 25
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.02, 0.04, 0.75)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = UITheme.panel()
	_panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(_panel)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_panel.add_child(_content)

func open(kind: String) -> void:
	_kind = kind
	_done = false
	GameState.state = GameState.State.PUZZLE
	visible = true
	AudioMan.play("ui_click")
	for child in _content.get_children():
		child.queue_free()
	match kind:
		"wires": _build_wires()
		"code": _build_code()
		"simon": _build_simon(4)
		"simon5": _build_simon(5)

func close() -> void:
	visible = false
	GameState.begin_play()
	closed.emit()

func _title(text: String, sub: String) -> void:
	var t := UITheme.title(text, 30)
	_content.add_child(t)
	var s := UITheme.label(sub, 18, UITheme.COL_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(s)

func _leave_button() -> void:
	var leave := UITheme.button("STEP AWAY", 18, Vector2(180, 50))
	leave.pressed.connect(close)
	var c := CenterContainer.new()
	c.add_child(leave)
	_content.add_child(c)

func _win() -> void:
	if _done:
		return
	_done = true
	AudioMan.play("heal")
	Fx.vibrate(40)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		close()
		completed.emit()
	)

# ---------------------------------------------------------------- WIRES
func _build_wires() -> void:
	_title("REWIRE THE PANEL", "Connect each wire to the terminal of the same color.")
	_left_pick = -1
	_matched = []
	_left_buttons = []
	_right_buttons = []
	_right_map = [0, 1, 2]
	_right_map.shuffle()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 60)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	for i in 3:
		var lb := UITheme.button("WIRE", 18, Vector2(150, 54))
		lb.modulate = WIRE_COLORS[i]
		lb.pressed.connect(_pick_left.bind(i))
		left.add_child(lb)
		_left_buttons.append(lb)
		var color_index: int = _right_map[i]
		var rb := UITheme.button("PORT", 18, Vector2(150, 54))
		rb.modulate = WIRE_COLORS[color_index]
		rb.pressed.connect(_pick_right.bind(i))
		right.add_child(rb)
		_right_buttons.append(rb)
	_leave_button()

func _pick_left(i: int) -> void:
	if i in _matched:
		return
	_left_pick = i
	for j in 3:
		_left_buttons[j].text = "WIRE >" if j == i else "WIRE"

func _pick_right(slot: int) -> void:
	if _left_pick < 0 or _right_map[slot] in _matched:
		return
	if _right_map[slot] == _left_pick:
		_matched.append(_left_pick)
		_left_buttons[_left_pick].disabled = true
		_right_buttons[slot].disabled = true
		_left_buttons[_left_pick].text = "OK"
		_right_buttons[slot].text = "OK"
		AudioMan.play("pickup_coin", -6.0)
		_left_pick = -1
		if _matched.size() == 3:
			_win()
	else:
		AudioMan.play("zombie_hit", -10.0)
		Fx.shake(2.0)
		_left_pick = -1
		for j in 3:
			if not _left_buttons[j].disabled:
				_left_buttons[j].text = "WIRE"

# ---------------------------------------------------------------- CODE
func _build_code() -> void:
	_title("GATE KEYPAD", "Code chips found near the relays reveal the digits.")
	var hint := UITheme.label("KNOWN: " + GameState.code_hint(), 24, UITheme.COL_ACCENT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(hint)
	_entry = ""
	_entry_label = UITheme.label("_ _ _", 34)
	_entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_entry_label)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var grid_center := CenterContainer.new()
	grid_center.add_child(grid)
	_content.add_child(grid_center)
	for n in 10:
		var b := UITheme.button(str(n), 22, Vector2(84, 56))
		b.pressed.connect(_code_press.bind(n))
		grid.add_child(b)
	_leave_button()

func _code_press(n: int) -> void:
	_entry += str(n)
	var shown := ""
	for i in 3:
		shown += (_entry[i] if i < _entry.length() else "_") + " "
	_entry_label.text = shown.strip_edges()
	if _entry.length() == 3:
		if _entry == GameState.gate_code:
			_win()
		else:
			AudioMan.play("zombie_hit", -8.0)
			Fx.shake(3.0)
			_entry = ""
			var tw := create_tween()
			tw.tween_interval(0.3)
			tw.tween_callback(func() -> void: _entry_label.text = "_ _ _")

# ---------------------------------------------------------------- SIMON
func _build_simon(length: int) -> void:
	_title("POWER SEQUENCE", "Watch the breakers light up, then repeat the order.")
	_sequence = []
	for i in length:
		_sequence.append(randi_range(0, 3))
	_step = 0
	_accepting = false
	_simon_buttons = []
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(row)
	for i in 4:
		var b := UITheme.button(str(i + 1), 24, Vector2(100, 76))
		b.modulate = WIRE_COLORS[i % 3] if i < 3 else Color(0.7, 1.0, 0.6)
		b.pressed.connect(_simon_press.bind(i))
		row.add_child(b)
		_simon_buttons.append(b)
	_leave_button()
	_play_sequence()

func _play_sequence() -> void:
	_accepting = false
	var tw := create_tween()
	tw.tween_interval(0.6)
	for idx in _sequence:
		tw.tween_callback(_flash.bind(idx))
		tw.tween_interval(0.55)
	tw.tween_callback(func() -> void: _accepting = true)

func _flash(i: int) -> void:
	if i >= _simon_buttons.size() or not is_instance_valid(_simon_buttons[i]):
		return
	AudioMan.play("ui_click", 0.0, 0.3)
	var b := _simon_buttons[i]
	var base := b.modulate
	b.modulate = Color(2.5, 2.5, 2.5)
	var tw := b.create_tween()
	tw.tween_property(b, "modulate", base, 0.4)

func _simon_press(i: int) -> void:
	if not _accepting or _done:
		return
	_flash(i)
	if i == _sequence[_step]:
		_step += 1
		if _step >= _sequence.size():
			_win()
	else:
		AudioMan.play("zombie_hit", -8.0)
		Fx.shake(2.0)
		_step = 0
		_play_sequence()
