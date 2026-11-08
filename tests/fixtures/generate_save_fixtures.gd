extends Node
## Regenerates tests/fixtures/saves/*.json from the live v5 save code.
##
## Fixtures are a frozen record of the v5 format; regenerate only on purpose:
##   godot --headless --path . res://tests/fixtures/GenerateSaveFixtures.tscn
## Every generated snapshot is checked with SaveService's own validator before it is written.

const OUT_DIR := "res://tests/fixtures/saves"
const FIXED_SAVED_AT := 1793000000.0   ## constant timestamp keeps fixtures byte-stable
const FIXED_DAILY_DATE := "2026-11-01"  ## dailies otherwise use today's date

var _player: StubPlayer
var _errors: Array[String] = []


class StubPlayer:
	extends Node
	var inventory := InventoryData.new()
	func get_inventory() -> InventoryData:
		return inventory


func _ready() -> void:
	SaveService.enabled = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_player = StubPlayer.new()
	_player.add_to_group("player")
	add_child(_player)

	var full := _full_original()
	_write("v5_full_original", full)
	_write_historic_versions(full)
	_write("v5_reference_items", _reference_items())
	_write("v5_quest_q306_progress", _quest_state({"main_quest_id": "q306", "main_progress": 0, "main_ready": false}))
	_write("v5_pending_claim_q311", _pending_claim_q311())
	_write_raw("v5_legacy_index_quest", _legacy_index_quest())
	_write_invalid(full)

	if _errors.is_empty():
		print("[FIXTURES] generated into %s" % OUT_DIR)
		get_tree().quit(0)
	else:
		for e in _errors:
			push_error("[FIXTURES] " + e)
		get_tree().quit(1)


# --- scenarios ---------------------------------------------------------------

func _reset() -> void:
	GameState.reset_profile()
	QuestService.reset()
	SaveService.discard_pending_claim()
	_player.inventory = InventoryData.new()


func _full_original() -> Dictionary:
	_reset()
	GameState.level = 12
	GameState.xp = 340
	GameState.heroes = {"warden": {"stars": 2}, "ranger": {"stars": 1}}
	GameState.hero_id = "ranger"
	GameState.pets = {"ember_fox": {"level": 4}, "moss_turtle": {"level": 1}}
	GameState.active_pet = "ember_fox"
	GameState.mounts = {"dust_pony": {"skin": 1, "skins": [0, 1]}}
	GameState.active_mount = "dust_pony"
	GameState.plots[0] = {"id": "lumber_mill", "level": 2, "last_collect": 1792990000.0}
	GameState.plots[2] = {"id": "herb_garden", "level": 1, "last_collect": 1792995000.0}
	GameState.boss_kills = {"mire_king": 2}
	GameState.kills_total = 250
	GameState.current_zone = "greenwood"
	QuestService.from_dict({"main_quest_id": "q03", "main_progress": 4, "main_ready": false})

	var inv := _player.inventory
	inv.gold = 1234
	inv.diamonds = 7
	inv.add_item(ItemDatabase.get_item("wood"), 50)
	inv.add_item(ItemDatabase.get_item("stone"), 20)
	inv.add_item(ItemDatabase.get_item("health_potion"), 5)
	inv.add_item(ItemDatabase.get_item("power_augment_t1"), 1)
	_equip_copy("fire_blade", 3, ["flame_augment_t1"])
	_equip_copy("leather_armor", 1, [])
	_equip_copy("silver_ring", 1, [])
	return _snapshot()


func _reference_items() -> Dictionary:
	_reset()
	var equipped := ReferenceEquipmentCatalog.materialize(28, _mid_stats(28))
	var bagged := ReferenceEquipmentCatalog.materialize(29, _mid_stats(29))
	_require(equipped != null and bagged != null, "reference equipment failed to materialize")
	if equipped != null and bagged != null:
		_player.inventory.add_item(equipped, 1)
		_require(_player.inventory.equip_item(_slot_of(equipped)), "could not equip reference weapon")
		_player.inventory.add_item(bagged, 1)
	return _snapshot()


func _quest_state(quests: Dictionary) -> Dictionary:
	_reset()
	QuestService.from_dict(quests)
	return _snapshot()


func _pending_claim_q311() -> Dictionary:
	_reset()
	QuestService.from_dict({"main_quest_id": "q311", "main_progress": 1, "main_ready": true})
	var quest := GameContent.MAIN_QUESTS[GameContent.get_main_quest_index("q311")] as Dictionary
	var rng := RandomNumberGenerator.new()
	rng.seed = 311
	var reward := QuestRewardResolver.resolve(quest, rng)
	_require(not reward.is_empty(), "q311 reward did not resolve")
	SaveService._pending_claim = SaveService._normalize_pending_claim({
		"version": 1, "claim_id": "main:q311", "source_kind": "main", "source_id": "q311", "reward": reward,
	})
	_require(not SaveService._pending_claim.is_empty(), "q311 pending claim did not normalize")
	var data := _snapshot()
	SaveService.discard_pending_claim()
	return data


