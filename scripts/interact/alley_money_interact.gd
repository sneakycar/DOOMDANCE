extends AlleyInteractable
class_name AlleyMoneyInteract

@export var interact_name: String = "Slot"
@export var cost_money: int = 1
@export var success_message: String = "You pay."
@export var fail_message: String = "Not enough money."

var _used: bool = false

func apply_definition(def: Dictionary) -> void:
	interact_name = def.get("label", "Pay")
	cost_money = def.get("cost", 1)
	success_message = def.get("success_message", success_message)
	fail_message = def.get("fail_message", fail_message)
	if def.has("marker_color"):
		_marker.color = AlleyContent.parse_color(def["marker_color"])
	prompt_text = "[E] %s ($%d)" % [interact_name, cost_money]
	_refresh_label()

func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "[E] %s ($%d)" % [interact_name, cost_money]
	super._ready()

func try_interact(_player: Node, _clock: GameClock, wallet: PlayerWallet, _inventory: Inventory) -> String:
	if _used:
		return "%s is empty." % interact_name
	if not wallet.can_afford(cost_money):
		return fail_message
	wallet.spend(cost_money)
	_used = true
	prompt_text = "[E] %s (empty)" % interact_name
	_refresh_label()
	return success_message
