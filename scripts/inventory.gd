extends Node
class_name Inventory

signal changed(items: Array[String])

var items: Array[String] = []
var _ids: Array[StringName] = []

func add_item(name: String) -> void:
	add_item_by_id(StringName(name.to_lower().replace(" ", "_")), name)

func add_item_by_id(item_id: StringName, display_name: String) -> void:
	if item_id in _ids:
		return
	_ids.append(item_id)
	items.append(display_name)
	changed.emit(items.duplicate())

func has_item(item_id: StringName) -> bool:
	return item_id in _ids

func remove_item(item_id: StringName) -> bool:
	var idx := _ids.find(item_id)
	if idx < 0:
		return false
	_ids.remove_at(idx)
	items.remove_at(idx)
	changed.emit(items.duplicate())
	return true

func first_usable_id() -> StringName:
	for item_id in _ids:
		if AlleyContent.item_is_usable(item_id):
			return item_id
	return &""

func use_first_usable() -> String:
	var item_id := first_usable_id()
	if item_id == &"":
		return ""
	var msg: String = AlleyContent.item_use_message(item_id)
	if AlleyContent.item_consume_on_use(item_id):
		remove_item(item_id)
	return msg

func sell_first() -> Dictionary:
	if _ids.is_empty():
		return {"ok": false, "msg": "Nothing to sell."}
	var item_id: StringName = _ids[0]
	var payout: int = AlleyContent.item_sell_value(item_id)
	var label: String = items[0]
	remove_item(item_id)
	return {"ok": true, "msg": "Sold %s for $%d." % [label, payout], "payout": payout}

func clear() -> void:
	items.clear()
	_ids.clear()
	changed.emit(items.duplicate())

func count() -> int:
	return items.size()
