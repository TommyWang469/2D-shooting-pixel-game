extends Node
## SFX + music manager. Preloads the generated WAVs and plays them through a small
## pool of AudioStreamPlayers with slight random pitch so repeats don't sound flat.
## Autoloaded as `Audio`.

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

const POOL_SIZE := 12

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SFX_PATHS:
		var s = load(SFX_PATHS[key])
		if s:
			_streams[key] = s
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var m = load("res://assets/music.wav")
	if m is AudioStreamWAV:
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_begin = 0
		m.loop_end = m.data.size() / 2   # 16-bit mono -> 2 bytes/sample
	_music.stream = m
	_music.volume_db = -16.0


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


func play_music() -> void:
	if _music.stream and not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()
