extends Control
## Full-screen dim + center caption while panhandling or watching a basement show.

@onready var _dim: ColorRect = $Dim
@onready var _label: Label = $Label

var _active := false
var _caption_base := "panhandling"
var _dot_phase := 0
var _dot_timer := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.color = Color(0.02, 0.03, 0.06, 0.68)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DoomTypography.stamp_fragment(_label, 34)
	_label.text = "panhandling."
	if not GameState.panhandle_changed.is_connected(_sync):
		GameState.panhandle_changed.connect(_sync)
	if not GameState.concert_changed.is_connected(_sync):
		GameState.concert_changed.connect(_sync)
	_sync()

func _exit_tree() -> void:
	if GameState.panhandle_changed.is_connected(_sync):
		GameState.panhandle_changed.disconnect(_sync)
	if GameState.concert_changed.is_connected(_sync):
		GameState.concert_changed.disconnect(_sync)

func bind_screen(screen_id: String) -> void:
	if not ScreenData.is_activity_site(screen_id):
		_force_hide()
	else:
		_sync()

func _sync() -> void:
	var should_show := GameState.is_panhandling_active() or GameState.is_concert_active()
	if should_show:
		_caption_base = "japan doll" if GameState.is_concert_active() else "panhandling"
	if should_show == _active and (not should_show or _label.text.begins_with(_caption_base)):
		return
	_active = should_show
	if should_show:
		_show()
	else:
		_hide()

func _show() -> void:
	_dot_phase = 0
	_dot_timer = 0.0
	_label.text = _caption_base + "."
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _hide() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func() -> void:
		if is_instance_valid(self) and not _active:
			visible = false
	)

func _force_hide() -> void:
	_active = false
	visible = false
	modulate.a = 0.0

func _process(delta: float) -> void:
	if not _active:
		return
	_dot_timer += delta
	if _dot_timer < 0.42:
		return
	_dot_timer = 0.0
	_dot_phase = (_dot_phase + 1) % 4
	var dots := ""
	for i in _dot_phase:
		dots += "."
	_label.text = _caption_base + dots
