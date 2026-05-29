extends Node
## Deadbicycle maze — navigation, visits, dig, random rooms.

signal room_changed(page_id: String)
signal overlay_message(text: String)
signal residue_changed
signal returned_to_beginning

const DATA_PATH := "res://data/maze_pages.json"
const SAVE_PATH := "user://maze_state.cfg"

var pages: Dictionary = {}
var start_room := "dead"
var current_id := "dead"
var history: Array[String] = []
var visited_counts: Dictionary = {}
var route_log: Array[String] = []
var residue: Array[String] = []
var haunt_level := 0
var dig_count := 0

func _ready() -> void:
	_load_pages()
	_load_state()

func _load_pages() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing maze data: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid maze_pages.json")
		return
	pages = parsed.get("pages", {})
	start_room = str(parsed.get("start_room", "dead"))

func page(page_id: String) -> Dictionary:
	return pages.get(page_id, pages.get("lost", {}))

func has_page(page_id: String) -> bool:
	return pages.has(page_id)

func all_room_ids() -> Array[String]:
	var out: Array[String] = []
	for k in pages.keys():
		if str(k) != "void":
			out.append(str(k))
	out.sort()
	return out

func random_room_id(excluding: String) -> String:
	var pool: Array[String] = []
	for rid in all_room_ids():
		if rid == excluding:
			continue
		var p: Dictionary = pages[rid]
		if bool(p.get("hidden", false)):
			if residue.size() <= 4 and visited_total() <= 10 and randi() % 21 != 0:
				continue
		pool.append(rid)
	if pool.is_empty():
		return "lost"
	return pool[randi() % pool.size()]

func visited_total() -> int:
	return visited_counts.size()

func resolve_destination(dest: String, from_id: String) -> String:
	if dest.is_empty():
		return from_id
	if dest == "randomroom":
		return random_room_id(from_id)
	if dest == "unstable":
		var opts := ["feed", "hidden", "puzzle", "machine", "reports", "failure", "void", "dots", "digsite", "bicycles"]
		return opts[randi() % opts.size()]
	if pages.has(dest):
		return dest
	return random_room_id(from_id)

func go(dest: String, record_visit: bool = true) -> void:
	var resolved := resolve_destination(dest, current_id)
	if resolved == current_id:
		return
	if current_id != "":
		history.append(current_id)
		if history.size() > 48:
			history.pop_front()
	visited_counts[current_id] = int(visited_counts.get(current_id, 0)) + 1
	route_log.append(resolved)
	if route_log.size() > 32:
		route_log.pop_front()
	current_id = resolved
	if record_visit:
		_mark_visit(resolved, true)
	_save_state()
	room_changed.emit(resolved)

func go_back() -> void:
	if history.is_empty():
		return
	var prev: String = history.pop_back()
	current_id = prev
	_apply_page_life(prev)
	_save_state()
	room_changed.emit(prev)

func go_lost() -> void:
	go("lost")

func go_random() -> void:
	go("randomroom")

func dig() -> void:
	dig_count += 1
	award_residue("DIG %d" % dig_count)
	var artifact_ids := all_room_ids()
	artifact_ids.shuffle()
	for rid in artifact_ids:
		if rid != current_id and not bool(pages[rid].get("hidden", false)):
			overlay_message.emit("DIG: recovered /%s" % rid)
			go(rid)
			return
	go("dig")

func reset_maze() -> void:
	history.clear()
	route_log.clear()
	visited_counts.clear()
	residue.clear()
	haunt_level = 0
	dig_count = 0
	current_id = start_room
	_mark_visit(start_room, true)
	_save_state()
	room_changed.emit(start_room)

func reset_to_beginning() -> void:
	history.clear()
	route_log.clear()
	visited_counts.clear()
	residue.clear()
	haunt_level = 0
	dig_count = 0
	current_id = start_room
	visited_counts[start_room] = 1
	_save_state()
	room_changed.emit(start_room)
	returned_to_beginning.emit()
	overlay_message.emit("YOU DIED // BEGINNING AGAIN")

