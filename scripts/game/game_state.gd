extends Node
## Money, time, inventory, collections, panhandle — Chapter 1 run state.

signal money_changed(amount: int)
signal time_changed(clock_minutes: int)
signal inventory_changed(items: Array[String])
signal collections_changed()
signal xp_changed(value: float)
signal panhandle_changed()
signal concert_changed()
signal message_requested(text: String)
signal document_requested(path: String, title: String)
signal world_event_changed()
signal life_changed(value: float)
signal player_died
signal the_end_changed(active: bool)
signal the_end_unlocked

const START_MONEY := 8
const START_LIFE := 100.0
const MAX_LIFE := 100.0
const DEATH_LIFE := 72.0
const PANHANDLE_SECONDS := 300
const PANHANDLE_SEC_PER_DOLLAR := 10.0
const CONCERT_SEC_PER_LIFE := 10.0
const DEFAULT_COLLECT_CHANCE := 0.38
const SAVE_PATH := "user://doom_dance_save.cfg"
var money: int = START_MONEY
var clock_minutes: int = 0
var xp: float = 0.0
var life: float = START_LIFE
var inventory: Array[String] = []
var collected_flags: Dictionary = {}
var seen_collectibles: Array[String] = []
var discovered_rumors: Array[String] = []
var panhandle_active := false
var panhandle_pending := 0
var panhandle_active_since := 0
var panhandle_site := ""
var _panhandle_accrual := 0.0
var concert_active := false
var concert_pending_life := 0
var concert_active_since := 0
var concert_site := ""
var _concert_accrual := 0.0
var fence_man_seen: bool = false
var screens_visited: Dictionary = {}
var location_visit_counts: Dictionary = {}
var hidden_metrics: Dictionary = HiddenMetrics.from_dict({})
var _repeat_collect_available: Dictionary = {}
var death_count: int = 0
var the_end_active := false
var _aftermath_pending := false
const THE_END_MIN_LIFE := 1.0

func _ready() -> void:
	CollectibleData.load_all()
	_load_save()
	_sync_local_clock(true)

func _process(delta: float) -> void:
	_sync_local_clock(false)
	_tick_panhandle(delta)
	_tick_concert(delta)

func _tick_panhandle(delta: float) -> void:
	if not panhandle_active:
		return
	_panhandle_accrual += delta
	if _panhandle_accrual < PANHANDLE_SEC_PER_DOLLAR:
		return
	var dollars := int(_panhandle_accrual / PANHANDLE_SEC_PER_DOLLAR)
	_panhandle_accrual = fmod(_panhandle_accrual, PANHANDLE_SEC_PER_DOLLAR)
	if dollars <= 0:
		return
	panhandle_pending += dollars
	panhandle_changed.emit()
	_save()

func _tick_concert(delta: float) -> void:
	if not concert_active:
		return
	_concert_accrual += delta
	if _concert_accrual < CONCERT_SEC_PER_LIFE:
		return
	var points := int(_concert_accrual / CONCERT_SEC_PER_LIFE)
	_concert_accrual = fmod(_concert_accrual, CONCERT_SEC_PER_LIFE)
	if points <= 0:
		return
	concert_pending_life += points
	concert_changed.emit()
	_save()

func _local_clock_minutes() -> int:
	var now := Time.get_datetime_dict_from_system()
	return int(now.hour) * 60 + int(now.minute)

func _sync_local_clock(force: bool) -> void:
	var local := _local_clock_minutes()
	if not force and local == clock_minutes:
		return
	clock_minutes = local
	time_changed.emit(clock_minutes)
	_check_fence_man_window()

