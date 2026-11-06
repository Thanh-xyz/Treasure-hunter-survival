extends Node
## QuestService — main quest chain + daily repeatables (autoload).
##
## Listens to GameEvent/GameState domain events and advances objectives.
## Quest definitions live in GameContent.MAIN_QUESTS / DAILY_QUESTS.

signal quests_changed
signal quest_completed(quest_id: String, quest_name: String)

## Index into GameContent.MAIN_QUESTS of the active main quest
var main_index: int = 0
## Progress of the active main quest
var main_progress: int = 0
## Whether the active main quest is complete and waiting to be claimed
var main_ready: bool = false
## daily quest id -> {"progress": int, "claimed": bool}
var dailies: Dictionary = {}
var daily_date: String = ""
var _reward_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_reward_rng.randomize()
	GameEvent.enemy_killed.connect(_on_enemy_killed)
	GameEvent.resource_gathered.connect(_on_resource_gathered)
	GameEvent.ground_dug.connect(_on_ground_dug)
	GameEvent.zone_entered.connect(_on_zone_entered)
	GameEvent.building_built.connect(_on_building_built)
	GameEvent.item_crafted.connect(func(_r: String, _t: int) -> void: _advance("craft", "any", 1))
	GameState.leveled_up.connect(func(_l: int) -> void: _refresh_state_objectives())
	GameState.collection_changed.connect(_refresh_state_objectives)
	GameState.pet_changed.connect(func(_p: String) -> void: _refresh_state_objectives())
	GameState.mount_changed.connect(func(_m: String, _r: bool) -> void: _refresh_state_objectives())
	reset()


## Offline mode owns this RNG locally. A future authoritative host can inject
## its own stream without coupling quest rules to a network transport.
func set_reward_authority_rng(rng: RandomNumberGenerator) -> bool:
	if rng == null:
		return false
	_reward_rng = rng
	return true


func reset() -> void:
	main_index = 0
	main_progress = 0
	main_ready = false
	_reset_dailies()


# =============================================================================
# QUERIES
# =============================================================================

func get_main_quest() -> Dictionary:
	if main_index >= GameContent.MAIN_QUESTS.size():
		return {}
	return GameContent.MAIN_QUESTS[main_index]


func is_main_chain_done() -> bool:
	return main_index >= GameContent.MAIN_QUESTS.size()


## Returns tracker rows: [{id, name, desc, progress, count, ready, daily, claimed}]
func get_tracker_rows() -> Array[Dictionary]:
	_check_daily_reset()
	var rows: Array[Dictionary] = []
	var q := get_main_quest()
	if not q.is_empty():
		rows.append({
			"id": q["id"], "name": q["name"], "desc": q["desc"],
			"progress": main_progress, "count": int(q["obj"]["count"]),
			"ready": main_ready, "daily": false, "claimed": false,
		})
	for dq in GameContent.DAILY_QUESTS:
		var st: Dictionary = dailies.get(dq["id"], {"progress": 0, "claimed": false})
		rows.append({
			"id": dq["id"], "name": dq["name"], "desc": dq["desc"],
			"progress": int(st["progress"]), "count": int(dq["obj"]["count"]),
			"ready": int(st["progress"]) >= int(dq["obj"]["count"]) and not st["claimed"],
			"daily": true, "claimed": bool(st["claimed"]),
		})
	return rows


func get_quest_def(quest_id: String) -> Dictionary:
	for q in GameContent.MAIN_QUESTS:
		if q["id"] == quest_id:
			return q
	for q in GameContent.DAILY_QUESTS:
		if q["id"] == quest_id:
			return q
	return {}


# =============================================================================
# CLAIM
# =============================================================================

func claim(quest_id: String) -> bool:
	_check_daily_reset()
	var pending := SaveService.get_pending_claim()
	if not pending.is_empty():
		if str(pending.get("source_id", "")) != quest_id:
			return false
		return _apply_pending_claim(pending)

	var main := get_main_quest()
	if not main.is_empty() and main["id"] == quest_id:
		if not main_ready:
			return false
		var main_record := _prepare_quest_claim("main", quest_id, main)
		if main_record.is_empty():
			return false
		return _apply_pending_claim(main_record)
	if dailies.has(quest_id):
		var dq := get_quest_def(quest_id)
		var st: Dictionary = dailies[quest_id]
		if st["claimed"] or int(st["progress"]) < int(dq["obj"]["count"]):
			return false
		var daily_record := _prepare_quest_claim("daily", quest_id, dq)
		if daily_record.is_empty():
			return false
		return _apply_pending_claim(daily_record)
	return false


func retry_pending_claim() -> bool:
	var pending := SaveService.get_pending_claim()
	if pending.is_empty():
		return false
	return _apply_pending_claim(pending)


