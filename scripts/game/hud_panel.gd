extends PanelContainer
## Permanent lower-left receipt HUD — artwork stays dominant.

const STRIP_WIDTH := 118.0
const MAX_PREVIEW_ITEMS := 4
const OVERFLOW_THRESHOLD := 5

@onready var _money: Label = %MoneyLabel
@onready var _time: Label = %TimeLabel
@onready var _panhandle: Label = %PanhandleLabel
@onready var _xp: Label = %XpLabel
@onready var _inv_btn: Button = %InventoryButton
@onready var _preview: VBoxContainer = %InventoryPreview
@onready var _collections_btn: Button = %CollectionsButton

signal inventory_requested
signal collections_requested

func _ready() -> void:
	_apply_style()
	_apply_typography()
	_inv_btn.pressed.connect(func() -> void: inventory_requested.emit())
	_collections_btn.pressed.connect(func() -> void: collections_requested.emit())
	_collections_btn.visible = false
	GameState.money_changed.connect(func(_v) -> void: _refresh_money())
	GameState.time_changed.connect(func(_v) -> void: _refresh_time())
	GameState.inventory_changed.connect(func(_v) -> void: _refresh_inventory())
	GameState.xp_changed.connect(func(_v) -> void: _refresh_xp())
	GameState.panhandle_changed.connect(func() -> void: _refresh_panhandle())
	GameState.concert_changed.connect(func() -> void: _refresh_panhandle())
	resized.connect(_clamp_width)
	get_viewport().size_changed.connect(_clamp_width)
	_refresh_all()

func _process(_delta: float) -> void:
	_refresh_xp()
	if GameState.is_panhandling_active() or GameState.is_concert_active():
		_refresh_panhandle()

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0, 0, 0, 0.62)
	panel.set_content_margin_all(8)
	panel.set_corner_radius_all(1)
	add_theme_stylebox_override("panel", panel)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_text_button(_inv_btn)
	_style_text_button(_collections_btn)

func _apply_typography() -> void:
	DoomTypography.stamp_mono(_money, 12)
	DoomTypography.stamp_mono(_time, 11, true)
	DoomTypography.stamp_mono(_panhandle, 11)
	DoomTypography.stamp_mono(_xp, 11, true)
	for btn in [_inv_btn, _collections_btn]:
		btn.add_theme_font_override("font", DoomTypography.game)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", DoomTypography.COLOR_INK)
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", DoomTypography.COLOR_DIM)

func _style_text_button(btn: Button) -> void:
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 18)
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)

func _clamp_width() -> void:
	custom_minimum_size.x = STRIP_WIDTH
	offset_left = 0.0

func _refresh_all() -> void:
	_refresh_money()
	_refresh_time()
	_refresh_panhandle()
	_refresh_xp()
	_refresh_inventory()

func _refresh_panhandle() -> void:
	var line := GameState.activity_hud_line()
	_panhandle.visible = not line.is_empty()
	_panhandle.text = line

func _refresh_money() -> void:
	_money.text = GameState.money_display()

func _refresh_time() -> void:
	_time.text = GameState.time_display()

func _refresh_xp() -> void:
	_xp.text = DoomTypography.format_xp(GameState.xp)

func _refresh_inventory() -> void:
	for child in _preview.get_children():
		child.queue_free()
	var items: Array = GameState.inventory
	if items.is_empty():
		return
	var show_count := items.size()
	var overflow := 0
	if show_count > OVERFLOW_THRESHOLD:
		show_count = MAX_PREVIEW_ITEMS
		overflow = items.size() - MAX_PREVIEW_ITEMS
	for i in show_count:
		_preview.add_child(_item_label(str(items[i])))
	if overflow > 0:
		_preview.add_child(_item_label("+%d MORE" % overflow, true))

func set_collections_unlocked(unlocked: bool) -> void:
	_collections_btn.visible = unlocked

func _item_label(text: String, dimmed: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = DoomTypography.format_item_label(text)
	DoomTypography.stamp_mono(lbl, 10, dimmed)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl
