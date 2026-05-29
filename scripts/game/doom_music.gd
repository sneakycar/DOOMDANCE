extends Node
## Chapter 1 soundtrack — loops with reverb tail masking the seam.

const TRACK_RES := "res://assets/audio/doom_soundtrack_01.mp3"
const WEB_TRACK_NAME := "doom_soundtrack_01.mp3"

var _player: AudioStreamPlayer
var _started := false
var _unlocked := false

func _ready() -> void:
	_setup_music_bus()
	_player = AudioStreamPlayer.new()
	_player.name = "SoundtrackPlayer"
	_player.bus = "Music"
	_player.volume_db = -5.0
	add_child(_player)
	if OS.has_feature("web"):
		_load_web_stream()
	else:
		_play_stream(_load_local_stream())

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

func _load_local_stream() -> AudioStream:
	var stream := load(TRACK_RES) as AudioStreamMP3
	if stream:
		stream.loop = true
	return stream

func _load_web_stream() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_web_track_loaded.bind(http))
	var url: String = _web_track_url()
	http.request(url)

func _web_track_url() -> String:
	if not OS.has_feature("web"):
		return WEB_TRACK_NAME
	return JavaScriptBridge.eval(
		"window.location.origin + window.location.pathname.replace(/[^/]+$/, '') + '%s'" % WEB_TRACK_NAME
	)

func _on_web_track_loaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.is_empty():
		push_warning("Web soundtrack HTTP load failed (%s); trying res://." % code)
		_play_stream(_load_local_stream())
		return
	var stream := AudioStreamMP3.new()
	stream.data = body
	stream.loop = true
	_play_stream(stream)

func _play_stream(stream: AudioStream) -> void:
	if stream == null:
		push_warning("Soundtrack missing.")
		return
	_player.stream = stream
	_maybe_start()

func unlock() -> void:
	if _unlocked:
		return
	_unlocked = true
	_maybe_start()

func _maybe_start() -> void:
	if _started or _player.stream == null:
		return
	if OS.has_feature("web") and not _unlocked:
		return
	_player.play()
	_started = true
