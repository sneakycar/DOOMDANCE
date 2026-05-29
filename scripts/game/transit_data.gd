extends RefCounted
class_name TransitData

const DATA_PATH := "res://data/transit.json"

static var _routes: Array = []
static var _header := "SEPTA"
static var _subtitle := ""

static func load_all() -> void:
	if not _routes.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing transit data: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_header = str(parsed.get("header", "SEPTA"))
	_subtitle = str(parsed.get("subtitle", ""))
	_routes = parsed.get("routes", [])

static func header_text() -> String:
	load_all()
	return _header

static func subtitle_text() -> String:
	load_all()
	return _subtitle

static func available_routes() -> Array[Dictionary]:
	load_all()
	var out: Array[Dictionary] = []
	for raw in _routes:
		if raw is not Dictionary:
			continue
		var route: Dictionary = raw
		if _route_available(route):
			out.append(route)
	return out

static func _route_available(route: Dictionary) -> bool:
	var now := Time.get_datetime_dict_from_system()
	var hour: int = int(now.hour)
	var weekday: int = int(now.weekday)
	if route.has("weekdays"):
		var days: Variant = route.get("weekdays")
		if days is Array and not weekday in days:
			return false
	if bool(route.get("night_only", false)) and not DayNight.is_night():
		return false
	if bool(route.get("day_only", false)) and DayNight.is_night():
		return false
	var start_h: int = int(route.get("hour_start", 0))
	var end_h: int = int(route.get("hour_end", 24))
	if end_h <= start_h:
		if not (hour >= start_h or hour < end_h):
			return false
	elif hour < start_h or hour >= end_h:
		return false
	if route.has("min_luck"):
		if float(GameState.hidden_metrics.get("luck", 50.0)) < float(route.get("min_luck", 0)):
			return false
	if route.has("max_heat"):
		if float(GameState.hidden_metrics.get("heat", 0.0)) > float(route.get("max_heat", 100)):
			return false
	if route.has("min_money"):
		if GameState.money < int(route.get("min_money", 0)):
			return false
	if route.has("min_intoxication"):
		if float(GameState.hidden_metrics.get("intoxication", 0.0)) < float(route.get("min_intoxication", 0)):
			return false
	var target := str(route.get("target", ""))
	if bool(route.get("require_unvisited", false)) and target != "":
		if GameState.location_visit_count(target) >= 1:
			return false
	return true

static func route_label(route: Dictionary) -> String:
	return str(route.get("label", route.get("id", "?"))).to_upper()

static func route_cost(route: Dictionary) -> int:
	return int(route.get("cost", 0))
