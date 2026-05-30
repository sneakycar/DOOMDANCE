class_name RbdCameraRig
extends Node2D

@export var camera: Camera2D
@export var world_sprite: Sprite2D

const MIN_ZOOM := 0.35
const MAX_ZOOM := 90.0
const PINCH_SENS := 0.0045

var _dragging := false
var _last_drag: Vector2 = Vector2.ZERO
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
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		_handle_mouse(event)
	elif event is InputEventMouseMotion and _dragging:
		_pan_by(event.relative)

func _handle_touch(ev: InputEventScreenTouch) -> void:
	if ev.pressed:
		_touch_indices[ev.index] = ev.position
	else:
		_touch_indices.erase(ev.index)
	if _touch_indices.size() == 2:
		_start_pinch()
	elif _touch_indices.size() == 1:
		_dragging = true
		_last_drag = _touch_indices[_touch_indices.keys()[0]]
		_pinch_active = false
	else:
		_dragging = false
		_pinch_active = false

func _handle_drag(ev: InputEventScreenDrag) -> void:
	_touch_indices[ev.index] = ev.position
	if _touch_indices.size() >= 2:
		_update_pinch()
		return
	if _dragging:
		_pan_by(ev.relative)

func _handle_mouse(ev: InputEventMouseButton) -> void:
	if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_at(ev.position, 1.12)
	elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_at(ev.position, 0.9)
	elif ev.button_index == MOUSE_BUTTON_LEFT:
		_dragging = ev.pressed

func _start_pinch() -> void:
	var pts := _touch_indices.values()
	_pinch_start_dist = pts[0].distance_to(pts[1])
	_pinch_start_zoom = camera.zoom.x
	_pinch_active = true
	_dragging = false

func _update_pinch() -> void:
	if not _pinch_active or not camera:
		return
	var pts := _touch_indices.values()
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

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	if not camera:
		return
	var old_z := camera.zoom.x
	var new_z := clampf(old_z * factor, MIN_ZOOM, MAX_ZOOM)
	_set_zoom(new_z, screen_pos)

func _set_zoom(z: float, focal_screen: Vector2) -> void:
	z = clampf(z, MIN_ZOOM, MAX_ZOOM)
	if not camera:
		return
	var before := camera.get_global_transform().affine_inverse() * focal_screen
	camera.zoom = Vector2(z, z)
	var after := camera.get_global_transform().affine_inverse() * focal_screen
	camera.position += before - after

func focus_origin() -> void:
	if camera:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(4.0, 4.0)

func focus_world() -> void:
	if camera:
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(0.55, 0.55)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	if not camera:
		return Vector2.ZERO
	var xform := camera.get_global_transform().affine_inverse()
	return xform * screen_pos
