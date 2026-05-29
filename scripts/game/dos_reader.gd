extends PanelContainer
class_name DosReader

signal closed

@onready var _title: Label = %TitleLabel
@onready var _title_bar: PanelContainer = $VBox/TitleBar
@onready var _client: PanelContainer = $VBox/Client
@onready var _scroll: ScrollContainer = %Scroll
@onready var _body: Label = %BodyText
@onready var _status: Label = %StatusLabel
@onready var _close: Button = %CloseButton

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	_apply_chrome()
	_close.pressed.connect(close_reader)
	_close.text = "Esc"
	_style_close()

func _apply_chrome() -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	outer.border_color = Color(0.12, 0.12, 0.12, 1.0)
	outer.set_border_width_all(2)
	outer.content_margin_left = 2
	outer.content_margin_right = 2
	outer.content_margin_top = 2
	outer.content_margin_bottom = 2
	add_theme_stylebox_override("panel", outer)
	var title_bar := StyleBoxFlat.new()
	title_bar.bg_color = Color(0.0, 0.0, 0.5, 1.0)
	title_bar.content_margin_left = 4
	title_bar.content_margin_top = 3
	title_bar.content_margin_bottom = 3
	_title_bar.add_theme_stylebox_override("panel", title_bar)
	var client := StyleBoxFlat.new()
	client.bg_color = Color(0.92, 0.92, 0.88, 1.0)
	client.border_color = Color(0.12, 0.12, 0.12, 1.0)
	client.set_border_width_all(1)
	client.content_margin_left = 8
	client.content_margin_right = 8
	client.content_margin_top = 8
	client.content_margin_bottom = 8
	_client.add_theme_stylebox_override("panel", client)
	var title_font := _mono_font()
	if title_font:
		_title.add_theme_font_override("font", title_font)
	_title.add_theme_font_size_override("font_size", 11)
	_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var body_font := _mono_font()
	if body_font:
		_body.add_theme_font_override("font", body_font)
	_body.add_theme_font_size_override("font_size", 11)
	_body.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1))
	_status.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	if body_font:
		_status.add_theme_font_override("font", body_font)
	_status.add_theme_font_size_override("font_size", 10)
	_status.text = "PgUp/PgDn scroll   Esc exit"

func _mono_font() -> Font:
	var path := "res://assets/fonts/PixelUni05.ttf"
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null

func _style_close() -> void:
	_close.flat = false
	_close.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	normal.border_color = Color(0.12, 0.12, 0.12, 1.0)
	normal.set_border_width_all(1)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	_close.add_theme_stylebox_override("normal", normal)
	_close.add_theme_stylebox_override("hover", normal)
	_close.add_theme_stylebox_override("pressed", normal)

func open_document(resource_path: String, window_title: String = "") -> void:
	var raw := DocumentData.load_text(resource_path)
	var title := window_title
	if title.is_empty():
		title = resource_path.get_file().to_upper()
	_title.text = "  %s" % title
	_body.text = DocumentData.markdown_to_dos(raw)
	_scroll.scroll_vertical = 0
	call_deferred("_fit_body_height")
	visible = true
	grab_focus()

func _fit_body_height() -> void:
	var width := maxf(240.0, _scroll.size.x - 12.0)
	_body.custom_minimum_size.x = width
	var font := _body.get_theme_font("font")
	var font_size := _body.get_theme_font_size("font_size")
	if font:
		var size := font.get_multiline_string_size(_body.text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 1.25)
		_body.custom_minimum_size.y = size.y + 8.0

func close_reader() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_reader()
			get_viewport().set_input_as_handled()
