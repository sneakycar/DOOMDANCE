extends RefCounted
class_name RumorData

const DATA_PATH := "res://data/rumors.json"

static var _labels: Dictionary = {}
static var _maze_pages: Dictionary = {}

static func load_all() -> void:
	if not _labels.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_labels = parsed.get("labels", {})
	_maze_pages = parsed.get("maze_pages", {})

static func label_for(rumor_id: String) -> String:
	load_all()
	var key := rumor_id.strip_edges()
	if _labels.has(key):
		return str(_labels[key])
	return key.replace("_", " ")

static func check_maze_page(page_id: String) -> void:
	load_all()
	var rumor_id: String = str(_maze_pages.get(page_id, ""))
	if rumor_id.is_empty() and page_id.begins_with("meridian_"):
		rumor_id = page_id
	if rumor_id.is_empty():
		return
	GameState.discover_rumor(rumor_id)
