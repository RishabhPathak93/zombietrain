extends Node
## Run state machine, mission objectives, and the escape timer.

enum State { MENU, CUTSCENE, PLAYING, PAUSED, WON, LOST, PUZZLE }

const RUN_TIME := 240.0
const RUN_TIMES := {1: 300.0, 2: 330.0, 3: 330.0, 4: 360.0, 5: 390.0}
const GATE_TEXTS := {
	1: "Restore power at the generator panel",
	2: "Crack the tower gate code",
	3: "Unseal the engine car door",
	4: "Reset the assembly shed breakers",
	5: "Override the vault door",
}
const MAX_CHAPTER := 5
const FUEL_NEEDED := 3
const MEDS_NEEDED := 2
const RELAYS_NEEDED := 3
const SEARCH_NEEDED := 3
const BOSS_NAMES := {1: "THE CONDUCTOR", 2: "THE BROADCASTER", 3: "THE PASSENGER", 4: "THE FOREMAN", 5: "THE VOICE"}
const CHAPTER_NAMES := {1: "JUNCTION NINE", 2: "SECTOR SEVEN", 3: "THE PASSENGER", 4: "DEPOT 12", 5: "PROJECT EMBER"}

var chapter := 1
var relays := 0
var searched := 0
var gate_open := false
var gate_code := "000"
var code_digits: Array[String] = []
var run_duration := RUN_TIME
var state: int = State.MENU
var time_left: float = RUN_TIME
var fuel := 0
var meds := 0
var boss_defeated := false
var survivor_rescued := false
var coins_run := 0
var kills := 0
var _time_low_fired := false
var _escape_emitted := false
var _lost_reason := ""

## Level fills this with world positions for the objective compass.
var objective_targets: Dictionary = {}

func start_run(chapter_num: int = 1) -> void:
	chapter = chapter_num
	SaveGame.data["last_chapter"] = chapter
	SaveGame.save_data()
	state = State.CUTSCENE
	run_duration = float(RUN_TIMES.get(chapter, RUN_TIME))
	time_left = run_duration
	relays = 0
	searched = 0
	gate_open = false
	gate_code = "%d%d%d" % [randi_range(1, 9), randi_range(0, 9), randi_range(0, 9)]
	code_digits = []
	fuel = 0
	meds = 0
	boss_defeated = false
	survivor_rescued = false
	coins_run = 0
	kills = 0
	_time_low_fired = false
	_escape_emitted = false
	_lost_reason = ""
	objective_targets.clear()

func begin_play() -> void:
	if state != State.WON and state != State.LOST:
		state = State.PLAYING

func enter_cutscene() -> void:
	if state == State.PLAYING:
		state = State.CUTSCENE

func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	time_left -= delta
	if time_left <= 30.0 and not _time_low_fired:
		_time_low_fired = true
		EventBus.time_low.emit()
	if time_left <= 0.0:
		time_left = 0.0
		lose("The horde overran the station.")

func objective_id() -> String:
	if chapter == 2 or chapter == 4 or chapter == 5:
		if relays < RELAYS_NEEDED:
			return "relays"
		if not gate_open:
			return "gate"
		if not boss_defeated:
			return "boss"
		return "escape"
	if chapter == 3:
		if searched < SEARCH_NEEDED:
			return "search"
		if not gate_open:
			return "gate"
		if not boss_defeated:
			return "boss"
		return "escape"
	if fuel < FUEL_NEEDED or meds < MEDS_NEEDED:
		return "supplies"
	if not gate_open:
		return "gate"
	if not boss_defeated:
		return "boss"
	if not survivor_rescued:
		return "rescue"
	return "escape"

