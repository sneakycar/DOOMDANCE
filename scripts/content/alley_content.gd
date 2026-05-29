extends RefCounted
class_name AlleyContent

## Loads `data/first_alley/*.json` — edit JSON to add doors, items, NPCs, etc.

const DATA_DIR := "res://data/first_alley/"

static var _loaded: bool = false
static var _items: Array[Dictionary] = []
static var _doors: Dictionary = {}
static var _npcs: Dictionary = {}
static var _vendors: Dictionary = {}
static var _money: Dictionary = {}
static var _time_events: Dictionary = {}
static var _placements: Dictionary = {}

static func ensure_loaded() -> void:
	if _loaded:
		return
	_load_file("items.json", func(data): _items = _array_to_dict_list(data.get("items", [])))
	_load_file("doors.json", func(data): _doors = _index_by_id(data.get("doors", [])))
	_load_file("npcs.json", func(data): _npcs = _index_by_id(data.get("npcs", [])))
	_load_file("vendors.json", func(data): _vendors = _index_by_id(data.get("vendors", [])))
	_load_file("money_interactions.json", func(data): _money = _index_by_id(data.get("money_interactions", [])))
	_load_file("time_events.json", func(data): _time_events = _index_by_id(data.get("time_events", [])))
	_load_file("placements.json", func(data): _placements = data)
	_loaded = true

static func reload() -> void:
	_loaded = false
	_items.clear()
	_doors.clear()
	_npcs.clear()
	_vendors.clear()
	_money.clear()
	_time_events.clear()
	_placements.clear()
	ensure_loaded()

static func all_items() -> Array[Dictionary]:
	ensure_loaded()
	return _items

static func item(item_id: StringName) -> Dictionary:
	ensure_loaded()
	for entry in _items:
		if StringName(entry.get("id", "")) == item_id:
			return entry
	return {}

static func item_label(item_id: StringName) -> String:
	var d := item(item_id)
	return d.get("label", str(item_id)) if not d.is_empty() else str(item_id)

static func item_sell_value(item_id: StringName) -> int:
	var d := item(item_id)
	return d.get("sell", 0) if not d.is_empty() else 0

static func item_is_usable(item_id: StringName) -> bool:
	var d := item(item_id)
	return d.get("usable", false) if not d.is_empty() else false

static func item_use_message(item_id: StringName) -> String:
	var d := item(item_id)
	return d.get("use_msg", "You use the item.") if not d.is_empty() else "You use the item."

static func item_consume_on_use(item_id: StringName) -> bool:
	var d := item(item_id)
	return d.get("consume_on_use", false) if not d.is_empty() else false

static func item_is_rare(item_id: StringName) -> bool:
	var d := item(item_id)
	return d.get("rare", false) if not d.is_empty() else false

static func item_spawn_phases(item_id: StringName) -> Array:
	var d := item(item_id)
	if d.is_empty():
		return []
	return d.get("spawn_phases", [])

static func item_spawn_active(item_id: StringName, phase: GameClock.TimePhase) -> bool:
	var phases: Array = item_spawn_phases(item_id)
	if phases.is_empty():
		return true
	return phase_name(phase) in phases

static func pick_spawn_item(rng: RandomNumberGenerator, state: AlleyState) -> Dictionary:
	ensure_loaded()
	var phase := state.get_phase() if state != null else GameClock.TimePhase.MORNING
	var pool: Array[Dictionary] = []
	for entry in _items:
		if entry.get("vendor_only", false):
			continue
		if entry.get("spawn_weight", 1) <= 0:
			continue
		if not item_spawn_active(StringName(entry.get("id", "")), phase):
			continue
		var w: float = entry.get("spawn_weight", 1)
		if entry.get("rare", false):
			w *= 0.35
		if state != null:
			w *= state.get_object_weight_multiplier(entry["id"])
		w = maxf(w, 0.25)
		for _i in maxi(1, int(round(w))):
			pool.append(entry)
	if pool.is_empty():
		return _items[0] if not _items.is_empty() else {}
	return pool[rng.randi_range(0, pool.size() - 1)]

