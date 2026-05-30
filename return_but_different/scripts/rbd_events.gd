class_name RbdEvents
extends RefCounted

class PendingEvent:
	var id: String = ""
	var headline: String = ""
	var choice_a: String = ""
	var choice_b: String = ""
	var region_a_id: String = ""
	var region_b_id: String = ""
	var effect: String = ""

var current: PendingEvent = null
var _cooldown_until: float = 0.0
var _second_light_logged := false
var _decisions: Dictionary = {}

func has_event() -> bool:
	return current != null

func tick_cooldown(clock_sec: float) -> void:
	pass

func try_generate(
	world: RbdWorld,
	regions: RbdRegions,
	clock: RbdClock,
	history: RbdHistory
) -> bool:
	if current != null:
		return false
	if clock.elapsed_sec < _cooldown_until:
		return false
	var origin := regions.regions.get("region_origin")
	if origin == null:
		return false
	# Dimming first white
	if origin.avg_activity < origin.last_activity_peak * 0.72 and origin.avg_activity > 20.0:
		_emit(
			"dim_first_white",
			"THE FIRST WHITE IS DIMMING.",
			"PROTECT IT",
			"LET IT FADE",
			"region_origin",
			"",
			"dim_origin"
		)
		return true
	# Second light
	var bright := _find_bright_non_origin(regions, world)
	if bright != null and bright.id != "region_origin":
		if not _second_light_logged:
			history.log(clock, "THE SECOND LIGHT APPEARED")
			_second_light_logged = true
		_emit(
			"second_light",
			"A SECOND LIGHT HAS APPEARED.",
			"LET IT GROW",
			"CUT IT OFF",
			bright.id,
			"region_origin",
			"second_light"
		)
		return true
	# Contact between named regions
	var contact := _find_contact_pair(regions)
	if contact.size() == 2:
		var a: RbdRegions.Region = contact[0]
		var b: RbdRegions.Region = contact[1]
		_emit(
			"contact_%s_%s" % [a.id, b.id],
			"%s HAS REACHED %s." % [a.name, b.name],
			"ALLOW CONTACT",
			"KEEP THEM APART",
			a.id,
			b.id,
			"contact"
		)
		return true
	# Static belt expanding
	var belt := _find_static_belt(regions)
	if belt != null and belt.velocity.length() > 2.0:
		_emit(
			"belt_expand_%s" % belt.id,
			"%s IS EXPANDING." % belt.name,
			"SLOW IT",
			"ENCOURAGE IT",
			belt.id,
			"",
			"belt"
		)
		return true
	# Old center stopped
	var old_c := _find_old_center(regions)
	if old_c != null and old_c.velocity.length() < 0.5 and old_c.avg_activity < 50.0:
		_emit(
			"wake_%s" % old_c.id,
			"%s HAS STOPPED MOVING." % old_c.name,
			"WAKE IT",
			"LEAVE IT",
			old_c.id,
			"",
			"stasis"
		)
		return true
	return false

func _emit(eid: String, headline: String, a: String, b: String, ra: String, rb: String, effect: String) -> void:
	var ev := PendingEvent.new()
	ev.id = eid
	ev.headline = headline
	ev.choice_a = a
	ev.choice_b = b
	ev.region_a_id = ra
	ev.region_b_id = rb
	ev.effect = effect
	current = ev

func resolve(choice_index: int, world: RbdWorld, regions: RbdRegions, clock: RbdClock, history: RbdHistory, influence: RbdInfluence) -> void:
	if current == null:
		return
	var picked := current.choice_a if choice_index == 0 else current.choice_b
	var effect := current.effect
	var region_id := current.region_a_id
	_decisions[current.id] = picked
	history.log(clock, "YOU %s." % picked)
	match effect:
		"dim_origin":
			_apply_origin_dim(world, choice_index == 0)
		"second_light":
			_apply_second_light(world, regions, choice_index == 0, region_id)
			if choice_index == 0:
				history.log(clock, "YOU LET THE SECOND LIGHT STAY.")
				regions.record_decision(region_id, "second_light_stay")
			else:
				history.log(clock, "YOU CUT OFF THE SECOND LIGHT.")
		"contact":
			_apply_contact(world, regions, current.region_a_id, current.region_b_id, choice_index == 0)
		"belt":
			_apply_belt(world, regions, region_id, choice_index == 1)
		"stasis":
			_apply_stasis(world, regions, region_id, choice_index == 0)
	_cooldown_until = clock.elapsed_sec + RbdConstants.EVENT_COOLDOWN_SEC
	current = null

