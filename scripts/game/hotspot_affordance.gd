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
			if MazeStore.has_page(str(target_id)):
				return "Leads deeper into the archive."
			var header: String = ScreenData.get_screen(target_id).get("header", target_id)
			if header.is_empty():
				return "Something leads out."
			return "Leads to %s." % header.to_lower()
		"invert_page":
			return "The screen looks wrong."
		"dialogue":
			return "Something happened here."
		"prompt":
			return _first_line(str(hotspot.get("text", "")))
		"document":
			return "Opens a file."
		"buy":
			var cid: String = hotspot.get("collectible_id", "")
			var data := CollectibleData.lookup(cid)
			var name: String = data.get("name", hotspot.get("label", "Item"))
			return "%s on the shelf." % name
		"collect":
			return "Something left behind."
		"panhandle":
			return "Sit. Ask."
		"stop_panhandle":
			return "Stand"
		"collect_panhandle":
			return "Collect $%d" % GameState.panhandle_pending_amount()
		"concert_offer":
			return "stay for JAPAN DOLL concert?"
		"stop_concert":
			return "Leave the pit."
		"collect_concert":
			return "Collect +%d life" % GameState.concert_pending_amount()
		"transit":
			return "Departures"
		"sell":
			return "They buy anything."
	return "—"

static func primary_label(hotspot: Dictionary) -> String:
	match hotspot.get("action", ""):
		"goto":
			return "Leave"
		"buy":
			return "Buy $%d" % int(hotspot.get("cost", 0))
		"collect":
			return "Take"
		"document":
			return "Read"
		"pay_message":
			return "Pay $%d" % int(hotspot.get("cost", 0))
		"panhandle":
			return "Sit"
		"stop_panhandle":
			return "Stand"
		"collect_panhandle":
			return "Collect"
		"concert_offer":
			return "Stay"
		"stop_concert":
			return "Leave"
		"collect_concert":
			return "Collect"
		"transit":
			return "Tickets"
		"sell":
			return "Sell"
		"prompt":
			return "Listen"
	return ""

static func has_primary(hotspot: Dictionary) -> bool:
	return not primary_label(hotspot).is_empty()

static func close_label(hotspot: Dictionary) -> String:
	match hotspot.get("action", ""):
		"concert_offer":
			return "No"
	return "Close"

static func _first_line(text: String) -> String:
	var cleaned := text.strip_edges().replace("\n\n", " ")
	if cleaned.is_empty():
		return "—"
	return cleaned.split("\n", false)[0]
