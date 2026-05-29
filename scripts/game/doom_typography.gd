extends Node
## Locked type system — receipt HUD, location card, happenings, symbols.

const MONO_PATH := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const PIXEL_PATH := "res://assets/fonts/PixelOperator.ttf"
const LOCATION_PATH := "res://assets/fonts/NeueHaasGrotDisp-95Black.otf"
const SYMBOL_PATH := "res://assets/fonts/Symbola.ttf"

const COLOR_INK := Color(0.92, 0.9, 0.86, 1.0)
const COLOR_DIM := Color(0.62, 0.6, 0.56, 1.0)
const COLOR_SIGNAGE := Color(0.95, 0.93, 0.88, 1.0)
const COLOR_OBSERVATION := Color(0.88, 0.86, 0.82, 1.0)
const COLOR_SYMBOL := Color(0.92, 0.9, 0.86, 0.55)

var mono: Font
var pixel: Font
var location: Font
var symbol: Font

func _ready() -> void:
	mono = _load_font(MONO_PATH, "IBM Plex Mono")
	pixel = _load_font(PIXEL_PATH, "Pixel Operator")
	location = _load_font(LOCATION_PATH, "Neue Haas Grotesk Display Black")
	symbol = _load_font(SYMBOL_PATH, "Symbola")

func _load_font(path: String, label: String) -> Font:
	var font := load(path) as Font
	if font == null:
		push_warning("Missing %s at %s" % [label, path])
	return font

func stamp_mono(control: Control, size: int = 12, dimmed: bool = false) -> void:
	if mono:
		control.add_theme_font_override("font", mono)
	control.add_theme_font_size_override("font_size", size)
	if control is Label:
		control.add_theme_color_override("font_color", COLOR_DIM if dimmed else COLOR_INK)
	elif control is Button:
		control.add_theme_color_override("font_color", COLOR_DIM if dimmed else COLOR_INK)

func stamp_happening(control: Control, size: int = 12) -> void:
	if pixel:
		control.add_theme_font_override("font", pixel)
	control.add_theme_font_size_override("font_size", size)
	if control is Label:
		control.add_theme_color_override("font_color", COLOR_OBSERVATION)
	elif control is Button:
		control.add_theme_color_override("font_color", COLOR_OBSERVATION)

func stamp_location(label: Label, size: int = 13) -> void:
	if location:
		label.add_theme_font_override("font", location)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(COLOR_SIGNAGE.r, COLOR_SIGNAGE.g, COLOR_SIGNAGE.b, 0.85))
	label.uppercase = true

func stamp_symbol(control: Control, size: int = 14) -> void:
	if symbol:
		control.add_theme_font_override("font", symbol)
	control.add_theme_font_size_override("font_size", size)
	if control is Label or control is Button:
		control.add_theme_color_override("font_color", COLOR_SYMBOL)
		control.add_theme_color_override("font_hover_color", Color(0.95, 0.93, 0.88, 0.82))
		control.add_theme_color_override("font_pressed_color", COLOR_DIM)

func stamp_observation(label: Label, size: int = 13) -> void:
	stamp_happening(label, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func stamp_signage(label: Label, size: int = 20) -> void:
	stamp_location(label, size)

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
	var k := round(value / 100.0) / 10.0
	if is_equal_approx(k, floor(k)):
		return "XP %dk" % int(k)
	return "XP %.1fk" % k

func header_for_screen(screen_id: String) -> String:
	var data := ScreenData.get_screen(screen_id)
	if data.has("header"):
		return str(data.get("header", "")).to_upper()
	return str(data.get("title", screen_id)).to_upper().replace("_", " ")

func symbol_mute_on() -> String:
	return char(0x1F50A)

func symbol_mute_off() -> String:
	return char(0x1F507)
