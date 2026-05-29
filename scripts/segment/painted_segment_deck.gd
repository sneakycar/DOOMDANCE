extends RefCounted
class_name PaintedSegmentDeck

## Shuffled bag of full-screen 480x270 segment paintings. No back-to-back repeats.

var _entries: Array[Dictionary] = []
var _bag: Array[int] = []
var _last_slot := -1

func load_folder(dir_path: String) -> int:
	_entries.clear()
	_bag.clear()
	_last_slot = -1
	var files := DirAccess.get_files_at(dir_path)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		var path := dir_path.path_join(file_name)
		if not ResourceLoader.exists(path):
			continue
		var label := file_name.get_basename().replace("_", " ")
		_entries.append({"path": path, "label": label})
	refill_bag()
	return _entries.size()

func has_art() -> bool:
	return not _entries.is_empty()

func count() -> int:
	return _entries.size()

func refill_bag() -> void:
	_bag.clear()
	for i in _entries.size():
		_bag.append(i)
	_shuffle_bag()

func pick() -> Dictionary:
	if _entries.is_empty():
		return {}
	if _bag.is_empty():
		refill_bag()
	var slot: int = _bag.pop_back()
	if _entries.size() > 1 and slot == _last_slot:
		if _bag.is_empty():
			refill_bag()
		slot = _bag.pop_back()
	_last_slot = slot
	var entry: Dictionary = _entries[slot]
	return {
		"path": entry.get("path", ""),
		"label": entry.get("label", "Alley"),
	}

func _shuffle_bag() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(_bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = tmp
