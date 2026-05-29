extends Node
## Real local time + Philadelphia sun — day art before sunset, night art after.

const LATITUDE := 39.9526
const LONGITUDE := -75.1652

func is_night() -> bool:
	var now := Time.get_datetime_dict_from_system()
	var minute_of_day: int = int(now.hour) * 60 + int(now.minute)
	var sun := sunrise_sunset_minutes(now.year, now.month, now.day)
	return minute_of_day >= sun.sunset or minute_of_day < sun.sunrise

func background_path(data: Dictionary) -> String:
	if is_night():
		if data.has("background_night"):
			return str(data.get("background_night"))
	else:
		if data.has("background_day"):
			return str(data.get("background_day"))
	if data.has("background"):
		return str(data.get("background"))
	if data.has("background_night"):
		return str(data.get("background_night"))
	return ""

func sunrise_sunset_minutes(year: int, month: int, day: int) -> Dictionary:
	var jd := _julian_day(year, month, day)
	var n := jd - 2451545.0 + 0.0008
	var j_star := n - LONGITUDE / 360.0
	var m := fmod(357.5291 + 0.98560028 * j_star, 360.0)
	var c := 1.9148 * sin(deg_to_rad(m)) + 0.0200 * sin(deg_to_rad(2.0 * m)) + 0.0003 * sin(deg_to_rad(3.0 * m))
	var lambda := fmod(m + c + 180.0 + 102.9372, 360.0)
	var j_transit := 2451545.0 + j_star + 0.0053 * sin(deg_to_rad(m)) - 0.0069 * sin(deg_to_rad(2.0 * lambda))
	var sin_dec := sin(deg_to_rad(lambda)) * sin(deg_to_rad(23.44))
	var cos_dec := cos(asin(sin_dec))
	var lat_rad := deg_to_rad(LATITUDE)
	var cos_omega := (sin(deg_to_rad(-0.833)) - sin(lat_rad) * sin_dec) / (cos(lat_rad) * cos_dec)
	cos_omega = clampf(cos_omega, -1.0, 1.0)
	var omega := rad_to_deg(acos(cos_omega))
	var j_rise := j_transit - omega / 360.0
	var j_set := j_transit + omega / 360.0
	var offset := _utc_offset_hours()
	var rise := _minutes_from_julian(j_rise, offset)
	var set := _minutes_from_julian(j_set, offset)
	return {"sunrise": rise, "sunset": set}

func _minutes_from_julian(julian: float, utc_offset_hours: float) -> int:
	var minutes := int(round(fmod((julian - 2451545.0 + 0.5 + utc_offset_hours / 24.0) * 24.0 * 60.0, 1440.0)))
	if minutes < 0:
		minutes += 1440
	return minutes

func _utc_offset_hours() -> float:
	var local := Time.get_datetime_dict_from_system()
	var unix := Time.get_unix_time_from_system()
	var utc := Time.get_datetime_dict_from_unix_time(unix)
	var local_minutes: int = int(local.hour) * 60 + int(local.minute)
	var utc_minutes: int = int(utc.hour) * 60 + int(utc.minute)
	var day_diff: int = int(local.day) - int(utc.day)
	return float(local_minutes - utc_minutes + day_diff * 1440) / 60.0

func _julian_day(year: int, month: int, day: int) -> float:
	var y := year
	var m := month
	if m <= 2:
		y -= 1
		m += 12
	return floor(365.25 * float(y + 4716)) + floor(30.6001 * float(m + 1)) + float(day) - 1524.5
