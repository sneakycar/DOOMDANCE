extends RefCounted
class_name RecordCatalog

const DATA_PATH := "res://data/record_catalog.json"

static var _buys: Array = []
static var _header := "SIGNAL STATIC"
static var _subtitle := ""
static var _sell_rate := 0.55

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
	_sell_rate = float(parsed.get("sell_rate", 0.55))
	_buys = parsed.get("buys", [])

static func header_text() -> String:
	load_all()
	return _header

static func subtitle_text() -> String:
	load_all()
	return _subtitle

static func sell_rate() -> float:
	load_all()
	return _sell_rate

static func buy_list() -> Array[Dictionary]:
	load_all()
	var out: Array[Dictionary] = []
	for raw in _buys:
		if raw is Dictionary:
			out.append(raw)
	return out
