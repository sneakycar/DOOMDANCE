extends Node
## Chapter 1 soundtrack — loops with reverb tail masking the seam.

const TRACK_RES := "res://assets/audio/doom_soundtrack_01.mp3"
const MUTE_PATH := "user://music_mute.cfg"

signal mute_changed(muted: bool)

var _player: AudioStreamPlayer
var _started := false
var _unlocked := false
var _stream_ready := false
var _muted := false

func _ready() -> void:
	_load_mute_pref()
	_setup_music_bus()
	_player = AudioStreamPlayer.new()
	_player.name = "SoundtrackPlayer"
	_player.bus = "Music"
	_player.volume_db = -3.0
	add_child(_player)
	_apply_mute()
	_load_track()

func _setup_music_bus() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, "Master")
		idx = 1
	if AudioServer.get_bus_effect_count(idx) > 0:
		return
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.94
	reverb.damping = 0.32
	reverb.spread = 0.88
	reverb.hipass = 0.12
	reverb.dry = 0.58
	reverb.wet = 0.42
	AudioServer.add_bus_effect(idx, reverb)

func _load_track() -> void:
	var stream := load(TRACK_RES) as AudioStreamMP3
	if stream == null:
		push_warning("Soundtrack missing at %s" % TRACK_RES)
		return
	stream.loop = true
	_player.stream = stream
	_stream_ready = true
	_maybe_start()

func unlock() -> void:
	_unlocked = true
	_maybe_start()
	if _stream_ready and _player != null and not _player.playing:
		_player.play()
		_started = true

func _maybe_start() -> void:
	if not _stream_ready or _player == null:
		return
	if OS.has_feature("web") and not _unlocked:
		return
	if _player.playing:
		_started = true
		return
	_player.play()
	_started = true

func is_muted() -> bool:
	return _muted

func toggle_mute() -> void:
	set_muted(not _muted)

func set_muted(value: bool) -> void:
	if _muted == value:
		return
	_muted = value
	_apply_mute()
	mute_changed.emit(_muted)
	_save_mute_pref()

func _apply_mute() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, _muted)

func _load_mute_pref() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(MUTE_PATH) != OK:
		return
	_muted = bool(cfg.get_value("audio", "muted", false))

func _save_mute_pref() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", _muted)
	cfg.save(MUTE_PATH)