func validate_pending_claim(record: Dictionary, quests: Dictionary) -> bool:
	var source_kind := str(record.get("source_kind", ""))
	var quest_id := str(record.get("source_id", ""))
	if source_kind == "main":
		if str(record.get("claim_id", "")) != "main:%s" % quest_id:
			return false
		return str(quests.get("main_quest_id", "")) == quest_id and bool(quests.get("main_ready", false))
	elif source_kind == "daily":
		var saved_date := str(quests.get("daily_date", ""))
		if saved_date.is_empty() or str(record.get("claim_id", "")) != "daily:%s:%s" % [saved_date, quest_id]:
			return false
		var daily_states := quests.get("dailies", {}) as Dictionary
		if not daily_states.get(quest_id) is Dictionary:
			return false
		var state := daily_states[quest_id] as Dictionary
		if bool(state.get("claimed", false)):
			return false
		return int(state.get("progress", 0)) > 0
	else:
		return false
	return false


func _prepare_quest_claim(source_kind: String, quest_id: String, quest: Dictionary) -> Dictionary:
	var rng_state := _reward_rng.state
	var reward := QuestRewardResolver.resolve(quest, _reward_rng)
	var record := _make_pending_claim(source_kind, quest_id, reward)
	if record.is_empty() or not SaveService.prepare_pending_claim(record):
		_reward_rng.state = rng_state
		return {}
	return record


func _make_pending_claim(source_kind: String, quest_id: String, reward: Dictionary) -> Dictionary:
	var normalized_reward := RewardBoxResolver.normalize_reward(reward)
	if normalized_reward.is_empty():
		return {}
	var claim_id := "%s:%s" % [source_kind, quest_id]
	if source_kind == "daily":
		claim_id = "%s:%s:%s" % [source_kind, daily_date, quest_id]
	return {
		"version": 1,
		"claim_id": claim_id,
		"source_kind": source_kind,
		"source_id": quest_id,
		"reward": normalized_reward,
	}


func _apply_pending_claim(record: Dictionary) -> bool:
	var source_kind := str(record.get("source_kind", ""))
	var quest_id := str(record.get("source_id", ""))
	var quest_name := quest_id
	var daily_state: Dictionary = {}
	if source_kind == "main":
		var main := get_main_quest()
		if main.is_empty() or str(main.get("id", "")) != quest_id or not main_ready:
			return false
		quest_name = str(main.get("name", quest_id))
	elif source_kind == "daily":
		var daily_date_prefix := "daily:%s:" % daily_date
		if not str(record.get("claim_id", "")).begins_with(daily_date_prefix):
			return false
		var daily := get_quest_def(quest_id)
		if daily.is_empty() or not dailies.has(quest_id):
			return false
		daily_state = dailies[quest_id]
		if bool(daily_state.get("claimed", false)) or int(daily_state.get("progress", 0)) <= 0:
			return false
		quest_name = str(daily.get("name", quest_id))
	else:
		return false

	# Persist the latest pre-grant state so capacity changes made after prepare
	# survive a failed final checkpoint without replaying an already-saved reward.
	if not SaveService.checkpoint_pending_claim():
		return false
	if not GameState.grant(record.get("reward", {})):
		return false

	if source_kind == "main":
		main_index += 1
		main_progress = 0
		main_ready = false
	elif not daily_state.is_empty():
		daily_state["claimed"] = true

	if not SaveService.finalize_pending_claim():
		SaveService.restore_pending_claim_checkpoint()
		return false

	quest_completed.emit(quest_id, quest_name)
	if source_kind == "main":
		_refresh_state_objectives()
	quests_changed.emit()
	return true


# =============================================================================
# PROGRESS
# =============================================================================

func _matches(obj: Dictionary, type: String, target: String) -> bool:
	if obj["type"] != type:
		return false
	return obj["target"] == "any" or obj["target"] == target or target == "any"


func _advance(type: String, target: String, amount: int) -> void:
	_check_daily_reset()
	var changed := false
	var main := get_main_quest()
	if not main.is_empty() and not main_ready and _matches(main["obj"], type, target):
		main_progress = mini(main_progress + amount, int(main["obj"]["count"]))
		if main_progress >= int(main["obj"]["count"]):
			main_ready = true
			GameEvent.toast.emit("Quest complete: %s" % main["name"], Color(1, 0.85, 0.3))
		changed = true
	for dq in GameContent.DAILY_QUESTS:
		var st: Dictionary = dailies[dq["id"]]
		if st["claimed"] or not _matches(dq["obj"], type, target):
			continue
		var count := int(dq["obj"]["count"])
		if int(st["progress"]) >= count:
			continue
		st["progress"] = mini(int(st["progress"]) + amount, count)
		if int(st["progress"]) >= count:
			GameEvent.toast.emit("Daily complete: %s" % dq["name"], Color(0.6, 1, 0.6))
		changed = true
	if changed:
		quests_changed.emit()


