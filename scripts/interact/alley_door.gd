extends AlleyInteractable
class_name AlleyDoor

@export var door_name: String = "Door"
@export var open_phases: Array = []
@export var cost_money: int = 0
@export var required_item: StringName = &""
@export var reward_money: int = 0
@export var reward_item: StringName = &""
@export var success_message: String = "The door opens."

var _opened: bool = false

func apply_definition(def: Dictionary) -> void:
	door_name = def.get("label", door_name)
	open_phases = AlleyContent.parse_phases(def.get("open_phases", []))
	cost_money = def.get("cost_money", 0)
	required_item = StringName(def.get("required_item", ""))
	reward_money = def.get("reward_money", 0)
	reward_item = StringName(def.get("reward_item", ""))
	success_message = def.get("success_message", success_message)
	if def.has("marker_color"):
		_marker.color = AlleyContent.parse_color(def["marker_color"])
	prompt_text = "[E] %s" % door_name
	_refresh_label()

func _ready() -> void:
	prompt_text = "[E] %s" % door_name
	super._ready()

func try_interact(_player: Node, clock: GameClock, wallet: PlayerWallet, inventory: Inventory) -> String:
	if _opened:
		return "%s is already open." % door_name
	if not _phase_ok(clock.phase):
		return "%s is locked until %s." % [door_name, _phase_hint()]
	if required_item != &"" and not inventory.has_item(required_item):
		return "%s needs: %s." % [door_name, AlleyContent.item_label(required_item)]
	if cost_money > 0 and not wallet.can_afford(cost_money):
		return "Need $%d for %s." % [cost_money, door_name]
	if cost_money > 0:
		wallet.spend(cost_money)
	_opened = true
	if reward_money > 0:
		wallet.earn(reward_money)
	if reward_item != &"":
		inventory.add_item_by_id(reward_item, AlleyContent.item_label(reward_item))
	return success_message

func _phase_ok(phase: GameClock.Phase) -> bool:
	if open_phases.is_empty():
		return true
	return phase in open_phases

func _phase_hint() -> String:
	if open_phases.is_empty():
		return "later"
	var names: PackedStringArray = []
	for p in open_phases:
		names.append(_phase_name(p))
	return ", ".join(names)

func _phase_name(phase: GameClock.Phase) -> String:
	match phase:
		GameClock.Phase.NIGHT:
			return "Late Night"
		GameClock.Phase.DAWN:
			return "Dawn"
		GameClock.Phase.MORNING:
			return "Morning"
		GameClock.Phase.AFTERNOON:
			return "Afternoon"
		GameClock.Phase.EVENING:
			return "Evening"
		_:
			return "?"
