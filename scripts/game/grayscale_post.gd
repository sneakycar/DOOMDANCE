extends CanvasLayer
## Full-viewport desaturation — used after THE END (100% rooms visited).

func _ready() -> void:
	visible = GameState.is_the_end_active()
	if not GameState.the_end_changed.is_connected(_on_the_end_changed):
		GameState.the_end_changed.connect(_on_the_end_changed)

func _on_the_end_changed(active: bool) -> void:
	visible = active
