class_name RbdWorldTexture
extends RefCounted

var image: Image
var texture: ImageTexture
var _update_stride := 4

func _init() -> void:
	image = Image.create(RbdConstants.WORLD_SIZE, RbdConstants.WORLD_SIZE, false, Image.FORMAT_RGB8)
	texture = ImageTexture.create_from_image(image)

func set_stride(stride: int) -> void:
	_update_stride = clampi(stride, 1, 16)

func refresh(world: RbdWorld, shimmer: float, full: bool = false) -> void:
	var w := RbdConstants.WORLD_SIZE
	var step := 1 if full else _update_stride
	for y in range(0, w, step):
		for x in range(0, w, step):
			var c := world.cell_color_at(x, y, shimmer)
			image.set_pixel(x, y, c)
			if step > 1:
				for oy in range(step):
					for ox in range(step):
						var px := mini(x + ox, w - 1)
						var py := mini(y + oy, w - 1)
						image.set_pixel(px, py, c)
	texture.update(image)
