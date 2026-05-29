extends CanvasLayer
## Skyline band — top strip of alley_bg, parallax behind segments.

const SKY_BAND_H := 108.0
const VIEWPORT_W := 480.0

@export var parallax_strength := 0.05

@onready var _sprite: Sprite2D = $SkySprite

func _ready() -> void:
	layer = -10
	if _sprite == null:
		return
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.position = Vector2.ZERO
	if _sprite.texture:
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(0.0, 0.0, VIEWPORT_W, SKY_BAND_H)

func _process(_delta: float) -> void:
	if _sprite == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	_sprite.position.x = -player.global_position.x * parallax_strength
