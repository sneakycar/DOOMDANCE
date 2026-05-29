extends RefCounted
class_name ItemCatalog

## Back-compat aliases — definitions live in `data/first_alley/items.json`.

const ID_TRASH_BAG := &"trash_bag"
const ID_BEER_CAN := &"beer_can"
const ID_CIG_PACK := &"cigarette_pack"
const ID_PILL_BOTTLE := &"pill_bottle"
const ID_JACKET := &"jacket"
const ID_BASEBALL_CARD := &"baseball_card"
const ID_RECORD := &"vinyl_single"
const ID_SHOPPING_CART := &"shopping_cart_wheel"
const ID_DEAD_PHONE := &"dead_phone"
const ID_FOLDED_NOTE := &"folded_note"
const ID_LOOSE_CIGS := &"loose_cigarettes"
const ID_NIGHT_KEY := &"alley_key"

static func lookup(item_id: StringName) -> Dictionary:
	AlleyContent.ensure_loaded()
	var d := AlleyContent.item(item_id)
	if d.is_empty():
		return {"id": item_id, "label": str(item_id), "sell": 0, "usable": false}
	return {
		"id": d["id"],
		"label": d.get("label", str(item_id)),
		"sell": d.get("sell", 0),
		"usable": d.get("usable", false),
		"use_msg": d.get("use_msg", ""),
		"consume_on_use": d.get("consume_on_use", false),
	}

static func label(item_id: StringName) -> String:
	return AlleyContent.item_label(item_id)

static func sell_value(item_id: StringName) -> int:
	return AlleyContent.item_sell_value(item_id)

static func is_usable(item_id: StringName) -> bool:
	return AlleyContent.item_is_usable(item_id)

static func use_message(item_id: StringName) -> String:
	return AlleyContent.item_use_message(item_id)
