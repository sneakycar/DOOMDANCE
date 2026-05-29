extends Node
## Money, time, inventory, collections, panhandle — Chapter 1 run state.

signal money_changed(amount: int)
signal time_changed(clock_minutes: int)
signal inventory_changed(items: Array[String])
signal collections_changed()
signal panhandle_changed()
signal message_requested(text: String)
signal world_event_changed()

const START_MONEY := 8
const START_CLOCK := 1380
const PANHANDLE_SECONDS := 300
const SAVE_PATH := "user://doom_dance_save.cfg"
const FENCE_MAN_CLOCK := 157
const MINUTES_PER_TRAVEL := 12

var money: int = START_MONEY
var clock_minutes: int = START_CLOCK
var inventory: Array[String] = []
var collected_flags: Dictionary = {}
var discovered_collectibles: Array[String] = []
var panhandling_until: int = 0
var fence_man_seen: bool = false
var screens_visited: Dictionary = {}

func _ready() -> void:
	CollectibleData.load_all()
	_load_save()

func _serialize_run() -> Dictionary:
	return {
		"money": money,
		"clock_minutes": clock_minutes,
		"inventory": inventory.duplicate(),
		"collected_flags": collected_flags.duplicate(),
		"discovered_collectibles": discovered_collectibles.duplicate(),
		"panhandling_until": panhandling_until,
		"fence_man_seen": fence_man_seen,
		"screens_visited": screens_visited.duplicate(),
	}

func _apply_save(data: Dictionary) -> void:
	money = int(data.get("money", START_MONEY))
	clock_minutes = int(data.get("clock_minutes", START_CLOCK))
	inventory.clear()
	var raw_inv: Variant = data.get("inventory", [])
	if raw_inv is Array:
		for item in raw_inv:
			inventory.append(str(item))
	collected_flags = data.get("collected_flags", {})
	discovered_collectibles.clear()
	var raw_disc: Variant = data.get("discovered_collectibles", [])
	if raw_disc is Array:
		for id in raw_disc:
			discovered_collectibles.append(str(id))
	for item_name in inventory:
		discover_by_name(item_name)
	panhandling_until = int(data.get("panhandling_until", 0))
	fence_man_seen = bool(data.get("fence_man_seen", false))
	screens_visited = data.get("screens_visited", {})

func reset_run() -> void:
	money = START_MONEY
	clock_minutes = START_CLOCK
	inventory.clear()
	collected_flags.clear()
	discovered_collectibles.clear()
	panhandling_until = 0
	fence_man_seen = false
	screens_visited.clear()
	_emit_all()
	if WebSave.is_web():
		WebSave.clear()
	_save()

func money_display() -> String:
	return DoomTypography.format_money(money)

func time_display() -> String:
	return DoomTypography.format_time(clock_minutes)

func inventory_display() -> String:
	return DoomTypography.format_inventory(inventory)

func advance_time(minutes: int = MINUTES_PER_TRAVEL) -> void:
	clock_minutes = (clock_minutes + minutes) % (24 * 60)
	_check_fence_man_window()
	time_changed.emit(clock_minutes)
	world_event_changed.emit()
	_save()

func mark_screen_visited(screen_id: String) -> void:
	screens_visited[screen_id] = true

func is_fence_man_visible() -> bool:
	return is_fence_man_hour() and not fence_man_seen

func is_fence_man_hour() -> bool:
	var h: int = (clock_minutes / 60) % 24
	var m: int = clock_minutes % 60
	return h == 2 and m >= 36 and m <= 39

func _check_fence_man_window() -> void:
	if is_fence_man_hour():
		world_event_changed.emit()

func note_fence_man_witnessed() -> void:
	if fence_man_seen:
		return
	fence_man_seen = true
	message_requested.emit(CopyData.get("world/fence_man", "SOMETHING MOVED.\n\nBEHIND THE FENCE."))
	world_event_changed.emit()
	_save()

func collections_summary() -> Dictionary:
	var out := {}
	for cat in ["liquor", "items"]:
		var total := CollectibleData.all_in_category(cat).size()
		var found := 0
		for entry in CollectibleData.all_in_category(cat):
			if entry.get("id", "") in discovered_collectibles:
				found += 1
		out[cat] = {"found": found, "total": total, "label": CollectibleData.category_label(cat)}
	return out

func discover_collectible(collectible_id: String) -> void:
	if collectible_id == "" or collectible_id in discovered_collectibles:
		return
	discovered_collectibles.append(collectible_id)
	collections_changed.emit()
	_save()

func discover_by_name(display_name: String) -> void:
	discover_collectible(CollectibleData.id_for_name(display_name))

