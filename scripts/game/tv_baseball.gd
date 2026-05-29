extends Control
class_name TvBaseball
## Frozen CRT baseball broadcast — paused on a MAL night game.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	modulate = Color(0.88, 0.95, 0.86, 1.0)
	add_child(_make_field())
	add_child(_make_score_bug())
	add_child(_make_scanlines())

func _make_field() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grass := ColorRect.new()
	grass.color = Color(0.1, 0.32, 0.13, 1.0)
	grass.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(grass)
	var dirt := ColorRect.new()
	dirt.color = Color(0.4, 0.26, 0.14, 1.0)
	dirt.anchor_left = 0.26
	dirt.anchor_top = 0.5
	dirt.anchor_right = 0.74
	dirt.anchor_bottom = 0.94
	root.add_child(dirt)
	var line := ColorRect.new()
	line.color = Color(0.82, 0.82, 0.78, 0.85)
	line.anchor_left = 0.47
	line.anchor_top = 0.46
	line.anchor_right = 0.53
	line.anchor_bottom = 0.94
	root.add_child(line)
	var base := ColorRect.new()
	base.color = Color(0.9, 0.9, 0.86, 0.9)
	base.anchor_left = 0.49
	base.anchor_top = 0.76
	base.anchor_right = 0.51
	base.anchor_bottom = 0.8
	root.add_child(base)
	var batter := ColorRect.new()
	batter.color = Color(0.95, 0.92, 0.88, 1.0)
	batter.anchor_left = 0.45
	batter.anchor_top = 0.58
	batter.anchor_right = 0.48
	batter.anchor_bottom = 0.72
	root.add_child(batter)
	var pitcher := ColorRect.new()
	pitcher.color = Color(0.78, 0.8, 0.86, 1.0)
	pitcher.anchor_left = 0.52
	pitcher.anchor_top = 0.54
	pitcher.anchor_right = 0.55
	pitcher.anchor_bottom = 0.68
	root.add_child(pitcher)
	return root

func _make_score_bug() -> PanelContainer:
	var bug := PanelContainer.new()
	bug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bug.anchor_left = 0.04
	bug.anchor_top = 0.06
	bug.anchor_right = 0.44
	bug.anchor_bottom = 0.24
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.22, 0.88)
	style.border_color = Color(0.75, 0.75, 0.8, 0.6)
	style.set_border_width_all(1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	bug.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = "MAL  BOT 7\nGARY 3  DOON 2"
	lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	lbl.add_theme_font_size_override("font_size", 8)
	var font_path := "res://assets/fonts/PixelUni05.ttf"
	if ResourceLoader.exists(font_path):
		lbl.add_theme_font_override("font", load(font_path))
	bug.add_child(lbl)
	return bug

func _make_scanlines() -> ColorRect:
	var scan := ColorRect.new()
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.color = Color(0.0, 0.0, 0.0, 0.08)
	return scan