## Query one state objective against the current profile and equipped inventory.
## Equipment targets use Emberfield's displayed level and ItemData rarity values,
## not the reference client's zero-based/raw enum fields.
func get_state_objective_value(obj: Dictionary, inventory: InventoryData = null) -> int:
	var value := -1
	match obj.get("type", ""):
		"level":
			value = GameState.level
		"own_pet":
			value = 1 if GameState.active_pet != "" else 0
		"own_mount":
			value = 1 if not GameState.mounts.is_empty() else 0
		"pet_level":
			value = GameState.max_pet_level()
		"hero_star":
			value = GameState.max_hero_stars()
		"build":
			value = 1 if GameState.building_level(str(obj.get("target", ""))) > 0 else 0
		"equipped_count":
			var equipped_inventory := inventory if inventory != null else GameState.get_inventory()
			value = equipped_inventory.count_equipped_items() if equipped_inventory != null else 0
		"equipped_rarity":
			var rarity_target: Variant = obj.get("target", null)
			if rarity_target is int and int(rarity_target) >= ItemData.ItemRarity.COMMON and int(rarity_target) <= ItemData.ItemRarity.LEGENDARY:
				var rarity_inventory := inventory if inventory != null else GameState.get_inventory()
				value = rarity_inventory.count_equipment_at_or_above_rarity(int(rarity_target)) if rarity_inventory != null else 0
		"equipment_level":
			var level_target: Variant = obj.get("target", null)
			if level_target is int and int(level_target) >= 1:
				var level_inventory := inventory if inventory != null else GameState.get_inventory()
				value = level_inventory.count_equipment_at_or_above_level(int(level_target)) if level_inventory != null else 0
	return value


## Objectives that reflect current state rather than accumulating events.
## Public so gameplay adapters can refresh after inventory-owned mutations.
func refresh_state_objectives(inventory: InventoryData = null) -> void:
	var main := get_main_quest()
	if main.is_empty() or main_ready:
		return
	var obj: Dictionary = main["obj"]
	var value := get_state_objective_value(obj, inventory)
	if value < 0:
		return
	main_progress = mini(value, int(obj["count"]))
	if main_progress >= int(obj["count"]):
		main_ready = true
		GameEvent.toast.emit("Quest complete: %s" % main["name"], Color(1, 0.85, 0.3))
	quests_changed.emit()


func _refresh_state_objectives() -> void:
	refresh_state_objectives()


func _on_enemy_killed(monster_id: String, _pos: Vector2, is_boss: bool) -> void:
	_advance("kill", monster_id, 1)
	if is_boss:
		_advance("boss", monster_id, 1)


func _on_resource_gathered(item_id: String, quantity: int) -> void:
	_advance("gather", item_id, quantity)


func _on_ground_dug(_item_id: String, _quantity: int) -> void:
	_advance("dig", "any", 1)


func _on_zone_entered(zone_id: String) -> void:
	_advance("visit", zone_id, 1)


func _on_building_built(_building_id: String, _level: int) -> void:
	_refresh_state_objectives()


# =============================================================================
# DAILIES
# =============================================================================

func _today() -> String:
	return Time.get_date_string_from_system()


func _reset_dailies() -> void:
	daily_date = _today()
	dailies = {}
	for dq in GameContent.DAILY_QUESTS:
		dailies[dq["id"]] = {"progress": 0, "claimed": false}


func _check_daily_reset() -> void:
	if daily_date != _today():
		var pending := SaveService.get_pending_claim()
		if (
			str(pending.get("source_kind", "")) == "daily"
			and str(pending.get("claim_id", "")).begins_with("daily:%s:" % daily_date)
		):
			return
		_reset_dailies()
		quests_changed.emit()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	var main := get_main_quest()
	return {
		"main_index": main_index,
		"main_quest_id": str(main.get("id", "")),
		"main_progress": main_progress, "main_ready": main_ready,
		"dailies": dailies, "daily_date": daily_date,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	var fallback_index := clampi(int(d.get("main_index", 0)), 0, GameContent.MAIN_QUESTS.size())
	var saved_quest_id := str(d.get("main_quest_id", ""))
	# Saves predating stable quest IDs used the old chain index. q305 was inserted
	# after q01, so old in-progress/completed indices at that boundary shift by one.
	if saved_quest_id.is_empty() and fallback_index > 0:
		fallback_index = mini(fallback_index + 1, GameContent.MAIN_QUESTS.size())
	var saved_quest_index := GameContent.get_main_quest_index(saved_quest_id)
	main_index = saved_quest_index if saved_quest_index >= 0 else fallback_index
	main_progress = int(d.get("main_progress", 0))
	main_ready = bool(d.get("main_ready", false))
	var saved_daily_date := str(d.get("daily_date", ""))
	var pending_claim := SaveService.get_pending_claim()
	var restores_pending_daily := (
		str(pending_claim.get("source_kind", "")) == "daily"
		and str(pending_claim.get("claim_id", "")).begins_with("daily:%s:" % saved_daily_date)
	)
	if saved_daily_date == _today() or restores_pending_daily:
		daily_date = saved_daily_date
		var raw: Dictionary = d.get("dailies", {})
		for dq in GameContent.DAILY_QUESTS:
			var st: Dictionary = raw.get(dq["id"], {})
			dailies[dq["id"]] = {"progress": int(st.get("progress", 0)), "claimed": bool(st.get("claimed", false))}
	_refresh_state_objectives()
	quests_changed.emit()
