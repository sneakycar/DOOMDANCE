extends PanelContainer
## Bottom text strip — lowercase fragments, dead-web tone. No game HUD.

@onready var _label: Label = %FragmentLabel

var _hide_tween: Tween

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_style()
	DoomTypography.stamp_fragment(_label, 13)
	_label.text = ""

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0, 0, 0, 0.9)
	panel.set_content_margin_all(10)
	panel.set_content_margin(Side.SIDE_LEFT, 14)
	panel.set_content_margin(Side.SIDE_RIGHT, 14)
	add_theme_stylebox_override("panel", panel)

func show_fragment(text: String, duration: float = 3.2) -> void:
	if _hide_tween and _hide_tween.is_valid():
		_hide_tween.kill()
	_label.text = DoomTypography.as_fragment(text)
	visible = true
	if duration <= 0.0:
		return
	_hide_tween = create_tween()
	_hide_tween.tween_interval(duration)
	_hide_tween.tween_callback(hide_fragment)

func hide_fragment() -> void:
	visible = false
	_label.text = ""

func is_showing() -> bool:
	return visible and not _label.text.is_empty()
