extends RefCounted
class_name SegmentLibrary

enum BackdropMode { PAINTED, ABANDON_CITY, TILED }

const SEGMENT_W := 480
const SEGMENT_H := 270
const FLOOR_Y := 228.0
const SKY_H := 96.0
const WALL_TOP := 88.0
const SIDEWALK_TOP := 204.0

const TILE_W := 64

## Painted 480x270 slices from your Leonardo panos (recommended).
const BACKDROP_MODE := BackdropMode.PAINTED

const PAINTED_NIGHT_DIR := "res://assets/segments/painted/night/"
const PAINTED_DAY_DIR := "res://assets/segments/painted/day/"

const BACKDROP_COUNT := 8

const WALL_TEX := preload("res://assets/tiles/wall_tile.png")
const SIDEWALK_TEX := preload("res://assets/tiles/sidewalk_tile.png")
const SKY_TEX := preload("res://assets/tiles/sky_strip.png")
const BUILDINGS_TEX := preload("res://assets/tiles/far_buildings.png")
const STREET_TEX := preload("res://assets/tiles/street_tile.png")

const SEGMENT_NAMES: PackedStringArray = [
	"Alley",
	"Back Street",
	"Garage Row",
	"Fence Line",
	"Vacant Block",
	"Loading Bay",
	"Graffiti Cut",
	"Underpass",
	"Bodega Wall",
	"Dead End",
]

static func name_for_index(index: int) -> String:
	return SEGMENT_NAMES[absi(index) % SEGMENT_NAMES.size()]

static func painted_dir_for_phase(phase: int) -> String:
	match phase:
		GameClock.Phase.MORNING, GameClock.Phase.AFTERNOON:
			if _res_dir_has_png(PAINTED_DAY_DIR):
				return PAINTED_DAY_DIR
		_:
			pass
	return PAINTED_NIGHT_DIR

static func _res_dir_has_png(res_dir: String) -> bool:
	if DirAccess.open(res_dir) == null:
		return false
	for file_name in DirAccess.get_files_at(res_dir):
		if file_name.ends_with(".png"):
			return true
	return false

static func backdrop_for_index(index: int) -> Texture2D:
	var slot := absi(index * 3 + int(index / 4)) % BACKDROP_COUNT
	return load("res://assets/abandon_city/backdrops/segment_%02d.png" % slot) as Texture2D

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
