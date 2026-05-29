extends RefCounted
class_name StreetObjectLibrary

## Spawn visuals + ids — loaded from `data/first_alley/items.json`.

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

static func pick_weighted(rng: RandomNumberGenerator, state: AlleyState = null) -> Dictionary:
	var entry := AlleyContent.pick_spawn_item(rng, state)
	if entry.is_empty():
		return {"id": ID_TRASH_BAG, "label": "Trash Bag"}
	return {
		"id": entry["id"],
		"label": entry.get("label", str(entry["id"])),
	}

static func catalog_id(object_id: StringName) -> StringName:
	return object_id

static func label_for(object_id: StringName) -> String:
	return AlleyContent.item_label(object_id)
