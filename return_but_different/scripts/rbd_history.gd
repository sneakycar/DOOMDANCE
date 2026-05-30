class_name RbdHistory
extends RefCounted

var entries: Array[Dictionary] = []

func log(clock: RbdClock, text: String, force_upper: bool = true) -> void:
	var body := text.to_upper() if force_upper else text
	var day_label := clock.day_label_for_stamp(clock.elapsed_sec)
	entries.append({
		"stamp": clock.elapsed_sec,
		"day_label": day_label,
		"text": body,
		"fragment": "%s — %s" % [day_label, body],
	})

func format_lines(max_lines: int = 80) -> PackedStringArray:
	var lines := PackedStringArray()
	var start := maxi(0, entries.size() - max_lines)
	for i in range(start, entries.size()):
		var e: Dictionary = entries[i]
		if e.has("fragment"):
			lines.append(str(e.fragment))
		else:
			lines.append("%s — %s" % [e.day_label, e.text])
	return lines

func to_dict() -> Array:
	return entries.duplicate()

func from_dict(data: Array) -> void:
	entries.clear()
	for raw in data:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		if not e.has("fragment") and e.has("day_label") and e.has("text"):
			e["fragment"] = "%s — %s" % [e.day_label, str(e.text).to_upper()]
		entries.append(e)