func can_afford(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	money_changed.emit(money)
	_save()
	return true

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	_save()

func has_item(item_name: String) -> bool:
	return item_name in inventory

func add_item(item_name: String) -> void:
	if item_name in inventory:
		return
	inventory.append(item_name)
	discover_by_name(item_name)
	inventory_changed.emit(inventory.duplicate())
	_save()

func add_collectible(collectible_id: String) -> void:
	var data := CollectibleData.get(collectible_id)
	if data.is_empty():
		return
	var name: String = data.get("name", collectible_id)
	if not has_item(name):
		inventory.append(name)
	discover_collectible(collectible_id)
	inventory_changed.emit(inventory.duplicate())
	_save()

func is_collected(flag: String) -> bool:
	return collected_flags.get(flag, false)

func mark_collected(flag: String) -> void:
	collected_flags[flag] = true
	_save()

func is_panhandling_active() -> bool:
	return panhandling_until > 0 and Time.get_unix_time_from_system() < panhandling_until

func is_panhandle_ready_to_collect() -> bool:
	return panhandling_until > 0 and Time.get_unix_time_from_system() >= panhandling_until

func can_start_panhandle() -> bool:
	return panhandling_until == 0

func start_panhandle() -> void:
	if not can_start_panhandle():
		return
	panhandling_until = int(Time.get_unix_time_from_system()) + PANHANDLE_SECONDS
	panhandle_changed.emit()
	message_requested.emit(CopyData.get("panhandle/start", "SIT.\nASK."))
	_save()

func _grant_panhandle_legendary() -> void:
	if "bus_pass" in discovered_collectibles or has_item("Bus Pass"):
		_grant_panhandle_uncommon()
		return
	add_collectible("bus_pass")
	message_requested.emit(CopyData.get("panhandle/bus_pass", "BUS PASS."))

func _grant_panhandle_uncommon() -> void:
	var pool: Array[String] = ["old_receipt", "crushed_beer_can"]
	pool.shuffle()
	for cid in pool:
		var data := CollectibleData.get(cid)
		var name: String = data.get("name", cid)
		if cid in discovered_collectibles or has_item(name):
			continue
		add_collectible(cid)
		if cid == "old_receipt":
			message_requested.emit(CopyData.get("panhandle/receipt", "OLD RECEIPT."))
		else:
			message_requested.emit(CopyData.get("panhandle/beer_can", "CRUSHED CAN."))
		return
	add_money(randi_range(1, 2))
	message_requested.emit(CopyData.get("panhandle/cash_one", "$1."))

func collect_panhandle() -> void:
	if not is_panhandle_ready_to_collect():
		return
	match DoomRarity.roll_tier():
		DoomRarity.Tier.LEGENDARY:
			_grant_panhandle_legendary()
		DoomRarity.Tier.UNCOMMON:
			_grant_panhandle_uncommon()
		_:
			var cash := randi_range(0, 4)
			add_money(cash)
			message_requested.emit(CopyData.get("panhandle/cash", "$%d.") % cash)
	panhandling_until = 0
	panhandle_changed.emit()
	_save()

func panhandle_status_line() -> String:
	if is_panhandling_active():
		return CopyData.get("panhandle/active", "PANHANDLING.")
	if is_panhandle_ready_to_collect():
		return CopyData.get("panhandle/ready", "COLLECT EARNINGS.")
	return ""

func _emit_all() -> void:
	money_changed.emit(money)
	time_changed.emit(clock_minutes)
	inventory_changed.emit(inventory.duplicate())
	collections_changed.emit()
	panhandle_changed.emit()
	world_event_changed.emit()

func _save() -> void:
	if WebSave.is_web():
		WebSave.save_dict(_serialize_run())
		return
	var cfg := ConfigFile.new()
	var data := _serialize_run()
	for key in data.keys():
		cfg.set_value("run", key, data[key])
	cfg.save(SAVE_PATH)

func _load_save() -> void:
	if WebSave.is_web():
		var data := WebSave.load_dict()
		if data.is_empty():
			reset_run()
			return
		_apply_save(data)
		_emit_all()
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		reset_run()
		return
	_apply_save({
		"money": cfg.get_value("run", "money", START_MONEY),
		"clock_minutes": cfg.get_value("run", "clock_minutes", START_CLOCK),
		"inventory": cfg.get_value("run", "inventory", []),
		"collected_flags": cfg.get_value("run", "collected_flags", {}),
		"discovered_collectibles": cfg.get_value("run", "discovered_collectibles", []),
		"panhandling_until": cfg.get_value("run", "panhandling_until", 0),
		"fence_man_seen": cfg.get_value("run", "fence_man_seen", false),
		"screens_visited": cfg.get_value("run", "screens_visited", {}),
	})
	_emit_all()
