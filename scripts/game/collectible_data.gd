extends RefCounted
class_name CollectibleData

const DATA_PATH := "res://data/collectibles.json"

static var _collectibles: Array = []
static var _categories: Dictionary = {}
static var _by_id: Dictionary = {}
static var _by_name: Dictionary = {}

static func load_all() -> void:
	if not _collectibles.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing collectibles: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_categories = parsed.get("categories", {})
	_collectibles = parsed.get("collectibles", [])
	_by_id.clear()
	_by_name.clear()
	for entry in _collectibles:
		var d: Dictionary = entry
		_by_id[d.get("id", "")] = d
		_by_name[d.get("name", "")] = d

static func lookup(id: String) -> Dictionary:
	load_all()
	return _by_id.get(id, {})

static func id_for_name(display_name: String) -> String:
	load_all()
	var d: Dictionary = _by_name.get(display_name, {})
	return d.get("id", "")

static func name_for_id(collectible_id: String) -> String:
	var data := lookup(collectible_id)
	return str(data.get("name", collectible_id))

static func category_label(category: String) -> String:
	load_all()
	return _categories.get(category, {}).get("label", category.to_upper())

static func category_keys() -> Array:
	load_all()
	return _categories.keys()

static func category_cap(category: String) -> int:
	load_all()
	return int(_categories.get(category, {}).get("cap", 99))

static func all_in_category(category: String) -> Array:
	load_all()
	var out: Array = []
	for entry in _collectibles:
		if entry.get("category", "") == category:
			out.append(entry)
	return out

static func base_value(collectible_id: String) -> int:
	var data := lookup(collectible_id)
	return int(data.get("base_value", 1))

static func pawn_rate(collectible_id: String) -> float:
	var data := lookup(collectible_id)
	return float(data.get("pawn_rate", 0.42))

static func is_sellable(collectible_id: String) -> bool:
	var data := lookup(collectible_id)
	if data.is_empty():
		return false
	return bool(data.get("sellable", true))

static func check_maze_page(page_id: String) -> void:
	load_all()
	for entry in _collectibles:
		var gate: String = str(entry.get("maze_page", ""))
		if gate.is_empty() or gate != page_id:
			continue
		var cid: String = str(entry.get("id", ""))
		if cid.is_empty():
			continue
		GameState.add_collectible(cid)
