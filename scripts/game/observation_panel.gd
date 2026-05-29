extends PanelContainer

signal action_confirmed(hotspot: Dictionary)
signal dismissed()

@onready var _name_label: Label = %NameLabel
@onready var _body_label: Label = %BodyLabel
@onready var _primary_btn: Button = %PrimaryButton
@onready var _close_btn: Button = %CloseButton

var _hotspot: Dictionary = {}
var _hide_timer: SceneTreeTimer
var _reading_active := false

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

func show_passive(text: String, duration: float = 2.4) -> void:
	_cancel_hide_timer()
	_reading_active = false
	_hotspot.clear()
	_name_label.visible = false
	_body_label.text = text
	_primary_btn.visible = false
	_close_btn.visible = false
	visible = true
	_hide_timer = get_tree().create_timer(duration)
	_hide_timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			hide_panel()
	)

func show_reading(title: String, body: String) -> void:
	_cancel_hide_timer()
	_reading_active = true
	_hotspot.clear()
	_name_label.visible = true
	_name_label.text = title.to_upper()
	_body_label.text = body
	_primary_btn.visible = false
	_close_btn.visible = false
	visible = true

func clear_reading() -> void:
	if not _reading_active:
		return
	_reading_active = false
	hide_panel()

func show_hotspot(hotspot: Dictionary) -> void:
	_cancel_hide_timer()
	_reading_active = false
	_hotspot = hotspot.duplicate()
	_name_label.visible = true
	var label := str(hotspot.get("label", "")).strip_edges()
	if label.is_empty():
		var cid: String = str(hotspot.get("collectible_id", ""))
		if cid != "":
			label = str(CollectibleData.lookup(cid).get("name", ""))
	if label.is_empty():
		var text := str(hotspot.get("text", "???")).strip_edges()
		label = text.split("\n", false)[0] if text != "" else "???"
	_name_label.text = label.to_upper()
	_body_label.text = HotspotAffordance.observation(hotspot)
	var primary := HotspotAffordance.primary_label(hotspot)
	_primary_btn.visible = HotspotAffordance.has_primary(hotspot)
	_primary_btn.text = "[%s]" % primary if not primary.is_empty() else ""
	_close_btn.visible = true
	_close_btn.text = "[%s]" % HotspotAffordance.close_label(hotspot)
	visible = true

func hide_panel() -> void:
	if not visible:
		return
	_cancel_hide_timer()
	visible = false
	_reading_active = false
	_hotspot.clear()
	_name_label.visible = true
	_primary_btn.visible = true
	_close_btn.visible = true
	dismissed.emit()

func _on_primary() -> void:
	if _hotspot.is_empty():
		return
	var hotspot := _hotspot.duplicate()
	hide_panel()
	action_confirmed.emit(hotspot)

func _cancel_hide_timer() -> void:
	if _hide_timer == null:
		return
	if _hide_timer.timeout.is_connected(_on_hide_timer):
		_hide_timer.timeout.disconnect(_on_hide_timer)
	_hide_timer = null

func _on_hide_timer() -> void:
	if is_instance_valid(self) and not _reading_active:
		hide_panel()