func _serialize_run() -> Dictionary:
	return {
		"money": money,
		"clock_minutes": _local_clock_minutes(),
		"xp": xp,
		"life": life,
		"inventory": inventory.duplicate(),
		"collected_flags": collected_flags.duplicate(),
		"seen_collectibles": seen_collectibles.duplicate(),
		"discovered_rumors": discovered_rumors.duplicate(),
		"panhandle_active": panhandle_active,
		"panhandle_pending": panhandle_pending,
		"panhandle_active_since": panhandle_active_since,
		"panhandle_site": panhandle_site,
		"panhandle_accrual": _panhandle_accrual,
		"concert_active": concert_active,
		"concert_pending_life": concert_pending_life,
		"concert_active_since": concert_active_since,
		"concert_site": concert_site,
		"concert_accrual": _concert_accrual,
		"fence_man_seen": fence_man_seen,
		"screens_visited": screens_visited.duplicate(),
		"location_visit_counts": location_visit_counts.duplicate(),
		"hidden_metrics": HiddenMetrics.to_dict(hidden_metrics),
		"death_count": death_count,
		"the_end_active": the_end_active,
	}

func _apply_save(data: Dictionary) -> void:
	money = int(data.get("money", START_MONEY))
	xp = float(data.get("xp", 0.0))
	life = float(data.get("life", START_LIFE))
	inventory.clear()
	var raw_inv: Variant = data.get("inventory", [])
	if raw_inv is Array:
		for item in raw_inv:
			inventory.append(str(item))
	collected_flags = data.get("collected_flags", {})
	seen_collectibles.clear()
	var raw_seen: Variant = data.get("seen_collectibles", data.get("discovered_collectibles", []))
	if raw_seen is Array:
		for id in raw_seen:
			seen_collectibles.append(str(id))
	discovered_rumors.clear()
	var raw_rumors: Variant = data.get("discovered_rumors", [])
	if raw_rumors is Array:
		for rumor in raw_rumors:
			discovered_rumors.append(str(rumor))
	for item_name in inventory:
		discover_by_name(item_name)
	panhandle_active = bool(data.get("panhandle_active", false))
	panhandle_pending = int(data.get("panhandle_pending", 0))
	panhandle_active_since = int(data.get("panhandle_active_since", 0))
	panhandle_site = str(data.get("panhandle_site", ""))
	_panhandle_accrual = float(data.get("panhandle_accrual", 0.0))
	concert_active = bool(data.get("concert_active", false))
	concert_pending_life = int(data.get("concert_pending_life", 0))
	concert_active_since = int(data.get("concert_active_since", 0))
	concert_site = str(data.get("concert_site", ""))
	_concert_accrual = float(data.get("concert_accrual", 0.0))
	if data.has("panhandling_until") and not data.has("panhandle_active"):
		var legacy_until := int(data.get("panhandling_until", 0))
		if legacy_until > int(Time.get_unix_time_from_system()):
			panhandle_active = true
			panhandle_active_since = int(Time.get_unix_time_from_system())
	fence_man_seen = bool(data.get("fence_man_seen", false))
	screens_visited = data.get("screens_visited", {})
	location_visit_counts = data.get("location_visit_counts", {})
	hidden_metrics = HiddenMetrics.from_dict(data.get("hidden_metrics", {}))
	death_count = int(data.get("death_count", 0))
	the_end_active = bool(data.get("the_end_active", false))

func reset_run() -> void:
	money = START_MONEY
	xp = 0.0
	life = START_LIFE
	inventory.clear()
	collected_flags.clear()
	seen_collectibles.clear()
	discovered_rumors.clear()
	panhandle_active = false
	panhandle_pending = 0
	panhandle_active_since = 0
	panhandle_site = ""
	_panhandle_accrual = 0.0
	concert_active = false
	concert_pending_life = 0
	concert_active_since = 0
	concert_site = ""
	_concert_accrual = 0.0
	fence_man_seen = false
	screens_visited.clear()
	location_visit_counts.clear()
	hidden_metrics = HiddenMetrics.from_dict({})
	death_count = 0
	the_end_active = false
	_aftermath_pending = false
	_sync_local_clock(true)
	the_end_changed.emit(false)
	MazeStore.reset_maze()
	_emit_all()
	if WebSave.is_web():
		WebSave.clear()
	_save()

func money_display() -> String:
	return DoomTypography.format_money(money)

func time_display() -> String:
	return DoomTypography.format_time(_local_clock_minutes())

func life_display() -> String:
	return "LIFE %d" % int(roundf(life))

