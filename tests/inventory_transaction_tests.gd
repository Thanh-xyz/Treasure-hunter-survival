extends Node

var _failures: Array[String] = []
var _player: StubPlayer


class StubPlayer:
	extends Node
	var inventory := InventoryData.new()
	func get_inventory() -> InventoryData:
		return inventory


func _ready() -> void:
	SaveService.SAVE_PATH = "user://saves/inventory_transaction_profile.json"
	SaveService.enabled = true
	SaveService.delete_save()
	_player = StubPlayer.new()
	_player.add_to_group("player")
	add_child(_player)
	_test_inventory_transaction()
	_test_inventory_add_signals()
	_test_economy_transaction()
	_test_shop_purchase_transaction()
	_test_sale_transaction()
	_test_equipment_transactions()
	_test_skill_cooldown_lifecycle()
	_test_health_bonus_removal()
	await _test_map_load_recovery()
	await _test_hurtbox_reset_race()
	_test_equipment_enhancement()
	_test_equipment_quest_objectives()
	_test_inventory_removal_invariants()
	_test_recipe_catalog_validation()
	_test_reward_box_resolver()
	_test_reward_box_checkbox_resolver()
	_test_reward_box_catalog()
	_test_reference_equipment_reward_resolver()
	_test_reference_equipment_stat_generator()
	_test_quest_reward_resolver()
	_test_reference_equipment_catalog()
	_test_crafting_transaction()
	_test_quest305_claim_transaction()
	_test_quest_claim_transaction()
	_test_daily_claim_recovery()
	_test_exact_equipment_reward_transaction()
	_test_building_collection_transaction()
	_test_building_upgrade_transaction()
	SaveService.delete_save()
	if _failures.is_empty():
		print("[INVENTORY TRANSACTION TEST] ALL PASSED")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("[INVENTORY TRANSACTION TEST] " + failure)
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _full_inventory_with_craft_materials() -> InventoryData:
	var inventory := InventoryData.new()
	inventory.add_item(ItemDatabase.get_item("fire_shard"), 4)
	inventory.add_item(ItemDatabase.get_item("iron_ore"), 3)
	inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE - 2)
	return inventory


func _test_inventory_transaction() -> void:
	var inventory := _full_inventory_with_craft_materials()
	var signal_count := {"value": 0}
	inventory.inventory_changed.connect(func() -> void: signal_count["value"] += 1)
	var removals: Array[Dictionary] = [
		{"item": ItemDatabase.get_item("fire_shard"), "quantity": 3},
		{"item": ItemDatabase.get_item("iron_ore"), "quantity": 2},
	]
	var additions: Array[Dictionary] = [
		{"item": ItemDatabase.get_item_copy("flame_augment_t1"), "quantity": 1},
	]
	_check(not inventory.transact_items(removals, additions), "full inventory accepted a transaction")
	_check(int(signal_count["value"]) == 0, "failed transaction emitted an inventory change")
	_check(inventory.get_item_count("fire_shard") == 4, "failed transaction consumed fire shards")
	_check(inventory.get_item_count("iron_ore") == 3, "failed transaction consumed iron ore")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	signal_count["value"] = 0
	_check(inventory.transact_items(removals, additions), "transaction failed after freeing a slot")
	_check(int(signal_count["value"]) == 1, "successful transaction did not emit exactly one change")
	_check(inventory.get_item_count("flame_augment_t1") == 1, "successful transaction omitted output")


func _test_inventory_add_signals() -> void:
	var inventory := InventoryData.new()
	var signals := {"value": 0}
	inventory.inventory_changed.connect(func() -> void: signals["value"] += 1)
	var sword := ItemDatabase.get_item("iron_sword")
	var wood := ItemDatabase.get_item("wood")

	_check(inventory.add_item(sword, InventoryData.INVENTORY_SIZE) == 0, "inventory setup did not fill all slots")
	_check(int(signals["value"]) == 1, "successful multi-slot add did not emit exactly one change")
	signals["value"] = 0
	_check(inventory.add_item(wood, 1) == 1, "full inventory accepted an item")
	_check(int(signals["value"]) == 0, "no-op add emitted an inventory change")
	_check(inventory.add_item(null, 1) == 1, "null item add returned an unexpected remainder")
	_check(inventory.add_item(wood, 0) == 0, "zero-quantity add returned an unexpected remainder")
	_check(int(signals["value"]) == 0, "invalid add emitted an inventory change")

	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	signals["value"] = 0
	_check(inventory.add_item(wood, wood.max_stack + 1) == 1, "partial add returned the wrong remainder")
	_check(inventory.get_item_count("wood") == wood.max_stack, "partial add stored the wrong quantity")
	_check(int(signals["value"]) == 1, "partial add did not emit exactly one change")


func _test_reward_box_resolver() -> void:
	var entries: Array[Dictionary] = [
		{"weight": 34.0, "reward": {"gold": 100}},
		{"weight": 33.0, "reward": {"diamonds": 1}},
		{"weight": 33.0, "reward": {"xp": 5, "items": {"wood": 2}}},
	]
	var first_rng := RandomNumberGenerator.new()
	var replay_rng := RandomNumberGenerator.new()
	first_rng.seed = 149
	replay_rng.seed = 149
	var seen := {}
	for index in range(100):
		var reward := RewardBoxResolver.resolve(entries, first_rng)
		var replay := RewardBoxResolver.resolve(entries, replay_rng)
		_check(reward == replay, "same reward-box seed diverged at roll %d" % index)
		_check(not reward.is_empty(), "valid reward box returned no reward")
		seen[JSON.stringify(reward)] = true
	_check(seen.size() == 3, "weighted reward box did not reach every valid entry")
	_check(RewardBoxResolver.resolve_roll(entries, 1) == {"gold": 100}, "roll 1 missed first reward")
	_check(RewardBoxResolver.resolve_roll(entries, 34) == {"gold": 100}, "roll 34 missed first reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 35) == {"diamonds": 1}, "roll 35 missed second reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 67) == {"diamonds": 1}, "roll 67 missed second reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 68) == {"xp": 5, "items": {"wood": 2}}, "roll 68 missed third reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 100) == {"xp": 5, "items": {"wood": 2}}, "roll 100 missed third reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 0).is_empty(), "reward box accepted roll zero")
	_check(RewardBoxResolver.resolve_roll(entries, 101).is_empty(), "reward box accepted roll above total")

	var normalized_rng := RandomNumberGenerator.new()
	normalized_rng.seed = 1
	var source_reward := {"xp": 0, "gold": 5.0, "items": {"wood": 2.0}}
	var normalized := RewardBoxResolver.resolve([
		{"weight": 1, "reward": source_reward},
	], normalized_rng)
	_check(normalized == {"gold": 5, "items": {"wood": 2}}, "reward normalization changed the payload")
	normalized["gold"] = 999
	(normalized["items"] as Dictionary)["wood"] = 999
	_check(source_reward == {"xp": 0, "gold": 5.0, "items": {"wood": 2.0}}, "resolved reward shared source state")

	var source_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	var equipment_reward := {"equipment": [{"card_id": 28, "stats": source_stats}]}
	var normalized_equipment := RewardBoxResolver.normalize_reward(equipment_reward)
	_check(normalized_equipment == {"equipment": [{"card_id": 28, "stats": source_stats}]}, "exact equipment reward normalization drifted")
	((normalized_equipment["equipment"] as Array)[0]["stats"] as Dictionary)["damage"] = 49.0
	_check(is_equal_approx(float(source_stats["damage"]), 29.8), "normalized equipment reward shared source stats")
	_check(
		RewardBoxResolver.resolve_roll([{"weight": 1, "reward": equipment_reward}], 1)
		== {"equipment": [{"card_id": 28, "stats": source_stats}]},
		"weighted reward did not preserve exact equipment",
	)

	var invalid_cases: Array = [
		[],
		[null],
		[{"weight": 0, "reward": {"gold": 1}}],
		[{"weight": 1.5, "reward": {"gold": 1}}],
		[{"weight": 1, "reward": {}}],
		[{"weight": 1, "reward": {"gold": -1}}],
		[{"weight": 1, "reward": {"unknown": 1}}],
		[{"weight": 1, "reward": {"items": {"missing_item": 1}}}],
		[{"weight": 1, "reward": {"items": {"wood": 0}}}],
		[{"weight": 1, "reward": {"equipment": "card_28"}}],
		[{"weight": 1, "reward": {"equipment": [{"card_id": 999, "stats": source_stats}]}}],
		[{"weight": 1, "reward": {"equipment": [{"card_id": 28, "stats": {"health": 13.9, "damage": 29.8}}]}}],
		[{"weight": 1, "reward": {"equipment": [{"card_id": 28, "stats": source_stats, "asset_id": "spoofed"}]}}],
		[entries[0], {"weight": 1, "reward": {"items": {"missing_item": 1}}}],
	]
	for invalid: Array in invalid_cases:
		var invalid_rng := RandomNumberGenerator.new()
		invalid_rng.seed = 1
		_check(RewardBoxResolver.resolve(invalid, invalid_rng).is_empty(), "invalid reward box resolved: %s" % [invalid])
	_check(RewardBoxResolver.resolve(entries, null).is_empty(), "reward box accepted a missing RNG")
	var too_many_equipment: Array = []
	for _index in range(InventoryData.INVENTORY_SIZE + 1):
		too_many_equipment.append({"card_id": 28, "stats": source_stats})
	_check(RewardBoxResolver.normalize_reward({"equipment": too_many_equipment}).is_empty(), "reward accepted more equipment than inventory capacity")


