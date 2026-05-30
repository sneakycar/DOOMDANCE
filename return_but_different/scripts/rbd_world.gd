class_name RbdWorld
extends RefCounted
## 1024×1024 deterministic living grid — hidden vars emerge in step, never shown in UI.

var seed: int = 0
var origin := RbdConstants.ORIGIN
var sim_tick: int = 0

var density: PackedByteArray
var warmth: PackedByteArray
var activity: PackedByteArray
var age: PackedByteArray
var memory: PackedByteArray
var flags: PackedByteArray

var _scratch_density: PackedByteArray
var _scratch_warmth: PackedByteArray
var _scratch_activity: PackedByteArray
var _rng: RandomNumberGenerator

var offline_delta_metric: float = 0.0

const FLAG_ORIGIN := 1
const FLAG_MARKED := 2

func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_allocate()

func _allocate() -> void:
	var n := RbdConstants.CELL_COUNT
	density = PackedByteArray()
	density.resize(n)
	warmth = PackedByteArray()
	warmth.resize(n)
	activity = PackedByteArray()
	activity.resize(n)
	age = PackedByteArray()
	age.resize(n)
	memory = PackedByteArray()
	memory.resize(n)
	flags = PackedByteArray()
	flags.resize(n)
	_scratch_density = density.duplicate()
	_scratch_warmth = warmth.duplicate()
	_scratch_activity = activity.duplicate()

func reset_world(new_seed: int = -1) -> void:
	if new_seed < 0:
		new_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	seed = new_seed
	_rng.seed = seed
	sim_tick = 0
	density.fill(0)
	warmth.fill(0)
	activity.fill(0)
	age.fill(0)
	memory.fill(0)
	flags.fill(0)
	var oi := _idx(origin)
	density[oi] = 255
	warmth[oi] = 255
	activity[oi] = 220
	flags[oi] = FLAG_ORIGIN | FLAG_MARKED
	offline_delta_metric = 0.0

func _idx(p: Vector2i) -> int:
	return p.y * RbdConstants.WORLD_SIZE + p.x

func _wrap(v: int) -> int:
	return clampi(v, 0, RbdConstants.WORLD_SIZE - 1)

func step_once(influence: RbdInfluence) -> void:
	sim_tick += 1
	var w := RbdConstants.WORLD_SIZE
	var inf := influence
	for y in range(w):
		var row := y * w
		for x in range(w):
			var i := row + x
			if flags[i] & FLAG_ORIGIN:
				_scratch_density[i] = 255
				_scratch_warmth[i] = 255
				_scratch_activity[i] = maxi(activity[i], 200)
				continue
			var d := int(density[i])
			var wm := int(warmth[i])
			var act := int(activity[i])
			var ag := int(age[i])
			var mem := int(memory[i])
			var nsum_d := 0
			var nsum_w := 0
			var ncount := 0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					var nx := _wrap(x + ox)
					var ny := _wrap(y + oy)
					var ni := ny * w + nx
					nsum_d += int(density[ni])
					nsum_w += int(warmth[ni])
					ncount += 1
			var avg_d := float(nsum_d) / float(ncount)
			var avg_w := float(nsum_w) / float(ncount)
			var pressure := avg_d - float(d)
			var cohesion := absf(avg_d - float(d)) < 18.0
			var spread := (avg_d - float(d)) * 0.11
			var drift := _rng.randf_range(-0.6, 0.6) + float(mem) * 0.0012
			var branch := float(act) * 0.0025
			var mutation := _rng.randf_range(-1.2, 1.2) if (sim_tick + i) % 97 == 0 else 0.0
			var decay := maxf(0.0, float(d) * 0.0018) if d < 24 else 0.0
			var growth := spread + branch + drift + mutation
			if cohesion and d > 40:
				growth += 0.35
			if pressure > 30.0:
				growth += 0.22
			var inf_boost := inf.sample_field(Vector2i(x, y))
			growth += inf_boost.growth
			wm = int(clampf(float(wm) + (avg_w - float(wm)) * 0.14 + inf_boost.warmth, 0.0, 255.0))
			d = int(clampf(float(d) + growth - decay + inf_boost.density, 0.0, 255.0))
			var activity_next := int(clampf(absf(growth) * 18.0 + float(act) * 0.92 + inf_boost.activity, 0.0, 255.0))
			if d > 30:
				ag = mini(255, ag + 1)
			_scratch_density[i] = d
			_scratch_warmth[i] = wm
			_scratch_activity[i] = activity_next
	density = _scratch_density.duplicate()
	warmth = _scratch_warmth.duplicate()
	activity = _scratch_activity.duplicate()
	_scratch_density = density.duplicate()
	_scratch_warmth = warmth.duplicate()
	_scratch_activity = activity.duplicate()
	# Age & memory lag one pass behind for stability.
	for i in range(RbdConstants.CELL_COUNT):
		if density[i] > 28:
			age[i] = mini(255, int(age[i]) + 1)
		elif int(age[i]) > 0:
			age[i] = maxi(0, int(age[i]) - 1)
		if activity[i] > 60:
			memory[i] = mini(255, int(memory[i]) + 1)

