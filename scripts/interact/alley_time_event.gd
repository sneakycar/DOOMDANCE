extends AlleyInteractable
class_name AlleyTimeEvent

@export var event_name: String = "Event"
@export var active_phases: Array = []
@export var reward_money: int = 0
@export var reward_item: StringName = &""
@export var success_message: String = "Something happens."
@export var wrong_phase_message: String = "Not the right time."

var _triggered: bool = false

func apply_definition(def: Dictionary) -> void:
	event_name = def.get("label", "Event")
	active_phases = AlleyContent.parse_phases(def.get("active_phases", []))
	reward_money = def.get("reward_money", 0)
	reward_item = StringName(def.get("reward_item", ""))
	success_message = def.get("success_message", success_message)
	wrong_phase_message = def.get("wrong_phase_message", wrong_phase_message)
	if def.has("marker_color"):
		_marker.color = AlleyContent.parse_color(def["marker_color"])
	prompt_text = "[E] %s" % event_name
	_refresh_label()

func _ready() -> void:
	if prompt_text == "[E] Interact":
		prompt_text = "[E] %s" % event_name
	super._ready()

func try_interact(_player: Node, clock: GameClock, wallet: PlayerWallet, inventory: Inventory) -> String:
	if _triggered:
		return "%s already happened." % event_name
	if not _phase_ok(clock.phase):
		return wrong_phase_message
	_triggered = true
	if reward_money > 0:
		wallet.earn(reward_money)
	if reward_item != &"":
		inventory.add_item_by_id(reward_item, AlleyContent.item_label(reward_item))
	return success_message

func _phase_ok(phase: GameClock.Phase) -> bool:
	if active_phases.is_empty():
		return true
	return phase in active_phases
