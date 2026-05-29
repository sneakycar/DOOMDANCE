extends Resource
class_name CorridorContext
## Drift modifiers — weights and tints hook here later (time, weather, mood, rep).

@export_range(0.0, 1.0) var time_of_day: float = 0.32
@export var weather: String = "rain"
@export_range(0.0, 1.0) var happiness: float = 0.5
@export_range(0.0, 1.0) var luck: float = 0.5
@export_range(0.0, 1.0) var neighborhood_reputation: float = 0.5

func get_type_weight_multiplier(_segment_type: StringName) -> float:
	# Future: e.g. auto_garage rarer at high rep, vacant_lot heavier when unhappy.
	return 1.0

func get_sky_top() -> Color:
	var night := 1.0 - time_of_day
	return Color(0.04 + night * 0.04, 0.05 + night * 0.05, 0.1 + night * 0.06, 1.0)

func get_sky_bottom() -> Color:
	return Color(0.1, 0.09, 0.14, 1.0)

func get_ground_color() -> Color:
	var wet := 1.15 if weather == "rain" else 1.0
	return Color(0.16 * wet, 0.17 * wet, 0.22 * wet, 1.0)

func get_ground_highlight() -> Color:
	return Color(0.26, 0.27, 0.34, 1.0)

func get_wall_brick() -> Color:
	return Color(0.28, 0.16, 0.18, 1.0)

func get_wall_dark() -> Color:
	return Color(0.12, 0.11, 0.16, 1.0)

func get_sodium() -> Color:
	return Color(0.78, 0.5, 0.28, 1.0)

func get_teal_glow() -> Color:
	return Color(0.28, 0.42, 0.52, 1.0)
