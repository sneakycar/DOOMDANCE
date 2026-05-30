class_name RbdNameGenerator
extends RefCounted
## MakeAwesome-style names: first + surname, lineage reuse, rare compound surnames.

var _rng := RandomNumberGenerator.new()
var _first_names: PackedStringArray = PackedStringArray()
var _surnames: PackedStringArray = PackedStringArray()
var _prefixes: PackedStringArray = PackedStringArray()
var _roots: PackedStringArray = PackedStringArray()
var _strange: PackedStringArray = PackedStringArray()
var _recent_surnames: Array[String] = []
const RECENT_SURNAME_CAP := 12

func _init(seed: int = 0) -> void:
	_rng.seed = seed if seed != 0 else int(Time.get_unix_time_from_system())
	_load_parts()

func _load_parts() -> void:
	var path := "res://return_but_different/data/rbd_name_parts.json"
	if not FileAccess.file_exists(path):
		_bootstrap_defaults()
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_bootstrap_defaults()
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_bootstrap_defaults()
		return
	_first_names = PackedStringArray(parsed.get("first_names", []))
	_surnames = PackedStringArray(parsed.get("surnames", []))
	_prefixes = PackedStringArray(parsed.get("surname_prefixes", []))
	_roots = PackedStringArray(parsed.get("surname_roots", []))
	_strange = PackedStringArray(parsed.get("strange_surnames", []))

func _bootstrap_defaults() -> void:
	_first_names = PackedStringArray(["Jaxon", "Mara", "Ezra", "Elias"])
	_surnames = PackedStringArray(["Thorn", "Black", "Vonwell"])
	_prefixes = PackedStringArray(["Von", "Van"])
	_roots = PackedStringArray(["Well", "Hollow"])
	_strange = PackedStringArray(["Vonwell", "Blackthorn"])

func set_seed(seed: int) -> void:
	_rng.seed = seed

func randf() -> float:
	return _rng.randf()

func randf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b)

func randi() -> int:
	return _rng.randi()

func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)

static func normalize_part(word: String) -> String:
	if word.is_empty():
		return ""
	var lower := word.to_lower()
	return lower.substr(0, 1).to_upper() + lower.substr(1)

static func surname_key(last_name: String) -> String:
	return last_name.to_upper().replace(" ", "")

func full_name_upper(first: String, last: String) -> String:
	return "%s %s" % [first.to_upper(), last.to_upper()]

func full_name_display(first: String, last: String) -> String:
	return "%s %s" % [normalize_part(first), normalize_part(last)]

func pick_first_name() -> String:
	return _first_names[_rng.randi() % _first_names.size()]

func pick_surname(families: Dictionary, force_lineage: bool = false) -> String:
	var lineage_roll := force_lineage or _rng.randf() < 0.52
	if lineage_roll and not families.is_empty():
		var keys: Array = families.keys()
		var total_weight := 0
		for k in keys:
			var fam: Dictionary = families[k]
			total_weight += maxi(1, int(fam.get("living_count", 1)))
		if total_weight > 0:
			var pick := _rng.randi_range(1, total_weight)
			for k in keys:
				var fam: Dictionary = families[k]
				pick -= maxi(1, int(fam.get("living_count", 1)))
				if pick <= 0:
					return str(k)

	if _recent_surnames.size() >= 4 and _rng.randf() < 0.38:
		return _pick_fresh_surname()

	if not _surnames.is_empty() and _rng.randf() < 0.45:
		return _surnames[_rng.randi() % _surnames.size()].to_upper()

	return _pick_fresh_surname()

func _pick_fresh_surname() -> String:
	var candidate := ""
	var attempts := 0
	while attempts < 16:
		attempts += 1
		if _rng.randf() < 0.22 and not _strange.is_empty():
			candidate = _strange[_rng.randi() % _strange.size()].to_upper()
		elif _rng.randf() < 0.35 and not _prefixes.is_empty() and not _roots.is_empty():
			var pre := _prefixes[_rng.randi() % _prefixes.size()]
			var root := _roots[_rng.randi() % _roots.size()]
			candidate = (pre + root).to_upper()
		elif not _surnames.is_empty():
			candidate = _surnames[_rng.randi() % _surnames.size()].to_upper()
		else:
			candidate = "VONWELL"
		if _count_recent(candidate) < 2:
			break
	_track_surname(candidate)
	return candidate

func _count_recent(surname: String) -> int:
	var n := 0
	for s in _recent_surnames:
		if s == surname:
			n += 1
	return n

func _track_surname(surname: String) -> void:
	_recent_surnames.append(surname)
	if _recent_surnames.size() > RECENT_SURNAME_CAP:
		_recent_surnames.pop_front()

func generate_person(families: Dictionary, prefer_lineage: bool = false) -> Dictionary:
	var first := pick_first_name()
	var last := pick_surname(families, prefer_lineage)
	_track_surname(last)
	return {
		"first_name": normalize_part(first),
		"last_name": normalize_part(last),
		"full_name": full_name_display(first, last),
		"full_name_upper": full_name_upper(first, last),
		"surname_key": surname_key(last),
	}

func to_dict() -> Dictionary:
	return {"recent_surnames": _recent_surnames.duplicate(), "rng_state": _rng.state}

func from_dict(data: Dictionary) -> void:
	_recent_surnames.clear()
	for s in data.get("recent_surnames", []):
		_recent_surnames.append(str(s))
	if data.has("rng_state"):
		_rng.state = int(data.rng_state)
