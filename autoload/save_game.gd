extends Node
## Persistent profile: coins, upgrades, records, settings. JSON in user://.

const SAVE_PATH := "user://save.json"
const MAX_LEVEL := 5

const UPGRADE_DEFS := {
	"pistol_damage": {"name": "Pistol Damage", "base_cost": 60, "per": 0.15},
	"pistol_rate": {"name": "Pistol Fire Rate", "base_cost": 80, "per": 0.10},
	"pistol_mag": {"name": "Pistol Mag +2", "base_cost": 50, "per": 2.0},
	"shotgun_damage": {"name": "Shotgun Damage", "base_cost": 70, "per": 0.15},
	"shotgun_rate": {"name": "Shotgun Fire Rate", "base_cost": 90, "per": 0.10},
	"shotgun_mag": {"name": "Shotgun Mag +1", "base_cost": 60, "per": 1.0},
	"smg_damage": {"name": "SMG Damage", "base_cost": 70, "per": 0.15},
	"smg_rate": {"name": "SMG Fire Rate", "base_cost": 90, "per": 0.10},
	"smg_mag": {"name": "SMG Mag +5", "base_cost": 60, "per": 5.0},
	"rifle_damage": {"name": "Rifle Damage", "base_cost": 90, "per": 0.15},
	"rifle_rate": {"name": "Rifle Fire Rate", "base_cost": 110, "per": 0.10},
	"rifle_mag": {"name": "Rifle Mag +1", "base_cost": 70, "per": 1.0},
	"vest": {"name": "Armor Vest (+15 HP)", "base_cost": 100, "per": 15.0},
	"boots": {"name": "Scout Boots (+6% Speed)", "base_cost": 100, "per": 0.06},
}

const WEAPON_SHOP := {
	"smg": {"name": "SMG — fast bullet hose", "cost": 350},
	"rifle": {"name": "Rifle — pierces 3 targets", "cost": 600},
}

var data: Dictionary = {}

func _ready() -> void:
	load_data()

func _defaults() -> Dictionary:
	var upgrades := {}
	for key in UPGRADE_DEFS.keys():
		upgrades[key] = 0
	return {
		"coins": 0,
		"best_time": -1.0,
		"runs": 0,
		"wins": 0,
		"kills_total": 0,
		"seen_intro": false,
		"weapons_owned": ["pistol", "shotgun"],
		"chapter2_unlocked": false,
		"unlocked_chapters": 1,
		"last_chapter": 1,
		"upgrades": upgrades,
		"settings": {
			"music": 0.8,
			"sfx": 0.9,
			"shake": true,
			"haptics": true,
			"auto_fire": true,
		},
	}

func load_data() -> void:
	data = _defaults()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_merge(data, parsed)
	# Migration: old saves only had the chapter-2 flag.
	if bool(data["chapter2_unlocked"]) and int(data["unlocked_chapters"]) < 2:
		data["unlocked_chapters"] = 2

func _merge(base: Dictionary, incoming: Dictionary) -> void:
	for key in incoming.keys():
		if base.has(key) and base[key] is Dictionary and incoming[key] is Dictionary:
			_merge(base[key], incoming[key])
		elif base.has(key):
			base[key] = incoming[key]

func save_data() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func coins() -> int:
	return int(data["coins"])

func add_coins(amount: int) -> void:
	data["coins"] = coins() + amount
	save_data()

func spend(amount: int) -> bool:
	if coins() < amount:
		return false
	data["coins"] = coins() - amount
	save_data()
	return true

func owns_weapon(id: String) -> bool:
	return id in data["weapons_owned"]

func buy_weapon(id: String) -> bool:
	if owns_weapon(id) or not spend(int(WEAPON_SHOP[id]["cost"])):
		return false
	data["weapons_owned"].append(id)
	save_data()
	return true

func upgrade_level(key: String) -> int:
	return int(data["upgrades"].get(key, 0))

func upgrade_cost(key: String) -> int:
	var level := upgrade_level(key)
	if level >= MAX_LEVEL:
		return -1
	return int(UPGRADE_DEFS[key]["base_cost"]) * (level + 1)

func buy_upgrade(key: String) -> bool:
	var cost := upgrade_cost(key)
	if cost < 0 or not spend(cost):
		return false
	data["upgrades"][key] = upgrade_level(key) + 1
	save_data()
	return true

func upgrade_bonus(key: String) -> float:
	return float(UPGRADE_DEFS[key]["per"]) * upgrade_level(key)

func setting(key: String):
	return data["settings"].get(key)

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	save_data()

func has_progress() -> bool:
	return int(data["runs"]) > 0 or coins() > 0 or int(data["unlocked_chapters"]) > 1 or bool(data["seen_intro"])

func reset() -> void:
	data = _defaults()
	save_data()
	AudioMan.apply_settings()

func record_run(won: bool, run_time: float, kills: int) -> void:
	data["runs"] = int(data["runs"]) + 1
	data["kills_total"] = int(data["kills_total"]) + kills
	if won:
		data["wins"] = int(data["wins"]) + 1
		if float(data["best_time"]) < 0.0 or run_time < float(data["best_time"]):
			data["best_time"] = run_time
	save_data()
