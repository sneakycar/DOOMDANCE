extends Node
## Room ambience overlays + Japan Doll concert playback — sits above the main soundtrack.

const AudioData := preload("res://scripts/game/audio_data.gd")
const BUS_AMBIENCE := "Ambience"
const BUS_CONCERT := "Concert"

var _ambience_players: Array[AudioStreamPlayer] = []
var _concert_player: AudioStreamPlayer
var _current_room := ""
var _current_concert_id := ""
var _music_ducked := false
var _saved_music_db := 0.0
var _muted := false
var _warned_paths: Dictionary = {}

func _ready() -> void:
	_ensure_bus(BUS_AMBIENCE)
	_ensure_bus(BUS_CONCERT)
	_concert_player = _make_player(BUS_CONCERT)
	add_child(_concert_player)
	_concert_player.finished.connect(_on_concert_track_finished)
	GameState.concert_changed.connect(_sync_concert)
	DoomMusic.mute_changed.connect(_on_mute_changed)
	_on_mute_changed(DoomMusic.is_muted())

func set_room(screen_id: String) -> void:
	if screen_id == _current_room:
		return
	_stop_ambience()
	_current_room = screen_id
	if screen_id.is_empty():
		return
	for layer in AudioData.room_ambience(screen_id):
		_start_ambience_layer(layer)

func clear_room() -> void:
	_stop_ambience()
	_current_room = ""

func _sync_concert() -> void:
	if GameState.is_concert_active():
		_start_concert()
	else:
		_stop_concert()

func _start_concert() -> void:
	if _muted:
		return
	var track := AudioData.random_concert_track(_current_concert_id)
	var path := AudioData.track_path(track)
	if path.is_empty() or not AudioData.path_exists(path):
		_warn_missing(path, "concert track")
		_duck_music(true)
		return
	var stream := _load_stream(path, true)
	if stream == null:
		return
	_current_concert_id = str(track.get("id", ""))
	_concert_player.volume_db = AudioData.concert_volume_db()
	_concert_player.stream = stream
	_concert_player.play()
	_duck_music(true)

func _stop_concert() -> void:
	_concert_player.stop()
	_current_concert_id = ""
	_duck_music(false)

func _on_concert_track_finished() -> void:
	if not GameState.is_concert_active() or _muted:
		_stop_concert()
		return
	_start_concert()

func _start_ambience_layer(layer: Dictionary) -> void:
	if _muted:
		return
	var path := AudioData.layer_path(layer)
	if path.is_empty() or not AudioData.path_exists(path):
		_warn_missing(path, str(layer.get("id", "ambience")))
		return
	var stream := _load_stream(path, bool(layer.get("loop", true)))
	if stream == null:
		return
	var player := _make_player(BUS_AMBIENCE)
	player.volume_db = float(layer.get("volume_db", -8.0))
	player.stream = stream
	add_child(player)
	player.play()
	_ambience_players.append(player)

func _stop_ambience() -> void:
	for player in _ambience_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_ambience_players.clear()

func _duck_music(duck: bool) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if duck and not _music_ducked:
		_saved_music_db = AudioServer.get_bus_volume_db(idx)
		AudioServer.set_bus_volume_db(idx, _saved_music_db + AudioData.concert_duck_db())
		_music_ducked = true
	elif not duck and _music_ducked:
		AudioServer.set_bus_volume_db(idx, _saved_music_db)
		_music_ducked = false

func _on_mute_changed(muted: bool) -> void:
	_muted = muted
	_set_bus_mute(BUS_AMBIENCE, muted)
	_set_bus_mute(BUS_CONCERT, muted)
	if muted:
		_concert_player.stop()
		for player in _ambience_players:
			if is_instance_valid(player):
				player.stop()
		_duck_music(false)
	elif GameState.is_concert_active():
		_sync_concert()
	elif not _current_room.is_empty():
		var room := _current_room
		_current_room = ""
		set_room(room)

func _set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus(AudioServer.bus_count)
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	return player

func _load_stream(path: String, loop: bool) -> AudioStream:
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return null
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	return stream

func _warn_missing(path: String, label: String) -> void:
	if path.is_empty():
		path = "(empty path)"
	if _warned_paths.has(path):
		return
	_warned_paths[path] = true
	push_warning("Audio file not found for %s: %s" % [label, path])
