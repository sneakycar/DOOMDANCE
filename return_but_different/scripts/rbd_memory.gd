class_name RbdMemory
extends RefCounted
## Named people & families — sparse mythology from simulation state, not a population sim.

const STATUS_ALIVE := "alive"
const STATUS_DEAD := "dead"
const STATUS_MISSING := "missing"
const STATUS_LEFT := "left"
const STATUS_RETURNED := "returned"

var people: Dictionary = {}
var families: Dictionary = {}
var events: Array[Dictionary] = []

var _names := RbdNameGenerator.new()
var _next_named_at: float = 0.0
var _person_serial := 0
var _event_serial := 0
var _last_notification := ""

func get_last_notification() -> String:
	return _last_notification

func _init(world_seed: int = 0) -> void:
	_names.set_seed(world_seed)
	_schedule_next(0.0, true)

func configure_from_world_seed(seed: int) -> void:
	_names.set_seed(seed ^ 0x6D656D)  # "mem"

func _schedule_next(clock_sec: float, initial: bool = false) -> void:
	var min_wait := 300.0 if initial else 420.0
	var max_wait := 1200.0 if initial else 900.0
	_next_named_at = clock_sec + _names.randf_range(min_wait, max_wait)

func recent_fragments(count: int = 4) -> PackedStringArray:
	var lines := PackedStringArray()
	var start := maxi(0, events.size() - count)
	for i in range(start, events.size()):
		lines.append(str(events[i].get("fragment", "")))
	return lines

