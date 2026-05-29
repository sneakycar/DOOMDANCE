extends RefCounted
class_name TimeSchedule

static func npcs_active(phase: GameClock.TimePhase) -> bool:
	return phase in [
		GameClock.TimePhase.LATE_NIGHT,
		GameClock.TimePhase.DAWN,
		GameClock.TimePhase.MORNING,
		GameClock.TimePhase.AFTERNOON,
		GameClock.TimePhase.EVENING,
	]

static func street_object_active(object_id: StringName, phase: GameClock.TimePhase) -> bool:
	return AlleyContent.item_spawn_active(object_id, phase)

static func segment_props_active(_phase: GameClock.TimePhase) -> bool:
	return true
