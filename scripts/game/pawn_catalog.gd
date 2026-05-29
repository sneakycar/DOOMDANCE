extends RefCounted
class_name PawnCatalog

const DATA_PATH := "res://data/pawn_catalog.json"

static var _buys: Array = []
static var _header := "KENSINGTON PAWN"
static var _subtitle := ""

static func load_all() -> void:
	if not _buys.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_header = str(parsed.get("header", _header))
	_subtitle = str(parsed.get("subtitle", ""))
	_buys = parsed.get("buys", [])

static func header_text() -> String:
	load_all()
	return _header

static func subtitle_text() -> String:
	load_all()
	return _subtitle

static func buy_list() -> Array[Dictionary]:
	load_all()
	var out: Array[Dictionary] = []
	for raw in _buys:
		if raw is Dictionary:
			out.append(raw)
	return out
