class_name RbdInfluence
extends RefCounted

class FieldSample:
	var growth: float = 0.0
	var warmth: float = 0.0
	var density: float = 0.0
	var activity: float = 0.0

var fields: Array[Dictionary] = []

func place(mode: RbdConstants.InfluenceMode, world_pos: Vector2i, clock_sec: float) -> void:
	fields.append({
		"mode": mode,
		"pos": world_pos,
		"placed_at": clock_sec,
		"duration": RbdConstants.INFLUENCE_DURATION_SEC,
	})

func tick_step() -> void:
	pass

func prune(clock_sec: float) -> void:
	var kept: Array[Dictionary] = []
	for f in fields:
		if clock_sec - float(f.placed_at) < float(f.duration):
			kept.append(f)
	fields = kept

func sample_field(cell: Vector2i) -> FieldSample:
	var out := FieldSample.new()
	if fields.is_empty():
		return out
	var r := RbdConstants.INFLUENCE_RADIUS_CELLS
	for f in fields:
		var pos: Vector2i = f.pos
		var dx := float(cell.x - pos.x)
		var dy := float(cell.y - pos.y)
		var dist := sqrt(dx * dx + dy * dy)
		if dist > r:
			continue
		var t := 1.0 - dist / r
		t = t * t
		match int(f.mode):
			RbdConstants.InfluenceMode.ATTRACT:
				out.growth += t * 0.9
			RbdConstants.InfluenceMode.REPEL:
				out.growth -= t * 0.85
			RbdConstants.InfluenceMode.BRIGHTEN:
				out.warmth += t * 2.2
				out.density += t * 0.4
				out.activity += t * 1.5
			RbdConstants.InfluenceMode.DARKEN:
				out.warmth -= t * 2.0
				out.density -= t * 0.35
				out.activity -= t * 1.2
	return out

func to_dict() -> Array:
	var arr: Array = []
	for f in fields:
		arr.append({
			"mode": f.mode,
			"pos": [f.pos.x, f.pos.y],
			"placed_at": f.placed_at,
			"duration": f.duration,
		})
	return arr

func from_dict(data: Array) -> void:
	fields.clear()
	for raw in data:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		fields.append({
			"mode": int(raw.get("mode", 0)),
			"pos": Vector2i(int(raw["pos"][0]), int(raw["pos"][1])),
			"placed_at": float(raw.get("placed_at", 0.0)),
			"duration": float(raw.get("duration", RbdConstants.INFLUENCE_DURATION_SEC),
		})