func _test_reward_box_checkbox_resolver() -> void:
	var entries: Array[Dictionary] = [
		{"chance": 100.0, "reward": {"gold": 100, "items": {"wood": 1}}},
		{"chance": 50.0, "reward": {"gold": 25, "items": {"wood": 2}}},
		{"chance": 50.0, "reward": {"diamonds": 1, "items": {"stone": 3}}},
	]
	_check(
		RewardBoxResolver.resolve_checkbox_rolls(entries, [100, 50, 51])
		== {"gold": 125, "items": {"wood": 3}},
		"checkbox reward did not merge successful entries",
	)
	_check(
		RewardBoxResolver.resolve_checkbox_rolls(entries, [1, 51, 50])
		== {"gold": 100, "diamonds": 1, "items": {"wood": 1, "stone": 3}},
		"checkbox reward used incorrect inclusive boundaries",
	)
	_check(
		RewardBoxResolver.resolve_checkbox_rolls(entries, [100, 100, 100])
		== {"gold": 100, "items": {"wood": 1}},
		"guaranteed checkbox entry did not resolve independently",
	)
	_check(
		RewardBoxResolver.resolve_checkbox_rolls([
			{"chance": 50, "reward": {"gold": 1}},
		], [51]).is_empty(),
		"missed checkbox entry returned a reward",
	)

	var first_rng := RandomNumberGenerator.new()
	var replay_rng := RandomNumberGenerator.new()
	first_rng.seed = 153
	replay_rng.seed = 153
	for index in range(100):
		_check(
			RewardBoxResolver.resolve_checkbox(entries, first_rng)
			== RewardBoxResolver.resolve_checkbox(entries, replay_rng),
			"same checkbox seed diverged at roll %d" % index,
		)

	var source_reward := {"gold": 10.0, "items": {"wood": 2.0}}
	var normalized := RewardBoxResolver.resolve_checkbox_rolls([
		{"chance": 100.0, "reward": source_reward},
		{"chance": 100, "reward": {"gold": 5, "items": {"wood": 1}}},
	], [100, 100])
	_check(normalized == {"gold": 15, "items": {"wood": 3}}, "checkbox reward normalization drifted")
	normalized["gold"] = 999
	(normalized["items"] as Dictionary)["wood"] = 999
	_check(source_reward == {"gold": 10.0, "items": {"wood": 2.0}}, "checkbox reward shared source state")
	var equipment_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	var merged_equipment := RewardBoxResolver.resolve_checkbox_rolls([
		{"chance": 100, "reward": {"equipment": [{"card_id": 28, "stats": equipment_stats}]}},
		{"chance": 100, "reward": {"equipment": [{"card_id": 30, "stats": {"health": 12.0, "damage": 20.0, "speed": 1.25}}]}},
	], [100, 100])
	_check((merged_equipment.get("equipment", []) as Array).size() == 2, "checkbox reward did not merge exact equipment instances")

	var invalid_cases: Array = [
		[],
		[null],
		[{"chance": 0, "reward": {"gold": 1}}],
		[{"chance": 101, "reward": {"gold": 1}}],
		[{"chance": 50.5, "reward": {"gold": 1}}],
		[{"chance": 50, "reward": {}}],
		[{"chance": 50, "reward": {"unknown": 1}}],
		[{"chance": 50, "reward": {"items": {"missing_item": 1}}}],
	]
	for invalid: Array in invalid_cases:
		var invalid_rng := RandomNumberGenerator.new()
		invalid_rng.seed = 1
		var initial_state := invalid_rng.state
		_check(
			RewardBoxResolver.resolve_checkbox(invalid, invalid_rng).is_empty(),
			"invalid checkbox reward box resolved: %s" % [invalid],
		)
		_check(invalid_rng.state == initial_state, "invalid checkbox reward consumed RNG state")
	_check(RewardBoxResolver.resolve_checkbox(entries, null).is_empty(), "checkbox reward accepted a missing RNG")
	_check(RewardBoxResolver.resolve_checkbox_rolls(entries, [1, 1]).is_empty(), "checkbox reward accepted too few rolls")
	_check(RewardBoxResolver.resolve_checkbox_rolls(entries, [1, 1, 1, 1]).is_empty(), "checkbox reward accepted too many rolls")
	_check(RewardBoxResolver.resolve_checkbox_rolls(entries, [0, 1, 1]).is_empty(), "checkbox reward accepted roll zero")
	_check(RewardBoxResolver.resolve_checkbox_rolls(entries, [101, 1, 1]).is_empty(), "checkbox reward accepted roll above 100")
	_check(RewardBoxResolver.resolve_checkbox_rolls([
		{"chance": 100, "reward": {"gold": 9223372036854775807}},
		{"chance": 100, "reward": {"gold": 1}},
	], [1, 1]).is_empty(), "checkbox reward accepted an overflowing total")


func _test_reward_box_catalog() -> void:
	var expected := {
		98: {"diamonds": 1},
		150: {"gold": 100},
		151: {"gold": 200},
		152: {"gold": 300},
	}
	for box_id: int in expected:
		_check(RewardBoxCatalog.has_box(box_id), "verified reward box %d is missing" % box_id)
		var entries := RewardBoxCatalog.get_entries(box_id)
		_check(entries == [{"weight": 100, "reward": expected[box_id]}], "reward box %d data drifted" % box_id)
		var rng := RandomNumberGenerator.new()
		rng.seed = box_id
		_check(RewardBoxCatalog.resolve(box_id, rng) == expected[box_id], "reward box %d resolved incorrectly" % box_id)
		(entries[0]["reward"] as Dictionary).clear()
		_check(RewardBoxCatalog.get_entries(box_id) == [{"weight": 100, "reward": expected[box_id]}], "reward box %d exposed mutable catalog state" % box_id)
	_check(not RewardBoxCatalog.has_box(149), "unmapped Box 149 was registered prematurely")
	_check(RewardBoxCatalog.get_entries(149).is_empty(), "unknown reward box returned entries")
	var missing_rng := RandomNumberGenerator.new()
	missing_rng.seed = 149
	_check(RewardBoxCatalog.resolve(149, missing_rng).is_empty(), "unknown reward box resolved a reward")


func _test_reference_equipment_reward_resolver() -> void:
	var options: Array = [
		{"weight": 34, "card_id": 28},
		{"weight": 33, "card_id": 29},
		{"weight": 33, "card_id": 30},
	]
	_check(RewardBoxCatalog.has_equipment_box(149), "verified equipment Box 149 is missing")
	_check(not RewardBoxCatalog.has_box(149), "equipment Box 149 leaked into direct canonical boxes")
	_check(RewardBoxCatalog.get_equipment_options(149) == options, "Box 149 equipment options drifted")
	_check(RewardBoxCatalog.select_equipment_roll(149, 1) == {"box_id": 149, "roll": 1, "card_id": 28}, "Box 149 roll 1 missed card 28")
	_check(RewardBoxCatalog.select_equipment_roll(149, 34)["card_id"] == 28, "Box 149 roll 34 missed card 28")
	_check(RewardBoxCatalog.select_equipment_roll(149, 35)["card_id"] == 29, "Box 149 roll 35 missed card 29")
	_check(RewardBoxCatalog.select_equipment_roll(149, 67)["card_id"] == 29, "Box 149 roll 67 missed card 29")
	_check(RewardBoxCatalog.select_equipment_roll(149, 68)["card_id"] == 30, "Box 149 roll 68 missed card 30")
	_check(RewardBoxCatalog.select_equipment_roll(149, 100)["card_id"] == 30, "Box 149 roll 100 missed card 30")
	_check(RewardBoxCatalog.select_equipment_roll(149, 0).is_empty(), "Box 149 accepted roll zero")
	_check(RewardBoxCatalog.select_equipment_roll(149, 101).is_empty(), "Box 149 accepted roll above total")
	_check(RewardBoxCatalog.select_equipment_roll(999, 1).is_empty(), "unknown equipment box selected a card")
	var mutable_options := RewardBoxCatalog.get_equipment_options(149)
	mutable_options[0]["card_id"] = 30
	_check(RewardBoxCatalog.get_equipment_options(149) == options, "Box 149 exposed mutable option state")

	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 149
	second_rng.seed = 149
	_check(
		RewardBoxCatalog.select_equipment(149, first_rng) == RewardBoxCatalog.select_equipment(149, second_rng),
		"Box 149 seeded selection was not deterministic",
	)
	var invalid_cases: Array = [
		[],
		[{"weight": 34, "card_id": 28}, {"weight": 33, "card_id": 28}],
		[{"weight": 100, "card_id": 999}],
		[{"weight": 0, "card_id": 28}],
		[{"weight": 100, "card_id": 28, "stats": {}}],
		[{"weight": 9223372036854775807, "card_id": 28}, {"weight": 1, "card_id": 29}],
	]
	for invalid: Array in invalid_cases:
		var invalid_rng := RandomNumberGenerator.new()
		invalid_rng.seed = 149
		var initial_state := invalid_rng.state
		_check(ReferenceEquipmentRewardResolver.select(invalid, invalid_rng).is_empty(), "invalid equipment options selected a card: %s" % [invalid])
		_check(invalid_rng.state == initial_state, "invalid equipment options consumed RNG state")
	_check(ReferenceEquipmentRewardResolver.select(options, null).is_empty(), "equipment selection accepted missing RNG")

	var source_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	var selection := RewardBoxCatalog.select_equipment_roll(149, 34)
	var finalized := RewardBoxCatalog.finalize_equipment_reward(selection, source_stats)
	_check(finalized == {"equipment": [{"card_id": 28, "stats": source_stats}]}, "Box 149 exact reward finalized incorrectly")
	_check(
		RewardBoxCatalog.finalize_equipment_reward(
			RewardBoxCatalog.select_equipment_roll(149, 35),
			{"health": 20, "damage": 3, "speed": 0.05},
		)["equipment"][0]["card_id"] == 29,
		"Box 149 did not finalize selected card 29",
	)
	_check(
		RewardBoxCatalog.finalize_equipment_reward(
			RewardBoxCatalog.select_equipment_roll(149, 68),
			{"health": 2, "damage": 3, "speed": 0.1},
		)["equipment"][0]["card_id"] == 30,
		"Box 149 did not finalize selected card 30",
	)
	source_stats["damage"] = 49.0
	_check(is_equal_approx(float(finalized["equipment"][0]["stats"]["damage"]), 29.8), "finalized Box 149 reward retained caller stats")
	var changed_card := selection.duplicate(true)
	changed_card["card_id"] = 29
	_check(RewardBoxCatalog.finalize_equipment_reward(changed_card, {"health": 20, "damage": 3, "speed": 0.05}).is_empty(), "Box 149 finalized a card that did not match its roll")
	var changed_roll := selection.duplicate(true)
	changed_roll["roll"] = 35
	_check(RewardBoxCatalog.finalize_equipment_reward(changed_roll, {"health": 2, "damage": 5, "speed": 0.05}).is_empty(), "Box 149 finalized a roll that did not match its card")
	var unknown_box := selection.duplicate(true)
	unknown_box["box_id"] = 999
	_check(RewardBoxCatalog.finalize_equipment_reward(unknown_box, {"health": 2, "damage": 5, "speed": 0.05}).is_empty(), "unknown box finalized equipment")
	_check(RewardBoxCatalog.finalize_equipment_reward(selection, {"health": 1, "damage": 5, "speed": 0.05}).is_empty(), "Box 149 finalized invalid exact stats")


