extends Button
## Barely-visible mute — no game chrome.

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(36, 16)
	modulate = Color(1, 1, 1, 0.72)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	DoomTypography.stamp_fragment(self, 10)
	pressed.connect(_on_pressed)
	DoomMusic.mute_changed.connect(_on_mute_changed)
	_refresh(DoomMusic.is_muted())

func _on_pressed() -> void:
	DoomMusic.toggle_mute()
	if not DoomMusic.is_muted():
		DoomMusic.unlock()

func _on_mute_changed(muted: bool) -> void:
	_refresh(muted)

func _refresh(muted: bool) -> void:
	text = DoomTypography.symbol_mute_off() if muted else DoomTypography.symbol_mute_on()
	modulate = Color(1, 1, 1, 0.82 if muted else 0.95)
	tooltip_text = "unmute" if muted else "mute"
