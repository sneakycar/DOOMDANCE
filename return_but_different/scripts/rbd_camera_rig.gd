class_name RbdCameraRig
extends Node2D

@export var camera: Camera2D
@export var world_sprite: Sprite2D

const MIN_ZOOM := 0.35
const MAX_ZOOM := 90.0

var _dragging := false
var _pinch_active := false
var _pinch_start_dist := 0.0
var _pinch_start_zoom := 1.0
var _touch_indices: Dictionary = {}

func _ready() -> void:
	if camera:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(0.55, 0.55)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _viewport_pixel(event_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return event_pos
	return vp.canvas_transform.affine_inverse() * event_pos

func _handle_touch(ev: InputEventScreenTouch) -> void:
	var pos := _viewport_pixel(ev.position)
	if ev.pressed:
		_touch_indices[ev.index] = pos
	else:
		_touch_indices.erase(ev.index)
	if _touch_indices.size() == 2:
		_start_pinch()
	elif _touch_indices.size() == 1:
		_dragging = true
		_pinch_active = false
	else:
		_dragging = false
		_pinch_active = false

func _handle_drag(ev: InputEventScreenDrag) -> void:
	var pos := _viewport_pixel(ev.position)
	_touch_indices[ev.index] = pos
	if _touch_indices.size() >= 2:
		_update_pinch()
		return
	if _dragging:
		_pan_by(ev.relative)

func _start_pinch() -> void:
	var pts: Array = _touch_indices.values()
	_pinch_start_dist = pts[0].distance_to(pts[1])
	_pinch_start_zoom = camera.zoom.x
	_pinch_active = true
	_dragging = false

func _update_pinch() -> void:
	if not _pinch_active or not camera:
		return
	var pts: Array = _touch_indices.values()
	if pts.size() < 2:
		return
	var dist := pts[0].distance_to(pts[1])
	if _pinch_start_dist < 1.0:
		return
	var ratio := dist / _pinch_start_dist
	var mid := (pts[0] + pts[1]) * 0.5
	_set_zoom(_pinch_start_zoom * ratio, mid)

func _pan_by(delta: Vector2) -> void:
	if not camera:
		return
	camera.position -= delta / camera.zoom

func _set_zoom(z: float, focal_vp: Vector2) -> void:
	z = clampf(z, MIN_ZOOM, MAX_ZOOM)
	if not camera:
		return
	var inv := camera.get_canvas_transform().affine_inverse()
	var before := inv * focal_vp
	camera.zoom = Vector2(z, z)
	var after := inv * focal_vp
	camera.position += before - after

func focus_origin() -> void:
	if camera:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(4.0, 4.0)

func focus_world() -> void:
	if camera:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(0.55, 0.55)

func viewport_position_to_cell(vp_pixel: Vector2) -> Vector2i:
	if not camera:
		return RbdConstants.ORIGIN
	var world_pos := camera.get_canvas_transform().affine_inverse() * vp_pixel
	var half := float(RbdConstants.WORLD_SIZE) * 0.5
	return Vector2i(
		clampi(int(world_pos.x + half), 0, RbdConstants.WORLD_SIZE - 1),
		clampi(int(world_pos.y + half), 0, RbdConstants.WORLD_SIZE - 1)
	)
