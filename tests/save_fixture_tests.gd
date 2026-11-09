extends Node
## Save fixture suite: every historic save format (v0–v5) must load under the current code
## without losing player value. The fixtures are frozen v5-era files (their generator was retired
## with save v6; see git history), so these tests describe the v6 + v7 migration results:
## retired equipment → gold refund, reference weapons → starter weapons, q305–q311 → t01–t06,
## and (v7) augments → socket stones, no player level/XP or hero classes.

const FIXTURE_DIR := "res://tests/fixtures/saves"
const SAVE_PATH := "user://saves/fixture_profile.json"
const HISTORIC := ["v0_legacy", "v1_historic", "v2_historic", "v3_historic", "v4_historic", "v5_full_original"]
const INVALID := ["corrupt_truncated", "future_version", "bad_types"]
const SCENARIOS := ["v5_reference_items", "v5_quest_q306_progress", "v5_pending_claim_q311", "v5_legacy_index_quest", "v6_stones_and_heroes", "v7_pets_and_treats"]

var _failures: Array[String] = []
var _player: StubPlayer


class StubPlayer:
	extends Node
	var inventory := InventoryData.new()
	func get_inventory() -> InventoryData:
		return inventory


func _ready() -> void:
	SaveService.SAVE_PATH = SAVE_PATH
	SaveService.enabled = true
	_player = StubPlayer.new()
	_player.add_to_group("player")
	add_child(_player)

	_test_fixture_set_complete()
	for name: String in HISTORIC:
		_test_full_profile_loads(name)
	_test_round_trip()
	_test_reference_items()
	_test_quest_q306()
	_test_pending_claim_q311()
	_test_legacy_index_quest()
	_test_v6_stones_and_heroes()
	_test_v7_pets_and_treats()
	_test_mount_owner_can_save_and_reload()
	_test_unknown_item_goes_to_lost_and_found()
	_test_migration_is_idempotent()
	for name: String in INVALID:
		_test_invalid_falls_back_to_backup(name)
		_test_invalid_without_backup(name)

	_reset()
	SaveService.delete_save()
	if _failures.is_empty():
		print("[SAVE FIXTURE TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[SAVE FIXTURE TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


# --- tests -------------------------------------------------------------------

func _test_fixture_set_complete() -> void:
	for name: String in HISTORIC + INVALID + SCENARIOS:
		_check(FileAccess.file_exists(_fixture_path(name)), "missing fixture %s" % name)


## v0–v5 all describe the same profile; each must migrate to v6 and keep the player's value.
## Its equipment (fire_blade, leather_armor, silver_ring) was retired: sell values are refunded and
## the flame augment socketed in the blade returns to the bag.
const FULL_PROFILE_GOLD_AFTER_V6 := 1234 + 500 + 40 + 100

func _test_full_profile_loads(name: String) -> void:
	_install(name)
	if not SaveService.load_game():
		_fail("%s: load_game failed (%s)" % [name, _explain(name)])
		return
	var inv := _player.inventory
	_check(not GameState.to_dict().has("level") and not GameState.to_dict().has("heroes"), "%s: level/heroes retired" % name)
	_check(GameState.pet_level("ember_fox:common") == 4 and GameState.active_pet == "ember_fox:common", "%s: pets became Common records" % name)
	_check(GameState.pets.has("moss_turtle:common") and GameState.mount_level("dust_pony") == 1 and GameState.mount_form("dust_pony") == 0, "%s: v8 pet/mount fields" % name)
	_check(GameState.active_mount == "dust_pony" and int(GameState.mounts["dust_pony"]["skin"]) == 1, "%s: mounts" % name)
	_check(str(GameState.plots[0].get("id", "")) == "lumber_mill" and int(GameState.plots[0].get("level", 0)) == 2, "%s: plot 0" % name)
	_check(str(GameState.plots[2].get("id", "")) == "herb_garden", "%s: plot 2" % name)
	_check(GameState.kills_total == 250 and GameState.current_zone == "greenwood", "%s: counters/zone" % name)
	_check(inv.gold == FULL_PROFILE_GOLD_AFTER_V6 and inv.diamonds == 7, "%s: currencies after refunds (gold %d)" % [name, inv.gold])
	_check(inv.get_item_count("wood") == 50 and inv.get_item_count("stone") == 20, "%s: materials" % name)
	_check(inv.get_item_count("health_potion") == 5, "%s: consumables" % name)
	_check(inv.get_item_count("stone_critical_damage_1") == 1, "%s: power augment did not become a Ravager Stone" % name)
	_check(inv.get_item_count("stone_fire_1") == 1, "%s: augment from the retired blade did not return as a stone" % name)
	for slot: String in InventoryData.EQUIPMENT_SLOTS:
		_check(inv.get_equipped(slot) == null, "%s: retired equipment still equipped in %s" % [name, slot])
	_check(str(QuestService.get_main_quest().get("id", "")) == "q03" and QuestService.main_progress == 4, "%s: main quest" % name)
	_check(SaveService.get_pending_claim().is_empty(), "%s: unexpected pending claim" % name)
	_check(SaveService.get_lost_and_found().is_empty(), "%s: nothing should be lost" % name)
	_check(SaveService.get_migration_log().size() >= 3, "%s: refunds were not logged" % name)


## v6 → v7: socketed augments become socket stones in the same sockets' order, runes and hero
## shards are refunded in gold, level/XP/hero fields are dropped and logged, pending XP becomes gold.
func _test_v6_stones_and_heroes() -> void:
	_install("v6_stones_and_heroes")
	if not SaveService.load_game():
		_fail("v6 stones: load failed (%s)" % _explain("v6_stones_and_heroes"))
		return
	var inv := _player.inventory
	var weapon := inv.get_equipped("weapon")
	_check(weapon != null and weapon.id == "emberforged_blade" and weapon.rarity == ItemData.ItemRarity.EPIC, "v6 stones: rare blade is now epic")
	var sockets := weapon.get_gem_sockets() if weapon else ([] as Array[String])
	_check(sockets.size() == 8 and sockets[0] == "stone_critical_2" and sockets[1] == "stone_lifesteal_1", "v6 stones: socketed augments became stones (%s)" % [sockets])
	_check(weapon != null and weapon.count_socketed_gems() == 2, "v6 stones: whirlwind rune left a stone behind")
	_check(inv.get_item_count("stone_fire_3") == 2, "v6 stones: bag augments did not become stones")
	_check(inv.get_item_count("hero_shard") == 0, "v6 stones: hero shards kept")
	# 500 base + 200 whirlwind rune + 7 hero shards × 60 + recovered q02 claim (80 gold + 60 XP → gold)
	_check(inv.gold == 500 + 200 + 7 * 60 + 80 + 60, "v6 stones: refunds wrong (gold %d)" % inv.gold)
	_check(inv.get_item_count("health_potion") == 3, "v6 stones: recovered claim items missing")
	_check(SaveService.get_pending_claim().is_empty() and str(QuestService.get_main_quest().get("id", "")) == "q03", "v6 stones: pending claim was not recovered")
	var log := SaveService.get_migration_log()
	var logged_levels := false
	for line: Variant in log:
		logged_levels = logged_levels or str(line).contains("Character levels")
	_check(logged_levels, "v6 stones: retired level/heroes were not logged")
	_check(SaveService.get_lost_and_found().is_empty(), "v6 stones: something was lost")
	_check(SaveService.save_game(), "v6 stones: resave failed")
	_reset()
	_check(SaveService.load_game(), "v6 stones: reload failed")
	_check(_player.inventory.get_equipped("weapon").get_gem_sockets()[0] == "stone_critical_2", "v6 stones: sockets did not survive a round trip")


## v7 → v8: pets become Common records, levels above 10 are refunded in gold, pet treats
## (bag, Lost & Found, pending reward) become gold, mounts gain level/form/sockets.
func _test_v7_pets_and_treats() -> void:
	_install("v7_pets_and_treats")
	if not SaveService.load_game():
		_fail("v7 pets: load failed (%s)" % _explain("v7_pets_and_treats"))
		return
	_check(GameState.pet_level("ember_fox:common") == 2, "v7 pets: ember fox kept its level")
	_check(GameState.pet_level("lucky_cat:common") == 10 and GameState.active_pet == "lucky_cat:common", "v7 pets: level 13 capped at 10 and still active")
	_check(GameState.mount_level("tusk_boar") == 1 and GameState.companion_sockets("mount", "tusk_boar").size() == 8, "v7 pets: mount gained level and sockets")
	# 300 + levels 10–12 (580 + 635 + 690) + 12 bag treats + 2 lost treats + 6 pending treats, × 15 gold
	var expected := 300 + 580 + 635 + 690 + (12 + 2 + 6) * 15
	_check(_player.inventory.gold == expected, "v7 pets: gold %d, expected %d" % [_player.inventory.gold, expected])
	_check(_player.inventory.get_item_count("wood") == 5, "v7 pets: other items kept")
	_check(SaveService.get_lost_and_found().is_empty(), "v7 pets: lost treats not refunded")
	_check(SaveService.get_pending_claim().is_empty() and str(QuestService.get_main_quest().get("id", "")) == "q05", "v7 pets: pending claim not recovered")


## A migrated save, written and read back, must reproduce the same profile and inventory.
func _test_round_trip() -> void:
	_install("v5_full_original")
	SaveService.load_game()
	var first := _normalize(SaveService.build_snapshot())
	_check(SaveService.save_game(), "round trip: save failed")
	_reset()
	_check(SaveService.load_game(), "round trip: reload failed")
	var second := _normalize(SaveService.build_snapshot())
	_check(_json(second["profile"]) == _json(first["profile"]), "round trip: profile changed")
	_check(_json(second["inventory"]) == _json(first["inventory"]), "round trip: inventory changed")
	_check(_json(second["migration_log"]) == _json(first["migration_log"]), "round trip: migration log changed")
	for key in ["main_quest_id", "main_progress", "main_ready", "main_index"]:
		_check(_json(second["quests"].get(key)) == _json(first["quests"].get(key)), "round trip: quests.%s changed" % key)


## Reference-card weapons become the original starter weapons; rolled damage above the new
## weapon's attack is compensated in gold.
func _test_reference_items() -> void:
	_install("v5_reference_items")
	var fixture: Dictionary = _read_fixture("v5_reference_items")["inventory"]
	_check(SaveService.load_game(), "reference: load failed (%s)" % _explain("v5_reference_items"))
	var weapon := _player.inventory.get_equipped("weapon")
	_check(weapon != null and weapon.id == "ashwood_blade", "reference: th_weapon_28 did not become ashwood_blade")
	_check(_player.inventory.get_item_count("ironbark_cleaver") == 1, "reference: th_weapon_29 did not become ironbark_cleaver")
	var expected_gold := int(fixture.get("gold", 0))
	var pairs := [[fixture["equipment"]["weapon"], "ashwood_blade"]]
	for entry: Dictionary in fixture["slots"]:
		if str(entry.get("id", "")) == "th_weapon_29":
			pairs.append([entry, "ironbark_cleaver"])
	for pair: Array in pairs:
		var old_damage := float(pair[0]["reference"]["stats"]["damage"])
		var new_attack := ItemDatabase.get_item(pair[1]).get_scaled_attack_bonus()
		expected_gold += maxi(0, roundi((old_damage - new_attack) * SaveService.REFERENCE_DAMAGE_COMPENSATION))
	_check(_player.inventory.gold == expected_gold, "reference: compensation gold %d, expected %d" % [_player.inventory.gold, expected_gold])


func _test_quest_q306() -> void:
	_install("v5_quest_q306_progress")
	_check(SaveService.load_game(), "q306: load failed")
	_check(str(QuestService.get_main_quest().get("id", "")) == "t02" and QuestService.main_progress == 0, "q306: did not continue as t02")


## A journalled claim must complete exactly once on load, and never again on a later load.
## q311 is retired: the claim continues as t06.
func _test_pending_claim_q311() -> void:
	_install("v5_pending_claim_q311")
	var before := int(_read_fixture("v5_pending_claim_q311")["inventory"].get("diamonds", 0))
	_check(SaveService.load_game(), "q311: load failed (%s)" % _explain("v5_pending_claim_q311"))
	_check(_player.inventory.diamonds == before + 1, "q311: reward not applied exactly once (%d -> %d)" % [before, _player.inventory.diamonds])
	_check(SaveService.get_pending_claim().is_empty(), "q311: claim still pending after recovery")
	_check(str(QuestService.get_main_quest().get("id", "")) == "t07", "q311: claim did not advance from t06 to t07")
	_check(not QuestService.claim("t06") and not QuestService.claim("q311"), "q311: duplicate claim accepted")
	_check(_player.inventory.diamonds == before + 1, "q311: duplicate claim changed diamonds")
	_reset()
	_check(SaveService.load_game(), "q311: reload after recovery failed")
	_check(_player.inventory.diamonds == before + 1, "q311: reward re-applied on reload")


## Saves predating stable quest IDs stored only the chain index; index 3 always meant q04.
func _test_legacy_index_quest() -> void:
	_install("v5_legacy_index_quest")
	_check(SaveService.load_game(), "legacy index: load failed")
	var expected_id := "q04"
	_check(str(QuestService.get_main_quest().get("id", "")) == expected_id, "legacy index: expected %s, got %s" % [expected_id, QuestService.get_main_quest().get("id", "")])


## Regression: after a JSON round trip, skin indices are floats. A profile owning a mount must
## still pass validation both when the save is written and when it is loaded.
func _test_mount_owner_can_save_and_reload() -> void:
	_reset()
	SaveService.delete_save()
	GameState.mounts = {"dust_pony": {"skin": 0, "skins": [0]}}
	GameState.active_mount = "dust_pony"
	_check(SaveService.save_game(), "mount owner: save_game refused the profile")
	_reset()
	_check(SaveService.load_game(), "mount owner: saved profile failed to load")
	_check(GameState.mounts.has("dust_pony") and GameState.active_mount == "dust_pony", "mount owner: mount lost on reload")


## Items the current game doesn't know are kept in Lost & Found, never dropped.
func _test_unknown_item_goes_to_lost_and_found() -> void:
	var data := _read_fixture("v5_full_original")
	(data["inventory"]["slots"] as Array)[5] = {"id": "mystery_relic", "qty": 2}
	_reset()
	SaveService.delete_save()
	_write_user(SAVE_PATH, JSON.stringify(data))
	_check(SaveService.load_game(), "lost and found: load failed (%s)" % _explain("v5_full_original"))
	var lost := SaveService.get_lost_and_found()
	_check(lost.size() == 1 and str(lost[0].get("id", "")) == "mystery_relic" and int(lost[0].get("qty", 0)) == 2, "unknown item not kept in Lost & Found: %s" % [lost])


## Running the migration chain on an already-migrated save changes nothing.
func _test_migration_is_idempotent() -> void:
	_install("v5_full_original")
	var migrated := SaveService.read_snapshot()
	_check(int(migrated.get("version", 0)) == SaveService.SAVE_VERSION, "fixture did not migrate to the current version")
	var again := SaveService._migrate(migrated.duplicate(true))
	_check(_json(again) == _json(migrated), "migrating a current save again changed it")


## An invalid main file must fall back to a valid .bak, and saving must never overwrite that backup.
func _test_invalid_falls_back_to_backup(name: String) -> void:
	_install(name)
	var backup_text := FileAccess.get_file_as_string(_fixture_path("v5_full_original"))
	_write_user(SAVE_PATH + ".bak", backup_text)
	_check(SaveService.load_game(), "%s: did not fall back to backup" % name)
	_check(GameState.kills_total == 250 and _player.inventory.gold == FULL_PROFILE_GOLD_AFTER_V6, "%s: backup state not loaded" % name)
	_check(SaveService.save_game(), "%s: save after fallback failed" % name)
	_check(FileAccess.get_file_as_string(SAVE_PATH + ".bak") == backup_text, "%s: good backup was overwritten" % name)


func _test_invalid_without_backup(name: String) -> void:
	_install(name)
	_check(not SaveService.load_game(), "%s: invalid save loaded without a backup" % name)


# --- helpers -----------------------------------------------------------------

## Names the snapshot section the validator rejects, so a failure is actionable.
func _explain(name: String) -> String:
	var migrated := SaveService._migrate(_read_fixture(name))
	if migrated.is_empty():
		return "migration rejected"
	var parts: Array[String] = []
	var profile: Dictionary = migrated.get("profile", {})
	if not SaveService._validate_profile(profile):
		parts.append("profile")
		for key: String in profile:
			if not SaveService._validate_profile({key: profile[key]}):
				parts.append("profile.%s" % key)
	if not SaveService._validate_quests(migrated.get("quests", {})):
		parts.append("quests")
	if not SaveService._validate_inventory(migrated.get("inventory", {})):
		parts.append("inventory")
	return ", ".join(parts) if not parts.is_empty() else "version/pending_claim"


func _reset() -> void:
	GameState.reset_profile()
	QuestService.reset()
	SaveService.discard_pending_claim()
	_player.inventory = InventoryData.new()


func _install(name: String) -> void:
	_reset()
	SaveService.delete_save()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_PATH.get_base_dir()))
	_write_user(SAVE_PATH, FileAccess.get_file_as_string(_fixture_path(name)))


func _write_user(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail("cannot write %s" % path)
		return
	f.store_string(text)
	f.close()


func _fixture_path(name: String) -> String:
	return "%s/%s.json" % [FIXTURE_DIR, name]


func _read_fixture(name: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_fixture_path(name)))
	return parsed if parsed is Dictionary else {}


## JSON round-trip so ints/floats compare the same way as the fixture file.
func _normalize(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	return parsed if parsed is Dictionary else {}


func _json(value: Variant) -> String:
	return JSON.stringify(_normalize({"v": value}), "", true)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("[SAVE FIXTURE TEST] " + message)
