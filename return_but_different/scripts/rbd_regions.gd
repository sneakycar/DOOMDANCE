class_name RbdRegions
extends RefCounted

class Region:
	var id: String = ""
	var name: String = ""
	var centroid: Vector2 = Vector2.ZERO
	var cell_count: int = 0
	var avg_density: float = 0.0
	var avg_warmth: float = 0.0
	var avg_activity: float = 0.0
	var birth_day: int = 1
	var last_activity_peak: float = 0.0
	var velocity: Vector2 = Vector2.ZERO
	var history_snippets: Array[String] = []
	var is_origin: bool = false
	var decision_tags: Array[String] = []

var regions: Dictionary = {}
var _origin_id := "region_origin"

func bootstrap_origin(clock: RbdClock) -> void:
	if regions.has(_origin_id):
		return
	var r := Region.new()
	r.id = _origin_id
	r.name = "THE FIRST WHITE"
	r.centroid = Vector2(RbdConstants.ORIGIN)
	r.is_origin = true
	r.birth_day = clock.day_index()
	r.last_activity_peak = 220.0
	regions[_origin_id] = r

func scan(world: RbdWorld, clock: RbdClock) -> Array[String]:
	var discovered: Array[String] = []
	var w := RbdConstants.WORLD_SIZE
	var visited := PackedByteArray()
	visited.resize(RbdConstants.CELL_COUNT)
	visited.fill(0)
	for y in range(0, w, 4):
		for x in range(0, w, 4):
			var i := y * w + x
			if visited[i]:
				continue
			if int(world.density[i]) < 48:
				continue
			var cluster := _flood(world, visited, Vector2i(x, y))
			if cluster.count < RbdConstants.REGION_MIN_CELLS:
				continue
			var rid := _match_existing(cluster)
			if rid.is_empty():
				rid = "region_%d_%d" % [cluster.centroid.x, cluster.centroid.y]
				var reg := Region.new()
				reg.id = rid
				reg.name = _generate_name(cluster, world)
				reg.centroid = cluster.centroid
				reg.cell_count = cluster.count
				reg.avg_density = cluster.avg_density
				reg.avg_warmth = cluster.avg_warmth
				reg.avg_activity = cluster.avg_activity
				reg.birth_day = clock.day_index()
				reg.last_activity_peak = cluster.avg_activity
				reg.is_origin = cluster.centroid.distance_to(Vector2(RbdConstants.ORIGIN)) < 12.0
				if reg.is_origin:
					reg.name = "THE FIRST WHITE"
					rid = _origin_id
				regions[rid] = reg
				discovered.append(reg.name)
			else:
				_update_region(rid, cluster)
	return discovered

func _update_region(rid: String, cluster: Dictionary) -> void:
	var reg: Region = regions[rid]
	var old_c := reg.centroid
	reg.centroid = cluster.centroid
	reg.velocity = cluster.centroid - old_c
	reg.cell_count = cluster.count
	reg.avg_density = cluster.avg_density
	reg.avg_warmth = cluster.avg_warmth
	reg.avg_activity = cluster.avg_activity
	reg.last_activity_peak = maxf(reg.last_activity_peak, cluster.avg_activity)

func _match_existing(cluster: Dictionary) -> String:
	var best := ""
	var best_d := 99999.0
	for rid in regions:
		var reg: Region = regions[rid]
		var d := reg.centroid.distance_to(cluster.centroid)
		if d < best_d and d < 80.0:
			best_d = d
			best = rid
	return best

func get_by_name(name: String) -> Region:
	for rid in regions:
		var reg: Region = regions[rid]
		if reg.name == name:
			return reg
	return null

func region_at_point(p: Vector2i) -> Region:
	var best: Region = null
	var best_d := 99999.0
	for rid in regions:
		var reg: Region = regions[rid]
		var d := reg.centroid.distance_to(Vector2(p))
		if d < best_d:
			best_d = d
			best = reg
	if best and best_d < 120.0:
		return best
	return null

class _Cluster:
	var count: int
	var centroid: Vector2
	var avg_density: float
	var avg_warmth: float
	var avg_activity: float

