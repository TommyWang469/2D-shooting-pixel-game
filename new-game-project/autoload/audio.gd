extends Node
## SFX + music manager. Preloads the generated WAVs and plays them through a small
## pool of AudioStreamPlayers with slight random pitch so repeats don't sound flat.
## Creates real "Music" and "SFX" buses (so Settings volume sliders work) and owns
## the per-biome music tracks. Autoloaded as `Audio`.

const SFX_PATHS := {
	"shoot": "res://assets/sfx/shoot.wav",
	"hit": "res://assets/sfx/hit.wav",
	"hurt": "res://assets/sfx/hurt.wav",
	"die": "res://assets/sfx/die.wav",
	"coin": "res://assets/sfx/coin.wav",
	"heart": "res://assets/sfx/heart.wav",
	"upgrade": "res://assets/sfx/upgrade.wav",
	"wave": "res://assets/sfx/wave.wav",
	"dash": "res://assets/sfx/dash.wav",
	"gameover": "res://assets/sfx/gameover.wav",
	"click": "res://assets/sfx/click.wav",
}

const MUSIC_PATHS := {
	"stone": "res://assets/music_stone.wav",
	"ember": "res://assets/music_ember.wav",
	"frost": "res://assets/music_frost.wav",
}

const POOL_SIZE := 12
const MUSIC_DB := -16.0

var _streams := {}
var _tracks := {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _current_track := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for key in SFX_PATHS:
		var s = load(SFX_PATHS[key])
		if s:
			_streams[key] = s
	for key in MUSIC_PATHS:
		var m = load(MUSIC_PATHS[key])
		if m is AudioStreamWAV:
			m.loop_mode = AudioStreamWAV.LOOP_FORWARD
			m.loop_begin = 0
			m.loop_end = m.data.size() / 2   # 16-bit mono -> 2 bytes/sample
			_tracks[key] = m
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func play(sound: String, pitch_var := 0.06, vol_db := 0.0) -> void:
	if not _streams.has(sound):
		return
	var p := _next_free()
	p.stream = _streams[sound]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = vol_db
	p.play()


func _next_free() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return _pool[0]


## Play a biome track ("stone"/"ember"/"frost"), fading out whatever was playing.
func play_music(track := "stone") -> void:
	if not _tracks.has(track):
		track = "stone"
	if _current_track == track and _music.playing:
		return
	_current_track = track
	if _music.playing:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -40.0, 0.35)
		tw.tween_callback(_start_track.bind(track))
	else:
		_start_track(track)


func _start_track(track: String) -> void:
	if _current_track != track:
		return   # a newer request superseded this fade
	_music.stop()
	_music.stream = _tracks.get(track)
	_music.volume_db = MUSIC_DB
	if _music.stream:
		_music.play()


func stop_music() -> void:
	_current_track = ""
	_music.stop()
