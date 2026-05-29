extends RefCounted
class_name HiddenMetrics
## Internal state — affects world but stays off the HUD.

static func clamp_metric(value: float) -> float:
	return clampf(value, 0.0, 100.0)

static func from_dict(data: Dictionary) -> Dictionary:
	return {
		"mood": clamp_metric(float(data.get("mood", 50.0))),
		"luck": clamp_metric(float(data.get("luck", 50.0))),
		"heat": clamp_metric(float(data.get("heat", 0.0))),
		"intoxication": clamp_metric(float(data.get("intoxication", 0.0))),
		"memory": clamp_metric(float(data.get("memory", 50.0))),
	}

static func to_dict(metrics: Dictionary) -> Dictionary:
	return {
		"mood": metrics.get("mood", 50.0),
		"luck": metrics.get("luck", 50.0),
		"heat": metrics.get("heat", 0.0),
		"intoxication": metrics.get("intoxication", 0.0),
		"memory": metrics.get("memory", 50.0),
	}