func _test_reference_equipment_catalog() -> void:
	var expected := {
		28: {"runtime_item_id": "th_weapon_28", "source_name": "Weapons_0", "asset_id": "item.weapon.card_28.icon", "can_upgrade": true, "upgrade_base_cost": 10, "upgrade_rate": 1.4},
		29: {"runtime_item_id": "th_weapon_29", "source_name": "Weapons_1", "asset_id": "item.weapon.card_29.icon", "can_upgrade": true, "upgrade_base_cost": 10, "upgrade_rate": 1.4},
		30: {"runtime_item_id": "th_weapon_30", "source_name": "Weapons_2", "asset_id": "item.weapon.card_30.icon", "can_upgrade": true, "upgrade_base_cost": 10, "upgrade_rate": 1.4},
	}
	_check(ReferenceEquipmentCatalog.get_card_ids() == [28, 29, 30], "reference weapon card IDs drifted")
	for card_id: int in expected:
		var definition := ReferenceEquipmentCatalog.get_definition(card_id)
		for key: String in expected[card_id]:
			_check(definition.get(key) == expected[card_id][key], "reference weapon %d %s drifted" % [card_id, key])
		var template := ItemDatabase.get_item(str(expected[card_id]["runtime_item_id"]))
		_check(template != null and template.item_type == ItemData.ItemType.WEAPON, "reference weapon %d template is missing" % card_id)
		_check(not ItemDatabase.items.has(str(expected[card_id]["runtime_item_id"])), "reference weapon %d leaked into public shop items" % card_id)
		_check(template != null and template.rarity == ItemData.ItemRarity.COMMON, "reference weapon %d rarity drifted" % card_id)
		_check(template != null and not template.can_upgrade and template.max_upgrade_level == 1, "reference weapon %d exposed incomplete runtime upgrades" % card_id)
		_check(template != null and not template.has_reference_instance_data(), "reference weapon %d polluted its catalog template" % card_id)

	var rolled_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	var first := ReferenceEquipmentCatalog.materialize(28, rolled_stats)
	var second := ReferenceEquipmentCatalog.materialize(28, rolled_stats)
	_check(first != null and first.id == "th_weapon_28", "card 28 did not materialize its runtime identity")
	_check(first != null and first.source_card_id == 28 and first.source_asset_id == "item.weapon.card_28.icon", "card 28 lost source identity")
	_check(first != null and first.get_reference_stats() == rolled_stats, "card 28 exact stats changed during materialization")
	_check(first != null and second != null and first != second, "reference weapon materialization reused an instance")
	rolled_stats["damage"] = 49.0
	_check(first != null and is_equal_approx(float(first.get_reference_stats().get("damage", 0.0)), 29.8), "materialized stats retained caller state")
	var inventory := InventoryData.new()
	_check(first != null and inventory.add_item(first, 1) == 0, "materialized reference weapon did not enter inventory")
	var restored_inventory := InventoryData.new()
	_check(SaveService.deserialize_inventory(restored_inventory, SaveService.serialize_inventory(inventory)), "materialized reference weapon did not survive save hydration")
	var restored := restored_inventory.get_item_at(0).get("item") as ItemData
	_check(restored != null and restored.id == "th_weapon_28" and restored.get_reference_stats() == first.get_reference_stats(), "materialized reference weapon changed during save hydration")
	var upgrade_inventory := InventoryData.new()
	var upgrade_candidate := ReferenceEquipmentCatalog.materialize(28, {"health": 13.9, "damage": 29.8, "speed": 0.08})
	_check(upgrade_candidate != null and upgrade_inventory.add_item(upgrade_candidate, 1) == 0, "reference upgrade rejection setup failed")
	_check(upgrade_inventory.equip_item(0), "reference upgrade rejection could not equip weapon")
	upgrade_inventory.gold = 100
	var upgrade_signals := {"gold": 0, "equipment": 0, "upgraded": 0}
	upgrade_inventory.gold_changed.connect(func(_amount: int) -> void: upgrade_signals["gold"] += 1)
	upgrade_inventory.equipment_changed.connect(func(_slot: String) -> void: upgrade_signals["equipment"] += 1)
	upgrade_inventory.equipment_upgraded.connect(func(_slot: String, _id: String, _level: int, _cost: int) -> void: upgrade_signals["upgraded"] += 1)
	_check(not upgrade_inventory.upgrade_equipment("weapon"), "reference weapon exposed an incomplete runtime upgrade")
	_check(upgrade_inventory.gold == 100 and upgrade_inventory.get_equipped("weapon").enhancement_level == 1, "rejected reference upgrade changed state")
	_check(upgrade_signals == {"gold": 0, "equipment": 0, "upgraded": 0}, "rejected reference upgrade emitted changes")

	_check(ReferenceEquipmentCatalog.materialize(28, {"health": 2, "damage": 5, "speed": 0.05}) != null, "card 28 rejected inclusive minimums")
	_check(ReferenceEquipmentCatalog.materialize(28, {"health": 20, "damage": 50, "speed": 0.1}) != null, "card 28 rejected inclusive maximums")
	_check(ReferenceEquipmentCatalog.materialize(29, {"health": 20, "damage": 3, "speed": 0.05}) != null, "card 29 exact payload was rejected")
	_check(ReferenceEquipmentCatalog.materialize(30, {"health": 20, "damage": 35, "speed": 2.0}) != null, "card 30 exact payload was rejected")
	_check(ReferenceEquipmentCatalog.materialize(28, {"health": 0, "damage": 5, "speed": 0}) != null, "card 28 rejected verified suppressed stats")
	var invalid_payloads: Array[Dictionary] = [
		{"health": 0, "damage": 0, "speed": 0},
		{"health": 1.9, "damage": 5, "speed": 0.05},
		{"health": 20.1, "damage": 5, "speed": 0.05},
		{"health": 2, "damage": 4.9, "speed": 0.05},
		{"health": 2, "damage": 50.1, "speed": 0.05},
		{"health": 2, "damage": 5, "speed": 0.049},
		{"health": 2, "damage": 5, "speed": 0.101},
		{"health": 2, "damage": 5},
		{"health": 2, "damage": 5, "speed": 0.05, "defense": 1},
	]
	for payload: Dictionary in invalid_payloads:
		_check(ReferenceEquipmentCatalog.materialize(28, payload) == null, "card 28 accepted invalid payload: %s" % str(payload))
	_check(ReferenceEquipmentCatalog.materialize(999, {"health": 2, "damage": 5, "speed": 0.05}) == null, "unknown reference card materialized")
	var mutable_definition := ReferenceEquipmentCatalog.get_definition(28)
	mutable_definition["runtime_item_id"] = "changed"
	_check(ReferenceEquipmentCatalog.get_runtime_item_id(28) == "th_weapon_28", "reference catalog exposed mutable state")


func _test_reference_equipment_stat_generator() -> void:
	var one_stat := ReferenceEquipmentStatGenerator.replay_common(28, [499, 0, 1, 5000])
	_check(one_stat == {"health": 0.0, "speed": 0.0, "damage": 5.0}, "Common duplicate-free suppression did not leave one stat")
	var duplicate_suppression := ReferenceEquipmentStatGenerator.replay_common(28, [0, 0, 0, 50, 5000])
	_check(duplicate_suppression == {"health": 0.0, "speed": 0.05, "damage": 5.0}, "Common duplicate suppression did not leave two stats")
	var two_stats_low := ReferenceEquipmentStatGenerator.replay_common(28, [500, 2, 2000, 50])
	var two_stats_high := ReferenceEquipmentStatGenerator.replay_common(28, [899, 2, 6499, 61])
	_check(two_stats_low == {"health": 2.0, "speed": 0.05, "damage": 0.0}, "Common outer roll 500 used the wrong suppression branch")
	_check(two_stats_high == {"health": 6.499, "speed": 0.061, "damage": 0.0}, "Common outer roll 899 or exclusive upper bounds drifted")
	var three_stats_low := ReferenceEquipmentStatGenerator.replay_common(28, [900, 2000, 50, 5000])
	var three_stats_high := ReferenceEquipmentStatGenerator.replay_common(28, [999, 6499, 61, 16249])
	_check(three_stats_low == {"health": 2.0, "speed": 0.05, "damage": 5.0}, "Common outer roll 900 did not keep all stats")
	_check(three_stats_high == {"health": 6.499, "speed": 0.061, "damage": 16.249}, "card 28 Common maximum draws drifted")
	_check(
		ReferenceEquipmentStatGenerator.replay_common(29, [900, 52499, 286, 8499]) == {"health": 52.499, "speed": 0.286, "damage": 8.499},
		"card 29 Common domains drifted",
	)
	_check(
		ReferenceEquipmentStatGenerator.replay_common(30, [900, 6499, 574, 10999]) == {"health": 6.499, "speed": 0.574, "damage": 10.999},
		"card 30 Common domains drifted",
	)
	for value: float in three_stats_high.values():
		_check(is_equal_approx(value * 1000.0, round(value * 1000.0)), "Common stat was not quantized to 0.001")

	var invalid_draws: Array[Array] = [
		[],
		[-1, 0, 0, 50, 5000],
		[1000, 2000, 50, 5000],
		[499, 0, 1],
		[499, 0, 3, 5000],
		[900, 6500, 61, 16249],
		[900, 6499, 62, 16249],
		[900, 6499, 61, 16250],
		[900, 6499, 61, 16249, 1],
	]
	for draws: Array in invalid_draws:
		_check(ReferenceEquipmentStatGenerator.replay_common(28, draws).is_empty(), "Common replay accepted invalid draws: %s" % [draws])
	_check(ReferenceEquipmentStatGenerator.replay_common(999, [900, 2000, 50, 5000]).is_empty(), "Common replay accepted an unknown card")
	_check(ReferenceEquipmentStatGenerator.generate_common(28, null).is_empty(), "Common generation accepted a missing RNG")
	var invalid_rng := RandomNumberGenerator.new()
	invalid_rng.seed = 149
	var invalid_state := invalid_rng.state
	_check(ReferenceEquipmentStatGenerator.generate_common(999, invalid_rng).is_empty(), "Common generation accepted an unknown card")
	_check(invalid_rng.state == invalid_state, "invalid Common generation consumed RNG state")

	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 149
	second_rng.seed = 149
	var first_reward := RewardBoxCatalog.resolve_common_equipment(149, first_rng)
	var second_reward := RewardBoxCatalog.resolve_common_equipment(149, second_rng)
	_check(not first_reward.is_empty() and first_reward == second_reward, "Box 149 Common resolution was not deterministic")
	_check(RewardBoxResolver.normalize_reward(first_reward) == first_reward, "generated Box 149 reward was not canonical")
	_check(RewardBoxCatalog.resolve_common_equipment(999, first_rng).is_empty(), "unknown box generated Common equipment")
	var generated_equipment := first_reward.get("equipment", []) as Array
	if not generated_equipment.is_empty():
		var generated_entry := generated_equipment[0] as Dictionary
		_check(
			ReferenceEquipmentCatalog.materialize(int(generated_entry["card_id"]), generated_entry["stats"]) != null,
			"generated Box 149 reward did not materialize",
		)