func apply_page_life(page_id: String, page: Dictionary) -> void:
	var amount: float
	var cause := ""
	if page.has("life_delta"):
		amount = float(page.get("life_delta", 0.0))
		cause = str(page.get("life_cause", _life_cause_for_page(page_id, page)))
	elif page.has("life_min") and page.has("life_max"):
		var lo: float = float(page.get("life_min", -10.0))
		var hi: float = float(page.get("life_max", 5.0))
		amount = randf_range(lo, hi)
		cause = _life_cause_for_page(page_id, page)
	else:
		amount = _default_page_life_roll(page_id, page)
		cause = _life_cause_for_page(page_id, page)
	adjust_life(amount, cause)

func _life_cause_for_page(page_id: String, page: Dictionary) -> String:
	if bool(page.get("unstable", false)):
		return "unstable page."
	if bool(page.get("hidden", false)):
		return "hidden file."
	if page_id in _dangerous_page_ids():
		return "bad room."
	if page_id in _calm_page_ids():
		return ""
	return "the crawl."

func _default_page_life_roll(page_id: String, page: Dictionary) -> float:
	var low: float = -10.0
	var high: float = 5.0
	if bool(page.get("unstable", false)):
		low -= 8.0
		high -= 2.0
	if bool(page.get("hidden", false)):
		low -= 12.0
		high -= 4.0
	if page_id in _dangerous_page_ids():
		low -= 18.0
		high -= 6.0
	elif page_id in _calm_page_ids():
		low += 4.0
		high += 8.0
	return randf_range(low, high)

func _dangerous_page_ids() -> Array[String]:
	return [
		"failure", "void", "murder", "broadcastpanic", "hidden", "bad",
		"violent", "incisions", "lung", "mad", "deaddarkness", "no_exit",
	]

func _calm_page_ids() -> Array[String]:
	return ["flowers", "happy", "money", "tea", "yard_sale"]

func adjust_life(amount: float, cause: String = "") -> void:
	if amount == 0.0:
		return
	if the_end_active:
		life = clampf(life + amount, THE_END_MIN_LIFE, MAX_LIFE)
		life_changed.emit(life)
		_save()
		if amount <= -5.0 and cause != "":
			message_requested.emit(cause.to_lower())
		return
	life = clampf(life + amount, 0.0, MAX_LIFE)
	life_changed.emit(life)
	_save()
	if amount <= -5.0 and cause != "":
		message_requested.emit(cause.to_lower())
	if life <= 0.0:
		_handle_death()

func reset_life() -> void:
	life = START_LIFE
	life_changed.emit(life)
	_save()

func _handle_death() -> void:
	if the_end_active:
		return
	death_count += 1
	adjust_metric("heat", 12.0)
	adjust_metric("mood", -8.0)
	adjust_metric("memory", 6.0)
	var tax := maxi(2, int(roundf(float(money) * 0.2)))
	money = maxi(0, money - tax)
	money_changed.emit(money)
	_strip_inventory_on_death()
	life = DEATH_LIFE
	life_changed.emit(life)
	_aftermath_pending = true
	mark_collected("died_%d" % death_count)
	player_died.emit()
	_save()

func consume_aftermath() -> bool:
	var pending := _aftermath_pending
	_aftermath_pending = false
	return pending

func is_fresh_run() -> bool:
	return not is_collected("game_started")

func mark_game_started() -> void:
	mark_collected("game_started")

func has_any_collectible() -> bool:
	return not seen_collectibles.is_empty() or not inventory.is_empty()

func has_seen(collectible_id: String) -> bool:
	return collectible_id in seen_collectibles

func holds_id(collectible_id: String) -> bool:
	var name := CollectibleData.name_for_id(collectible_id)
	return has_item(name)

func inventory_counts() -> Dictionary:
	var counts := {}
	for item_name in inventory:
		var key := str(item_name)
		counts[key] = int(counts.get(key, 0)) + 1
	return counts

func inventory_stack_ids() -> Array[Dictionary]:
	var counts := inventory_counts()
	var out: Array[Dictionary] = []
	for item_name in counts.keys():
		var cid := CollectibleData.id_for_name(item_name)
		if cid == "":
			continue
		out.append({"id": cid, "name": item_name, "count": counts[item_name]})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return out

