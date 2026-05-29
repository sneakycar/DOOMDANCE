extends Node
## Pixel Uni 05 — all in-game UI. Neue Haas Display — scene transitions only. Symbola — icons.

const GAME_PATH := "res://assets/fonts/PixelUni05.ttf"
const TRANSITION_PATH := "res://assets/fonts/NeueHaasGrotDisp-95Black.otf"
const SYMBOL_PATH := "res://assets/fonts/Symbola.ttf"

const COLOR_INK := Color(0.92, 0.9, 0.86, 1.0)
const COLOR_DIM := Color(0.62, 0.6, 0.56, 1.0)
const COLOR_OBSERVATION := Color(0.88, 0.86, 0.82, 1.0)
const COLOR_SYMBOL := Color(0.92, 0.9, 0.86, 0.55)
const COLOR_FRAGMENT := Color(0.78, 0.76, 0.72, 0.92)
const COLOR_TRANSITION := Color(0.95, 0.93, 0.88, 1.0)

var game: Font
var transition: Font
var symbol: Font

func _ready() -> void:
	game = _load_font(GAME_PATH, "Pixel Uni 05")
	transition = _load_font(TRANSITION_PATH, "Neue Haas Grotesk Display Black")
	symbol = _load_font(SYMBOL_PATH, "Symbola")

func _load_font(path: String, label: String) -> Font:
	var font := load(path) as Font
	if font == null:
		push_warning("Missing %s at %s" % [label, path])
	return font

func stamp_game(control: Control, size: int = 12, dimmed: bool = false) -> void:
	if game:
		control.add_theme_font_override("font", game)
	control.add_theme_font_size_override("font_size", size)
	var color := COLOR_DIM if dimmed else COLOR_INK
	if control is Label:
		control.add_theme_color_override("font_color", color)
	elif control is Button:
		control.add_theme_color_override("font_color", color)

func stamp_happening(control: Control, size: int = 12) -> void:
	if game:
		control.add_theme_font_override("font", game)
	control.add_theme_font_size_override("font_size", size)
	if control is Label:
		control.add_theme_color_override("font_color", COLOR_OBSERVATION)
	elif control is Button:
		control.add_theme_color_override("font_color", COLOR_OBSERVATION)

func stamp_fragment(control: Control, size: int = 12) -> void:
	if game:
		control.add_theme_font_override("font", game)
	control.add_theme_font_size_override("font_size", size)
	if control is Label:
		control.add_theme_color_override("font_color", COLOR_FRAGMENT)
		control.uppercase = false
	elif control is Button:
		control.add_theme_color_override("font_color", COLOR_FRAGMENT)

func as_fragment(text: String) -> String:
	return text.strip_edges().to_lower()

func stamp_transition(label: Label, size: int = 28) -> void:
	if transition:
		label.add_theme_font_override("font", transition)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", COLOR_TRANSITION)
	label.uppercase = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func stamp_symbol(control: Control, size: int = 14) -> void:
	if symbol:
		control.add_theme_font_override("font", symbol)
	control.add_theme_font_size_override("font_size", size)
	if control is Label or control is Button:
		control.add_theme_color_override("font_color", COLOR_SYMBOL)
		control.add_theme_color_override("font_hover_color", Color(0.95, 0.93, 0.88, 0.82))
		control.add_theme_color_override("font_pressed_color", COLOR_DIM)

func stamp_mono(control: Control, size: int = 12, dimmed: bool = false) -> void:
	stamp_game(control, size, dimmed)

func stamp_location(label: Label, size: int = 12) -> void:
	stamp_game(label, size)
	label.uppercase = true

func stamp_observation(label: Label, size: int = 13) -> void:
	stamp_happening(label, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func stamp_signage(label: Label, size: int = 20) -> void:
	stamp_transition(label, size)

func format_money(amount: int) -> String:
	return "$%d.00" % amount

func format_time(clock_minutes: int) -> String:
	var h24: int = (clock_minutes / 60) % 24
	var m: int = clock_minutes % 60
	var suffix := "AM" if h24 < 12 else "PM"
	var h12: int = h24 % 12
	if h12 == 0:
		h12 = 12
	return "%02d:%02d %s" % [h12, m, suffix]

func format_inventory(items: Array) -> String:
	if items.is_empty():
		return CopyData.lookup("hud/inventory_empty", "—")
	var lines: PackedStringArray = []
	for item in items:
		lines.append(str(item).to_upper())
	return "\n".join(lines)

func format_item_label(item_name: String) -> String:
	return item_name.to_upper()

func format_xp(value: float) -> String:
	if value < 1000.0:
		if is_equal_approx(value, floor(value)):
			return "XP %d" % int(value)
		return "XP %.2f" % value
	if value >= 10000.0:
		var whole_k := int(round(value / 1000.0))
		if is_equal_approx(value, float(whole_k * 1000)):
			return "XP %dk" % whole_k
	var k: float = round(value / 100.0) / 10.0
	if is_equal_approx(k, floor(k)):
		return "XP %dk" % int(k)
	return "XP %.1fk" % k

func header_for_screen(screen_id: String) -> String:
	var data := ScreenData.get_screen(screen_id)
	if data.has("header"):
		return str(data.get("header", "")).to_upper()
	return str(data.get("title", screen_id)).to_upper().replace("_", " ")

func transition_for_screen(screen_id: String) -> String:
	var data := ScreenData.get_screen(screen_id)
	if data.has("transition_title"):
		return str(data.get("transition_title", "")).to_upper()
	return header_for_screen(screen_id)

func symbol_mute_on() -> String:
	return char(0x1F50A)

func symbol_mute_off() -> String:
	return char(0x1F507)