func _test_quest_reward_resolver() -> void:
	var direct := {"id": "direct", "reward": {"gold": 100}}
	var direct_rng := RandomNumberGenerator.new()
	direct_rng.seed = 305
	var direct_state := direct_rng.state
	_check(QuestRewardResolver.resolve(direct, direct_rng) == {"gold": 100}, "direct quest reward did not normalize")
	_check(direct_rng.state == direct_state, "direct quest reward consumed RNG")
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 305
	second_rng.seed = 305
	var box_quest := {"id": "q305", "reward_box_id": 149}
	var first := QuestRewardResolver.resolve(box_quest, first_rng)
	_check(not first.is_empty() and first == QuestRewardResolver.resolve(box_quest, second_rng), "quest Box 149 reward was not deterministic")
	_check(RewardBoxResolver.normalize_reward(first) == first, "quest Box 149 reward was not canonical")
	var invalid: Array[Dictionary] = [
		{},
		{"reward": [], "reward_box_id": 149},
		{"reward": {"gold": 1}, "reward_box_id": 149},
		{"reward_box_id": 999},
		{"reward_box_id": "149"},
	]
	for quest: Dictionary in invalid:
		var invalid_rng := RandomNumberGenerator.new()
		invalid_rng.seed = 305
		_check(QuestRewardResolver.resolve(quest, invalid_rng).is_empty(), "invalid quest reward resolved: %s" % [quest])
	_check(QuestRewardResolver.resolve(box_quest, null).is_empty(), "random quest reward accepted a missing RNG")


func _test_economy_transaction() -> void:
	_player.inventory = InventoryData.new()
	_player.inventory.gold = 100
	_player.inventory.diamonds = 3
	_player.inventory.add_item(ItemDatabase.get_item("wood"), 10)
	var inventory_signals := {"value": 0}
	var gold_signals := {"value": 0}
	var diamond_signals := {"value": 0}
	var observed := {"gold": -1, "diamonds": -1, "wood": -1}
	_player.inventory.inventory_changed.connect(func() -> void: inventory_signals["value"] += 1)
	_player.inventory.gold_changed.connect(func(_amount: int) -> void:
		gold_signals["value"] += 1
		observed["gold"] = _player.inventory.gold
		observed["diamonds"] = _player.inventory.diamonds
		observed["wood"] = _player.inventory.get_item_count("wood")
	)
	_player.inventory.diamonds_changed.connect(func(_amount: int) -> void:
		diamond_signals["value"] += 1
		observed["gold"] = _player.inventory.gold
		observed["diamonds"] = _player.inventory.diamonds
		observed["wood"] = _player.inventory.get_item_count("wood")
	)
	inventory_signals["value"] = 0
	gold_signals["value"] = 0
	diamond_signals["value"] = 0

	_check(not GameState.spend({"gold": 50, "diamonds": 2, "wood": 11}), "mixed cost succeeded without enough items")
	_check(_player.inventory.gold == 100, "failed mixed cost consumed gold")
	_check(_player.inventory.diamonds == 3, "failed mixed cost consumed diamonds")
	_check(_player.inventory.get_item_count("wood") == 10, "failed mixed cost consumed items")
	_check(int(inventory_signals["value"]) == 0 and int(gold_signals["value"]) == 0 and int(diamond_signals["value"]) == 0, "failed mixed cost emitted changes")
	_check(not GameState.spend({"diamonds": 4}), "diamond cost succeeded without enough currency")
	_check(_player.inventory.diamonds == 3, "failed diamond cost changed the wallet")
	_check(not GameState.grant({"diamonds": -1}), "negative diamond reward was accepted")
	_check(_player.inventory.diamonds == 3, "negative diamond reward changed the wallet")

	_check(not GameState.spend({"gold": 50, "missing_item": 1}), "unknown cost item was accepted")
	_check(_player.inventory.gold == 100 and _player.inventory.diamonds == 3 and _player.inventory.get_item_count("wood") == 10, "invalid cost changed economy state")

	_check(GameState.spend({"gold": 50, "diamonds": 2, "wood": 4}), "valid mixed cost failed")
	_check(_player.inventory.gold == 50, "valid mixed cost charged incorrect gold")
	_check(_player.inventory.diamonds == 1, "valid mixed cost charged incorrect diamonds")
	_check(_player.inventory.get_item_count("wood") == 6, "valid mixed cost charged incorrect item quantity")
	_check(int(inventory_signals["value"]) == 1 and int(gold_signals["value"]) == 1 and int(diamond_signals["value"]) == 1, "mixed cost did not emit one final-state signal per domain")
	_check(observed == {"gold": 50, "diamonds": 1, "wood": 6}, "currency signals exposed a partial economy state")
	_check(GameState.can_afford({"diamonds": 1}) and not GameState.can_afford({"diamonds": 2}), "diamond affordability is incorrect")
	_check(GameState.format_cost({"diamonds": 2}) == "2 diamonds", "diamond cost formatting is incorrect")

	var full_inventory := InventoryData.new()
	full_inventory.diamonds = 5
	full_inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	_player.inventory = full_inventory
	_check(not GameState.grant({"gold": 10, "diamonds": 1, "items": {"wood": 1}}), "full inventory accepted a mixed reward")
	_check(full_inventory.gold == 0 and full_inventory.diamonds == 5, "failed mixed reward partially changed currencies")
	full_inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(GameState.grant({"gold": 10, "diamonds": 1, "items": {"wood": 1}}), "valid mixed reward failed")
	_check(full_inventory.gold == 10 and full_inventory.diamonds == 6 and full_inventory.get_item_count("wood") == 1, "mixed reward committed incorrect state")


func _test_shop_purchase_transaction() -> void:
	_player.inventory = InventoryData.new()
	_player.inventory.gold = 200
	var shop := ShopComponent.new()
	add_child(shop)
	var observed := {"gold": -1, "items": -1}
	_player.inventory.gold_changed.connect(func(amount: int) -> void:
		observed["gold"] = amount
		observed["items"] = _player.inventory.get_item_count("iron_sword")
	)

	_check(shop.process_purchase({"id": "iron_sword", "name": "Iron Sword", "price": -500}), "shop rejected a valid catalog item")
	_check(_player.inventory.gold == 100, "shop trusted a spoofed client price")
	_check(_player.inventory.get_item_count("iron_sword") == 1, "shop purchase omitted the item")
	_check(int(observed["gold"]) == 100 and int(observed["items"]) == 1, "shop signals exposed a partial purchase state")

	_player.inventory.add_item(ItemDatabase.get_item("wooden_sword"), InventoryData.INVENTORY_SIZE - 1)
	_check(not shop.process_purchase({"id": "wooden_sword", "name": "Wooden Sword", "price": 1}), "full inventory accepted a shop purchase")
	_check(_player.inventory.gold == 100, "failed full-inventory purchase consumed gold")

	_player.inventory = InventoryData.new()
	_player.inventory.gold = 49
	_check(not shop.process_purchase({"id": "wooden_sword", "name": "Wooden Sword", "price": 1}), "shop purchase ignored insufficient authoritative gold")
	_check(_player.inventory.gold == 49 and _player.inventory.get_item_count("wooden_sword") == 0, "failed shop purchase changed inventory")
	_check(not shop.process_purchase({"id": "flame_augment_t1", "price": -100}), "shop accepted an item without a catalog price")
	_check(not shop.process_purchase({"id": "missing_item", "price": -100}), "shop accepted an unknown item")
	shop.queue_free()


func _test_sale_transaction() -> void:
	var inventory := InventoryData.new()
	var wood := ItemDatabase.get_item("wood")
	var sword := ItemDatabase.get_item("iron_sword")
	var spoofed_wood := ItemDatabase.get_item_copy("wood")
	spoofed_wood.sell_price = 999999
	inventory.add_item(spoofed_wood, 2)
	var inventory_signals := {"value": 0}
	var gold_signals := {"value": 0}
	var observed := {"wood": -1, "gold": -1}
	inventory.inventory_changed.connect(func() -> void:
		inventory_signals["value"] += 1
		observed["wood"] = inventory.get_item_count("wood")
		observed["gold"] = inventory.gold
	)
	inventory.gold_changed.connect(func(amount: int) -> void:
		gold_signals["value"] += 1
		observed["wood"] = inventory.get_item_count("wood")
		observed["gold"] = amount
	)

	var credited := inventory.sell_item_at(0, "wood")
	_check(credited == wood.sell_price, "sale did not use the authoritative item price")
	_check(inventory.gold == wood.sell_price and inventory.get_item_count("wood") == 1, "sale did not commit item and gold together")
	_check(int(inventory_signals["value"]) == 1 and int(gold_signals["value"]) == 1, "sale emitted duplicate or missing signals")
	_check(int(observed["wood"]) == 1 and int(observed["gold"]) == wood.sell_price, "sale signal exposed a partial state")

	inventory_signals["value"] = 0
	gold_signals["value"] = 0
	_check(inventory.sell_item_at(0, sword.id) == 0, "stale sale confirmation sold a different item")
	_check(inventory.gold == wood.sell_price and inventory.get_item_count("wood") == 1, "rejected stale sale changed inventory")
	_check(int(inventory_signals["value"]) == 0 and int(gold_signals["value"]) == 0, "rejected stale sale emitted changes")

	var unsellable := ItemDatabase.get_item_copy("flame_augment_t1")
	inventory.inventory_slots[1] = {"item": unsellable, "quantity": 1}
	_check(inventory.sell_item_at(1, unsellable.id) == 0, "unsellable item credited gold")
	_check(inventory.get_item_at(1).item == unsellable, "failed unsellable sale removed the item")