func check_history_milestones(regions: RbdRegions, clock: RbdClock, history: RbdHistory) -> void:
	var origin: RbdRegions.Region = regions.regions.get("region_origin")
	if origin == null:
		return
	var brightest_id := ""
	var brightest_val := -1.0
	for rid in regions.regions:
		var r: RbdRegions.Region = regions.regions[rid]
		if r.is_origin:
			continue
		var v := r.avg_density + r.cell_count * 0.02
		if v > brightest_val and "second_light_stay" in r.decision_tags:
			brightest_val = v
			brightest_id = rid
	if brightest_id.is_empty():
		return
	var second: RbdRegions.Region = regions.regions[brightest_id]
	if second.avg_density + second.cell_count * 0.02 > origin.avg_density + origin.cell_count * 0.02:
		if not _decisions.has("milestone_surpassed"):
			_decisions["milestone_surpassed"] = true
			history.log(clock, "%s IS NOW LARGER THAN THE FIRST WHITE." % second.name)

func _apply_origin_dim(world: RbdWorld, protect: bool) -> void:
	var oi := world.origin.y * RbdConstants.WORLD_SIZE + world.origin.x
	if protect:
		world.activity[oi] = 255
		world.warmth[oi] = 255
	else:
		world.activity[oi] = maxi(40, int(world.activity[oi]) - 40)

func _apply_second_light(world: RbdWorld, regions: RbdRegions, grow: bool, rid: String) -> void:
	if not regions.regions.has(rid):
		return
	var reg: RbdRegions.Region = regions.regions[rid]
	var p := Vector2i(int(reg.centroid.x), int(reg.centroid.y))
	var r := 18 if grow else 8
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var px := clampi(p.x + x, 0, RbdConstants.WORLD_SIZE - 1)
			var py := clampi(p.y + y, 0, RbdConstants.WORLD_SIZE - 1)
			var i := py * RbdConstants.WORLD_SIZE + px
			if grow:
				world.density[i] = mini(255, int(world.density[i]) + 18)
				world.warmth[i] = mini(255, int(world.warmth[i]) + 12)
			else:
				world.density[i] = maxi(0, int(world.density[i]) - 35)
				world.activity[i] = maxi(0, int(world.activity[i]) - 30)

func _apply_contact(world: RbdWorld, regions: RbdRegions, aid: String, bid: String, allow: bool) -> void:
	if not regions.regions.has(aid) or not regions.regions.has(bid):
		return
	var a: RbdRegions.Region = regions.regions[aid]
	var b: RbdRegions.Region = regions.regions[bid]
	var mid := Vector2i(int((a.centroid.x + b.centroid.x) * 0.5), int((a.centroid.y + b.centroid.y) * 0.5))
	var boost := 22 if allow else -28
	for y in range(-12, 13):
		for x in range(-12, 13):
			var px := clampi(mid.x + x, 0, RbdConstants.WORLD_SIZE - 1)
			var py := clampi(mid.y + y, 0, RbdConstants.WORLD_SIZE - 1)
			var i := py * RbdConstants.WORLD_SIZE + px
			world.density[i] = clampi(int(world.density[i]) + boost, 0, 255)

func _apply_belt(world: RbdWorld, regions: RbdRegions, rid: String, encourage: bool) -> void:
	if not regions.regions.has(rid):
		return
	var reg: RbdRegions.Region = regions.regions[rid]
	var p := Vector2i(int(reg.centroid.x), int(reg.centroid.y))
	var delta := 10 if encourage else -14
	for y in range(-20, 21):
		for x in range(-20, 21):
			var px := clampi(p.x + x, 0, RbdConstants.WORLD_SIZE - 1)
			var py := clampi(p.y + y, 0, RbdConstants.WORLD_SIZE - 1)
			var i := py * RbdConstants.WORLD_SIZE + px
			world.activity[i] = clampi(int(world.activity[i]) + delta, 0, 255)

