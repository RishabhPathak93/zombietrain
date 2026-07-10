class_name WeaponData
extends Resource
## Data-driven weapon definition. Balance lives here, behavior in Player.
## Upgrade bonuses come from the persistent profile (SaveGame).

@export var id: String = "pistol"
@export var display_name: String = "Pistol"
@export var base_damage: float = 12.0
@export var pellets: int = 1
@export var spread_deg: float = 3.0
@export var fire_rate: float = 3.0 ## shots per second
@export var base_mag_size: int = 12
@export var reload_time: float = 1.0
@export var bullet_speed: float = 900.0
@export var bullet_range: float = 520.0
@export var sfx: String = "pistol"
@export var shake: float = 2.0
@export var kick: float = 40.0

func damage_now() -> float:
	return base_damage * (1.0 + SaveGame.upgrade_bonus(id + "_damage"))

func fire_rate_now() -> float:
	return fire_rate * (1.0 + SaveGame.upgrade_bonus(id + "_rate"))

func mag_size_now() -> int:
	return base_mag_size + int(SaveGame.upgrade_bonus(id + "_mag"))
