extends Area2D

@export var def: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite
@onready var _body: Polygon2D = $Body
@onready var _tag: Label = $Tag

func configure(data: Dictionary) -> void:
	def = data
	if is_node_ready():
		_apply()

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	_apply()

func _apply() -> void:
	PropVisual.apply(_sprite, _body, _tag, def)
	_tag.visible = false

func get_line(phase_name: String) -> String:
	var lines: Dictionary = def.get("lines", {})
	var line: String = lines.get(phase_name, "...")
	if line == "...":
		return "%s isn't talking right now." % def.get("label", "Someone")
	return line

func get_prompt() -> String:
	return "Talk to %s" % def.get("label", "NPC")
