extends AlleyInteractable
class_name AlleyVendor

@export var vendor_name: String = "Vendor"
@export var active_phases: Array = []
@export var buy_item: StringName = &""
@export var buy_price: int = 2
@export var sell_item: StringName = &""
@export var sell_payout: int = 2

func apply_definition(def: Dictionary) -> void:
	vendor_name = def.get("label", vendor_name)
	active_phases = AlleyContent.parse_phases(def.get("active_phases", []))
	buy_item = StringName(def.get("buy_item", ""))
	buy_price = def.get("buy_price", 0)
	sell_item = StringName(def.get("sell_item", ""))
	sell_payout = def.get("sell_payout", 0)
	if def.has("marker_color"):
		_marker.color = AlleyContent.parse_color(def["marker_color"])
	prompt_text = "[E] Talk to %s" % vendor_name
	_refresh_label()

func _ready() -> void:
	prompt_text = "[E] Talk to %s" % vendor_name
	super._ready()

func try_interact(_player: Node, clock: GameClock, wallet: PlayerWallet, inventory: Inventory) -> String:
	if not _phase_ok(clock.phase):
		return "%s is not here right now." % vendor_name
	if sell_item != &"" and inventory.has_item(sell_item):
		inventory.remove_item(sell_item)
		wallet.earn(sell_payout)
		return "Sold %s for $%d." % [AlleyContent.item_label(sell_item), sell_payout]
	if buy_item != &"":
		if inventory.has_item(buy_item):
			return "You already bought %s." % AlleyContent.item_label(buy_item)
		if not wallet.can_afford(buy_price):
			return "Need $%d for %s." % [buy_price, AlleyContent.item_label(buy_item)]
		wallet.spend(buy_price)
		inventory.add_item_by_id(buy_item, AlleyContent.item_label(buy_item))
		return "Bought %s for $%d." % [AlleyContent.item_label(buy_item), buy_price]
	return "%s nods. Come back with something to sell." % vendor_name

func _phase_ok(phase: GameClock.TimePhase) -> bool:
	if active_phases.is_empty():
		return true
	return phase in active_phases
