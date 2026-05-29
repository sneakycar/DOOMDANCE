extends RefCounted
class_name HotspotAffordance

static func observation(hotspot: Dictionary) -> String:
	if hotspot.has("observation"):
		return str(hotspot.observation)
	match hotspot.get("action", ""):
		"message", "pay_message":
			return _first_line(str(hotspot.get("text", "")))
		"goto":
			var target_id: String = hotspot.get("target", "")
			var header: String = ScreenData.get_screen(target_id).get("header", target_id)
			return "Leads to %s." % header.to_lower()
		"buy":
			var cid: String = hotspot.get("collectible_id", "")
			var data := CollectibleData.lookup(cid)
			var name: String = data.get("name", hotspot.get("label", "Item"))
			return "%s on the shelf." % name
		"collect":
			return "Something left behind."
		"panhandle":
			return "Sit. Ask."
		"collect_panhandle":
			return "Check what they gave you."
	return "—"

static func primary_label(hotspot: Dictionary) -> String:
	match hotspot.get("action", ""):
		"goto":
			return "Leave"
		"buy":
			return "Buy $%d" % int(hotspot.get("cost", 0))
		"collect":
			return "Take"
		"pay_message":
			return "Pay $%d" % int(hotspot.get("cost", 0))
		"panhandle":
			return "Sit"
		"collect_panhandle":
			return "Collect"
	return ""

static func has_primary(hotspot: Dictionary) -> bool:
	return not primary_label(hotspot).is_empty()

static func _first_line(text: String) -> String:
	var cleaned := text.strip_edges().replace("\n\n", " ")
	if cleaned.is_empty():
		return "—"
	return cleaned.split("\n", false)[0]
