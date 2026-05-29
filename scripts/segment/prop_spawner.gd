extends RefCounted
class_name PropSpawner

const PROP_SCENE := preload("res://scenes/world/alley_prop.tscn")
const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")
const NPC_SCENE := preload("res://scenes/world/alley_npc.tscn")

static func populate_segment(
	seg: AlleySegment,
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase: int
) -> void:
	if SegmentLibrary.BACKDROP_MODE == SegmentLibrary.BackdropMode.PAINTED:
		# Paintings already carry dumpsters, lamps, etc. — keep gameplay light.
		if rng.randf() > 0.35:
			return
	AlleyData.load_all()
	var phase_name := AlleyData.phase_key(phase)
	var root := seg.get_props_root()
	var slots := _pick_slot_count(rng, state)
	if SegmentLibrary.BACKDROP_MODE == SegmentLibrary.BackdropMode.PAINTED:
		slots = mini(slots, 1)
	var used_x: Array[float] = []
	for _i in slots:
		if rng.randf() > state.prop_spawn_chance():
			continue
		var roll := rng.randf()
		if roll < 0.22 and _try_spawn_npc(root, rng, state, phase_name, used_x):
			continue
		if roll < 0.55:
			_try_spawn_pickup(root, rng, state, phase_name, used_x)
		else:
			_try_spawn_static(root, rng, state, phase_name, used_x)

static func _pick_slot_count(rng: RandomNumberGenerator, state: AlleyState) -> int:
	return rng.randi_range(1, 2 + int(round(state.luck * 2.0)))

static func _try_spawn_static(
	root: Node2D,
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase_name: String,
	used_x: Array[float]
) -> bool:
	var def := _pick_weighted(AlleyData.all_props(), rng, state, phase_name, "static")
	if def.is_empty():
		return false
	return _spawn_def(root, def, rng, used_x, PROP_SCENE)

static func _try_spawn_pickup(
	root: Node2D,
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase_name: String,
	used_x: Array[float]
) -> bool:
	var def := _pick_weighted(AlleyData.all_props(), rng, state, phase_name, "pickup")
	if def.is_empty():
		return false
	return _spawn_def(root, def, rng, used_x, PICKUP_SCENE)

static func _try_spawn_npc(
	root: Node2D,
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase_name: String,
	used_x: Array[float]
) -> bool:
	var def := _pick_weighted_npcs(rng, state, phase_name)
	if def.is_empty():
		return false
	return _spawn_def(root, def, rng, used_x, NPC_SCENE)

static func _pick_weighted(
	pool: Array[Dictionary],
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase_name: String,
	kind: String
) -> Dictionary:
	var bag: Array[Dictionary] = []
	for def in pool:
		if def.get("kind", "") != kind:
			continue
		if not _phase_ok(def, phase_name):
			continue
		if state.luck < float(def.get("min_luck", 0.0)):
			continue
		var w: int = maxi(1, int(def.get("spawn_weight", 1)))
		for _j in w:
			bag.append(def)
	if bag.is_empty():
		return {}
	return bag[rng.randi_range(0, bag.size() - 1)]

static func _pick_weighted_npcs(
	rng: RandomNumberGenerator,
	state: AlleyState,
	phase_name: String
) -> Dictionary:
	var bag: Array[Dictionary] = []
	for def in AlleyData.all_npcs():
		if not _phase_ok(def, phase_name):
			continue
		if state.luck < float(def.get("min_luck", 0.0)):
			continue
		var w: int = maxi(1, int(def.get("spawn_weight", 1)))
		for _j in w:
			bag.append(def)
	if bag.is_empty():
		return {}
	return bag[rng.randi_range(0, bag.size() - 1)]

static func _phase_ok(def: Dictionary, phase_name: String) -> bool:
	var phases: Array = def.get("phases", [])
	if phases.is_empty():
		return true
	return phase_name in phases

static func _spawn_def(
	root: Node2D,
	def: Dictionary,
	rng: RandomNumberGenerator,
	used_x: Array[float],
	scene: PackedScene
) -> bool:
	var margin := 48.0
	var half := SegmentLibrary.SEGMENT_W * 0.5 - margin
	for _attempt in 8:
		var local_x := rng.randf_range(-half, half)
		if not _x_clear(local_x, used_x):
			continue
		var node: Node2D = scene.instantiate()
		root.add_child(node)
		node.position = Vector2(local_x, SegmentLibrary.FLOOR_Y + float(def.get("y_offset", -20)))
		if node.has_method("configure"):
			node.configure(def)
		used_x.append(local_x)
		return true
	return false

static func _x_clear(x: float, used_x: Array[float]) -> bool:
	for other in used_x:
		if absf(x - other) < 36.0:
			return false
	return true
