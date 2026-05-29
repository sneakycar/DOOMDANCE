extends PanelContainer
class_name SellPicker

signal item_selected(collectible_id: String, venue: String)
signal closed()

@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _list: VBoxContainer = %ItemList
@onready var _close: Button = %CloseButton

var _venue := "pawn"

func _ready() -> void:
	visible = false
	_apply_style()
	_close.pressed.connect(close_picker)

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.08, 0.94)
	panel.border_color = Color(0.55, 0.52, 0.48, 0.55)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(14)
	panel.set_corner_radius_all(1)
	add_theme_stylebox_override("panel", panel)
	DoomTypography.stamp_game(_title, 14)
	DoomTypography.stamp_game(_subtitle, 11, true)
	_style_button(_close)
	_close.text = "[CLOSE]"

func _style_button(btn: Button) -> void:
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	DoomTypography.stamp_happening(btn, 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.border_color = Color(1, 1, 1, 0.18)
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

func open_picker(venue: String, header: String, subtitle: String) -> void:
	_venue = venue
	_title.text = header
	_subtitle.text = subtitle
	for child in _list.get_children():
		child.queue_free()
	var stacks := GameState.inventory_stack_ids()
	if stacks.is_empty():
		var empty := Label.new()
		empty.text = "nothing to sell."
		DoomTypography.stamp_game(empty, 12, true)
		_list.add_child(empty)
	else:
		for stack in stacks:
			_list.add_child(_make_item_button(stack))
	visible = true

func close_picker() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _make_item_button(stack: Dictionary) -> Button:
	var btn := Button.new()
	var cid: String = str(stack.get("id", ""))
	var name: String = str(stack.get("name", cid))
	var count: int = int(stack.get("count", 1))
	var offer := GameState.pawn_offer(cid) if _venue == "pawn" else GameState.record_sell_offer(cid)
	var count_suffix := " x%d" % count if count > 1 else ""
	btn.text = "%s%s  $%d" % [name, count_suffix, offer]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	_style_button(btn)
	btn.pressed.connect(func() -> void:
		item_selected.emit(cid, _venue)
		close_picker()
	)
	return btn
