extends Area2D

signal collected(item_name: String)

@export var def: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite
@onready var _body: Polygon2D = $Body
@onready var _tag: Label = $Tag

func configure(data: Dictionary) -> void:
	def = data
	if is_node_ready():
		_apply()

func _ready() -> void:
	add_to_group("pickup")
	_apply()

func _apply() -> void:
	PropVisual.apply(_sprite, _body, _tag, def)
	_tag.visible = false

func try_pickup() -> bool:
	collected.emit(def.get("label", "Item"))
	queue_free()
	return true

func get_prompt() -> String:
	return "Pick up: %s" % def.get("label", "Item")