func inventory_display() -> String:
	return DoomTypography.format_inventory(inventory)

func advance_time(_minutes: int = 0) -> void:
	_sync_local_clock(true)

func mark_screen_visited(screen_id: String) -> void:
	var first_visit: bool = not bool(screens_visited.get(screen_id, false))
	screens_visited[screen_id] = true
	if first_visit:
		award_xp(25.0)
		collections_changed.emit()
	_save()

func mark_location_visit(location_id: String) -> int:
	var count: int = int(location_visit_counts.get(location_id, 0)) + 1
	location_visit_counts[location_id] = count
	_save()
	check_the_end()
	return count

func is_the_end_active() -> bool:
	return the_end_active

func is_immortal() -> bool:
	return the_end_active

func all_locations_visited() -> bool:
	ScreenData.load_all()
	for screen_id in ScreenData.screen_ids():
		var required := ProgressionData.location_visits_required(str(screen_id))
		if location_visit_count(str(screen_id)) < required:
			return false
	return true

func rooms_completion_ratio() -> Vector2:
	var maze_total := MazeStore.all_page_ids().size()
	var maze_seen := MazeStore.visited_page_count()
	var loc_total := ScreenData.screen_ids().size()
	var loc_seen := 0
	ScreenData.load_all()
	for screen_id in ScreenData.screen_ids():
		if location_visit_count(str(screen_id)) >= 1:
			loc_seen += 1
	return Vector2(float(maze_seen + loc_seen), float(maze_total + loc_total))

func check_the_end() -> void:
	if the_end_active:
		return
	if not MazeStore.all_maze_pages_meet_minimum(ProgressionData.maze_min_visits_per_page()):
		return
	if not MazeStore.maze_grind_complete(
		ProgressionData.maze_grind_visits(),
		ProgressionData.maze_grind_ratio()
	):
		return
	if not all_locations_visited():
		return
	_activate_the_end()

func _activate_the_end() -> void:
	the_end_active = true
	mark_collected("the_end")
	the_end_changed.emit(true)
	the_end_unlocked.emit()
	_save()

func location_visit_count(location_id: String) -> int:
	return int(location_visit_counts.get(location_id, 0))

func tick_xp(delta: float) -> void:
	if delta <= 0.0:
		return
	xp += delta
	xp_changed.emit(xp)

func award_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	xp += amount
	xp_changed.emit(xp)
	_save()

func persist() -> void:
	_save()

func set_metric(key: String, value: float) -> void:
	if not hidden_metrics.has(key):
		return
	hidden_metrics[key] = HiddenMetrics.clamp_metric(value)
	_save()

func adjust_metric(key: String, delta: float) -> void:
	if not hidden_metrics.has(key):
		return
	set_metric(key, float(hidden_metrics[key]) + delta)

func discover_rumor(rumor_id: String) -> void:
	if rumor_id == "" or rumor_id in discovered_rumors:
		return
	discovered_rumors.append(rumor_id)
	award_xp(20.0)
	collections_changed.emit()
	_save()

func visited_places() -> Array[String]:
	var out: Array[String] = []
	for screen_id in screens_visited.keys():
		if screens_visited[screen_id]:
			out.append(str(screen_id))
	out.sort()
	return out

func is_fence_man_visible() -> bool:
	return is_fence_man_hour() and not fence_man_seen

func is_fence_man_hour() -> bool:
	var local := _local_clock_minutes()
	var h: int = (local / 60) % 24
	var m: int = local % 60
	return h == 2 and m >= 36 and m <= 39

func _check_fence_man_window() -> void:
	if is_fence_man_hour():
		world_event_changed.emit()

func note_fence_man_witnessed() -> void:
	if fence_man_seen:
		return
	fence_man_seen = true
	award_xp(50.0)
	message_requested.emit(CopyData.lookup("world/fence_man", "SOMETHING MOVED.\n\nBEHIND THE FENCE."))
	world_event_changed.emit()
	_save()

func collections_summary() -> Dictionary:
	var out := {}
	for cat in CollectibleData.category_keys():
		var total := CollectibleData.all_in_category(cat).size()
		var seen := 0
		for entry in CollectibleData.all_in_category(cat):
			if entry.get("id", "") in seen_collectibles:
				seen += 1
		out[cat] = {"found": seen, "total": total, "label": CollectibleData.category_label(cat)}
	return out