func _test_equipment_transactions() -> void:
	var inventory := InventoryData.new()
	inventory.add_item(ItemDatabase.get_item("fire_blade"), 1)
	_check(inventory.equip_item(0), "equipment setup failed")
	inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	var inventory_signals := {"value": 0}
	var equipment_signals := {"value": 0}
	var augment_signals := {"value": 0}
	var observed := {"inventory_has_weapon": false, "equipment_empty": false, "augment_consumed": false}
	var on_inventory_changed := func() -> void: inventory_signals["value"] += 1
	var on_equipment_changed := func(_slot: String) -> void:
		equipment_signals["value"] += 1
		observed["inventory_has_weapon"] = inventory.get_item_count("fire_blade") == 1
		observed["equipment_empty"] = inventory.get_equipped("weapon") == null
	var on_augments_changed := func(_slot: String) -> void:
		augment_signals["value"] += 1
		observed["augment_consumed"] = inventory.get_item_count("flame_augment_t1") == 0
	inventory.inventory_changed.connect(on_inventory_changed)
	inventory.equipment_changed.connect(on_equipment_changed)
	inventory.augments_changed.connect(on_augments_changed)

	_check(not inventory.unequip_item("weapon"), "full inventory accepted unequip")
	_check(inventory.get_equipped("weapon") != null, "failed unequip lost equipment")
	_check(int(inventory_signals["value"]) == 0 and int(equipment_signals["value"]) == 0, "failed unequip emitted changes")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	_check(inventory.unequip_item("weapon"), "unequip failed after freeing capacity")
	_check(int(inventory_signals["value"]) == 1 and int(equipment_signals["value"]) == 1, "unequip emitted duplicate or missing signals")
	_check(bool(observed["inventory_has_weapon"]) and bool(observed["equipment_empty"]), "unequip signal exposed partial state")
	var swap_inventory := InventoryData.new()
	swap_inventory.add_item(ItemDatabase.get_item("iron_sword"), 1)
	swap_inventory.equip_item(0)
	swap_inventory.add_item(ItemDatabase.get_item("fire_blade"), 1)
	_check(swap_inventory.unequip_item("weapon", 0), "target-slot equipment swap failed")
	_check(swap_inventory.get_equipped("weapon").id == "fire_blade", "target-slot swap equipped the wrong item")
	_check(swap_inventory.get_item_at(0).item.id == "iron_sword", "target-slot swap lost the previous equipment")

	inventory = InventoryData.new()
	inventory.inventory_changed.connect(on_inventory_changed)
	inventory.equipment_changed.connect(on_equipment_changed)
	inventory.augments_changed.connect(on_augments_changed)
	inventory.add_item(ItemDatabase.get_item("fire_blade"), 1)
	inventory.equip_item(0)
	inventory.add_item(ItemDatabase.get_item("flame_augment_t1"), 1)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	augment_signals["value"] = 0
	observed["augment_consumed"] = false
	_check(inventory.apply_augment("weapon", 0), "valid augment application failed")
	_check(int(inventory_signals["value"]) == 1 and int(equipment_signals["value"]) == 1 and int(augment_signals["value"]) == 1, "augment application emitted duplicate or missing signals")
	_check(bool(observed["augment_consumed"]), "augment signal exposed an unconsumed item")

	inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	augment_signals["value"] = 0
	_check(not inventory.remove_augment("weapon", 0), "full inventory accepted augment removal")
	_check(inventory.get_equipped("weapon").applied_augments.size() == 1, "failed augment removal changed equipment")
	_check(int(inventory_signals["value"]) == 0 and int(equipment_signals["value"]) == 0 and int(augment_signals["value"]) == 0, "failed augment removal emitted changes")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	augment_signals["value"] = 0
	_check(inventory.remove_augment("weapon", 0), "augment removal failed after freeing capacity")
	_check(inventory.get_item_count("flame_augment_t1") == 1 and inventory.get_equipped("weapon").applied_augments.is_empty(), "augment removal did not commit final state")
	_check(int(inventory_signals["value"]) == 1 and int(equipment_signals["value"]) == 1 and int(augment_signals["value"]) == 1, "augment removal emitted duplicate or missing signals")


func _test_equipment_enhancement() -> void:
	var inventory := InventoryData.new()
	var template := ItemDatabase.get_item("fire_blade")
	inventory.add_item(template, 1)
	_check(inventory.equip_item(0), "enhancement equipment setup failed")
	inventory.add_item(ItemDatabase.get_item("flame_augment_t1"), 1)
	_check(inventory.apply_augment("weapon", 0), "enhancement augment setup failed")

	var weapon := inventory.get_equipped("weapon")
	var base_attack := weapon.attack_bonus
	var cost := weapon.get_upgrade_cost()
	_check(cost == int(weapon.upgrade_base_cost * pow(weapon.upgrade_cost_rate, 1)), "level-1 upgrade cost did not follow configured curve")
	inventory.gold = cost + 25
	var stats := CharacterStats.new()
	stats.apply_equipment_bonuses(inventory)
	var attack_before := stats.attack_damage
	var signal_counts := {"gold": 0, "equipment": 0, "upgraded": 0}
	var observed := {"level": 0, "gold": -1, "augments": 0}
	inventory.gold_changed.connect(func(amount: int) -> void:
		signal_counts["gold"] += 1
		observed["level"] = inventory.get_equipped("weapon").enhancement_level
		observed["gold"] = amount
	)
	inventory.equipment_changed.connect(func(_slot: String) -> void:
		signal_counts["equipment"] += 1
		stats.apply_equipment_bonuses(inventory)
	)
	inventory.equipment_upgraded.connect(func(_slot: String, _id: String, level: int, _cost: int) -> void:
		signal_counts["upgraded"] += 1
		observed["level"] = level
		observed["augments"] = inventory.get_equipped("weapon").applied_augments.size()
	)

	_check(inventory.upgrade_equipment("weapon"), "valid equipment upgrade failed")
	weapon = inventory.get_equipped("weapon")
	_check(weapon.enhancement_level == 2, "upgrade did not increase displayed level")
	_check(inventory.gold == 25, "upgrade charged the wrong gold cost")
	_check(weapon.get_scaled_attack_bonus() == roundi(base_attack * 1.1), "level-2 attack did not follow the provisional growth curve")
	_check(weapon.get_scaled_attack_bonus() > base_attack and stats.attack_damage > attack_before, "upgrade did not increase character attack")
	_check(weapon.applied_augments == ["flame_augment_t1"], "upgrade lost applied augments")
	_check(template.enhancement_level == 1 and template.applied_augments.is_empty(), "upgrade mutated the catalog template")
	_check(int(signal_counts["gold"]) == 1 and int(signal_counts["equipment"]) == 1 and int(signal_counts["upgraded"]) == 1, "upgrade emitted duplicate or missing signals")
	_check(int(observed["level"]) == 2 and int(observed["gold"]) == 25 and int(observed["augments"]) == 1, "upgrade signal exposed partial state")
	_check(inventory.count_equipment_at_or_above_level(2) == 1, "level query missed upgraded equipment")
	var augment_slot := inventory.get_item_count("flame_augment_t1")
	_check(inventory.remove_augment("weapon", 0), "upgraded equipment could not remove its augment")
	_check(inventory.get_equipped("weapon").enhancement_level == 2, "augment removal reset enhancement level")
	_check(inventory.get_item_count("flame_augment_t1") == augment_slot + 1, "augment removal did not return the augment")
	var returned_augment_index := -1
	for i in range(inventory.inventory_slots.size()):
		var slot: Dictionary = inventory.inventory_slots[i]
		if slot.item != null and slot.item.id == "flame_augment_t1":
			returned_augment_index = i
			break
	_check(inventory.apply_augment("weapon", returned_augment_index), "upgraded equipment could not reapply its augment")
	_check(inventory.get_equipped("weapon").enhancement_level == 2, "augment application reset enhancement level")

	weapon = inventory.get_equipped("weapon")
	inventory.gold = weapon.get_upgrade_cost() - 1
	var level_before := weapon.enhancement_level
	var gold_before := inventory.gold
	signal_counts["gold"] = 0
	signal_counts["equipment"] = 0
	signal_counts["upgraded"] = 0
	_check(not inventory.upgrade_equipment("weapon"), "upgrade ignored insufficient gold")
	_check(inventory.get_equipped("weapon").enhancement_level == level_before and inventory.gold == gold_before, "failed upgrade changed state")
	_check(int(signal_counts["gold"]) == 0 and int(signal_counts["equipment"]) == 0 and int(signal_counts["upgraded"]) == 0, "failed upgrade emitted changes")
	_check(not inventory.upgrade_equipment("missing"), "invalid equipment slot upgraded")

	var capped := weapon.duplicate() as ItemData
	capped.applied_augments = weapon.applied_augments.duplicate()
	capped.enhancement_level = capped.max_upgrade_level
	inventory._set_equipped("weapon", capped)
	inventory.gold = 999999
	_check(not inventory.upgrade_equipment("weapon"), "max-level equipment upgraded")
	_check(capped.enhancement_level == capped.max_upgrade_level, "max-level rejection changed equipment")

	var locked := ItemDatabase.get_item_copy("iron_sword")
	locked.can_upgrade = false
	locked.max_upgrade_level = 1
	inventory._set_equipped("weapon", locked)
	_check(not inventory.upgrade_equipment("weapon"), "non-upgradeable equipment upgraded")