func _flood(world: RbdWorld, visited: PackedByteArray, start: Vector2i) -> Dictionary:
	var w := RbdConstants.WORLD_SIZE
	var stack: Array[Vector2i] = [start]
	var count := 0
	var sx := 0.0
	var sy := 0.0
	var sd := 0.0
	var sw := 0.0
	var sa := 0.0
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var i := p.y * w + p.x
		if visited[i]:
			continue
		if int(world.density[i]) < 48:
			continue
		visited[i] = 1
		count += 1
		sx += float(p.x)
		sy += float(p.y)
		sd += float(world.density[i])
		sw += float(world.warmth[i])
		sa += float(world.activity[i])
		if count > 8000:
			break
		for oy in range(-2, 3):
			for ox in range(-2, 3):
				if ox == 0 and oy == 0:
					continue
				var nx := clampi(p.x + ox, 0, w - 1)
				var ny := clampi(p.y + oy, 0, w - 1)
				var ni := ny * w + nx
				if not visited[ni] and int(world.density[ni]) >= 48:
					stack.append(Vector2i(nx, ny))
	var inv := 1.0 / maxf(1.0, float(count))
	return {
		"count": count,
		"centroid": Vector2(sx * inv, sy * inv),
		"avg_density": sd * inv,
		"avg_warmth": sw * inv,
		"avg_activity": sa * inv,
	}

func _generate_name(cluster: Dictionary, world: RbdWorld) -> String:
	var c: Vector2 = cluster.centroid
	var warm := cluster.avg_warmth
	var act := cluster.avg_activity
	var d := cluster.avg_density
	var parts: Array[String] = []
	if c.distance_to(Vector2(RbdConstants.ORIGIN)) < 30.0:
		parts.append("FIRST")
	elif d > 180.0:
		parts.append("OLD")
	if warm < 90.0:
		parts.append("LOW BLUE")
	elif warm > 200.0 and d > 150.0:
		parts.append("LIGHT")
	elif act < 40.0:
		parts.append("STATIC")
	elif warm > 160.0:
		parts.append("AMBER")
	else:
		parts.append("BLUE")
	if c.y > RbdConstants.WORLD_SIZE * 0.62:
		parts.append("SOUTHERN EDGE")
	elif c.y < RbdConstants.WORLD_SIZE * 0.25:
		parts.append("NORTHERN")
	elif c.x > RbdConstants.WORLD_SIZE * 0.7:
		parts.append("EASTERN")
	elif c.x < RbdConstants.WORLD_SIZE * 0.3:
		parts.append("WESTERN")
	elif act < 55.0:
		parts.append("BELT")
	elif cluster.count > 2000:
		parts.append("CENTER")
	else:
		parts.append("HOLLOW")
	var name := "THE " + " ".join(parts)
	return name.to_upper()

func record_decision(region_id: String, tag: String) -> void:
	if not regions.has(region_id):
		return
	var reg: Region = regions[regions[region_id]]
	if tag not in reg.decision_tags:
		reg.decision_tags.append(tag)

func to_dict() -> Array:
	var arr: Array = []
	for rid in regions:
		var r: Region = regions[rid]
		arr.append({
			"id": r.id,
			"name": r.name,
			"centroid": [r.centroid.x, r.centroid.y],
			"cell_count": r.cell_count,
			"avg_density": r.avg_density,
			"avg_warmth": r.avg_warmth,
			"avg_activity": r.avg_activity,
			"birth_day": r.birth_day,
			"last_activity_peak": r.last_activity_peak,
			"velocity": [r.velocity.x, r.velocity.y],
			"history_snippets": r.history_snippets.duplicate(),
			"is_origin": r.is_origin,
			"decision_tags": r.decision_tags.duplicate(),
		})
	return arr

func from_dict(data: Array) -> void:
	regions.clear()
	for raw in data:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var r := Region.new()
		r.id = str(raw.get("id", ""))
		r.name = str(raw.get("name", "UNKNOWN"))
		var cen: Array = raw.get("centroid", [0, 0])
		r.centroid = Vector2(float(cen[0]), float(cen[1]))
		r.cell_count = int(raw.get("cell_count", 0))
		r.avg_density = float(raw.get("avg_density", 0.0))
		r.avg_warmth = float(raw.get("avg_warmth", 0.0))
		r.avg_activity = float(raw.get("avg_activity", 0.0))
		r.birth_day = int(raw.get("birth_day", 1))
		r.last_activity_peak = float(raw.get("last_activity_peak", 0.0))
		var vel: Array = raw.get("velocity", [0, 0])
		r.velocity = Vector2(float(vel[0]), float(vel[1]))
		r.history_snippets = Array(raw.get("history_snippets", []))
		r.is_origin = bool(raw.get("is_origin", false))
		r.decision_tags = Array(raw.get("decision_tags", []))
		regions[r.id] = r
