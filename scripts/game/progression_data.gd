extends RefCounted
class_name ProgressionData

const DATA_PATH := "res://data/progression.json"

static var _loaded := false
static var _default_visits := 5
static var _location_visits: Dictionary = {}
static var _maze_min := 1
static var _maze_grind := 3
static var _maze_grind_ratio := 0.55

static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_default_visits = int(parsed.get("location_visits_default", 5))
	_location_visits = parsed.get("location_visits", {})
	_maze_min = int(parsed.get("maze_min_visits_per_page", 1))
	_maze_grind = int(parsed.get("maze_grind_visits", 3))
	_maze_grind_ratio = float(parsed.get("maze_grind_ratio", 0.55))

static func location_visits_required(screen_id: String) -> int:
	load_all()
	return int(_location_visits.get(screen_id, _default_visits))

static func maze_min_visits_per_page() -> int:
	load_all()
	return _maze_min

static func maze_grind_visits() -> int:
	load_all()
	return _maze_grind

static func maze_grind_ratio() -> float:
	load_all()
	return _maze_grind_ratio