func _test_equipment_quest_objectives() -> void:
	var inventory := InventoryData.new()
	var rare_weapon := ItemDatabase.get_item_copy("fire_blade")
	rare_weapon.rarity = ItemData.ItemRarity.RARE
	rare_weapon.enhancement_level = 5
	var epic_armor := ItemDatabase.get_item_copy("leather_armor")
	epic_armor.rarity = ItemData.ItemRarity.EPIC
	epic_armor.enhancement_level = 3
	var common_helmet := ItemDatabase.get_item_copy("iron_helmet")
	common_helmet.rarity = ItemData.ItemRarity.COMMON
	common_helmet.enhancement_level = 2
	inventory._set_equipped("weapon", rare_weapon)
	inventory._set_equipped("armor", epic_armor)
	inventory._set_equipped("helmet", common_helmet)

	_check(inventory.count_equipped_items() == 3, "equipped-count query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_rarity(ItemData.ItemRarity.RARE) == 2, "rare equipment query missed rare-or-better items")
	_check(inventory.count_equipment_at_or_above_rarity(ItemData.ItemRarity.EPIC) == 1, "epic equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_rarity(-1) == 0, "invalid rarity query was accepted")
	_check(inventory.count_equipment_at_or_above_level(3) == 2, "level-3 equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_level(5) == 1, "level-5 equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_level(0) == 0, "invalid equipment-level query was accepted")

	_check(QuestService.get_state_objective_value({"type": "equipped_count", "target": "any"}, inventory) == 3, "equipped-count quest objective returned the wrong value")
	_check(QuestService.get_state_objective_value({"type": "equipped_rarity", "target": ItemData.ItemRarity.RARE}, inventory) == 2, "rarity quest objective returned the wrong value")
	_check(QuestService.get_state_objective_value({"type": "equipment_level", "target": 3}, inventory) == 2, "equipment-level quest objective returned the wrong value")
	_check(QuestService.get_state_objective_value({"type": "equipped_rarity", "target": ItemData.ItemRarity.LEGENDARY + 1}, inventory) == -1, "out-of-range rarity objective was accepted")
	_check(QuestService.get_state_objective_value({"type": "equipment_level", "target": 0}, inventory) == -1, "zero equipment-level target was accepted")
	_check(QuestService.get_state_objective_value({"type": "equipment_level", "target": "3"}, inventory) == -1, "invalid equipment-level target was accepted")
	_check(QuestService.get_state_objective_value({"type": "unknown"}, inventory) == -1, "unknown state objective was accepted")

func _test_inventory_removal_invariants() -> void:
	var inventory := InventoryData.new()
	var wood := ItemDatabase.get_item("wood")
	inventory.add_item(wood, 5)
	var signals := {"value": 0}
	inventory.inventory_changed.connect(func() -> void: signals["value"] += 1)
	signals["value"] = 0

	_check(not inventory.remove_item(wood, 6), "remove_item accepted an insufficient total quantity")
	_check(inventory.get_item_count("wood") == 5, "failed remove_item partially consumed a stack")
	_check(not inventory.remove_item(wood, 0), "remove_item accepted zero quantity")
	_check(not inventory.remove_item(wood, -2), "remove_item accepted negative quantity")
	_check(int(signals["value"]) == 0, "invalid remove_item emitted inventory changes")

	_check(not inventory.remove_item_at(0, 6), "remove_item_at accepted an insufficient stack")
	_check(not inventory.remove_item_at(0, 0), "remove_item_at accepted zero quantity")
	_check(not inventory.remove_item_at(0, -2), "remove_item_at accepted negative quantity")
	_check(inventory.get_item_count("wood") == 5, "invalid remove_item_at changed stack quantity")
	_check(int(signals["value"]) == 0, "invalid remove_item_at emitted inventory changes")

	_check(inventory.remove_item(wood, 3), "valid remove_item failed")
	_check(inventory.get_item_count("wood") == 2, "valid remove_item removed the wrong quantity")
	_check(int(signals["value"]) == 1, "valid remove_item did not emit exactly one change")
	_check(inventory.remove_item_at(0, 2), "valid remove_item_at failed")
	_check(inventory.get_item_count("wood") == 0, "valid remove_item_at did not clear the stack")
	_check(int(signals["value"]) == 2, "valid remove_item_at did not emit exactly one change")


func _test_recipe_catalog_validation() -> void:
	var all_recipes := RecipeDatabase.get_all_recipes()
	_check(all_recipes.size() == 10, "recipe catalog changed unexpectedly")
	for recipe: CraftingRecipe in all_recipes:
		_check(recipe.evidence_status == CraftingRecipe.EvidenceStatus.PROVISIONAL, "%s is missing its provisional evidence label" % recipe.id)
		_check(not recipe.evidence_source.is_empty(), "%s is missing its evidence source" % recipe.id)
		_check(recipe.validate_catalog().is_empty(), "%s failed catalog validation" % recipe.id)

	var invalid := CraftingRecipe.new()
	invalid.id = "invalid_reference_recipe"
	invalid.recipe_name = "Invalid Reference Recipe"
	invalid.evidence_source = "Synthetic invalid recipe used by automated tests."
	invalid.tiers = [
		{
			"tier": 1,
			"ingredients": [
				{"item_id": "missing_reference_item", "quantity": 0},
				{"item_id": "missing_reference_item", "quantity": 1},
			],
			"result_item_id": "missing_reference_output",
			"result_quantity": 0,
		},
		{
			"tier": 1,
			"ingredients": [],
			"result_item_id": "health_potion",
			"result_quantity": 1,
		},
	]
	var errors := invalid.validate_catalog()
	_check(errors.size() >= 6, "invalid recipe did not report all structural/catalog errors")
	_check(not RecipeDatabase.register_recipe(invalid, false), "invalid recipe entered the catalog")
	_check(RecipeDatabase.get_recipe(invalid.id) == null, "rejected recipe remained registered")

	var existing := RecipeDatabase.get_recipe("flame_augment")
	_check(not RecipeDatabase.register_recipe(existing, false), "duplicate recipe id overwrote the catalog")
	_check(RecipeDatabase.get_recipe("flame_augment") == existing, "duplicate registration replaced the original recipe")

	var padded_recipe_id := _copy_recipe_with_id(" recipe_with_padded_id ")
	_assert_recipe_registration_rejected(padded_recipe_id, "padded recipe id")

	var string_tier := _copy_recipe_with_id("string_tier_recipe")
	string_tier.tiers[0]["tier"] = "1"
	_assert_recipe_registration_rejected(string_tier, "string tier")

	var padded_ingredient_id := _copy_recipe_with_id("padded_ingredient_recipe")
	padded_ingredient_id.tiers[0]["ingredients"][0]["item_id"] = " fire_shard "
	_assert_recipe_registration_rejected(padded_ingredient_id, "padded ingredient id")
	var non_string_ingredient_id := _copy_recipe_with_id("non_string_ingredient_recipe")
	non_string_ingredient_id.tiers[0]["ingredients"][0]["item_id"] = 123
	_check(non_string_ingredient_id.validate_catalog().size() == 1, "non-string ingredient id produced duplicate validation errors")
	_assert_recipe_registration_rejected(non_string_ingredient_id, "non-string ingredient id")

	var padded_result_id := _copy_recipe_with_id("padded_result_recipe")
	padded_result_id.tiers[0]["result_item_id"] = " flame_augment_t1 "
	_assert_recipe_registration_rejected(padded_result_id, "padded result id")
	var non_string_result_id := _copy_recipe_with_id("non_string_result_recipe")
	non_string_result_id.tiers[0]["result_item_id"] = 123
	_check(non_string_result_id.validate_catalog().size() == 1, "non-string result id produced duplicate validation errors")
	_assert_recipe_registration_rejected(non_string_result_id, "non-string result id")

	var string_ingredient_quantity := _copy_recipe_with_id("string_ingredient_quantity_recipe")
	string_ingredient_quantity.tiers[0]["ingredients"][0]["quantity"] = "3"
	_assert_recipe_registration_rejected(string_ingredient_quantity, "string ingredient quantity")

	var string_result_quantity := _copy_recipe_with_id("string_result_quantity_recipe")
	string_result_quantity.tiers[0]["result_quantity"] = "1"
	_assert_recipe_registration_rejected(string_result_quantity, "string result quantity")


func _copy_recipe_with_id(recipe_id: String) -> CraftingRecipe:
	var recipe := (RecipeDatabase.get_recipe("flame_augment") as CraftingRecipe).duplicate(true) as CraftingRecipe
	recipe.id = recipe_id
	return recipe


func _assert_recipe_registration_rejected(recipe: CraftingRecipe, field_description: String) -> void:
	_check(not recipe.validate_catalog().is_empty(), "%s passed catalog validation" % field_description)
	var registered := RecipeDatabase.register_recipe(recipe, false)
	_check(not registered, "%s entered the recipe catalog" % field_description)
	_check(RecipeDatabase.get_recipe(recipe.id) == null, "%s remained in the recipe catalog" % field_description)
	if registered:
		RecipeDatabase.recipes.erase(recipe.id)


func _test_crafting_transaction() -> void:
	var inventory := _full_inventory_with_craft_materials()
	var panel := CraftingPanel.new()
	panel.player_inventory = inventory
	panel.selected_recipe = RecipeDatabase.get_recipe("flame_augment")
	panel.selected_tier = 1
	_check(not panel._execute_craft(), "craft succeeded without output capacity")
	_check(inventory.get_item_count("fire_shard") == 4, "failed craft consumed fire shards")
	_check(inventory.get_item_count("iron_ore") == 3, "failed craft consumed iron ore")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(panel._execute_craft(), "craft failed after freeing a slot")
	_check(inventory.get_item_count("flame_augment_t1") == 1, "craft did not add its output")
	panel.free()


func _test_quest305_claim_transaction() -> void:
	SaveService.delete_save()
	GameState.reset_profile()
	QuestService.reset()
	var quest_index := GameContent.get_main_quest_index("q305")
	var next_index := GameContent.get_main_quest_index("q306")
	_check(quest_index == 1 and next_index == 2, "quest 305/306 chain position drifted")
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	QuestService.main_index = quest_index
	QuestService.main_progress = 10
	QuestService.main_ready = true
	var authority_rng := RandomNumberGenerator.new()
	authority_rng.seed = 305
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 305
	var expected_reward := RewardBoxCatalog.resolve_common_equipment(149, expected_rng)
	_check(QuestService.set_reward_authority_rng(authority_rng), "quest reward authority RNG injection failed")
	GameState.current_zone = "invalid_zone"
	var state_before_failed_prepare := authority_rng.state
	_check(not QuestService.claim("q305"), "invalid snapshot prepared quest 305")
	_check(authority_rng.state == state_before_failed_prepare, "failed quest 305 prepare consumed RNG")
	_check(SaveService.get_pending_claim().is_empty(), "failed quest 305 prepare left a journal")
	GameState.current_zone = "town"
	_check(not QuestService.claim("q305"), "full inventory accepted quest 305 equipment")
	var pending := SaveService.get_pending_claim()
	_check(pending.get("claim_id", "") == "main:q305", "quest 305 did not prepare its journal")
	_check(pending.get("reward", {}) == expected_reward, "quest 305 journal did not preserve the resolved Box 149 reward")
	var state_after_prepare := authority_rng.state
	_check(not QuestService.claim("q305"), "full inventory retried quest 305 successfully")
	_check(authority_rng.state == state_after_prepare, "quest 305 retry rerolled its reward")

	_player.inventory = InventoryData.new()
	QuestService.reset()
	_check(SaveService.load_game(), "quest 305 pending claim did not reload")
	_check(QuestService.main_index == quest_index and QuestService.main_ready, "quest 305 state did not recover")
	_check(SaveService.get_pending_claim().get("reward", {}) == expected_reward, "quest 305 reward changed after reload")
	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("q305"), "quest 305 did not retry after freeing capacity")
	_check(QuestService.main_index == next_index and SaveService.get_pending_claim().is_empty(), "quest 305 did not advance to q306")
	var expected_entry := (expected_reward["equipment"] as Array)[0] as Dictionary
	var rewarded := _player.inventory.get_item_at(InventoryData.INVENTORY_SIZE - 1).get("item") as ItemData
	_check(rewarded != null and rewarded.source_card_id == int(expected_entry["card_id"]), "quest 305 granted the wrong card")
	_check(rewarded != null and rewarded.get_reference_stats() == expected_entry["stats"], "quest 305 rerolled exact stats")
	_check(not QuestService.claim("q305"), "completed quest 305 granted twice")


func _test_quest_claim_transaction() -> void:
	GameState.reset_profile()
	QuestService.reset()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	var q02_index := GameContent.get_main_quest_index("q02")
	QuestService.main_index = q02_index
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[q02_index]["obj"]["count"])
	QuestService.main_ready = true
	var xp_before := GameState.xp
	_check(not QuestService.claim("q02"), "quest advanced without reward capacity")
	_check(QuestService.main_index == q02_index and QuestService.main_ready, "failed quest claim changed state")
	_check(GameState.xp == xp_before, "failed quest claim granted partial XP")
	_check(SaveService.get_pending_claim().get("claim_id", "") == "main:q02", "failed claim did not persist its resolved journal")

	# Loading the prepared snapshot retries the same reward but keeps it pending
	# while the restored inventory is still full.
	_player.inventory = InventoryData.new()
	QuestService.reset()
	_check(SaveService.load_game(), "prepared quest claim did not reload")
	_check(QuestService.main_index == q02_index and QuestService.main_ready, "prepared quest state did not recover")
	_check(
		SaveService.get_pending_claim().get("reward", {}) == RewardBoxResolver.normalize_reward(GameContent.MAIN_QUESTS[q02_index]["reward"]),
		"prepared reward changed during recovery",
	)

	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	var corrupted := {"value": false}
	_player.inventory.inventory_changed.connect(func() -> void:
		if not corrupted["value"]:
			corrupted["value"] = true
			GameState.current_zone = "invalid_zone"
	)
	_check(not QuestService.claim("q02"), "invalid final snapshot committed a quest claim")
	_check(GameState.current_zone == "town" and QuestService.main_index == q02_index and QuestService.main_ready, "failed final checkpoint did not restore prepared state")
	_check(_player.inventory.get_item_count("health_potion") == 0, "failed final checkpoint retained a granted reward")
	_check(not SaveService.get_pending_claim().is_empty(), "failed final checkpoint lost the retry journal")

	_check(QuestService.claim("q02"), "quest failed after freeing reward capacity")
	_check(_player.inventory.get_item_count("health_potion") == 3, "quest did not grant full item reward")
	_check(QuestService.main_index == q02_index + 1 and SaveService.get_pending_claim().is_empty(), "successful claim did not advance and clear its journal")
	_check(not QuestService.claim("q02") and _player.inventory.get_item_count("health_potion") == 3, "completed claim granted twice")


