extends RefCounted
class_name AlleyData

const DATA_DIR := "res://data/"

static var _props: Array[Dictionary] = []
static var _npcs: Array[Dictionary] = []
static var _loaded := false

static func load_all() -> void:
	if _loaded:
		return
	var props_doc = _read_json("props.json")
	var npcs_doc = _read_json("npcs.json")
	_props = _as_dict_array(props_doc.get("props", []))
	_npcs = _as_dict_array(npcs_doc.get("npcs", []))
	_loaded = true

static func all_props() -> Array[Dictionary]:
	load_all()
	return _props

static func all_npcs() -> Array[Dictionary]:
	load_all()
	return _npcs

static func phase_key(phase: int) -> String:
	match phase:
		GameClock.Phase.DAWN:
			return "dawn"
		GameClock.Phase.MORNING:
			return "morning"
		GameClock.Phase.AFTERNOON:
			return "afternoon"
		GameClock.Phase.EVENING:
			return "evening"
		_:
			return "night"

static func parse_color(raw: Array) -> Color:
	if raw.size() >= 3:
		var a := 1.0 if raw.size() < 4 else float(raw[3])
		return Color(float(raw[0]), float(raw[1]), float(raw[2]), a)
	return Color.WHITE

static func _read_json(filename: String) -> Dictionary:
	var path := DATA_DIR + filename
	if not FileAccess.file_exists(path):
		push_error("AlleyData: missing %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func _as_dict_array(rows: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in rows:
		if row is Dictionary:
			out.append(row)
	return out
