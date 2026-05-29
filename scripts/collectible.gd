extends Area2D
class_name StreetCollectible

signal collected(id: int, item_name: String, item_id: StringName)

@export var collectible_id: int = 0
@export var label_text: String = "Test Pickup"
@export var item_id: StringName = &""

@onready var _body: Polygon2D = $Body
@onready var _tag: Label = $Label
@onready var _prompt: Label = $Prompt

var _base_y: float
var _pending_visual: Dictionary = {}

func configure(item_uid: int, display_name: String, visual: Dictionary = {}, catalog_id: StringName = &"") -> void:
	collectible_id = item_uid
	label_text = display_name
	item_id = catalog_id if catalog_id != &"" else StringName(display_name.to_lower().replace(" ", "_"))
	_pending_visual = visual
	if is_node_ready():
		_apply_ready()

func _ready() -> void:
	add_to_group("pickup")
	_base_y = position.y
	_apply_ready()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_start_bob()

func _apply_ready() -> void:
	_tag.text = label_text
	_prompt.visible = false
	if not _pending_visual.is_empty():
		_apply_visual(_pending_visual)
		_pending_visual = {}

func _apply_visual(visual: Dictionary) -> void:
	if visual.has("color"):
		_body.color = visual["color"]
	if visual.has("polygon"):
		_body.polygon = visual["polygon"]
	if visual.has("scale"):
		var s: float = visual["scale"]
		scale = Vector2(s, s)

func _start_bob() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", _base_y - 3.0, 0.85).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _base_y, 0.85).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_prompt.visible = false

func try_pickup(_by: Node) -> bool:
	collected.emit(collectible_id, label_text, item_id)
	queue_free()
	return true
