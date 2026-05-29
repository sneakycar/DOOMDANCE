extends Node
class_name GameClock

enum Phase { NIGHT, DAWN, MORNING, AFTERNOON, EVENING }
## Legacy name used by first-alley scripts (`LATE_NIGHT` = `NIGHT`).
enum TimePhase { LATE_NIGHT = 0, DAWN = 1, MORNING = 2, AFTERNOON = 3, EVENING = 4 }

signal phase_changed(phase: Phase, phase_name: String)

@export var seconds_per_phase := 90.0
@export var start_phase: Phase = Phase.EVENING
@export var alley_state: AlleyState

var phase: Phase = Phase.NIGHT
var _elapsed := 0.0

func _ready() -> void:
	add_to_group("game_clock")
	phase = start_phase
	_sync_state()
	phase_changed.emit(phase, phase_name())

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= seconds_per_phase:
		_elapsed = 0.0
		advance_phase()

func advance_phase() -> void:
	phase = ((int(phase) + 1) % 5) as Phase
	_sync_state()
	phase_changed.emit(phase, phase_name())

func _sync_state() -> void:
	if alley_state:
		alley_state.current_phase = phase

func phase_name() -> String:
	match phase:
		Phase.DAWN:
			return "Dawn"
		Phase.MORNING:
			return "Morning"
		Phase.AFTERNOON:
			return "Afternoon"
		Phase.EVENING:
			return "Evening"
		_:
			return "Late Night"

func phase_progress() -> float:
	return clampf(_elapsed / maxf(seconds_per_phase, 0.01), 0.0, 1.0)
