extends Node
## Central audio: pooled SFX players + crossfading music. All streams are
## original procedurally-generated placeholders (CC0-equivalent, project-owned).

const SFX := {
	"pistol": preload("res://assets/audio/sfx/pistol.ogg"),
	"shotgun": preload("res://assets/audio/sfx/shotgun.ogg"),
	"reload": preload("res://assets/audio/sfx/reload.ogg"),
	"ui_click": preload("res://assets/audio/sfx/ui_click.ogg"),
	"pickup_coin": preload("res://assets/audio/sfx/pickup_coin.ogg"),
	"pickup_item": preload("res://assets/audio/sfx/pickup_item.ogg"),
	"heal": preload("res://assets/audio/sfx/heal.ogg"),
	"hurt": preload("res://assets/audio/sfx/hurt.ogg"),
	"zombie_growl1": preload("res://assets/audio/sfx/zombie_growl1.ogg"),
	"zombie_growl2": preload("res://assets/audio/sfx/zombie_growl2.ogg"),
	"zombie_growl3": preload("res://assets/audio/sfx/zombie_growl3.ogg"),
	"zombie_hit": preload("res://assets/audio/sfx/zombie_hit.ogg"),
	"zombie_die": preload("res://assets/audio/sfx/zombie_die.ogg"),
	"boss_roar": preload("res://assets/audio/sfx/boss_roar.ogg"),
	"slam": preload("res://assets/audio/sfx/slam.ogg"),
	"dash": preload("res://assets/audio/sfx/dash.ogg"),
	"crate": preload("res://assets/audio/sfx/crate.ogg"),
	"cage_open": preload("res://assets/audio/sfx/cage_open.ogg"),
	"train_horn": preload("res://assets/audio/sfx/train_horn.ogg"),
	"radio": preload("res://assets/audio/sfx/radio.ogg"),
	"heartbeat": preload("res://assets/audio/sfx/heartbeat.ogg"),
	"alert": preload("res://assets/audio/sfx/alert.ogg"),
	"victory": preload("res://assets/audio/sfx/victory.ogg"),
	"defeat": preload("res://assets/audio/sfx/defeat.ogg"),
	"step": preload("res://assets/audio/sfx/step.ogg"),
	"power_down": preload("res://assets/audio/sfx/power_down.ogg"),
	"signal": preload("res://assets/audio/sfx/signal.ogg"),
}

const MUSIC := {
	"menu": preload("res://assets/audio/music/music_menu.ogg"),
	"game": preload("res://assets/audio/music/music_game.ogg"),
	"boss": preload("res://assets/audio/music/music_boss.ogg"),
}

const SFX_VOICES := 10

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: String = ""
var _active_is_a := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = "Music"
		add_child(m)
	for key in MUSIC.keys():
		MUSIC[key].loop = true
	apply_settings()

func apply_settings() -> void:
	var music_v := float(SaveGame.setting("music"))
	var sfx_v := float(SaveGame.setting("sfx"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_v, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_v <= 0.001)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_v, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sfx_v <= 0.001)

func play(sfx_name: String, volume_db: float = 0.0, pitch_var: float = 0.08) -> void:
	if not SFX.has(sfx_name):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = SFX[sfx_name]
			p.volume_db = volume_db
			p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
			p.play()
			return
	# All voices busy: steal the first one.
	var p0 := _sfx_players[0]
	p0.stream = SFX[sfx_name]
	p0.volume_db = volume_db
	p0.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p0.play()

func music(track: String, fade_time: float = 1.2) -> void:
	if track == _music_current:
		return
	_music_current = track
	var from := _music_a if _active_is_a else _music_b
	var to := _music_b if _active_is_a else _music_a
	_active_is_a = not _active_is_a
	var tw := create_tween()
	if from.playing:
		tw.tween_property(from, "volume_db", -40.0, fade_time)
		tw.tween_callback(from.stop)
	if track != "" and MUSIC.has(track):
		to.stream = MUSIC[track]
		to.volume_db = -40.0
		to.play()
		var tw2 := create_tween()
		tw2.tween_property(to, "volume_db", -6.0, fade_time)

func stop_music(fade_time: float = 1.0) -> void:
	music("", fade_time)
