extends RefCounted
class_name ScreenOverlays
## Subtle looping overlays — no character animation.

static func build(parent: Control, effect_names: Array, size: Vector2, extras: Dictionary = {}) -> void:
	for child in parent.get_children():
		child.queue_free()
	if size.x < 2.0:
		size = parent.get_viewport_rect().size
	for effect_name in effect_names:
		var node := _make_effect(str(effect_name), size, extras)
		if node:
			parent.add_child(node)

static func _make_effect(name: String, size: Vector2, extras: Dictionary = {}) -> Node:
	match name:
		"rain":
			return _rain(size)
		"light_flicker":
			return _light_flicker(size, Color(1.0, 0.82, 0.55, 0.07), 1.4)
		"puddle_shimmer":
			return _puddle_shimmer(size)
		"smoke", "steam":
			return _steam(size)
		"drifting_trash", "wind_trash":
			return _drifting_trash(size)
		"distant_light_sweep", "distant_light":
			return _light_sweep(size)
		"fluorescent_flicker":
			return _light_flicker(size, Color(0.75, 0.95, 1.0, 0.09), 0.35)
		"neon_buzz":
			return _neon_buzz(size)
		"lamp_buzz":
			return _lamp_buzz(size, extras.get("lamp_spots", []))
		"train_flash", "passing_train_flash":
			return _train_flash(size)
		_:
			return null

static func _rain(size: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "Rain"
	var drops := CPUParticles2D.new()
	drops.emitting = true
	drops.amount = 48
	drops.lifetime = 0.9
	drops.preprocess = 0.5
	drops.speed_scale = 1.1
	drops.direction = Vector2(0.15, 1)
	drops.spread = 8.0
	drops.gravity = Vector2(0, 420)
	drops.initial_velocity_min = 180.0
	drops.initial_velocity_max = 260.0
	drops.scale_amount_min = 1.0
	drops.scale_amount_max = 2.0
	drops.color = Color(0.7, 0.78, 0.9, 0.22)
	drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drops.emission_rect_extents = Vector2(size.x * 0.5, 8.0)
	drops.position = Vector2(size.x * 0.5, -8.0)
	root.add_child(drops)
	return root

static func _light_flicker(size: Vector2, tint: Color, interval: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "LightFlicker"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_right = size.x
	rect.offset_bottom = size.y
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = tint
	var tween := rect.create_tween().set_loops()
	tween.tween_property(rect, "modulate:a", 0.35, interval * 0.45)
	tween.tween_property(rect, "modulate:a", 1.0, interval * 0.55)
	return rect

static func _puddle_shimmer(size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "PuddleShimmer"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(0.0, size.y * 0.72)
	rect.size = Vector2(size.x, size.y * 0.22)
	rect.color = Color(0.55, 0.65, 0.85, 0.06)
	var tween := rect.create_tween().set_loops()
	tween.tween_property(rect, "color:a", 0.03, 1.1)
	tween.tween_property(rect, "color:a", 0.1, 1.3)
	return rect

static func _steam(size: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "Steam"
	var p := CPUParticles2D.new()
	p.emitting = true
	p.amount = 10
	p.lifetime = 2.4
	p.direction = Vector2(0, -1)
	p.spread = 18.0
	p.gravity = Vector2(-8, -30)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 28.0
	p.color = Color(0.85, 0.85, 0.9, 0.12)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40.0, 6.0)
	p.position = Vector2(size.x * 0.18, size.y * 0.55)
	root.add_child(p)
	return root

static func _drifting_trash(size: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "DriftingTrash"
	var piece := ColorRect.new()
	piece.size = Vector2(10.0, 5.0)
	piece.color = Color(0.35, 0.32, 0.3, 0.45)
	piece.position = Vector2(size.x * 0.4, size.y * 0.82)
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(piece)
	var tween := piece.create_tween().set_loops()
	tween.tween_property(piece, "position:x", size.x * 0.55, 4.5)
	tween.tween_property(piece, "position:x", size.x * 0.35, 4.5)
	return root

static func _light_sweep(size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "LightSweep"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(48.0, size.y * 0.35)
	rect.position = Vector2(-60.0, size.y * 0.25)
	rect.color = Color(1.0, 0.9, 0.6, 0.05)
	var tween := rect.create_tween().set_loops()
	tween.tween_property(rect, "position:x", size.x + 20.0, 7.0)
	tween.tween_property(rect, "position:x", -60.0, 0.01)
	return rect

static func _neon_buzz(size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "NeonBuzz"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_right = size.x
	rect.offset_bottom = size.y
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.9, 0.2, 0.55, 0.04)
	var tween := rect.create_tween().set_loops()
	tween.tween_property(rect, "modulate", Color(0.85, 0.25, 0.7, 1.0), 0.18)
	tween.tween_property(rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
	return rect

static func _lamp_buzz(size: Vector2, spots: Array) -> Control:
	var root := Control.new()
	root.name = "LampBuzz"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_right = size.x
	root.offset_bottom = size.y
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if spots.is_empty():
		spots = [
			{"rect": [0.04, 0.06, 0.16, 0.22]},
			{"rect": [0.64, 0.06, 0.14, 0.18]},
		]
	var flicker_script: Script = load("res://scripts/game/lamp_flicker.gd")
	for i in spots.size():
		var spot: Dictionary = spots[i]
		var rect_norm: Array = spot.get("rect", [0.0, 0.0, 0.1, 0.1])
		var glow := ColorRect.new()
		glow.set_script(flicker_script)
		glow.set("buzz_seed", float(i) * 0.37)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.position = Vector2(rect_norm[0], rect_norm[1]) * size
		glow.size = Vector2(rect_norm[2], rect_norm[3]) * size
		var tint: Variant = spot.get("color", Color(1.0, 0.78, 0.42, 0.34))
		if tint is Array and tint.size() >= 4:
			glow.color = Color(float(tint[0]), float(tint[1]), float(tint[2]), float(tint[3]))
		elif tint is Color:
			glow.color = tint
		else:
			glow.color = Color(1.0, 0.78, 0.42, 0.34)
		root.add_child(glow)
	return root

static func _train_flash(size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "TrainFlash"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_right = size.x
	rect.offset_bottom = size.y
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 0.0)
	var tween := rect.create_tween().set_loops()
	tween.tween_interval(5.5)
	tween.tween_property(rect, "color:a", 0.14, 0.06)
	tween.tween_property(rect, "color:a", 0.0, 0.25)
	return rect
