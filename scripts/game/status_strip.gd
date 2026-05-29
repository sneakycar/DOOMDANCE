extends PanelContainer
## Always-visible money / life / time / XP strip (top of screen).

@onready var _money: Label = %MoneyLabel
@onready var _life_label: Label = %LifeLabel
@onready var _life_bar: ProgressBar = %LifeBar
@onready var _time: Label = %TimeLabel
@onready var _xp: Label = %XpLabel

func _ready() -> void:
	_apply_style()
	GameState.money_changed.connect(func(_v) -> void: _refresh_money())
	GameState.time_changed.connect(func(_v) -> void: _refresh_time())
	GameState.xp_changed.connect(func(_v) -> void: _refresh_xp())
	GameState.life_changed.connect(func(_v) -> void: _refresh_life())
	_refresh_all()

func _process(_delta: float) -> void:
	_refresh_xp()

func _apply_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0, 0, 0, 0.72)
	panel.set_content_margin_all(6)
	panel.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", panel)
	for lbl in [_money, _life_label, _time, _xp]:
		DoomTypography.stamp_mono(lbl, 10)
	_life_bar.max_value = GameState.MAX_LIFE
	_life_bar.show_percentage = false
	_life_bar.custom_minimum_size = Vector2(72, 10)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.1, 0.1, 0.95)
	track.set_corner_radius_all(1)
	_life_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.82, 0.38, 1.0)
	fill.set_corner_radius_all(1)
	_life_bar.add_theme_stylebox_override("fill", fill)

func _refresh_all() -> void:
	_refresh_money()
	_refresh_life()
	_refresh_time()
	_refresh_xp()

func _refresh_money() -> void:
	_money.text = GameState.money_display()

func _refresh_life() -> void:
	_life_bar.value = GameState.life
	_life_label.text = GameState.life_display()
	var ratio: float = GameState.life / GameState.MAX_LIFE
	var fill := _life_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		if ratio <= 0.2:
			fill.bg_color = Color(0.82, 0.12, 0.1, 1.0)
		elif ratio <= 0.45:
			fill.bg_color = Color(0.86, 0.55, 0.12, 1.0)
		else:
			fill.bg_color = Color(0.72, 0.82, 0.38, 1.0)

func _refresh_time() -> void:
	_time.text = GameState.time_display()

func _refresh_xp() -> void:
	_xp.text = DoomTypography.format_xp(GameState.xp)
