extends Area2D
class_name AlleyInteractable

@export var prompt_text: String = "[E] Interact"

@onready var _marker: Polygon2D = $Marker
@onready var _label: Label = $Label

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_label()

func get_prompt() -> String:
	return prompt_text

func try_interact(_player: Node, _clock: GameClock, _wallet: PlayerWallet, _inventory: Inventory) -> String:
	return "Nothing happens."

func _refresh_label() -> void:
	if _label:
		_label.text = prompt_text

func _on_body_entered(_body: Node2D) -> void:
	pass

func _on_body_exited(_body: Node2D) -> void:
	pass