func on_region_emerged(region: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> void:
	if region == null:
		return
	if _names.randf() > 0.62:
		return
	var person: Dictionary
	var message := ""
	if _names.randf() < 0.42:
		person = _birth_in_region(region, clock)
		if person.is_empty():
			return
		message = "%s WAS BORN IN %s." % [person["full_name_upper"], region.name]
	else:
		person = _witness_in_region(region, clock, "emerged")
		if person.is_empty():
			return
		message = "%s WITNESSED %s." % [person["full_name_upper"], region.name]
	_post_event(clock, "witness", region.id, person["id"], person["surname_key"], message, ["witness", region.id])
	_push_history(history, clock, events.back())

func on_world_headline(
	headline: String,
	region: RbdRegions.Region,
	clock: RbdClock,
	history: RbdHistory,
	tag: String = ""
) -> void:
	if region == null:
		return
	var upper := headline.to_upper()
	if "SECOND LIGHT" in upper:
		var w := _witness_in_region(region, clock, "second_light")
		if not w.is_empty():
			_post_event(
				clock,
				"witness",
				region.id,
				w["id"],
				w["surname_key"],
				"%s SAW THE SECOND LIGHT FIRST." % w["full_name_upper"],
				["witness", "second_light", tag]
			)
			_push_history(history, clock, events.back())
	elif "EXPANDING" in upper or "BRIGHT" in upper:
		if _names.randf() < 0.4:
			var p := _birth_in_region(region, clock)
			if not p.is_empty():
				_post_event(
					clock,
					"birth",
					region.id,
					p["id"],
					p["surname_key"],
					"%s WAS BORN IN %s." % [p["full_name_upper"], region.name],
					["birth", tag]
				)
				_push_history(history, clock, events.back())

func check_contacts(regions: RbdRegions, clock: RbdClock, history: RbdHistory) -> void:
	var keys := regions.regions.keys()
	for i in range(keys.size()):
		var a: RbdRegions.Region = regions.regions[keys[i]]
		for j in range(i + 1, keys.size()):
			var b: RbdRegions.Region = regions.regions[keys[j]]
			if a.centroid.distance_to(b.centroid) >= 95.0:
				continue
			if _names.randf() < 0.18:
				on_region_contact(a, b, clock, history)
			return

func on_region_contact(a: RbdRegions.Region, b: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> void:
	var person := _person_in_region(a.id)
	if person.is_empty():
		person = _person_in_region(b.id)
	if person.is_empty():
		return
	var from_region := a
	if person.get("region_id", "") == b.id:
		from_region = b
	_set_person_status(person["id"], STATUS_LEFT)
	_post_event(
		clock,
		"left",
		from_region.id,
		person["id"],
		person["surname_key"],
		"%s LEFT %s." % [person["full_name_upper"], from_region.name],
		["left", "contact"]
	)
	_push_history(history, clock, events.back())
	if _names.randf() < 0.35:
		_try_family_move(person["surname_key"], from_region, clock, history)

func on_event_resolved(
	ev: RbdEvents.PendingEvent,
	choice_index: int,
	regions: RbdRegions,
	clock: RbdClock,
	history: RbdHistory
) -> void:
	if ev == null:
		return
	if not regions.regions.has(ev.region_a_id):
		return
	var region: RbdRegions.Region = regions.regions[ev.region_a_id]
	match ev.effect:
		"dim_origin":
			if choice_index == 1:
				_maybe_death_in_region(region, clock, history, "fade")
			elif choice_index == 0 and _names.randf() < 0.4:
				_region_remembrance(region, clock, history)
		"second_light":
			if choice_index == 0:
				var w := _witness_in_region(region, clock, "second_light_stay")
				if not w.is_empty():
					_post_event(
						clock,
						"witness",
						region.id,
						w["id"],
						w["surname_key"],
						"%s SAW THE SECOND LIGHT FIRST." % w["full_name_upper"],
						["witness", "second_light", "stay"]
					)
					_push_history(history, clock, events.back())
		"contact":
			if regions.regions.has(ev.region_b_id):
				var other: RbdRegions.Region = regions.regions[ev.region_b_id]
				if choice_index == 0:
					on_region_contact(region, other, clock, history)
		"belt":
			if choice_index == 1 and _names.randf() < 0.4:
				var p := _birth_in_region(region, clock)
				if not p.is_empty():
					_post_event(
						clock,
						"birth",
						region.id,
						p["id"],
						p["surname_key"],
						"%s WAS BORN IN %s." % [p["full_name_upper"], region.name],
						["birth", "belt"]
					)
					_push_history(history, clock, events.back())
		"stasis":
			if choice_index == 0 and _names.randf() < 0.3:
				_try_return(region, clock, history)

func tick(clock: RbdClock, regions: RbdRegions, world: RbdWorld, history: RbdHistory) -> void:
	if clock.elapsed_sec < _next_named_at:
		return
	_schedule_next(clock.elapsed_sec)
	if not _try_scheduled_event(clock, regions, world, history):
		_schedule_next(clock.elapsed_sec + 180.0)

func process_offline(
	sim_elapsed_sec: float,
	regions: RbdRegions,
	world: RbdWorld,
	clock: RbdClock,
	history: RbdHistory
) -> void:
	if sim_elapsed_sec < 60.0:
		return
	var count := clampi(int(sim_elapsed_sec / 600.0) + 1, 1, RbdConstants.MEMORY_OFFLINE_MAX)
	for _i in range(count):
		if not _try_scheduled_event(clock, regions, world, history, true):
			break

func _try_scheduled_event(
	clock: RbdClock,
	regions: RbdRegions,
	_world: RbdWorld,
	history: RbdHistory,
	offline: bool = false
) -> bool:
	if regions.regions.is_empty():
		return false
	var keys := regions.regions.keys()
	var rid: String = str(keys[_names.randi() % keys.size()])
	var region: RbdRegions.Region = regions.regions[rid]
	if region.is_origin and _names.randf() < 0.6:
		return false
	var roll := _names.randf()
	if roll < 0.28:
		return _maybe_death_in_region(region, clock, history, "time")
	if roll < 0.48:
		var p := _birth_in_region(region, clock)
		if p.is_empty():
			return false
		_post_event(
			clock,
			"birth",
			region.id,
			p["id"],
			p["surname_key"],
			"%s WAS BORN IN %s." % [p["full_name_upper"], region.name],
			["birth", "scheduled"]
		)
		_push_history(history, clock, events.back())
		return true
	if roll < 0.62:
		return _try_return(region, clock, history)
	if roll < 0.78:
		return _region_remembrance(region, clock, history)
	if roll < 0.9:
		return _maybe_disappear(region, clock, history)
	if offline:
		return _maybe_death_in_region(region, clock, history, "offline")
	return false

func _region_remembrance(region: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> bool:
	var dead := _dead_in_region(region.id)
	if dead.is_empty():
		dead = _any_person_with_tag("remembered")
	if dead.is_empty():
		return false
	_bump_family_remembered(dead["surname_key"])
	_post_event(
		clock,
		"remembrance",
		region.id,
		dead["id"],
		dead["surname_key"],
		"%s REMEMBERS %s." % [region.name, dead["full_name_upper"]],
		["remembrance"]
	)
	_push_history(history, clock, events.back())
	return true

func _try_return(region: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> bool:
	var left := _people_with_status(STATUS_LEFT)
	if left.is_empty():
		return false
	var person: Dictionary = left[_names.randi() % left.size()]
	_set_person_status(person["id"], STATUS_RETURNED)
	_set_person_field(person["id"], "region_id", region.id)
	_post_event(
		clock,
		"returned",
		region.id,
		person["id"],
		person["surname_key"],
		"%s RETURNED." % person["full_name_upper"],
		["returned"]
	)
	_push_history(history, clock, events.back())
	return true

func _maybe_disappear(region: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> bool:
	var alive := _alive_in_region(region.id)
	if alive.is_empty():
		return false
	var person: Dictionary = alive[_names.randi() % alive.size()]
	_set_person_status(person["id"], STATUS_MISSING)
	_adjust_family_living(person["surname_key"], -1)
	_post_event(
		clock,
		"missing",
		region.id,
		person["id"],
		person["surname_key"],
		"%s DISAPPEARED." % person["full_name_upper"],
		["missing"]
	)
	_push_history(history, clock, events.back())
	return true

func _maybe_death_in_region(region: RbdRegions.Region, clock: RbdClock, history: RbdHistory, tag: String) -> bool:
	var alive := _alive_in_region(region.id)
	if alive.is_empty():
		alive = _all_alive()
	if alive.is_empty():
		return false
	var person: Dictionary = alive[_names.randi() % alive.size()]
	_set_person_status(person["id"], STATUS_DEAD)
	_set_person_field(person["id"], "died_day", clock.day_index())
	_adjust_family_living(person["surname_key"], -1)
	_bump_family_remembered(person["surname_key"])
	_post_event(
		clock,
		"death",
		region.id,
		person["id"],
		person["surname_key"],
		"%s HAS DIED." % person["full_name_upper"],
		["death", tag]
	)
	_push_history(history, clock, events.back())
	return true

func _try_family_move(surname_key: String, from_region: RbdRegions.Region, clock: RbdClock, history: RbdHistory) -> void:
	if not families.has(surname_key):
		return
	var living := int(families[surname_key].get("living_count", 0))
	if living < 2:
		return
	_post_event(
		clock,
		"family_move",
		from_region.id,
		"",
		surname_key,
		"THE %sS LEFT %s." % [surname_key, from_region.name],
		["family", "left"]
	)
	_push_history(history, clock, events.back())

func _birth_in_region(region: RbdRegions.Region, clock: RbdClock) -> Dictionary:
	var gen := _names.generate_person(families, region.cell_count > 1200)
	var id := _new_person_id()
	var surname_key: String = gen["surname_key"]
	_ensure_family(surname_key, region.id, clock.day_index())
	_adjust_family_living(surname_key, 1)
	var person := {
		"id": id,
		"first_name": gen["first_name"],
		"last_name": gen["last_name"],
		"full_name": gen["full_name"],
		"full_name_upper": gen["full_name_upper"],
		"surname_key": surname_key,
		"region_id": region.id,
		"born_day": clock.day_index(),
		"died_day": -1,
		"status": STATUS_ALIVE,
		"significance": 1.0,
		"tags": [],
		"parent_family": surname_key,
	}
	people[id] = person
	return person

func _witness_in_region(region: RbdRegions.Region, clock: RbdClock, tag: String) -> Dictionary:
	var existing := _alive_in_region(region.id)
	if not existing.is_empty():
		var p: Dictionary = existing[0]
		var tags: Array = p.get("tags", [])
		if tag not in tags:
			tags.append(tag)
		p["tags"] = tags
		p["significance"] = float(p.get("significance", 1.0)) + 0.5
		people[p["id"]] = p
		return p
	return _birth_in_region(region, clock)

func _post_event(
	clock: RbdClock,
	etype: String,
	region_id: String,
	person_id: String,
	family_key: String,
	message: String,
	consequence_tags: Array
) -> void:
	_event_serial += 1
	var upper := message.to_upper()
	var day_label := clock.day_label_for_stamp(clock.elapsed_sec)
	var fragment := "%s — %s" % [day_label, upper]
	var ev := {
		"id": "mem_%d" % _event_serial,
		"day": clock.day_index(),
		"stamp": clock.elapsed_sec,
		"type": etype,
		"region_id": region_id,
		"person_id": person_id,
		"family": family_key,
		"message": upper,
		"fragment": fragment,
		"consequence_tags": consequence_tags.duplicate(),
	}
	events.append(ev)
	_last_notification = upper

func _push_history(history: RbdHistory, clock: RbdClock, ev: Dictionary) -> void:
	history.log(clock, str(ev.get("message", "")), true)

func _new_person_id() -> String:
	_person_serial += 1
	return "person_%d" % _person_serial

func _ensure_family(surname_key: String, region_id: String, day: int) -> void:
	if families.has(surname_key):
		return
	families[surname_key] = {
		"surname": surname_key,
		"origin_region_id": region_id,
		"first_seen_day": day,
		"living_count": 0,
		"remembered_count": 0,
		"significance": 1.0,
	}

func _adjust_family_living(surname_key: String, delta: int) -> void:
	if not families.has(surname_key):
		return
	families[surname_key].living_count = maxi(0, int(families[surname_key].living_count) + delta)

func _bump_family_remembered(surname_key: String) -> void:
	if not families.has(surname_key):
		return
	families[surname_key].remembered_count = int(families[surname_key].remembered_count) + 1
	families[surname_key].significance = float(families[surname_key].significance) + 0.25

func _set_person_status(pid: String, status: String) -> void:
	if not people.has(pid):
		return
	people[pid].status = status

func _set_person_field(pid: String, key: String, value: Variant) -> void:
	if not people.has(pid):
		return
	people[pid][key] = value

func _person_in_region(region_id: String) -> Dictionary:
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("region_id", "") == region_id and p.get("status", "") == STATUS_ALIVE:
			return p
	return {}

func _alive_in_region(region_id: String) -> Array:
	var out: Array = []
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("region_id", "") == region_id and p.get("status", "") == STATUS_ALIVE:
			out.append(p)
	return out

func _dead_in_region(region_id: String) -> Dictionary:
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("region_id", "") == region_id and p.get("status", "") == STATUS_DEAD:
			return p
	return {}

func _all_alive() -> Array:
	var out: Array = []
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("status", "") == STATUS_ALIVE:
			out.append(p)
	return out

func _people_with_status(status: String) -> Array:
	var out: Array = []
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("status", "") == status:
			out.append(p)
	return out

func _any_person_with_tag(_tag: String) -> Dictionary:
	for pid in people:
		var p: Dictionary = people[pid]
		if p.get("status", "") == STATUS_DEAD:
			return p
	return {}

func to_dict() -> Dictionary:
	return {
		"people": people.duplicate(true),
		"families": families.duplicate(true),
		"events": events.duplicate(true),
		"names": _names.to_dict(),
		"next_named_at": _next_named_at,
		"person_serial": _person_serial,
		"event_serial": _event_serial,
	}

func from_dict(data: Dictionary) -> void:
	people = Dictionary(data.get("people", {}))
	families = Dictionary(data.get("families", {}))
	events.clear()
	for raw in data.get("events", []):
		if typeof(raw) == TYPE_DICTIONARY:
			events.append(raw)
	_names.from_dict(data.get("names", {}))
	_next_named_at = float(data.get("next_named_at", 0.0))
	_person_serial = int(data.get("person_serial", 0))
	_event_serial = int(data.get("event_serial", 0))