## Saves made before stable quest IDs stored only the chain index.
func _legacy_index_quest() -> Dictionary:
	var data := _quest_state({"main_quest_id": "q03"})
	data["quests"] = {"main_index": 3, "main_progress": 1, "main_ready": false, "dailies": {}, "daily_date": ""}
	return data


func _write_historic_versions(full: Dictionary) -> void:
	for version in range(0, 5):
		var data := full.duplicate(true)
		data.erase("pending_claim")
		if version == 0:
			data.erase("version")
		else:
			data["version"] = version
		if version == 4:
			data["pending_claim"] = {}
		_write_raw("v%d_%s" % [version, "legacy" if version == 0 else "historic"], data)


func _write_invalid(full: Dictionary) -> void:
	var text := JSON.stringify(full, "  ", true)
	_store("corrupt_truncated", text.substr(0, text.length() / 2))
	var future := full.duplicate(true)
	future["version"] = 99
	_store("future_version", JSON.stringify(future, "  ", true))
	var bad := full.duplicate(true)
	(bad["profile"] as Dictionary)["level"] = "twelve"
	_store("bad_types", JSON.stringify(bad, "  ", true))


# --- helpers -----------------------------------------------------------------

func _equip_copy(item_id: String, level: int, augments: Array) -> void:
	var item := ItemDatabase.get_item_copy(item_id) as ItemData
	_require(item != null, "unknown item %s" % item_id)
	if item == null:
		return
	_require(level <= item.max_upgrade_level, "%s max level %d < %d" % [item_id, item.max_upgrade_level, level])
	item.enhancement_level = level
	for augment_id: String in augments:
		item.applied_augments.append(augment_id)
	_require(_player.inventory.add_item(item, 1) == 0, "no space for %s" % item_id)
	_require(_player.inventory.equip_item(_slot_of(item)), "could not equip %s" % item_id)


func _slot_of(item: ItemData) -> int:
	for i in range(_player.inventory.inventory_slots.size()):
		if _player.inventory.inventory_slots[i].get("item") == item:
			return i
	return -1


func _mid_stats(card_id: int) -> Dictionary:
	var ranges: Dictionary = (ReferenceEquipmentCatalog._CARDS[card_id] as Dictionary)["ranges"]
	var stats := {}
	for key: String in ranges:
		stats[key] = snappedf((float(ranges[key]["min"]) + float(ranges[key]["max"])) / 2.0, 0.01)
	return stats


func _snapshot() -> Dictionary:
	var data := SaveService.build_snapshot()
	data["saved_at"] = FIXED_SAVED_AT
	var quests: Dictionary = data.get("quests", {})
	if quests.has("daily_date"):
		quests["daily_date"] = FIXED_DAILY_DATE
	return data


func _write(name: String, data: Dictionary) -> void:
	if not SaveService._validate_snapshot(data):
		_errors.append("%s fails SaveService validation: %s" % [name, _diagnose(data)])
	_write_raw(name, data)


func _diagnose(data: Dictionary) -> String:
	var parts: Array[String] = []
	if not SaveService._validate_profile(data.get("profile", {})):
		parts.append("profile")
	if not SaveService._validate_quests(data.get("quests", {})):
		parts.append("quests")
	var inv: Dictionary = data.get("inventory", {})
	if not SaveService._validate_inventory(inv):
		parts.append("inventory")
		for entry: Dictionary in inv.get("slots", []):
			if not entry.is_empty() and not SaveService._validate_item_entry(entry):
				parts.append("slot %s" % JSON.stringify(entry))
		var equipment: Dictionary = inv.get("equipment", {})
		for slot: String in equipment:
			if not SaveService._validate_item_entry(equipment[slot], slot):
				parts.append("equip %s %s" % [slot, JSON.stringify(equipment[slot])])
	return ", ".join(parts) if not parts.is_empty() else "other (version/pending_claim)"


func _write_raw(name: String, data: Dictionary) -> void:
	_store(name, JSON.stringify(data, "  ", true))


func _store(name: String, text: String) -> void:
	var f := FileAccess.open("%s/%s.json" % [OUT_DIR, name], FileAccess.WRITE)
	_require(f != null, "cannot write fixture %s" % name)
	if f != null:
		f.store_string(text + "\n")
		f.close()


func _require(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