func mark_seen(collectible_id: String) -> void:
	if collectible_id == "" or collectible_id in seen_collectibles:
		return
	seen_collectibles.append(collectible_id)
	award_xp(15.0)
	collections_changed.emit()
	var data := CollectibleData.lookup(collectible_id)
	var reveal: String = str(data.get("reveal", data.get("name", ""))).strip_edges()
	if reveal != "":
		message_requested.emit(reveal.to_lower())
	_save()

func discover_collectible(collectible_id: String) -> void:
	mark_seen(collectible_id)

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
	var cid := CollectibleData.id_for_name(item_name)
	if cid != "":
		if cid not in seen_collectibles:
			mark_seen(cid)
	else:
		award_xp(10.0)
	inventory_changed.emit(inventory.duplicate())
	_save()

func add_item_stack(item_name: String) -> void:
	if item_name.is_empty():
		return
	inventory.append(item_name)
	var cid := CollectibleData.id_for_name(item_name)
	if cid != "":
		discover_collectible(cid)
	award_xp(8.0)
	inventory_changed.emit(inventory.duplicate())
	_save()

func add_collectible(collectible_id: String) -> void:
	var data := CollectibleData.lookup(collectible_id)
	if data.is_empty():
		return
	var name: String = data.get("name", collectible_id)
	if not has_item(name):
		inventory.append(name)
	discover_collectible(collectible_id)
	_apply_item_metrics(collectible_id)
	inventory_changed.emit(inventory.duplicate())
	_save()

func add_collectible_stack(collectible_id: String) -> void:
	var data := CollectibleData.lookup(collectible_id)
	if data.is_empty():
		return
	var name: String = data.get("name", collectible_id)
	inventory.append(name)
	discover_collectible(collectible_id)
	_apply_item_metrics(collectible_id)
	award_xp(8.0)
	inventory_changed.emit(inventory.duplicate())
	_save()

func _apply_item_metrics(collectible_id: String) -> void:
	var cat: String = str(CollectibleData.lookup(collectible_id).get("category", ""))
	match cat:
		"liquor":
			adjust_metric("intoxication", 4.0)
		"drugs":
			adjust_metric("intoxication", 9.0)
			adjust_metric("heat", 2.5)
		"guns":
			adjust_metric("heat", 6.0)
		"vinyl":
			adjust_metric("mood", 3.0)
		_:
			pass

func prepare_location_collects(screen_id: String) -> void:
	var data := ScreenData.get_screen(screen_id)
	for raw in data.get("hotspots", []):
		if raw is not Dictionary or str(raw.get("action", "")) != "collect":
			continue
		var hotspot: Dictionary = raw
		var hotspot_id: String = str(hotspot.get("id", ""))
		if hotspot_id.is_empty():
			continue
		var chance: float = float(hotspot.get("collect_chance", DEFAULT_COLLECT_CHANCE))
		_repeat_collect_available[_repeat_collect_key(screen_id, hotspot_id)] = randf() < chance

func is_repeat_collect_available(screen_id: String, hotspot_id: String) -> bool:
	return bool(_repeat_collect_available.get(_repeat_collect_key(screen_id, hotspot_id), false))

func consume_repeat_collect(screen_id: String, hotspot_id: String) -> void:
	_repeat_collect_available[_repeat_collect_key(screen_id, hotspot_id)] = false

func _repeat_collect_key(screen_id: String, hotspot_id: String) -> String:
	return "%s:%s" % [screen_id, hotspot_id]

func is_collected(flag: String) -> bool:
	return collected_flags.get(flag, false)

func mark_collected(flag: String) -> void:
	collected_flags[flag] = true
	_save()

func is_panhandling_active() -> bool:
	return panhandle_active

func panhandle_pending_amount() -> int:
	return panhandle_pending

func can_collect_panhandle() -> bool:
	return panhandle_pending > 0 and not panhandle_active

func can_start_panhandle() -> bool:
	return not panhandle_active and panhandle_pending == 0 and not concert_active and concert_pending_life == 0

