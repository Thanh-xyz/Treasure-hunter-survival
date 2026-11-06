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


func _ready() -> void:
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
	var main := get_main_quest()
	if not main.is_empty() and main["id"] == quest_id:
		if not main_ready:
			return false
		if not GameState.grant(main.get("reward", {})):
			return false
		quest_completed.emit(quest_id, main["name"])
		main_index += 1
		main_progress = 0
		main_ready = false
		_refresh_state_objectives()
		quests_changed.emit()
		return true
	if dailies.has(quest_id):
		var dq := get_quest_def(quest_id)
		var st: Dictionary = dailies[quest_id]
		if st["claimed"] or int(st["progress"]) < int(dq["obj"]["count"]):
			return false
		if not GameState.grant(dq.get("reward", {})):
			return false
		st["claimed"] = true
		quest_completed.emit(quest_id, dq["name"])
		quests_changed.emit()
		return true
	return false


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
		_reset_dailies()
		quests_changed.emit()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"main_index": main_index, "main_progress": main_progress, "main_ready": main_ready,
		"dailies": dailies, "daily_date": daily_date,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	main_index = clampi(int(d.get("main_index", 0)), 0, GameContent.MAIN_QUESTS.size())
	main_progress = int(d.get("main_progress", 0))
	main_ready = bool(d.get("main_ready", false))
	if str(d.get("daily_date", "")) == _today():
		daily_date = _today()
		var raw: Dictionary = d.get("dailies", {})
		for dq in GameContent.DAILY_QUESTS:
			var st: Dictionary = raw.get(dq["id"], {})
			dailies[dq["id"]] = {"progress": int(st.get("progress", 0)), "claimed": bool(st.get("claimed", false))}
	_refresh_state_objectives()
	quests_changed.emit()
