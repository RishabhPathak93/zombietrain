extends Node
## Game feel: screen shake, hit-stop, camera zoom punches, floating text,
## one-shot particles, haptics. All pooled / allocation-free at runtime.

const GLOW := preload("res://assets/textures/glow.png")
const SPARK := preload("res://assets/textures/spark.png")
const GOO := preload("res://assets/textures/goo.png")
const SOFTDOT := preload("res://assets/textures/softdot.png")

var camera: Camera2D = null
var _shake_power := 0.0
var _base_zoom := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Pool.register("float_text", _make_float_text)
	Pool.register("burst", _make_burst)

func register_camera(cam: Camera2D) -> void:
	camera = cam
	_shake_power = 0.0
	_base_zoom = cam.zoom.x

func shake(power: float) -> void:
	if not bool(SaveGame.setting("shake")):
		return
	_shake_power = maxf(_shake_power, power)

func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if _shake_power > 0.01:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_power
		_shake_power = lerpf(_shake_power, 0.0, minf(10.0 * delta, 1.0))
	else:
		camera.offset = Vector2.ZERO

func zoom_punch(amount: float = 0.06, duration: float = 0.25) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var tw := camera.create_tween()
	tw.tween_property(camera, "zoom", Vector2.ONE * (_base_zoom + amount), duration * 0.3)
	tw.tween_property(camera, "zoom", Vector2.ONE * _base_zoom, duration * 0.7)

func hitstop(duration: float = 0.05, scale: float = 0.1) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = scale
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0

func vibrate(ms: int = 30) -> void:
	if bool(SaveGame.setting("haptics")):
		Input.vibrate_handheld(ms)

# ---------- floating text ----------
func _make_float_text() -> Label:
	var label := Label.new()
	label.z_index = 50
	label.top_level = true
	return label

func float_text(pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 22) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var label: Label = Pool.acquire("float_text")
	label.text = text
	label.modulate = color
	label.modulate.a = 1.0
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.09, 0.13))
	label.add_theme_constant_override("outline_size", 6)
	scene.add_child(label)
	label.global_position = pos + Vector2(-20, -30)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "global_position:y", label.global_position.y - 46.0, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(Pool.release.bind(label))

# ---------- particle bursts ----------
func _make_burst() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 1.0
	p.top_level = true
	p.z_index = 40
	return p

func burst(pos: Vector2, color: Color, amount: int = 10, speed: float = 140.0, life: float = 0.45, tex: Texture2D = null) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p: CPUParticles2D = Pool.acquire("burst")
	p.texture = tex if tex != null else SPARK
	p.amount = amount
	p.lifetime = life
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	p.color = color
	scene.add_child(p)
	p.global_position = pos
	p.restart()
	p.emitting = true
	var timer := get_tree().create_timer(life + 0.2)
	timer.timeout.connect(Pool.release.bind(p))

func hit_spark(pos: Vector2) -> void:
	burst(pos, Color(1.0, 0.92, 0.6), 6, 160.0, 0.3)

func goo_splat(pos: Vector2) -> void:
	burst(pos, Color(0.55, 0.85, 0.45), 8, 120.0, 0.5, SOFTDOT)
	var scene := get_tree().current_scene
	if scene == null:
		return
	var splat := Sprite2D.new()
	splat.texture = GOO
	splat.rotation = randf() * TAU
	splat.z_index = 1
	splat.modulate.a = 0.85
	scene.add_child(splat)
	splat.global_position = pos
	var tw := splat.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(splat, "modulate:a", 0.0, 3.0)
	tw.tween_callback(splat.queue_free)
