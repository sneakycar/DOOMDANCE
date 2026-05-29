extends RefCounted
class_name TimeSchedule

static func npcs_active(phase: int) -> bool:
	return phase in [
		GameClock.Phase.NIGHT,
		GameClock.Phase.DAWN,
		GameClock.Phase.MORNING,
		GameClock.Phase.AFTERNOON,
		GameClock.Phase.EVENING,
	]

static func street_object_active(object_id: StringName, phase: int) -> bool:
	return AlleyContent.item_spawn_active(object_id, phase)

static func segment_props_active(_phase: int) -> bool:
	return true
