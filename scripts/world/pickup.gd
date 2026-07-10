class_name Pickup
extends Area2D
## World loot: coins, fuel cans, medicine, ammo speed-loaders, hearts.
## Coins magnet toward the player. Coins are pooled.

const TEXTURES := {
	"coin": preload("res://assets/textures/coin.png"),
	"fuel": preload("res://assets/textures/fuel.png"),
	"med": preload("res://assets/textures/medkit.png"),
	"ammo": preload("res://assets/textures/ammo.png"),
	"heart": preload("res://assets/textures/medkit.png"),
}

const MAGNET_RANGE := 110.0
const MAGNET_SPEED := 420.0

var kind := "coin"
var amount := 1
var _sprite: Sprite2D
var _collected := false
var _bob_tween: Tween
var _pulse_tween: Tween
var _player: Player = null

func _init() -> void:
	collision_layer = 16
	collision_mask = 0
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	z_index = 5
	body_entered.connect(_on_body_entered)

func setup(pickup_kind: String, pickup_amount: int = 1) -> void:
	kind = pickup_kind
	amount = pickup_amount
	_collected = false
	_sprite.texture = TEXTURES[kind]
	_sprite.scale = Vector2.ONE
	_sprite.position = Vector2.ZERO
	modulate = Color.WHITE if kind != "heart" else Color(1.0, 0.65, 0.7)
	collision_mask = 2
	set_physics_process(kind == "coin")
	# Gentle bob so loot reads as interactive.
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(_sprite, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	if kind == "fuel" or kind == "med":
		_pulse_tween = create_tween()
		_pulse_tween.set_loops()
		_pulse_tween.tween_property(_sprite, "scale", Vector2.ONE * 1.15, 0.5)
		_pulse_tween.tween_property(_sprite, "scale", Vector2.ONE, 0.5)

func _physics_process(delta: float) -> void:
	# Coin magnet.
	if _collected:
		return
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() == 0:
			return
		_player = players[0]
	var dist := global_position.distance_to(_player.global_position)
	if dist < MAGNET_RANGE:
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * MAGNET_SPEED * delta * (1.0 - dist / (MAGNET_RANGE * 1.2))

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Player:
		return
	_collected = true
	collision_mask = 0
	var player: Player = body
	match kind:
		"coin":
			GameState.add_coins(amount)
			AudioMan.play("pickup_coin", -6.0, 0.15)
		"fuel":
			GameState.add_fuel()
			AudioMan.play("pickup_item")
			Fx.float_text(global_position, "FUEL SECURED", UITheme.COL_ACCENT, 24)
			Fx.vibrate(30)
		"med":
			GameState.add_meds()
			AudioMan.play("pickup_item")
			Fx.float_text(global_position, "MEDICINE SECURED", UITheme.COL_GOOD, 24)
			Fx.vibrate(30)
		"ammo":
			player.instant_refill()
			AudioMan.play("reload", 0.0)
			Fx.float_text(global_position, "AMMO", UITheme.COL_TEXT, 20)
		"heart":
			player.heal(30)
	EventBus.pickup_collected.emit(kind, amount)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "scale", Vector2.ONE * 1.6, 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(_vanish)

func _vanish() -> void:
	modulate.a = 1.0
	if kind == "coin":
		Pool.release(self)
	else:
		queue_free()