func can_collect_panhandle_at(site: String) -> bool:
	return can_collect_panhandle() and panhandle_site == site

func start_panhandle(site: String = "") -> void:
	if panhandle_active:
		return
	panhandle_active = true
	panhandle_site = site
	panhandle_active_since = int(Time.get_unix_time_from_system())
	_panhandle_accrual = 0.0
	panhandle_changed.emit()
	message_requested.emit(CopyData.lookup("panhandle/start", "sit. ask."))
	_save()

func stop_panhandle() -> void:
	if not panhandle_active:
		return
	panhandle_active = false
	panhandle_active_since = 0
	_panhandle_accrual = 0.0
	panhandle_changed.emit()
	if panhandle_pending > 0:
		message_requested.emit(CopyData.lookup("panhandle/stopped", "money waits where you sat."))
	_save()

func panhandle_hud_line() -> String:
	if not panhandle_active:
		return ""
	var elapsed := maxi(0, int(Time.get_unix_time_from_system()) - panhandle_active_since)
	var minutes := elapsed / 60
	var seconds := elapsed % 60
	return "PANHANDLE %02d:%02d · $%d held" % [minutes, seconds, panhandle_pending]

func _grant_panhandle_legendary() -> void:
	if "bus_pass" in seen_collectibles or has_item("Bus Pass"):
		_grant_panhandle_uncommon()
		return
	add_collectible("bus_pass")
	message_requested.emit(CopyData.lookup("panhandle/bus_pass", "BUS PASS."))

func _grant_panhandle_uncommon() -> void:
	var pool: Array[String] = ["old_receipt", "crushed_beer_can"]
	pool.shuffle()
	for cid in pool:
		var data := CollectibleData.lookup(cid)
		var name: String = data.get("name", cid)
		if cid in seen_collectibles or has_item(name):
			continue
		add_collectible(cid)
		if cid == "old_receipt":
			message_requested.emit(CopyData.lookup("panhandle/receipt", "OLD RECEIPT."))
		else:
			message_requested.emit(CopyData.lookup("panhandle/beer_can", "CRUSHED CAN."))
		return
	add_money(randi_range(1, 2))
	message_requested.emit(CopyData.lookup("panhandle/cash_one", "$1."))

func collect_panhandle() -> bool:
	if not can_collect_panhandle():
		return false
	var payout := panhandle_pending
	panhandle_pending = 0
	add_money(payout)
	match DoomRarity.roll_tier():
		DoomRarity.Tier.LEGENDARY:
			_grant_panhandle_legendary()
		DoomRarity.Tier.UNCOMMON:
			_grant_panhandle_uncommon()
		_:
			pass
	message_requested.emit(CopyData.lookup("panhandle/collected", "$%d.") % payout)
	panhandle_site = ""
	panhandle_changed.emit()
	_save()
	return true

func buy_collectible(collectible_id: String, cost: int, source_screen: String = "") -> bool:
	var data := CollectibleData.lookup(collectible_id)
	if data.is_empty():
		return false
	var name: String = str(data.get("name", collectible_id))
	if has_item(name):
		message_requested.emit(CopyData.lookup("affordance/already_have", "already have."))
		return false
	if not spend(cost):
		message_requested.emit(CopyData.lookup("affordance/no_money", "short."))
		return false
	add_collectible(collectible_id)
	if source_screen == "pawn_shop" and not is_collected("pawn_stub_granted"):
		add_collectible("pawn_stub")
		mark_collected("pawn_stub_granted")
	message_requested.emit(CopyData.lookup("commerce/bought", "$%d.\n%s.") % [cost, name.to_lower()])
	return true

func _price_luck_factor() -> float:
	var luck := float(hidden_metrics.get("luck", 50.0))
	return 0.82 + (luck / 100.0) * 0.36

func pawn_offer(collectible_id: String) -> int:
	if not CollectibleData.is_sellable(collectible_id):
		return 0
	var base := CollectibleData.base_value(collectible_id)
	var rate := CollectibleData.pawn_rate(collectible_id)
	var heat := float(hidden_metrics.get("heat", 0.0))
	var heat_cut := 1.0 - clampf(heat / 200.0, 0.0, 0.35)
	return maxi(1, int(roundf(float(base) * rate * _price_luck_factor() * heat_cut)))

