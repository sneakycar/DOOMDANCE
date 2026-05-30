class_name RbdConstants
extends RefCounted

const WORLD_SIZE := 1024
const ORIGIN := Vector2i(512, 512)
const CELL_COUNT := WORLD_SIZE * WORLD_SIZE

const SAVE_PATH := "user://return_but_different.save"

const SECONDS_PER_DAY := 86400.0
const VISUAL_TICK_HZ := 30.0
const ACTIVE_STEPS_PER_SECOND := 8.0
const OFFLINE_MAX_STEPS := 120_000
const OFFLINE_SIGNIFICANCE := 0.08

const REGION_MIN_CELLS := 420
const REGION_SCAN_INTERVAL := 2.5
const EVENT_COOLDOWN_SEC := 45.0

const MEMORY_MIN_INTERVAL_SEC := 300.0
const MEMORY_MAX_INTERVAL_SEC := 1200.0
const MEMORY_OFFLINE_MAX := 5

const INFLUENCE_DURATION_SEC := 28.0
const INFLUENCE_RADIUS_CELLS := 36.0

enum InfluenceMode { ATTRACT, REPEL, BRIGHTEN, DARKEN }

const NAME_PARTS := {
	"color": ["WHITE", "BLUE", "LOW BLUE", "GRAY", "AMBER", "RUST", "PURPLE", "STATIC"],
	"place": ["CENTER", "EDGE", "BELT", "RIVER", "HOLLOW", "LIGHT", "RING", "FRONTIER"],
	"dir": ["NORTHERN", "SOUTHERN", "EASTERN", "WESTERN", "OUTSIDE"],
	"age": ["FIRST", "OLD", "NEW", "SECOND", "DEEP"],
}
