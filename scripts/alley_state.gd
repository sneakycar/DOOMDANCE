extends Resource
class_name AlleyState

@export_range(0.0, 1.0) var luck := 0.5
@export_range(0.0, 1.0) var happiness := 0.5

var current_phase: int = 0

func get_phase() -> int:
	return current_phase

func prop_spawn_chance() -> float:
	return clampf(0.65 + luck * 0.25 + (1.0 - happiness) * 0.1, 0.45, 0.98)

func get_scene_modulate() -> Color:
	var night := 1.0
	match current_phase:
		GameClock.Phase.MORNING, GameClock.Phase.AFTERNOON:
			night = 0.35
		GameClock.Phase.DAWN, GameClock.Phase.EVENING:
			night = 0.65
		_:
			night = 1.0
	return Color(1.0, 1.0, 1.0, 1.0).darkened(night * 0.28)

func get_state_hash() -> int:
	return hash(Vector2(luck, float(current_phase)))
