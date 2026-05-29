extends Node
## Chapter 1 soundtrack — desktop uses Godot audio; web/iOS uses HTML5 <audio>.

const TRACK_RES := "res://assets/audio/doom_soundtrack_01.mp3"
const MUTE_PATH := "user://music_mute.cfg"
const RETRY_SECONDS := 8.0

signal mute_changed(muted: bool)

var _player: AudioStreamPlayer
var _use_html_audio := false
var _started := false
var _unlocked := false
var _stream_ready := false
var _muted := false
var _retry_until := 0.0

func _ready() -> void:
	_load_mute_pref()
	_use_html_audio = OS.has_feature("web")
	if _use_html_audio:
		_stream_ready = true
		return
	_setup_music_bus()
	_player = AudioStreamPlayer.new()
	_player.name = "SoundtrackPlayer"
	_player.bus = "Music"
	_player.volume_db = 0.0
	add_child(_player)
	_apply_mute()
	_load_track_packed()

func _process(_delta: float) -> void:
	if not _unlocked or _muted or not _stream_ready:
		return
	if _use_html_audio:
		if _html_is_playing():
			return
	elif _player and _player.playing:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now > _retry_until:
		return
	_start_playback()

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

func _load_track_packed() -> void:
	var stream: AudioStream = load(TRACK_RES) as AudioStream
	if stream == null:
		push_warning("Soundtrack missing at %s" % TRACK_RES)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_player.stream = stream
	_stream_ready = true
	_maybe_start()

func unlock() -> void:
	_unlocked = true
	_retry_until = Time.get_ticks_msec() / 1000.0 + RETRY_SECONDS
	if _muted:
		return
	_start_playback()

func _maybe_start() -> void:
	if not _stream_ready or _muted:
		return
	if not _unlocked:
		return
	_start_playback()

func _start_playback() -> void:
	if not _stream_ready or _muted or not _unlocked:
		return
	if _use_html_audio:
		_html_start()
		_started = _html_is_playing()
		return
	if _player == null:
		return
	_player.stream_paused = false
	if _player.playing:
		_started = true
		return
	_player.stop()
	_player.play()
	_started = _player.playing

func _html_start() -> void:
	_js("window.doomDanceStartMusic && window.doomDanceStartMusic()")

func _html_stop() -> void:
	_js("window.doomDanceStopMusic && window.doomDanceStopMusic()")

func _html_set_muted(value: bool) -> void:
	_js("window.doomDanceSetMuted && window.doomDanceSetMuted(%s)" % ("true" if value else "false"))

func _html_is_playing() -> bool:
	var result: Variant = _js("return window.doomDanceIsPlaying ? window.doomDanceIsPlaying() : false")
	return bool(result)

func _js(code: String) -> Variant:
	if not _use_html_audio:
		return null
	return JavaScriptBridge.eval(code, true)

func is_muted() -> bool:
	return _muted

func is_playing() -> bool:
	if _muted:
		return false
	if _use_html_audio:
		return _html_is_playing()
	return _player != null and _player.playing

func toggle_mute() -> void:
	set_muted(not _muted)

func set_muted(value: bool) -> void:
	if _muted == value:
		return
	_muted = value
	_apply_mute()
	mute_changed.emit(_muted)
	_save_mute_pref()
	if not _muted:
		_unlocked = true
		_retry_until = Time.get_ticks_msec() / 1000.0 + RETRY_SECONDS
		_start_playback()
	else:
		if _use_html_audio:
			_html_stop()
		elif _player:
			_player.stop()

func _apply_mute() -> void:
	if _use_html_audio:
		_html_set_muted(_muted)
		return
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, _muted)

func _load_mute_pref() -> void:
	if _use_html_audio:
		_muted = false
		return
	var cfg := ConfigFile.new()
	if cfg.load(MUTE_PATH) != OK:
		return
	_muted = bool(cfg.get_value("audio", "muted", false))

func _save_mute_pref() -> void:
	if _use_html_audio:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", _muted)
	cfg.save(MUTE_PATH)