func _test_daily_claim_recovery() -> void:
	SaveService.delete_save()
	GameState.reset_profile()
	GameState.level = GameContent.MAX_LEVEL
	QuestService.reset()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	QuestService.dailies["d_boss"]["progress"] = 1
	var xp_before := GameState.xp
	var gold_before := _player.inventory.gold
	_check(not QuestService.claim("d_boss"), "daily claim advanced without reward capacity")
	_check(
		SaveService.get_pending_claim().get("claim_id", "") == "daily:%s:d_boss" % QuestService.daily_date,
		"failed daily claim did not persist a dated journal",
	)

	# Simulate loading the prepared claim after the calendar day changed. The old
	# daily state must remain available until its exact persisted reward is retried.
	var prepared := SaveService.read_snapshot()
	var stale_date := "2000-01-01"
	prepared["quests"]["daily_date"] = stale_date
	prepared["pending_claim"]["claim_id"] = "daily:%s:d_boss" % stale_date
	var save_file := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	_check(save_file != null, "daily recovery fixture could not open its save")
	if save_file != null:
		save_file.store_string(JSON.stringify(prepared, "  "))
		save_file.close()

	_player.inventory = InventoryData.new()
	QuestService.reset()
	_check(SaveService.load_game(), "stale pending daily claim did not reload")
	_check(QuestService.daily_date == stale_date, "load reset a daily before its pending claim recovered")
	_check(not SaveService.get_pending_claim().is_empty(), "failed automatic daily retry lost its journal")
	_check(GameState.xp == xp_before and _player.inventory.gold == gold_before, "failed automatic daily retry granted a partial reward")

	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("d_boss"), "stale pending daily claim did not retry")
	_check(GameState.level == GameContent.MAX_LEVEL and GameState.xp == xp_before, "daily retry bypassed the max-level XP cap")
	_check(_player.inventory.gold == gold_before + 300, "daily retry granted incorrect gold")
	_check(_player.inventory.get_item_count("hero_shard") == 3, "daily retry omitted its item reward")
	_check(bool(QuestService.dailies["d_boss"]["claimed"]), "daily retry did not mark the saved quest claimed")
	_check(SaveService.get_pending_claim().is_empty(), "successful daily retry did not clear its journal")

	QuestService.get_tracker_rows()
	_check(QuestService.daily_date != stale_date, "completed stale daily state did not reset")
	_check(not QuestService.claim("d_boss"), "completed daily journal granted twice after reset")
	_check(_player.inventory.get_item_count("hero_shard") == 3, "duplicate daily claim changed the reward")


func _test_exact_equipment_reward_transaction() -> void:
	SaveService.delete_save()
	GameState.reset_profile()
	QuestService.reset()
	_player.inventory = InventoryData.new()
	var valid_stats := ReferenceEquipmentStatGenerator.replay_common(28, [0, 0, 0, 50, 5000])
	_check(not GameState.grant({"equipment": [{"card_id": "28", "stats": valid_stats}]}), "direct grant accepted a string equipment card ID")
	_check(not GameState.grant({"equipment": [{"card_id": 28, "stats": valid_stats, "level": 10}]}), "direct grant accepted an unapproved equipment field")
	_check(_player.inventory.get_item_count("th_weapon_28") == 0, "invalid direct equipment grant changed inventory")
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	var q02_index := GameContent.get_main_quest_index("q02")
	QuestService.main_index = q02_index
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[q02_index]["obj"]["count"])
	QuestService.main_ready = true
	var source_stats := valid_stats.duplicate(true)
	var exact_reward := {"gold": 25, "equipment": [{"card_id": 28, "stats": source_stats}]}
	var record := {
		"version": 1,
		"claim_id": "main:q02",
		"source_kind": "main",
		"source_id": "q02",
		"reward": exact_reward,
	}
	_check(SaveService.prepare_pending_claim(record), "exact equipment claim did not prepare")
	source_stats["damage"] = 49.0
	_check(
		is_equal_approx(float(SaveService.get_pending_claim()["reward"]["equipment"][0]["stats"]["damage"]), 5.0),
		"prepared equipment claim retained caller stats",
	)
	_check(not QuestService.retry_pending_claim(), "full inventory accepted exact equipment claim")
	_check(_player.inventory.gold == 0 and QuestService.main_index == q02_index, "failed equipment claim partially changed state")

	_player.inventory = InventoryData.new()
	QuestService.reset()
	_check(SaveService.load_game(), "exact equipment journal did not reload")
	_check(not SaveService.get_pending_claim().is_empty(), "failed automatic equipment retry lost its journal")
	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("q02"), "exact equipment journal did not retry")
	_check(_player.inventory.gold == 25 and QuestService.main_index == q02_index + 1, "exact equipment retry did not commit final state")
	var rewarded := _player.inventory.get_item_at(InventoryData.INVENTORY_SIZE - 1).get("item") as ItemData
	_check(rewarded != null and rewarded.id == "th_weapon_28", "exact equipment retry granted the wrong runtime item")
	_check(rewarded != null and rewarded.source_card_id == 28, "exact equipment retry lost source card identity")
	_check(rewarded != null and rewarded.source_asset_id == "item.weapon.card_28.icon", "exact equipment retry lost stable asset identity")
	_check(rewarded != null and rewarded.get_reference_stats() == valid_stats, "exact equipment retry changed generated stats")
	_check(SaveService.get_pending_claim().is_empty(), "exact equipment retry did not clear its journal")
	_check(not QuestService.claim("q02") and _player.inventory.get_item_count("th_weapon_28") == 1, "exact equipment claim granted twice")
	_check(not ItemDatabase.get_item("th_weapon_28").has_reference_instance_data(), "exact equipment reward mutated its catalog template")


func _test_building_collection_transaction() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	GameState.plots[0] = {
		"id": "lumber_mill",
		"level": 1,
		"last_collect": Time.get_unix_time_from_system() - 3600.0,
	}
	var timestamp := float(GameState.plots[0]["last_collect"])
	_check(GameState.collect_building(0) == 0, "building collection succeeded without capacity")
	_check(float(GameState.plots[0]["last_collect"]) == timestamp, "failed collection reset production time")
	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(GameState.collect_building(0) > 0, "building collection failed after freeing capacity")
	_check(_player.inventory.get_item_count("wood") > 0, "building collection omitted resources")


func _test_building_upgrade_transaction() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	_player.inventory.gold = 500
	_player.inventory.add_item(ItemDatabase.get_item("wood"), 999)
	_player.inventory.add_item(ItemDatabase.get_item("stone"), 20)
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE - 2)
	GameState.plots[0] = {
		"id": "lumber_mill",
		"level": 1,
		"last_collect": Time.get_unix_time_from_system() - 3600.0,
	}
	var timestamp := float(GameState.plots[0]["last_collect"])
	_check(not GameState.build_or_upgrade(0, "lumber_mill"), "upgrade succeeded while pending output could not fit")
	_check(int(GameState.plots[0]["level"]) == 1, "failed upgrade changed building level")
	_check(float(GameState.plots[0]["last_collect"]) == timestamp, "failed upgrade reset production time")
	_check(_player.inventory.gold == 500, "failed upgrade consumed gold")
	_check(_player.inventory.get_item_count("wood") == 999, "failed upgrade consumed wood")
	_check(_player.inventory.get_item_count("stone") == 20, "failed upgrade consumed stone")

	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(GameState.build_or_upgrade(0, "lumber_mill"), "upgrade failed after freeing output capacity")
	_check(int(GameState.plots[0]["level"]) == 2, "successful upgrade did not increase level")
	_check(float(GameState.plots[0]["last_collect"]) > timestamp, "successful upgrade did not advance production time")
	_check(_player.inventory.gold == 100, "successful upgrade did not charge gold exactly once")
	_check(_player.inventory.get_item_count("stone") == 0, "successful upgrade did not charge stone exactly once")


## Equipment refresh must not let a skill bypass its configured cooldown or cost.
func _test_skill_cooldown_lifecycle() -> void:
	var component := SkillComponent.new()
	add_child(component)
	component.set_process(false)
	var binding: Array[Dictionary] = [{"skill_id": "whirlwind", "source_equip_slot": "weapon"}]
	component.get_active_skills_func = func() -> Array: return binding
	var paid_costs: Array[float] = []
	component.use_stamina_func = func(cost: float) -> bool:
		paid_costs.append(cost)
		return true
	var activated: Array[String] = []
	component.skill_activated.connect(func(skill_id: String) -> void: activated.append(skill_id))
	component.rebuild_skills()
	_check(component.try_activate_skill("whirlwind"), "skill initial activation failed")
	var duration: float = SkillDatabase.get_skill("whirlwind").cooldown
	component._process(1.0)
	component.rebuild_skills()
	_check(not component.is_skill_ready("whirlwind"), "equipment refresh cleared active skill cooldown")
	_check(is_equal_approx(float(component.available_skills[0]["current_cooldown"]), duration - 1.0), "equipment refresh changed remaining cooldown")
	_check(not component.try_activate_skill("whirlwind"), "skill reactivated during cooldown after refresh")
	_check(paid_costs.size() == 1 and activated.size() == 1, "cooldown rejection consumed stamina or emitted activation")

	binding.clear()
	component.rebuild_skills()
	_check(component.available_skills.is_empty() and not component.try_activate_skill("whirlwind"), "unequipped skill remained usable")
	component._process(1.0)
	binding.append({"skill_id": "whirlwind", "source_equip_slot": "armor"})
	component.rebuild_skills()
	_check(not component.is_skill_ready("whirlwind"), "re-equipping skill bypassed cooldown")
	_check(is_equal_approx(float(component.available_skills[0]["current_cooldown"]), duration - 2.0), "unequipped cooldown did not elapse")
	binding.append({"skill_id": "whirlwind", "source_equip_slot": "weapon"})
	component.rebuild_skills()
	component._process(duration - 2.0)
	_check(component.is_skill_ready("whirlwind"), "skill did not become ready at cooldown expiry")
	_check(component.try_activate_skill("whirlwind"), "skill could not reactivate after expiry")
	for entry: Dictionary in component.available_skills:
		_check(is_equal_approx(float(entry["current_cooldown"]), duration), "duplicate skill binding showed a different cooldown")
	_check(not component.try_activate_skill("whirlwind"), "duplicate binding bypassed shared cooldown")
	_check(paid_costs.size() == 2 and activated.size() == 2, "skill cost/activation count drifted")
	component.queue_free()


