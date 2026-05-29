extends RefCounted
class_name ScreenData

const DATA_PATH := "res://data/screens.json"

static var _screens: Dictionary = {}

static func load_all() -> void:
	if not _screens.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing screens data: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid screens.json")
		return
	_screens = parsed.get("screens", {})

static func get_screen(screen_id: String) -> Dictionary:
	load_all()
	return _screens.get(screen_id, {})

static func background_path(data: Dictionary) -> String:
	return DayNight.background_path(data)

static func screen_ids() -> Array:
	load_all()
	return _screens.keys()

static func is_panhandle_site(screen_id: String) -> bool:
	var data := get_screen(screen_id)
	if data.is_empty():
		return false
	for raw in data.get("hotspots", []):
		if raw is not Dictionary:
			continue
		match str(raw.get("action", "")):
			"panhandle", "stop_panhandle", "collect_panhandle":
				return true
	return false

static func is_concert_site(screen_id: String) -> bool:
	var data := get_screen(screen_id)
	if data.is_empty():
		return false
	for raw in data.get("hotspots", []):
		if raw is not Dictionary:
			continue
		match str(raw.get("action", "")):
			"concert_offer", "stop_concert", "collect_concert":
				return true
	return false

static func is_activity_site(screen_id: String) -> bool:
	return is_panhandle_site(screen_id) or is_concert_site(screen_id)
