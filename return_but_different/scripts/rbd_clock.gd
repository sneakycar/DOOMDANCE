class_name RbdClock
extends RefCounted
## Real-time historical clock — centisecond precision, persists with save.

var elapsed_sec: float = 0.0
var _accum_cs: float = 0.0

func tick(delta: float) -> void:
	elapsed_sec += delta
	_accum_cs += delta

func day_index() -> int:
	return int(floor(elapsed_sec / RbdConstants.SECONDS_PER_DAY)) + 1

func day_fraction() -> float:
	return fmod(elapsed_sec, RbdConstants.SECONDS_PER_DAY)

func format() -> String:
	var day := day_index()
	var frac := day_fraction()
	var h := int(frac / 3600.0)
	var m := int(fmod(frac, 3600.0) / 60.0)
	var s := int(fmod(frac, 60.0))
	var cs := int(fmod(frac * 100.0, 100.0))
	return "DAY %06d :: %02d:%02d:%02d.%02d" % [day, h, m, s, cs]

func day_label_for_stamp(stamp_sec: float) -> String:
	var day := int(floor(stamp_sec / RbdConstants.SECONDS_PER_DAY)) + 1
	return "DAY %06d" % day

func to_dict() -> Dictionary:
	return {"elapsed_sec": elapsed_sec}

func from_dict(data: Dictionary) -> void:
	elapsed_sec = float(data.get("elapsed_sec", 0.0))
	_accum_cs = 0.0