func record_sell_offer(collectible_id: String) -> int:
	if not CollectibleData.is_sellable(collectible_id):
		return 0
	var data := CollectibleData.lookup(collectible_id)
	if str(data.get("category", "")) != "vinyl":
		return pawn_offer(collectible_id)
	return maxi(1, int(roundf(float(CollectibleData.base_value(collectible_id)) * RecordCatalog.sell_rate() * _price_luck_factor())))

func remove_one_by_id(collectible_id: String) -> bool:
	var name := CollectibleData.name_for_id(collectible_id)
	if name.is_empty() or not has_item(name):
		return false
	inventory.erase(name)
	inventory_changed.emit(inventory.duplicate())
	collections_changed.emit()
	_save()
	return true

func sell_at_pawn(collectible_id: String) -> bool:
	if collectible_id.is_empty():
		return false
	if not CollectibleData.is_sellable(collectible_id):
		message_requested.emit(CopyData.lookup("commerce/not_sellable", "they won't take it."))
		return false
	if not holds_id(collectible_id):
		message_requested.emit(CopyData.lookup("affordance/nothing_here", "don't have it."))
		return false
	var payout := pawn_offer(collectible_id)
	if not remove_one_by_id(collectible_id):
		return false
	add_money(payout)
	adjust_metric("mood", 2.0)
	message_requested.emit(CopyData.lookup("commerce/sold", "$%d.\n%s.") % [payout, CollectibleData.name_for_id(collectible_id).to_lower()])
	return true

func sell_at_record_store(collectible_id: String) -> bool:
	if collectible_id.is_empty():
		return false
	var data := CollectibleData.lookup(collectible_id)
	if str(data.get("category", "")) != "vinyl":
		message_requested.emit(CopyData.lookup("commerce/records_only", "vinyl only."))
		return false
	if not holds_id(collectible_id):
		message_requested.emit(CopyData.lookup("affordance/nothing_here", "don't have it."))
		return false
	var payout := record_sell_offer(collectible_id)
	if not remove_one_by_id(collectible_id):
		return false
	add_money(payout)
	message_requested.emit(CopyData.lookup("commerce/sold", "$%d.\n%s.") % [payout, CollectibleData.name_for_id(collectible_id).to_lower()])
	return true

func _strip_inventory_on_death() -> void:
	if inventory.is_empty():
		return
	var heat := float(hidden_metrics.get("heat", 0.0))
	var loss_ratio := clampf(0.22 + heat / 180.0, 0.22, 0.55)
	var to_remove := maxi(1, int(roundf(float(inventory.size()) * loss_ratio)))
	var pool := inventory.duplicate()
	pool.shuffle()
	for i in mini(to_remove, pool.size()):
		inventory.erase(pool[i])
	inventory_changed.emit(inventory.duplicate())
	collections_changed.emit()
	message_requested.emit(CopyData.lookup("death/lost_items", "something slipped away in the dark."))

func buy_transit_pass(cost: int) -> bool:
	if not spend(cost):
		message_requested.emit(CopyData.lookup("affordance/no_money", "short."))
		return false
	if "transit_map" not in seen_collectibles:
		add_collectible("transit_map")
	return true

func panhandle_status_line() -> String:
	if panhandle_active:
		return CopyData.lookup("panhandle/active", "panhandling.")
	if can_collect_panhandle():
		return CopyData.lookup("panhandle/ready", "collect earnings.")
	return ""

func is_concert_active() -> bool:
	return concert_active

func concert_pending_amount() -> int:
	return concert_pending_life

func can_collect_concert() -> bool:
	return concert_pending_life > 0 and not concert_active

func can_start_concert() -> bool:
	return not concert_active and concert_pending_life == 0 and not panhandle_active and panhandle_pending == 0

func can_collect_concert_at(site: String) -> bool:
	return can_collect_concert() and concert_site == site

