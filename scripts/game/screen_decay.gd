extends RefCounted
class_name ScreenDecay

static func tier_for(visits: int) -> int:
	if visits <= 1:
		return 0
	if visits <= 3:
		return 1
	if visits <= 6:
		return 2
	return 3

static func progress(visits: int) -> float:
	return clampf(float(visits - 1) / 9.0, 0.0, 1.0)

static func apply(parent: Control, background: CanvasItem, visits: int, size: Vector2) -> void:
	for child in parent.get_children():
		child.queue_free()
	if size.x < 2.0:
		size = parent.get_viewport_rect().size

	var tier := tier_for(visits)
	var t := progress(visits)

	background.modulate = Color(
		1.0 - t * 0.38,
		1.0 - t * 0.46,
		1.0 - t * 0.34,
		1.0
	)

	_vignette(parent, size, 0.1 + t * 0.52)
	if tier >= 1:
		_wash(parent, size, Color(0.34, 0.24, 0.14, 0.05 + t * 0.14))
	if tier >= 2:
		_grime_spots(parent, size, visits)
		_wash(parent, size, Color(0.12, 0.26, 0.14, 0.03 + t * 0.1))
	if tier >= 3:
		_crumble(parent, size, t)
		_flicker_blackout(parent, size)

static func status_line(visits: int) -> String:
	match tier_for(visits):
		0:
			return ""
		1:
			return "visit %d — the basement remembers you." % visits
		2:
			return "visit %d — something is rotting faster than it should." % visits
		_:
			return "visit %d — the room is eating itself." % visits

static func whisper(visits: int) -> String:
	if visits <= 1:
		return ""
	var lines := [
		"THE CONCRETE IS SOFTER THAN LAST TIME.",
		"THE BULB HUMS LIKE IT WANTS TO GO OUT.",
		"ATLANTIC CITY STAIN SPREADING IN THE CORNER.",
		"THE COUCH SAGS LOWER. THE SMELL STAYS.",
		"WATER IN THE WALLS. NOT FROM RAIN.",
		"THE RADIO KEEPS PLAYING THE SAME WRONG NAME.",
	]
	if visits >= 7:
		lines.append("YOU SHOULD NOT KEEP COMING BACK HERE.")
	if visits >= 10:
		lines.append("THE BASEMENT IS BECOMING A COPY OF A COPY.")
	return lines[(visits - 2) % lines.size()]

static func life_erosion(visits: int) -> float:
	if visits <= 6:
		return 0.0
	return -2.0 - float(min(visits - 7, 5))

static func _vignette(parent: Control, size: Vector2, strength: float) -> void:
	var edge := ColorRect.new()
	edge.name = "DecayVignette"
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge.offset_right = size.x
	edge.offset_bottom = size.y
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.color = Color(0.02, 0.01, 0.03, strength)
	parent.add_child(edge)

static func _wash(parent: Control, size: Vector2, tint: Color) -> void:
	var wash := ColorRect.new()
	wash.name = "DecayWash"
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.offset_right = size.x
	wash.offset_bottom = size.y
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = tint
	parent.add_child(wash)

static func _grime_spots(parent: Control, size: Vector2, visits: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(visits) + "grime")
	var count := mini(4 + visits / 2, 14)
	for i in count:
		var spot := ColorRect.new()
		spot.name = "Grime_%d" % i
		spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var w := rng.randf_range(size.x * 0.04, size.x * 0.16)
		var h := rng.randf_range(size.y * 0.02, size.y * 0.08)
		spot.size = Vector2(w, h)
		spot.position = Vector2(
			rng.randf_range(0.0, maxf(size.x - w, 1.0)),
			rng.randf_range(size.y * 0.2, maxf(size.y - h, 1.0))
		)
		spot.color = Color(0.08, 0.07, 0.06, rng.randf_range(0.18, 0.42))
		spot.rotation = rng.randf_range(-0.08, 0.08)
		parent.add_child(spot)

static func _crumble(parent: Control, size: Vector2, t: float) -> void:
	var scan := ColorRect.new()
	scan.name = "DecayScan"
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.offset_right = size.x
	scan.offset_bottom = size.y
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.color = Color(0.0, 0.0, 0.0, 0.04 + t * 0.06)
	parent.add_child(scan)
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in 6:
		var crack := ColorRect.new()
		crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crack.size = Vector2(rng.randf_range(2.0, 5.0), size.y * rng.randf_range(0.15, 0.55))
		crack.position = Vector2(rng.randf_range(0.0, size.x), rng.randf_range(size.y * 0.1, size.y * 0.75))
		crack.color = Color(0.0, 0.0, 0.0, rng.randf_range(0.12, 0.28))
		parent.add_child(crack)

static func _flicker_blackout(parent: Control, size: Vector2) -> void:
	var blackout := ColorRect.new()
	blackout.name = "DecayBlackout"
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.offset_right = size.x
	blackout.offset_bottom = size.y
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout.color = Color(0.0, 0.0, 0.0, 0.0)
	parent.add_child(blackout)
	var tween := blackout.create_tween().set_loops()
	tween.tween_interval(randf_range(2.8, 6.5))
	tween.tween_property(blackout, "color:a", randf_range(0.18, 0.38), 0.04)
	tween.tween_property(blackout, "color:a", 0.0, 0.12)
