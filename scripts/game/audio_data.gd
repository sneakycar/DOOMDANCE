extends RefCounted
class_name AudioData

const DATA_PATH := "res://data/audio.json"

static var _data: Dictionary = {}

static func load_all() -> void:
	if not _data.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing audio data: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid audio.json")
		return
	_data = parsed

static func ambience_def(ambience_id: String) -> Dictionary:
	load_all()
	var raw: Variant = _data.get("ambience", {}).get(ambience_id, {})
	if raw is not Dictionary:
		return {}
	var cfg: Dictionary = raw.duplicate()
	cfg["id"] = ambience_id
	return cfg

static func room_ambience(screen_id: String) -> Array[Dictionary]:
	load_all()
	var out: Array[Dictionary] = []
	var seen: Dictionary = {}
	for ambience_id in _data.get("rooms", {}).get(screen_id, []):
		var id := str(ambience_id)
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		var cfg := ambience_def(id)
		if not cfg.is_empty():
			out.append(cfg)
	var screen := ScreenData.get_screen(screen_id)
	for ambience_id in screen.get("audio_ambience", []):
		var id := str(ambience_id)
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		var cfg := ambience_def(id)
		if not cfg.is_empty():
			out.append(cfg)
	return out

static func concert_config() -> Dictionary:
	load_all()
	var raw: Variant = _data.get("japan_doll_concert", {})
	if raw is Dictionary:
		return raw
	return {}

static func concert_duck_db() -> float:
	return float(concert_config().get("duck_music_db", -12.0))

static func concert_volume_db() -> float:
	return float(concert_config().get("volume_db", 0.0))

static func concert_tracks() -> Array[Dictionary]:
	var cfg := concert_config()
	var raw: Variant = cfg.get("tracks", [])
	var out: Array[Dictionary] = []
	if raw is not Array:
		return out
	for entry in raw:
		if entry is Dictionary:
			out.append(entry)
	return out

static func random_concert_track(exclude_id: String = "") -> Dictionary:
	var tracks := concert_tracks()
	if tracks.is_empty():
		return {}
	var candidates: Array[Dictionary] = []
	for track in tracks:
		if str(track.get("id", "")) != exclude_id:
			candidates.append(track)
	if candidates.is_empty():
		candidates = tracks
	return candidates[randi() % candidates.size()].duplicate()

static func track_path(track: Dictionary) -> String:
	return str(track.get("path", ""))

static func layer_path(layer: Dictionary) -> String:
	return str(layer.get("path", ""))

static func path_exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)