func objective_text() -> String:
	match objective_id():
		"relays":
			if chapter == 4:
				return "Destroy the amplifiers  •  %d/%d" % [relays, RELAYS_NEEDED]
			if chapter == 5:
				return "Destroy the echo conduits  •  %d/%d" % [relays, RELAYS_NEEDED]
			return "Destroy the signal relays  •  %d/%d" % [relays, RELAYS_NEEDED]
		"search":
			return "Search the train cars  •  %d/%d" % [searched, SEARCH_NEEDED]
		"gate":
			return String(GATE_TEXTS.get(chapter, "Open the way"))
		"supplies":
			var parts: Array[String] = []
			if fuel < FUEL_NEEDED:
				parts.append("Fuel %d/%d" % [fuel, FUEL_NEEDED])
			if meds < MEDS_NEEDED:
				parts.append("Medicine %d/%d" % [meds, MEDS_NEEDED])
			return "Collect supplies  •  " + "  •  ".join(parts)
		"boss":
			match chapter:
				2: return "Destroy the Broadcaster at the tower"
				3: return "The Passenger waits in the engine car"
				4: return "Bring down the Foreman"
				5: return "Silence The Voice in the vault"
			return "Defeat the Conductor in the North Hall"
		"rescue":
			return "Open the cage and free the survivor"
		"escape":
			if chapter == 3:
				return "Get back to the passenger car!"
			return "Get back to the train!"
	return ""

func current_target() -> Vector2:
	var id := objective_id()
	if id == "supplies":
		# Point at whichever supply is still missing (fuel first).
		if fuel < FUEL_NEEDED and objective_targets.has("fuel"):
			return objective_targets["fuel"]
		if objective_targets.has("meds"):
			return objective_targets["meds"]
	if objective_targets.has(id):
		return objective_targets[id]
	return Vector2.ZERO

func add_fuel() -> void:
	fuel += 1
	EventBus.objective_changed.emit()

func add_meds() -> void:
	meds += 1
	EventBus.objective_changed.emit()

func add_relay() -> void:
	relays += 1
	EventBus.objective_changed.emit()
	_maybe_start_escape()

func add_search() -> void:
	searched += 1
	EventBus.objective_changed.emit()
	_maybe_start_escape()

func open_gate() -> void:
	gate_open = true
	EventBus.objective_changed.emit()

func add_code_digit() -> void:
	if code_digits.size() < 3:
		code_digits.append(gate_code[code_digits.size()])
		EventBus.objective_changed.emit()

func code_hint() -> String:
	var hint := ""
	for i in 3:
		hint += (code_digits[i] if i < code_digits.size() else "_") + " "
	return hint.strip_edges()

func add_coins(amount: int) -> void:
	coins_run += amount
	EventBus.coins_changed.emit(coins_run)

func on_boss_defeated() -> void:
	boss_defeated = true
	EventBus.objective_changed.emit()
	_maybe_start_escape()

func _side_objectives_done() -> bool:
	match chapter:
		2, 4, 5: return relays >= RELAYS_NEEDED
		3: return searched >= SEARCH_NEEDED
	return true

func _maybe_start_escape() -> void:
	# Chapters 2-4 have no rescue step: the escape starts once the side
	# objectives AND the boss are both done (in either order).
	if chapter >= 2 and boss_defeated and _side_objectives_done() and not _escape_emitted:
		_escape_emitted = true
		EventBus.escape_phase_started.emit()

func on_survivor_rescued() -> void:
	survivor_rescued = true
	EventBus.objective_changed.emit()
	EventBus.escape_phase_started.emit()

func run_time_used() -> float:
	return run_duration - time_left

func win() -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.WON
	var unlocked := mini(maxi(int(SaveGame.data["unlocked_chapters"]), chapter + 1), MAX_CHAPTER)
	SaveGame.data["unlocked_chapters"] = unlocked
	if unlocked >= 2:
		SaveGame.data["chapter2_unlocked"] = true
	var bonus := int(time_left)
	coins_run += bonus
	SaveGame.add_coins(coins_run)
	SaveGame.record_run(true, run_time_used(), kills)
	EventBus.game_won.emit()

func lose(reason: String) -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.LOST
	_lost_reason = reason
	SaveGame.add_coins(int(coins_run / 2.0))
	SaveGame.record_run(false, run_time_used(), kills)
	EventBus.game_lost.emit(reason)

func lost_reason() -> String:
	return _lost_reason

func format_time(seconds: float) -> String:
	var s := int(ceilf(seconds))
	return "%d:%02d" % [int(s / 60.0), s % 60]
