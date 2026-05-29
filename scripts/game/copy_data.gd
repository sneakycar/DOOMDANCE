extends RefCounted
class_name CopyData

const DATA_PATH := "res://data/copy.json"

static var _copy: Dictionary = {}

static func load_all() -> void:
	if not _copy.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_copy = parsed

static func get(path: String, fallback: String = "") -> String:
	load_all()
	var parts := path.split("/")
	var node: Variant = _copy
	for part in parts:
		if typeof(node) != TYPE_DICTIONARY:
			return fallback
		node = node.get(part, null)
		if node == null:
			return fallback
	return str(node) if node != null else fallback