func _mark_visit(page_id: String, roll_life: bool) -> void:
	var first: bool = not visited_counts.has(page_id)
	var count: int = int(visited_counts.get(page_id, 0)) + 1
	visited_counts[page_id] = count
	if first:
		GameState.mark_screen_visited(page_id)
		GameState.award_xp(8.0)
	var p: Dictionary = pages.get(page_id, {})
	var rk: String = str(p.get("residue_key", ""))
	if rk != "" and not rk in residue:
		residue.append(rk)
		residue_changed.emit()
	haunt_level = mini(99, haunt_level + 1)
	if count > 1:
		GameState.advance_time(3)
	GameState.persist()
	if roll_life:
		_apply_page_life(page_id)

func _apply_page_life(page_id: String) -> void:
	GameState.apply_page_life(page_id, page(page_id))

func award_residue(key: String) -> void:
	if key != "" and not key in residue:
		residue.append(key)
		residue_changed.emit()

func mutation_line(page_id: String) -> String:
	var count: int = int(visited_counts.get(page_id, 0))
	if count <= 1:
		return ""
	var lines := [
		"revisit #%d. local copy differs from previous copy." % count,
		"this room has been opened %d times and denies it." % count,
		"cached version damaged. links may not match labels.",
		"timestamp changed while you were looking away.",
	]
	return lines[randi() % lines.size()]

func encounter_line(page_id: String) -> String:
	if randi() % 5 != 0:
		return ""
	var lines := [
		"someone changed the label after you tapped it.",
		"a directory opened behind the image.",
		"the page blinked and pretended not to.",
		"gerald residue crossed into /%s." % page_id,
		"deadbicycle server answered from localhost.",
	]
	return lines[randi() % lines.size()]

func status_line(page_id: String) -> String:
	var count: int = int(visited_counts.get(page_id, 0))
	var recent := " / ".join(route_log.slice(max(0, route_log.size() - 5)))
	if count == 0:
		return "local copy // unopened room"
	if count > 5:
		return "overopened. copy is soft. last route: " + recent
	if bool(pages.get(page_id, {}).get("hidden", false)):
		return "hidden file accepted. do not trust stable links."
	return "visit %d. local route: %s" % [count, recent]

func location_screen_for(page_id: String) -> String:
	return str(page(page_id).get("location_screen", ""))

func filtered_fragments(page_id: String) -> Array:
	var p: Dictionary = page(page_id)
	var raw: Array = p.get("fragments", [])
	var out: Array = []
	for f in raw:
		var rarity: int = int(f.get("rarity", 0))
		if rarity > 0 and randi() % (rarity + 2) != 0:
			continue
		out.append(f)
	return out

func filtered_links(page_id: String) -> Array:
	var p: Dictionary = page(page_id)
	var raw: Array = p.get("links", [])
	var out: Array = []
	for l in raw:
		if bool(l.get("unstable", false)) and randi() % 3 == 0:
			continue
		out.append(l)
	if out.is_empty() and not raw.is_empty():
		out.append(raw[0])
	return out

func residue_text() -> String:
	if residue.is_empty():
		return "no residue yet."
	return "\n".join(residue)

func _save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("maze", "current_id", current_id)
	cfg.set_value("maze", "history", history.duplicate())
	cfg.set_value("maze", "visited_counts", visited_counts.duplicate())
	cfg.set_value("maze", "route_log", route_log.duplicate())
	cfg.set_value("maze", "residue", residue.duplicate())
	cfg.set_value("maze", "haunt_level", haunt_level)
	cfg.set_value("maze", "dig_count", dig_count)
	cfg.save(SAVE_PATH)

func _load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		current_id = start_room
		return
	current_id = str(cfg.get_value("maze", "current_id", start_room))
	history.clear()
	for h in cfg.get_value("maze", "history", []):
		history.append(str(h))
	visited_counts = cfg.get_value("maze", "visited_counts", {})
	route_log.clear()
	for r in cfg.get_value("maze", "route_log", []):
		route_log.append(str(r))
	residue.clear()
	for r in cfg.get_value("maze", "residue", []):
		residue.append(str(r))
	haunt_level = int(cfg.get_value("maze", "haunt_level", 0))
	dig_count = int(cfg.get_value("maze", "dig_count", 0))
	if not pages.has(current_id):
		current_id = start_room
