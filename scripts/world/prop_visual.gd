extends RefCounted
class_name PropVisual

static func apply(sprite: Sprite2D, body: CanvasItem, tag: Label, def: Dictionary) -> void:
	var size_arr: Array = def.get("size", [24, 24])
	var w := float(size_arr[0])
	var h := float(size_arr[1])
	var tex := SegmentLibrary.load_texture(str(def.get("texture", "")))
	if tex != null:
		body.visible = false
		tag.visible = false
		sprite.visible = true
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		var ts := tex.get_size()
		if ts.x > 0.0 and ts.y > 0.0:
			sprite.scale = Vector2(w / ts.x, h / ts.y)
		sprite.position = Vector2(-w * 0.5, -h)
		return
	sprite.visible = false
	body.visible = true
	tag.visible = true
	if body is Polygon2D:
		body.polygon = PackedVector2Array([
			Vector2(-w * 0.5, 0.0),
			Vector2(-w * 0.5, -h),
			Vector2(w * 0.5, -h),
			Vector2(w * 0.5, 0.0),
		])
		body.color = AlleyData.parse_color(def.get("color", [0.5, 0.5, 0.5, 1.0]))
	tag.text = def.get("label", "?")
