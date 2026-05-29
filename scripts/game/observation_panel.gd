extends PanelContainer

signal action_confirmed(hotspot: Dictionary)
signal dismissed()

@onready var _name_label: Label = %NameLabel
@onready var _body_label: Label = %BodyLabel
@onready var _primary_btn: Button = %PrimaryButton
@onready var _close_btn: Button = %CloseButton

var _hotspot: Dictionary = {}

func _ready() -> void:
	visible = false
	_apply_typography()
	_primary_btn.pressed.connect(_on_primary)
	_close_btn.pressed.connect(hide_panel)

func _apply_typography() -> void:
	DoomTypography.stamp_happening(_name_label, 14)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	DoomTypography.stamp_happening(_body_label, 12)
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DoomTypography.stamp_happening(_primary_btn, 12)
	DoomTypography.stamp_happening(_close_btn, 12)
	_style_button(_primary_btn)
	_style_button(_close_btn)

func _style_button(btn: Button) -> void:
	btn.flat = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.border_color = Color(1, 1, 1, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)

func show_hotspot(hotspot: Dictionary) -> void:
	_hotspot = hotspot.duplicate()
	_name_label.text = str(hotspot.get("label", "???")).to_upper()
	_body_label.text = HotspotAffordance.observation(hotspot)
	var primary := HotspotAffordance.primary_label(hotspot)
	_primary_btn.visible = HotspotAffordance.has_primary(hotspot)
	_primary_btn.text = "[%s]" % primary if not primary.is_empty() else ""
	_close_btn.text = "[Close]"
	visible = true

func hide_panel() -> void:
	if not visible:
		return
	visible = false
	_hotspot.clear()
	dismissed.emit()

func _on_primary() -> void:
	if _hotspot.is_empty():
		return
	var hotspot := _hotspot.duplicate()
	hide_panel()
	action_confirmed.emit(hotspot)
