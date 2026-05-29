extends Node
## Locked type system — field notes, receipts, signage.

const MONO_PATH := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const SIGNAGE_PATH := "res://assets/fonts/IBMPlexSansCondensed-Bold.ttf"

const COLOR_INK := Color(0.92, 0.9, 0.86, 1.0)
const COLOR_DIM := Color(0.62, 0.6, 0.56, 1.0)
const COLOR_SIGNAGE := Color(0.95, 0.93, 0.88, 1.0)
const COLOR_OBSERVATION := Color(0.88, 0.86, 0.82, 1.0)

var mono: Font
var signage: Font

func _ready() -> void:
	mono = load(MONO_PATH) as Font
	signage = load(SIGNAGE_PATH) as Font
	if mono == null:
		push_warning("Missing IBM Plex Mono at %s" % MONO_PATH)
	if signage == null:
		push_warning("Missing signage font at %s" % SIGNAGE_PATH)

func stamp_mono(control: Control, size: int = 12, dimmed: bool = false) -> void:
	if mono:
		control.add_theme_font_override("font", mono)
	control.add_theme_font_size_override("font_size", size)
	if control is Label:
		control.add_theme_color_override("font_color", COLOR_DIM if dimmed else COLOR_INK)

func stamp_signage(label: Label, size: int = 20) -> void:
	if signage:
		label.add_theme_font_override("font", signage)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", COLOR_SIGNAGE)
	label.uppercase = true

func stamp_observation(label: Label, size: int = 13) -> void:
	stamp_mono(label, size)
	label.add_theme_color_override("font_color", COLOR_OBSERVATION)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
		return CopyData.get("hud/inventory_empty", "—")
	var lines: PackedStringArray = []
	for item in items:
		lines.append(str(item).to_upper())
	return "\n".join(lines)

func format_item_label(item_name: String) -> String:
	return item_name.to_upper()

func header_for_screen(screen_id: String) -> String:
	var data := ScreenData.get_screen(screen_id)
	if data.has("header"):
		return str(data.get("header", "")).to_upper()
	return str(data.get("title", screen_id)).to_upper().replace("_", " ")
