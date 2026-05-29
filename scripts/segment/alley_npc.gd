extends Node2D
class_name AlleyNpc

const FLOOR_Y := 203.0

@onready var _body: Polygon2D = $Body
@onready var _coat: Polygon2D = $Coat
@onready var _tag: Label = $Tag

var npc_id: StringName = &""
var display_label: String = "NPC"

func configure(def: Dictionary, state: AlleyState, rng: RandomNumberGenerator, local_x: float) -> void:
	npc_id = StringName(def.get("id", ""))
	display_label = def.get("label", "NPC")
	position = Vector2(local_x, FLOOR_Y)
	var profile := {
		"body": AlleyContent.parse_color(def.get("body_color", [0.2, 0.22, 0.28, 1])),
		"coat": AlleyContent.parse_color(def.get("coat_color", [0.32, 0.3, 0.38, 1])),
	}
	if is_node_ready():
		_apply_profile(profile, state, rng, def)
	else:
		set_meta("pending_profile", profile)
		set_meta("pending_state", state)
		set_meta("pending_rng", rng)
		set_meta("pending_def", def)

func _ready() -> void:
	if has_meta("pending_profile"):
		_apply_profile(
			get_meta("pending_profile"),
			get_meta("pending_state"),
			get_meta("pending_rng"),
			get_meta("pending_def")
		)
		remove_meta("pending_profile")
		remove_meta("pending_state")
		remove_meta("pending_rng")
		remove_meta("pending_def")

func _apply_profile(profile: Dictionary, state: AlleyState, rng: RandomNumberGenerator, def: Dictionary) -> void:
	_body.color = profile["body"]
	_coat.color = profile["coat"]
	if _tag:
		_tag.text = display_label
		_tag.visible = false
	if state != null:
		var light: Color = state.get_scene_modulate()
		modulate = light.lerp(Color.WHITE, 0.35)
	scale.x = -1.0 if rng.randf() > 0.5 else 1.0