func _apply_stasis(world: RbdWorld, regions: RbdRegions, rid: String, wake: bool) -> void:
	if not regions.regions.has(rid):
		return
	var reg: RbdRegions.Region = regions.regions[rid]
	var p := Vector2i(int(reg.centroid.x), int(reg.centroid.y))
	var delta := 35 if wake else -8
	for y in range(-14, 15):
		for x in range(-14, 15):
			var px := clampi(p.x + x, 0, RbdConstants.WORLD_SIZE - 1)
			var py := clampi(p.y + y, 0, RbdConstants.WORLD_SIZE - 1)
			var i := py * RbdConstants.WORLD_SIZE + px
			world.activity[i] = clampi(int(world.activity[i]) + delta, 0, 255)

func _find_bright_non_origin(regions: RbdRegions, world: RbdWorld) -> RbdRegions.Region:
	var best: RbdRegions.Region = null
	var best_score := 200.0
	for rid in regions.regions:
		var r: RbdRegions.Region = regions.regions[rid]
		if r.is_origin:
			continue
		if r.avg_density < 140.0:
			continue
		if r.centroid.distance_to(Vector2(RbdConstants.ORIGIN)) < 80.0:
			continue
		var score := r.avg_density + r.avg_warmth
		if score > best_score:
			best_score = score
			best = r
	return best

func _find_contact_pair(regions: RbdRegions) -> Array:
	var keys := regions.regions.keys()
	for i in range(keys.size()):
		var a: RbdRegions.Region = regions.regions[keys[i]]
		for j in range(i + 1, keys.size()):
			var b: RbdRegions.Region = regions.regions[keys[j]]
			if a.centroid.distance_to(b.centroid) < 95.0:
				if a.name.contains("BLUE") or b.name.contains("EDGE") or a.name.contains("EDGE"):
					return [a, b]
	return []

func _find_static_belt(regions: RbdRegions) -> RbdRegions.Region:
	for rid in regions.regions:
		var r: RbdRegions.Region = regions.regions[rid]
		if r.name.contains("STATIC") or r.name.contains("BELT"):
			if r.avg_activity < 70.0:
				return r
	return null

func _find_old_center(regions: RbdRegions) -> RbdRegions.Region:
	for rid in regions.regions:
		var r: RbdRegions.Region = regions.regions[rid]
		if r.name.contains("OLD") or r.name.contains("CENTER"):
			if r.cell_count > 800:
				return r
	return null

func to_dict() -> Dictionary:
	var pending: Variant = null
	if current != null:
		pending = {
			"id": current.id,
			"headline": current.headline,
			"choice_a": current.choice_a,
			"choice_b": current.choice_b,
			"region_a_id": current.region_a_id,
			"region_b_id": current.region_b_id,
			"effect": current.effect,
		}
	return {
		"cooldown_until": _cooldown_until,
		"second_light_logged": _second_light_logged,
		"decisions": _decisions.duplicate(),
		"pending": pending,
	}

func from_dict(data: Dictionary) -> void:
	_cooldown_until = float(data.get("cooldown_until", 0.0))
	_second_light_logged = bool(data.get("second_light_logged", false))
	_decisions = Dictionary(data.get("decisions", {}))
	current = null
	var raw: Variant = data.get("pending", null)
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var ev := PendingEvent.new()
	ev.id = str(raw.get("id", ""))
	ev.headline = str(raw.get("headline", ""))
	ev.choice_a = str(raw.get("choice_a", ""))
	ev.choice_b = str(raw.get("choice_b", ""))
	ev.region_a_id = str(raw.get("region_a_id", ""))
	ev.region_b_id = str(raw.get("region_b_id", ""))
	ev.effect = str(raw.get("effect", ""))
	if not ev.id.is_empty():
		current = ev
