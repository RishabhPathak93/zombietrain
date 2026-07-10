class_name EnemyData
extends Resource
## Stats + behavior flags for a zombie variant.

@export var id: String = "walker"
@export var texture: Texture2D
@export var max_hp: float = 30.0
@export var speed: float = 60.0
@export var damage: int = 10
@export var attack_range: float = 42.0
@export var attack_windup: float = 0.35
@export var attack_cooldown: float = 1.1
@export var aggro_range: float = 260.0
@export var hearing_range: float = 520.0
@export var coin_min: int = 1
@export var coin_max: int = 3
@export var sprite_scale: float = 1.0
@export var tint: Color = Color.WHITE
@export_enum("sway", "lean", "stomp") var anim: String = "sway"
@export_enum("none", "lunge", "slam") var special: String = "none"
@export var special_range: float = 0.0
@export var special_cooldown: float = 4.0
