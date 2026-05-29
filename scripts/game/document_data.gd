extends RefCounted
class_name DocumentData

static func load_text(path: String) -> String:
	if path.is_empty():
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Missing document: %s" % path)
		return "FILE NOT FOUND.\n\n%s" % path
	return file.get_as_text()

static func markdown_to_dos(raw: String) -> String:
	var out: PackedStringArray = []
	for line in raw.split("\n", false):
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			out.append("")
			continue
		if trimmed == "---":
			out.append("----------------------------------------")
			continue
		if trimmed.begins_with("# "):
			out.append("")
			out.append(trimmed.substr(2).strip_edges().to_upper())
			out.append(_rule("=", mini(42, trimmed.length() + 4)))
			continue
		if trimmed.begins_with("## "):
			out.append("")
			out.append(trimmed.substr(3).strip_edges().to_upper())
			out.append(_rule("-", mini(36, trimmed.length() + 2)))
			continue
		if trimmed.begins_with("- "):
			out.append("  * %s" % _strip_md(trimmed.substr(2)))
			continue
		out.append(_strip_md(trimmed))
	return "\n".join(out).strip_edges()

static func _strip_md(text: String) -> String:
	var out := text
	if out.begins_with("*") and out.ends_with("*") and out.count("*") >= 2:
		out = out.substr(1, out.length() - 2)
	out = out.replace("**", "")
	return out.strip_edges()

static func _rule(char: String, width: int) -> String:
	var count: int = maxi(8, width)
	var parts: PackedStringArray = []
	parts.resize(count)
	parts.fill(char.substr(0, 1))
	return "".join(parts)
