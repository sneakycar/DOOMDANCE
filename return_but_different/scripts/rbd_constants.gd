class_name RbdConstants
extends RefCounted

const WORLD_SIZE := 1024
const ORIGIN := Vector2i(512, 512)
const CELL_COUNT := WORLD_SIZE * WORLD_SIZE

const SAVE_PATH := "user://return_but_different.save"

## 15 real minutes = one in-game day (playable on phone; was 24h).
const SECONDS_PER_DAY := 900.0
const OFFLINE_MAX_STEPS := 2400
const OFFLINE_STEPS_PER_FRAME := 40
const MAX_SIM_STEPS_PER_FRAME := 2
const OFFLINE_SIGNIFICANCE := 0.08

const REGION_MIN_CELLS := 420
const REGION_SCAN_INTERVAL := 3.5
const EVENT_COOLDOWN_SEC := 45.0

const MEMORY_MIN_INTERVAL_SEC := 300.0
const MEMORY_MAX_INTERVAL_SEC := 1200.0
const MEMORY_OFFLINE_MAX := 5

const INFLUENCE_DURATION_SEC := 28.0
const INFLUENCE_RADIUS_CELLS := 36.0

enum InfluenceMode { ATTRACT, REPEL, BRIGHTEN, DARKEN }

static func is_phone_profile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web")

static func active_steps_per_second() -> float:
	return 2.0 if is_phone_profile() else 5.0

static func visual_tick_hz() -> float:
	return 10.0 if is_phone_profile() else 20.0

static func visual_stride_for_zoom(zoom: float) -> int:
	if zoom < 1.2:
		return 8
	if zoom < 3.5:
		return 4
	return 2