func start_concert(site: String = "") -> void:
	if not can_start_concert():
		return
	concert_active = true
	concert_site = site
	concert_active_since = int(Time.get_unix_time_from_system())
	_concert_accrual = 0.0
	concert_changed.emit()
	message_requested.emit(CopyData.lookup("concert/start", "stay. listen."))
	_save()

func stop_concert() -> void:
	if not concert_active:
		return
	concert_active = false
	concert_active_since = 0
	_concert_accrual = 0.0
	concert_changed.emit()
	if concert_pending_life > 0:
		message_requested.emit(CopyData.lookup("concert/stopped", "life waits where you stood."))
	_save()

func concert_hud_line() -> String:
	if not concert_active:
		return ""
	var elapsed := maxi(0, int(Time.get_unix_time_from_system()) - concert_active_since)
	var minutes := elapsed / 60
	var seconds := elapsed % 60
	return "CONCERT %02d:%02d · +%d life" % [minutes, seconds, concert_pending_life]

func collect_concert() -> bool:
	if not can_collect_concert():
		return false
	var heal := float(concert_pending_life)
	concert_pending_life = 0
	adjust_life(heal, "concert")
	message_requested.emit(CopyData.lookup("concert/collected", "+%d life.") % int(heal))
	concert_site = ""
	concert_changed.emit()
	_save()
	return true

func concert_status_line() -> String:
	if concert_active:
		return CopyData.lookup("concert/active", "japan doll.")
	if can_collect_concert():
		return CopyData.lookup("concert/ready", "collect life.")
	return ""

func activity_hud_line() -> String:
	var pan := panhandle_hud_line()
	if not pan.is_empty():
		return pan
	return concert_hud_line()

func activity_status_line() -> String:
	var pan := panhandle_status_line()
	if not pan.is_empty():
		return pan
	return concert_status_line()

func _emit_all() -> void:
	money_changed.emit(money)
	time_changed.emit(clock_minutes)
	xp_changed.emit(xp)
	life_changed.emit(life)
	inventory_changed.emit(inventory.duplicate())
	collections_changed.emit()
	panhandle_changed.emit()
	concert_changed.emit()
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
		if the_end_active:
			the_end_changed.emit(true)
		_emit_all()
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		reset_run()
		return
	_apply_save({
		"money": cfg.get_value("run", "money", START_MONEY),
		"clock_minutes": cfg.get_value("run", "clock_minutes", 0),
		"xp": cfg.get_value("run", "xp", 0.0),
		"life": cfg.get_value("run", "life", START_LIFE),
		"inventory": cfg.get_value("run", "inventory", []),
		"collected_flags": cfg.get_value("run", "collected_flags", {}),
		"seen_collectibles": cfg.get_value("run", "seen_collectibles", cfg.get_value("run", "discovered_collectibles", [])),
		"discovered_rumors": cfg.get_value("run", "discovered_rumors", []),
		"panhandle_active": cfg.get_value("run", "panhandle_active", false),
		"panhandle_pending": cfg.get_value("run", "panhandle_pending", 0),
		"panhandle_active_since": cfg.get_value("run", "panhandle_active_since", 0),
		"panhandle_site": cfg.get_value("run", "panhandle_site", ""),
		"panhandle_accrual": cfg.get_value("run", "panhandle_accrual", 0.0),
		"concert_active": cfg.get_value("run", "concert_active", false),
		"concert_pending_life": cfg.get_value("run", "concert_pending_life", 0),
		"concert_active_since": cfg.get_value("run", "concert_active_since", 0),
		"concert_site": cfg.get_value("run", "concert_site", ""),
		"concert_accrual": cfg.get_value("run", "concert_accrual", 0.0),
		"fence_man_seen": cfg.get_value("run", "fence_man_seen", false),
		"screens_visited": cfg.get_value("run", "screens_visited", {}),
		"location_visit_counts": cfg.get_value("run", "location_visit_counts", {}),
		"hidden_metrics": cfg.get_value("run", "hidden_metrics", {}),
		"death_count": cfg.get_value("run", "death_count", 0),
		"the_end_active": cfg.get_value("run", "the_end_active", false),
	})
	if the_end_active:
		the_end_changed.emit(true)
	_emit_all()
