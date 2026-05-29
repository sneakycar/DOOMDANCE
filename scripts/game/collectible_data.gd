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

static func category_label(category: String) -> String:
	load_all()
	return _categories.get(category, {}).get("label", category.to_upper())

static func category_cap(category: String) -> int:
	load_all()
	return int(_categories.get(category, {}).get("cap", 20))

static func all_in_category(category: String) -> Array:
	load_all()
	var out: Array = []
	for entry in _collectibles:
		if entry.get("category", "") == category:
			out.append(entry)
	return out

static func total_count() -> int:
	load_all()
	return _collectibles.size()
