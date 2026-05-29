extends ColorRect
## Dying sodium lamp — irregular buzz, brief brownouts.

@export var buzz_seed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.75
	_buzz_step()

func _buzz_step() -> void:
	if not is_inside_tree():
		return
	var roll := randf()
	var tween := create_tween()
	if roll < 0.28:
		tween.tween_property(self, "modulate:a", 0.04, 0.05 + randf() * 0.04)
		tween.tween_property(self, "modulate:a", 0.55 + randf() * 0.25, 0.14 + buzz_seed * 0.05)
	elif roll < 0.55:
		tween.tween_property(self, "modulate:a", 0.18, 0.02)
		tween.tween_property(self, "modulate:a", 0.92, 0.03)
		tween.tween_property(self, "modulate:a", 0.42, 0.04)
		tween.tween_property(self, "modulate:a", 0.78, 0.06)
	else:
		tween.tween_property(self, "modulate:a", 0.35 + randf() * 0.2, 0.04 + randf() * 0.06)
		tween.tween_property(self, "modulate:a", 0.88 + randf() * 0.1, 0.05)
	tween.tween_interval(0.08 + randf() * 0.35 + buzz_seed * 0.08)
	tween.finished.connect(_buzz_step)
