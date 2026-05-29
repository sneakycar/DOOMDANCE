extends Node2D

@export var def: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite
@onready var _body: Polygon2D = $Body
@onready var _tag: Label = $Tag

func configure(data: Dictionary) -> void:
	def = data
	if is_node_ready():
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	PropVisual.apply(_sprite, _body, _tag, def)
