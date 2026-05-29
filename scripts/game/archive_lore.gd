extends RefCounted
class_name ArchiveLore

const DATA_PATH := "res://data/maze_pages.json"
const MIN_LEN := 32
const MAX_LEN := 360
const JUNK_MARKERS: Array[String] = [
	"new Image(",
	"navigator.appName",
	"function preload",
	"document.images",
	"var myimages",
	"parseInt(navigator",
	"browser = (((navigator",
]

static var _pool: Array[Dictionary] = []
static var _built := false

static func random_fragment(exclude_ids: Array = []) -> Dictionary:
	_ensure_pool()
	if _pool.is_empty():
		return {"id": "empty", "title": "archive", "body": "nothing readable in the rain."}
	var candidates: Array[Dictionary] = []
	for entry in _pool:
		if str(entry.get("id", "")) not in exclude_ids:
			candidates.append(entry)
	if candidates.is_empty():
		candidates.assign(_pool)
	return candidates[randi() % candidates.size()].duplicate()

static func _ensure_pool() -> void:
	if _built:
		return
	_built = true
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing maze data for archive lore: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var pages: Dictionary = parsed.get("pages", {})
	for page_id in pages.keys():
		if str(page_id) == "void":
			continue
		_add_page_fragments(str(page_id), pages[page_id])

static func _add_page_fragments(page_id: String, page: Variant) -> void:
	if page is not Dictionary:
		return
	var title := _clean_title(str(page.get("title", page_id)))
	var body := _clean_text(str(page.get("body", "")))
	var subtitle := _clean_text(str(page.get("subtitle", "")))
	if _is_readable(body):
		_add("%s_body" % page_id, title, _clip(body))
	if _is_readable(subtitle) and subtitle != body:
		_add("%s_sub" % page_id, title, _clip(subtitle))
	for chunk in _split_chunks(body):
		if _is_readable(chunk):
			var chunk_id := "%s_%s" % [page_id, chunk.hash()]
			_add(chunk_id, title, _clip(chunk))

static func _add(id: String, title: String, body: String) -> void:
	for existing in _pool:
		if existing.get("body", "") == body:
			return
	_pool.append({"id": id, "title": title, "body": body})

static func _clean_title(text: String) -> String:
	var cleaned := _clean_text(text)
	if cleaned.is_empty():
		return "archive"
	return cleaned.split("\n", false)[0].strip_edges()

static func _clean_text(text: String) -> String:
	var out := text
	out = out.replace("&quot;", "\"")
	out = out.replace("&nbsp;", " ")
	out = out.replace("&amp;", "&")
	out = out.replace("&lt;", "<")
	out = out.replace("&gt;", ">")
	out = out.replace("[deaddeaddead.com]", "")
	out = out.replace("deaddeaddead.com", "")
	out = out.replace("deaddeaddead", "")
	while "  " in out:
		out = out.replace("  ", " ")
	out = out.strip_edges()
	return out

static func _split_chunks(text: String) -> Array[String]:
	var chunks: Array[String] = []
	if text.is_empty():
		return chunks
	for block in text.split("\n\n", false):
		var piece := block.strip_edges()
		if piece.is_empty():
			continue
		if piece.length() >= MIN_LEN:
			chunks.append(piece)
			continue
		for sentence in piece.split(". ", false):
			var trimmed := sentence.strip_edges()
			if trimmed.ends_with("."):
				pass
			elif not trimmed.is_empty() and not trimmed.ends_with("."):
				trimmed += "."
			if trimmed.length() >= MIN_LEN:
				chunks.append(trimmed)
	return chunks

static func _clip(text: String) -> String:
	if text.length() <= MAX_LEN:
		return text
	var clipped := text.substr(0, MAX_LEN)
	var last_space := clipped.rfind(" ")
	if last_space > MAX_LEN * 0.6:
		clipped = clipped.substr(0, last_space)
	return clipped.strip_edges() + "..."

static func _is_readable(text: String) -> bool:
	if text.length() < MIN_LEN:
		return false
	if _is_junk(text):
		return false
	var letters := 0
	for i in text.length():
		var ch: String = text[i]
		if (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z") or ch == " ":
			letters += 1
	return float(letters) / float(text.length()) >= 0.55

static func _is_junk(text: String) -> bool:
	var lower := text.to_lower()
	for marker in JUNK_MARKERS:
		if marker.to_lower() in lower:
			return true
	if lower.count("dead") >= 6 and text.length() < 120:
		return true
	if lower.count("the hidden page") >= 3:
		return true
	var words := lower.split(" ", false)
	if words.size() < 5 and text.length() < 72:
		return true
	var unique: Dictionary = {}
	for word in words:
		if word.length() > 2:
			unique[word] = true
	if unique.size() < 4 and text.length() < 100:
		return true
	return false
