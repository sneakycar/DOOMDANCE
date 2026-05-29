extends RefCounted
class_name CorridorLibrary

const SEGMENT_WIDTH := 160
const SEGMENT_FLOOR_Y := 211.0
const SEGMENT_FLOOR_TOP := 203.0

const TYPE_DUMPSTER := &"dumpster_alley"
const TYPE_FENCE := &"chain_link_fence"
const TYPE_DOCK := &"loading_dock"
const TYPE_GARAGE := &"auto_garage"
const TYPE_BOARDED := &"boarded_storefront"
const TYPE_VACANT := &"vacant_lot"
const TYPE_GRAFFITI := &"graffiti_wall"
const TYPE_BRICK := &"brick_corridor"
const TYPE_SEPTA := &"septa_overpass"

const _DEFINITIONS: Dictionary = {
	TYPE_DUMPSTER: {"weight": 14, "label": "Dumpster Alley"},
	TYPE_FENCE: {"weight": 12, "label": "Chain-Link Fence"},
	TYPE_DOCK: {"weight": 10, "label": "Loading Dock"},
	TYPE_GARAGE: {"weight": 10, "label": "Auto Garage"},
	TYPE_BOARDED: {"weight": 11, "label": "Boarded Storefront"},
	TYPE_VACANT: {"weight": 9, "label": "Vacant Lot"},
	TYPE_GRAFFITI: {"weight": 12, "label": "Graffiti Wall"},
	TYPE_BRICK: {"weight": 18, "label": "Brick Corridor"},
	TYPE_SEPTA: {"weight": 6, "label": "SEPTA Overpass"},
}

static func all_types() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _DEFINITIONS.keys():
		out.append(key)
	return out

static func label_for(segment_type: StringName) -> String:
	return _DEFINITIONS.get(segment_type, {}).get("label", "Unknown")

static func pick_type(ctx: CorridorContext, last_type: StringName, rng: RandomNumberGenerator) -> StringName:
	var pool: Array[StringName] = []
	for segment_type in _DEFINITIONS.keys():
		var def: Dictionary = _DEFINITIONS[segment_type]
		var w: int = int(def.weight * ctx.get_type_weight_multiplier(segment_type))
		if segment_type == last_type:
			w = maxi(1, w / 4)
		for _i in w:
			pool.append(segment_type)
	if pool.is_empty():
		return TYPE_BRICK
	return pool[rng.randi_range(0, pool.size() - 1)]