func run_steps(count: int, influence: RbdInfluence) -> void:
	if count <= 0:
		return
	var before := _snapshot_metric()
	for _s in range(count):
		step_once(influence)
		influence.tick_step()
	var after := _snapshot_metric()
	offline_delta_metric = maxf(offline_delta_metric, absf(after - before))

func _snapshot_metric() -> float:
	var s := 0.0
	var stride := 64
	var w := RbdConstants.WORLD_SIZE
	for y in range(0, w, stride):
		for x in range(0, w, stride):
			var i := y * w + x
			s += float(density[i]) + float(warmth[i]) * 0.5
	return s

func origin_strength() -> float:
	var i := _idx(origin)
	return float(density[i]) + float(activity[i]) * 0.5

func cell_color_at(x: int, y: int, shimmer: float) -> Color:
	var i := y * RbdConstants.WORLD_SIZE + x
	var d := float(density[i]) / 255.0
	var w := float(warmth[i]) / 255.0
	var a := float(activity[i]) / 255.0
	var ag := float(age[i]) / 255.0
	if d < 0.02 and w < 0.02:
		return Color(0.02, 0.02, 0.03, 1.0)
	var pulse := sin(shimmer * 3.1 + float(x) * 0.01 + float(y) * 0.008) * 0.03
	var cool := Color(0.15, 0.22, 0.32).lerp(Color(0.35, 0.55, 0.62), w)
	var warm := Color(0.45, 0.28, 0.18).lerp(Color(0.62, 0.38, 0.22), w * 0.7)
	var bright := Color(0.92, 0.94, 0.96).lerp(Color(0.75, 0.82, 0.95), w)
	var base: Color
	if d < 0.15:
		base = Color(0.05, 0.05, 0.07)
	elif d < 0.35:
		base = Color(0.2, 0.22, 0.26).lerp(cool, w)
	elif ag > 0.55:
		base = warm.lerp(Color(0.42, 0.18, 0.28), a * 0.4)
	else:
		base = cool.lerp(warm, clampf(d * 0.8, 0.0, 1.0))
	if d > 0.72:
		base = base.lerp(bright, (d - 0.72) * 2.5)
	base = base.lerp(Color(0.55, 0.2, 0.55), a * 0.12 * ag)
	base += Color(pulse, pulse * 0.6, pulse * 1.2, 0.0)
	if flags[i] & FLAG_ORIGIN:
		base = base.lerp(Color(1.0, 1.0, 1.0), 0.35 + a * 0.15)
	return base.clamp()

func to_save_dict() -> Dictionary:
	return {
		"seed": seed,
		"origin": [origin.x, origin.y],
		"sim_tick": sim_tick,
		"density": density.compress(FileAccess.COMPRESSION_FASTLZ),
		"warmth": warmth.compress(FileAccess.COMPRESSION_FASTLZ),
		"activity": activity.compress(FileAccess.COMPRESSION_FASTLZ),
		"age": age.compress(FileAccess.COMPRESSION_FASTLZ),
		"memory": memory.compress(FileAccess.COMPRESSION_FASTLZ),
		"flags": flags.compress(FileAccess.COMPRESSION_FASTLZ),
	}

func from_save_dict(data: Dictionary) -> void:
	seed = int(data.get("seed", seed))
	var o_arr: Array = data.get("origin", [origin.x, origin.y])
	origin = Vector2i(int(o_arr[0]), int(o_arr[1]))
	sim_tick = int(data.get("sim_tick", 0))
	_load_channel(data, "density", density)
	_load_channel(data, "warmth", warmth)
	_load_channel(data, "activity", activity)
	_load_channel(data, "age", age)
	_load_channel(data, "memory", memory)
	_load_channel(data, "flags", flags)
	_rng.seed = seed
	_scratch_density = density.duplicate()
	_scratch_warmth = warmth.duplicate()
	_scratch_activity = activity.duplicate()
	offline_delta_metric = 0.0

func _load_channel(data: Dictionary, key: String, target: PackedByteArray) -> void:
	if not data.has(key):
		return
	var raw: PackedByteArray = data[key]
	var dec := raw.decompress(RbdConstants.CELL_COUNT, FileAccess.COMPRESSION_FASTLZ)
	if dec.size() == RbdConstants.CELL_COUNT:
		target = dec
		match key:
			"density":
				density = dec
			"warmth":
				warmth = dec
			"activity":
				activity = dec
			"age":
				age = dec
			"memory":
				memory = dec
			"flags":
				flags = dec