static func parse_color(raw) -> Color:
	return _parse_color(raw)

static func item_visual(entry: Dictionary) -> Dictionary:
	var vis: Dictionary = entry.get("visual", {})
	var out := {}
	if vis.has("color"):
		out["color"] = _parse_color(vis["color"])
	if vis.has("polygon"):
		out["polygon"] = _parse_polygon(vis["polygon"])
	if vis.has("scale"):
		out["scale"] = float(vis["scale"])
	return out

static func door(def_id: StringName) -> Dictionary:
	ensure_loaded()
	return _doors.get(def_id, {})

static func npc(def_id: StringName) -> Dictionary:
	ensure_loaded()
	return _npcs.get(def_id, {})

static func vendor(def_id: StringName) -> Dictionary:
	ensure_loaded()
	return _vendors.get(def_id, {})

static func money_interaction(def_id: StringName) -> Dictionary:
	ensure_loaded()
	return _money.get(def_id, {})

static func time_event(def_id: StringName) -> Dictionary:
	ensure_loaded()
	return _time_events.get(def_id, {})

static func placements_for_segment(segment_id: StringName) -> Dictionary:
	ensure_loaded()
	var key := str(segment_id)
	for row in _placements.get("segments", []):
		if row.get("segment", "") == key:
			return row
	return {}

static func all_npc_defs() -> Array[Dictionary]:
	ensure_loaded()
	var out: Array[Dictionary] = []
	for id in _npcs:
		out.append(_npcs[id])
	return out

static func parse_phases(phase_names: Array) -> Array:
	var out: Array = []
	for name in phase_names:
		var p := phase_from_name(str(name))
		if p >= 0:
			out.append(p)
	return out

static func phase_from_name(name: String) -> int:
	match name.to_lower():
		"late_night":
			return GameClock.TimePhase.LATE_NIGHT
		"dawn":
			return GameClock.TimePhase.DAWN
		"morning":
			return GameClock.TimePhase.MORNING
		"afternoon":
			return GameClock.TimePhase.AFTERNOON
		"evening":
			return GameClock.TimePhase.EVENING
		_:
			return -1

static func phase_name(phase: int) -> String:
	match phase:
		GameClock.TimePhase.LATE_NIGHT:
			return "late_night"
		GameClock.TimePhase.DAWN:
			return "dawn"
		GameClock.TimePhase.MORNING:
			return "morning"
		GameClock.TimePhase.AFTERNOON:
			return "afternoon"
		GameClock.TimePhase.EVENING:
			return "evening"
		_:
			return ""

static func phases_display(phase_names: Array) -> String:
	var labels: PackedStringArray = []
	for name in phase_names:
		labels.append(str(name).replace("_", " ").capitalize())
	return ", ".join(labels)

static func _load_file(filename: String, apply: Callable) -> void:
	var path := DATA_DIR + filename
	if not FileAccess.file_exists(path):
		push_error("AlleyContent: missing %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("AlleyContent: invalid JSON in %s" % path)
		return
	apply.call(parsed)

static func _index_by_id(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		if row is Dictionary and row.has("id"):
			out[StringName(row["id"])] = row
	return out

static func _array_to_dict_list(rows: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in rows:
		if row is Dictionary:
			out.append(row)
	return out

static func _parse_color(raw) -> Color:
	if raw is Array and raw.size() >= 3:
		var a := 1.0 if raw.size() < 4 else float(raw[3])
		return Color(float(raw[0]), float(raw[1]), float(raw[2]), a)
	return Color.WHITE

static func _parse_polygon(raw) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if raw is Array:
		for pair in raw:
			if pair is Array and pair.size() >= 2:
				pts.append(Vector2(float(pair[0]), float(pair[1])))
	return pts