## Bonus expiry and equipment removal must publish one valid, non-healing HP state.
func _test_health_bonus_removal() -> void:
	var stats := CharacterStats.new()
	var inventory := InventoryData.new()
	var armor := ItemDatabase.get_item_copy("leather_armor")
	armor.health_bonus = 50
	_check(inventory.add_item(armor, 1) == 0 and inventory.equip_item(0), "HP bonus equipment setup failed")
	var notifications: Array[Vector2i] = []
	var deaths: Array[bool] = []
	stats.health_changed.connect(func(current: int, maximum: int) -> void: notifications.append(Vector2i(current, maximum)))
	stats.died.connect(func() -> void: deaths.append(true))
	stats.apply_equipment_bonuses(inventory)
	_check(stats.current_health == 100 and stats.max_health == 150, "equipping HP bonus healed the player")
	stats.heal(50)
	notifications.clear()
	_check(inventory.unequip_item("armor"), "HP bonus unequip failed")
	stats.apply_equipment_bonuses(inventory)
	_check(stats.current_health == 100, "unequipped HP bonus left health above maximum")
	_check(notifications == [Vector2i(100, 100)], "unequip did not publish one valid final HP state")

	_check(inventory.equip_item(0), "HP bonus re-equip failed")
	stats.apply_equipment_bonuses(inventory)
	stats.heal(50)
	notifications.clear()
	stats.clear_equipment_bonuses()
	_check(stats.current_health == 100 and notifications == [Vector2i(100, 100)], "clearing equipment HP bonus did not clamp exactly once")

	var buffs := BuffComponent.new()
	add_child(buffs)
	buffs.set_process(false)
	buffs.buffs_changed.connect(func() -> void: stats.apply_buff_bonuses(buffs))
	buffs.apply_buff(ItemDatabase.get_item("vitality_tonic_t1"))
	_check(stats.current_health == 100 and stats.max_health == 120, "HP buff healed on cap increase")
	stats.heal(20)
	notifications.clear()
	buffs._process(61.0)
	_check(stats.current_health == 100 and notifications == [Vector2i(100, 100)], "expired buff left excess HP or duplicate notification")

	buffs.apply_buff(ItemDatabase.get_item("vitality_tonic_t1"))
	stats.heal(20)
	notifications.clear()
	stats.clear_buff_bonuses()
	_check(stats.current_health == 100 and notifications == [Vector2i(100, 100)], "clearing buff HP bonus did not clamp exactly once")
	stats.current_health = 25
	stats.apply_buff_bonuses(buffs)
	stats.clear_buff_bonuses()
	_check(stats.current_health == 25, "bonus update healed or injured a wounded player")
	stats.current_health = 0
	var death_count: int = deaths.size()
	notifications.clear()
	stats.apply_buff_bonuses(buffs)
	stats.clear_buff_bonuses()
	stats.apply_equipment_bonuses(inventory)
	stats.clear_equipment_bonuses()
	_check(stats.current_health == 0 and deaths.size() == death_count, "bonus refresh resurrected player or repeated death")
	_check(notifications.size() == 4, "dead bonus updates changed notification count")
	buffs.queue_free()


## Failed destination preparation must preserve the current run and player position.
func _test_map_load_recovery() -> void:
	var root_node := Node2D.new()
	add_child(root_node)
	var player := Node2D.new()
	root_node.add_child(player)
	player.position = Vector2(12, 34)
	var service: Node = load("res://sense/globals/scene_transition_service.gd").new()
	add_child(service)
	service.set("_root", root_node)
	service.set("_player", player)
	var old_map := Node2D.new()
	root_node.add_child(old_map)
	service.set("_active_map_id", "dungeon")
	service.set("_active_map_node", old_map)
	service.set("_loaded_maps", {"dungeon": old_map})
	service.call("register_map", "broken", "res://tests/missing_destination.tscn")
	var completed: Array[String] = []
	service.connect("transition_completed", func(map_id: String) -> void: completed.append(map_id))
	await service.call("go_to", "broken")
	_check(old_map.get_parent() == root_node and not old_map.is_queued_for_deletion(), "failed load detached or freed active dungeon")
	_check(service.call("get_active_map_node") == old_map and service.call("get_active_map") == "dungeon", "failed load changed active map identity")
	_check(player.position == Vector2(12, 34) and completed.is_empty(), "failed load moved player or emitted completion")
	_check(not bool(service.get("_is_transitioning")), "failed load kept transition locked")

	var wrong_resource := Resource.new()
	var resource_path := "user://map_recovery_wrong.tres"
	_check(ResourceSaver.save(wrong_resource, resource_path) == OK, "wrong-map resource fixture failed")
	service.call("register_map", "wrong", resource_path)
	await service.call("go_to", "wrong")
	_check(old_map.get_parent() == root_node and completed.is_empty(), "non-scene destination destroyed current map")

	var wrong_root := Node.new()
	var wrong_scene := PackedScene.new()
	_check(wrong_scene.pack(wrong_root) == OK, "wrong-root scene pack failed")
	var wrong_path := "user://map_recovery_wrong_root.tscn"
	_check(ResourceSaver.save(wrong_scene, wrong_path) == OK, "wrong-root scene save failed")
	wrong_root.free()
	service.call("register_map", "wrong_root", wrong_path)
	await service.call("go_to", "wrong_root")
	_check(old_map.get_parent() == root_node and not old_map.is_queued_for_deletion() and completed.is_empty(), "non-Node2D scene changed current run")

	var map_template := Node2D.new()
	var spawn := Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector2(90, 120)
	map_template.add_child(spawn)
	spawn.owner = map_template
	var packed := PackedScene.new()
	_check(packed.pack(map_template) == OK, "valid map fixture pack failed")
	var map_path := "user://map_recovery_valid.tscn"
	_check(ResourceSaver.save(packed, map_path) == OK, "valid map fixture save failed")
	map_template.free()
	service.call("register_map", "valid", map_path)
	await service.call("go_to", "valid")
	var new_map: Node2D = service.call("get_active_map_node")
	_check(new_map != old_map and new_map.get_parent() == root_node, "valid transition did not attach destination")
	_check(player.global_position == Vector2(90, 120), "valid transition did not use spawn marker")
	_check(completed == ["valid"], "valid transition did not emit exactly one completion")
	_check(old_map.is_queued_for_deletion(), "successful exit kept noncached dungeon alive")
	service.call("register_map", "return", map_path)
	await service.call("go_to", "return")
	await service.call("go_to", "valid")
	_check(service.call("get_active_map_node") == new_map, "cached map was not reused")
	# Deleted cached maps must be recreated, and the real fade must release its lock.
	new_map.free()
	service.call("initialize", root_node, player)
	await service.call("go_to", "return")
	await service.call("go_to", "valid")
	var restored_map: Node2D = service.call("get_active_map_node")
	_check(is_instance_valid(restored_map) and restored_map.get_parent() == root_node, "stale map cache was not recovered")
	_check(not bool(service.get("_is_transitioning")), "successful fade left transition lock active")
	var fade_rect: ColorRect = service.get("_fade_rect")
	_check(is_zero_approx(fade_rect.modulate.a), "successful fade did not restore visibility")
	await service.call("go_to", "broken")
	_check(service.call("get_active_map_node") == restored_map and restored_map.get_parent() == root_node, "failed faded transition detached current map")
	_check(not bool(service.get("_is_transitioning")) and is_zero_approx(fade_rect.modulate.a), "failed fade did not restore visibility or unlock")
	DirAccess.remove_absolute(wrong_path)
	DirAccess.remove_absolute(resource_path)
	DirAccess.remove_absolute(map_path)
	service.queue_free()
	root_node.queue_free()


## A pre-reset timer must not shorten invincibility for a newer accepted hit.
func _test_hurtbox_reset_race() -> void:
	var hurtbox := HurtboxComponent.new()
	add_child(hurtbox)
	hurtbox.invincibility_time = 0.10
	_check(hurtbox.take_damage(1, 0.0, Vector2.ZERO), "initial hurtbox damage rejected")
	await get_tree().create_timer(0.03).timeout
	hurtbox.reset()
	hurtbox.invincibility_time = 0.30
	_check(not hurtbox.take_resolved_damage(1, false, 0.0, Vector2.ZERO).is_empty(), "post-reset resolved damage rejected")
	await get_tree().create_timer(0.14).timeout
	_check(not hurtbox.can_take_damage, "pre-reset timer released a newer hit's invincibility")
	_check(not hurtbox.take_damage(1, 0.0, Vector2.ZERO), "raw damage bypassed newer invincibility")
	await get_tree().create_timer(0.20).timeout
	_check(hurtbox.can_take_damage, "new hit timer did not release invincibility")

	# Synchronous signal observers can reset and accept another hit immediately.
	var replaced := [false]
	var callback := func(_amount: int, _knockback: float, _position: Vector2) -> void:
		if replaced[0]:
			return
		replaced[0] = true
		hurtbox.reset()
		hurtbox.invincibility_time = 0.30
		hurtbox.take_damage(1, 0.0, Vector2.ZERO)
	hurtbox.damage_received.connect(callback)
	hurtbox.invincibility_time = 0.10
	hurtbox.take_damage(1, 0.0, Vector2.ZERO)
	hurtbox.damage_received.disconnect(callback)
	await get_tree().create_timer(0.14).timeout
	_check(not hurtbox.can_take_damage, "reentrant reset let old damage callback unlock the new hit")
	await get_tree().create_timer(0.20).timeout
	_check(hurtbox.can_take_damage, "reentrant hit did not expire normally")
	hurtbox.queue_free()
