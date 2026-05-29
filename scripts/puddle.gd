extends Node2D

@export var shimmer_speed := 1.4
@export var shimmer_amount := 0.06

@onready var surface: ColorRect = $Surface
@onready var highlight: ColorRect = $Highlight

var _phase := 0.0

func _ready() -> void:
	_phase = randf() * TAU

func _process(delta: float) -> void:
	_phase += delta * shimmer_speed
	var pulse := sin(_phase) * shimmer_amount
	surface.modulate.a = 0.55 + pulse
	highlight.position.x = sin(_phase * 0.7) * 8.0
