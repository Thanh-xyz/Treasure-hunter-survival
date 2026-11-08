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
	_test_equipment_enhancement()
	_test_equipment_quest_objectives()
	_test_inventory_removal_invariants()
	_test_recipe_catalog_validation()
	_test_reward_box_resolver()
	_test_reward_box_checkbox_resolver()
	_test_reward_box_catalog()
	_test_quest_reward_resolver()
	_test_crafting_transaction()
	_test_tutorial_t01_claim_transaction()
	_test_quest_claim_transaction()
	_test_daily_claim_recovery()
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
	inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE - 2)
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
		{"item": ItemDatabase.get_item_copy("stone_fire_1"), "quantity": 1},
	]
	_check(not inventory.transact_items(removals, additions), "full inventory accepted a transaction")
	_check(int(signal_count["value"]) == 0, "failed transaction emitted an inventory change")
	_check(inventory.get_item_count("fire_shard") == 4, "failed transaction consumed fire shards")
	_check(inventory.get_item_count("iron_ore") == 3, "failed transaction consumed iron ore")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	signal_count["value"] = 0
	_check(inventory.transact_items(removals, additions), "transaction failed after freeing a slot")
	_check(int(signal_count["value"]) == 1, "successful transaction did not emit exactly one change")
	_check(inventory.get_item_count("stone_fire_1") == 1, "successful transaction omitted output")


func _test_inventory_add_signals() -> void:
	var inventory := InventoryData.new()
	var signals := {"value": 0}
	inventory.inventory_changed.connect(func() -> void: signals["value"] += 1)
	var sword := ItemDatabase.get_item("ashwood_blade")
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
		{"weight": 33.0, "reward": {"gold": 5, "items": {"wood": 2}}},
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
	_check(RewardBoxResolver.resolve_roll(entries, 68) == {"gold": 5, "items": {"wood": 2}}, "roll 68 missed third reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 100) == {"gold": 5, "items": {"wood": 2}}, "roll 100 missed third reward boundary")
	_check(RewardBoxResolver.resolve_roll(entries, 0).is_empty(), "reward box accepted roll zero")
	_check(RewardBoxResolver.resolve_roll(entries, 101).is_empty(), "reward box accepted roll above total")

	var normalized_rng := RandomNumberGenerator.new()
	normalized_rng.seed = 1
	var source_reward := {"diamonds": 0, "gold": 5.0, "items": {"wood": 2.0}}
	var normalized := RewardBoxResolver.resolve([
		{"weight": 1, "reward": source_reward},
	], normalized_rng)
	_check(normalized == {"gold": 5, "items": {"wood": 2}}, "reward normalization changed the payload")
	normalized["gold"] = 999
	(normalized["items"] as Dictionary)["wood"] = 999
	_check(source_reward == {"diamonds": 0, "gold": 5.0, "items": {"wood": 2.0}}, "resolved reward shared source state")

	var source_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	# Equipment rewards are ordinary items since save v6; the retired "equipment" key is invalid.
	_check(RewardBoxResolver.normalize_reward({"equipment": [{"card_id": 28, "stats": source_stats}]}).is_empty(), "retired equipment reward kind was accepted")

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
	var fixed := {
		"diamond_1": {"diamonds": 1},
		"gold_200": {"gold": 200},
		"mossback_bounty": {"gold": 30, "diamonds": 1},
	}
	for table_id: String in fixed:
		_check(RewardBoxCatalog.has_table(table_id), "reward table %s is missing" % table_id)
		var entries := RewardBoxCatalog.get_entries(table_id)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		_check(RewardBoxCatalog.resolve(table_id, rng) == fixed[table_id], "reward table %s resolved incorrectly" % table_id)
		(entries[0]["reward"] as Dictionary).clear()
		_check(RewardBoxCatalog.get_entries(table_id)[0]["reward"] == fixed[table_id], "reward table %s exposed mutable state" % table_id)
	var seen := {}
	var starter_rng := RandomNumberGenerator.new()
	starter_rng.seed = 101
	for _i in range(60):
		var reward := RewardBoxCatalog.resolve("starter_weapon", starter_rng)
		for item_id: String in reward.get("items", {}):
			seen[item_id] = true
	var starters := seen.keys()
	starters.sort()
	_check(starters == ["ashwood_blade", "ember_dirk", "ironbark_cleaver"], "starter weapon table did not reach every weapon: %s" % [starters])
	for table_id: String in RewardBoxCatalog.table_ids():
		for entry: Dictionary in RewardBoxCatalog.get_entries(table_id):
			_check(not RewardBoxResolver.normalize_reward(entry["reward"]).is_empty(), "reward table %s holds an invalid reward" % table_id)
	_check(not RewardBoxCatalog.has_table("149") and RewardBoxCatalog.get_entries("missing").is_empty(), "unknown reward table registered")
	var missing_rng := RandomNumberGenerator.new()
	missing_rng.seed = 1
	_check(RewardBoxCatalog.resolve("missing", missing_rng).is_empty(), "unknown reward table resolved a reward")


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
	var box_quest := {"id": "t01", "reward_table": "starter_weapon"}
	var first := QuestRewardResolver.resolve(box_quest, first_rng)
	_check(not first.is_empty() and first == QuestRewardResolver.resolve(box_quest, second_rng), "quest reward table roll was not deterministic")
	_check(RewardBoxResolver.normalize_reward(first) == first, "quest reward table roll was not canonical")
	var invalid: Array[Dictionary] = [
		{},
		{"reward": [], "reward_table": "starter_weapon"},
		{"reward": {"gold": 1}, "reward_table": "starter_weapon"},
		{"reward_table": "missing"},
		{"reward_table": 149},
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
	full_inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
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
		observed["items"] = _player.inventory.get_item_count("ashwood_blade")
	)

	_check(shop.process_purchase({"id": "ashwood_blade", "name": "Ashwood Blade", "price": -500}), "shop rejected a valid catalog item")
	var price := ItemDatabase.get_item("ashwood_blade").buy_price
	_check(price > 0 and _player.inventory.gold == 200 - price, "shop trusted a spoofed client price")
	_check(_player.inventory.get_item_count("ashwood_blade") == 1, "shop purchase omitted the item")
	_check(int(observed["gold"]) == 200 - price and int(observed["items"]) == 1, "shop signals exposed a partial purchase state")

	_player.inventory.add_item(ItemDatabase.get_item("ember_dirk"), InventoryData.INVENTORY_SIZE - 1)
	_check(not shop.process_purchase({"id": "ember_dirk", "name": "Ember Dirk", "price": 1}), "full inventory accepted a shop purchase")
	_check(_player.inventory.gold == 200 - price, "failed full-inventory purchase consumed gold")

	_player.inventory = InventoryData.new()
	_player.inventory.gold = 49
	_check(not shop.process_purchase({"id": "ember_dirk", "name": "Ember Dirk", "price": 1}), "shop purchase ignored insufficient authoritative gold")
	_check(_player.inventory.gold == 49 and _player.inventory.get_item_count("ember_dirk") == 0, "failed shop purchase changed inventory")
	_check(not shop.process_purchase({"id": "vitality_tonic_t1", "price": -100}), "shop accepted an item without a catalog price")
	_check(not shop.process_purchase({"id": "missing_item", "price": -100}), "shop accepted an unknown item")
	shop.queue_free()


func _test_sale_transaction() -> void:
	var inventory := InventoryData.new()
	var wood := ItemDatabase.get_item("wood")
	var sword := ItemDatabase.get_item("ashwood_blade")
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

	var unsellable := ItemDatabase.get_item_copy("vitality_tonic_t1")
	inventory.inventory_slots[1] = {"item": unsellable, "quantity": 1}
	_check(inventory.sell_item_at(1, unsellable.id) == 0, "unsellable item credited gold")
	_check(inventory.get_item_at(1).item == unsellable, "failed unsellable sale removed the item")


func _test_equipment_transactions() -> void:
	var inventory := InventoryData.new()
	inventory.add_item(ItemDatabase.get_item("emberforged_blade"), 1)
	_check(inventory.equip_item(0), "equipment setup failed")
	inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	var inventory_signals := {"value": 0}
	var equipment_signals := {"value": 0}
	var gem_signals := {"value": 0}
	var observed := {"inventory_has_weapon": false, "equipment_empty": false, "gem_consumed": false}
	var on_inventory_changed := func() -> void: inventory_signals["value"] += 1
	var on_equipment_changed := func(_slot: String) -> void:
		equipment_signals["value"] += 1
		observed["inventory_has_weapon"] = inventory.get_item_count("emberforged_blade") == 1
		observed["equipment_empty"] = inventory.get_equipped("weapon") == null
	var on_gems_changed := func(_slot: String) -> void:
		gem_signals["value"] += 1
		observed["gem_consumed"] = inventory.get_item_count("stone_fire_1") == 0
	inventory.inventory_changed.connect(on_inventory_changed)
	inventory.equipment_changed.connect(on_equipment_changed)
	inventory.gems_changed.connect(on_gems_changed)

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
	swap_inventory.add_item(ItemDatabase.get_item("ashwood_blade"), 1)
	swap_inventory.equip_item(0)
	swap_inventory.add_item(ItemDatabase.get_item("emberforged_blade"), 1)
	_check(swap_inventory.unequip_item("weapon", 0), "target-slot equipment swap failed")
	_check(swap_inventory.get_equipped("weapon").id == "emberforged_blade", "target-slot swap equipped the wrong item")
	_check(swap_inventory.get_item_at(0).item.id == "ashwood_blade", "target-slot swap lost the previous equipment")

	inventory = InventoryData.new()
	inventory.inventory_changed.connect(on_inventory_changed)
	inventory.equipment_changed.connect(on_equipment_changed)
	inventory.gems_changed.connect(on_gems_changed)
	inventory.add_item(ItemDatabase.get_item("emberforged_blade"), 1)
	inventory.equip_item(0)
	inventory.add_item(ItemDatabase.get_item("stone_fire_1"), 1)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	gem_signals["value"] = 0
	observed["gem_consumed"] = false
	_check(not inventory.socket_gem("weapon", 8, 0), "socket index past the 8 sockets was accepted")
	_check(not inventory.socket_gem("weapon", 0, 5), "empty bag slot was socketed")
	_check(inventory.socket_gem("weapon", 3, 0), "valid stone socketing failed")
	_check(int(inventory_signals["value"]) == 1 and int(equipment_signals["value"]) == 1 and int(gem_signals["value"]) == 1, "socketing emitted duplicate or missing signals")
	_check(bool(observed["gem_consumed"]), "gem signal exposed an unconsumed stone")
	_check(inventory.get_equipped("weapon").get_gem_sockets()[3] == "stone_fire_1", "stone landed in the wrong socket")
	inventory.add_item(ItemDatabase.get_item("stone_fire_1"), 1)
	_check(not inventory.socket_gem("weapon", 3, _find_item(inventory, "stone_fire_1")), "occupied socket accepted a second stone")

	inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	gem_signals["value"] = 0
	inventory.remove_item_at(_find_item(inventory, "stone_fire_1"))
	inventory.add_item(ItemDatabase.get_item("ashwood_blade"), 1)
	inventory_signals["value"] = 0
	_check(not inventory.unsocket_gem("weapon", 3), "full inventory accepted stone removal")
	_check(inventory.get_equipped("weapon").count_socketed_gems() == 1, "failed stone removal changed equipment")
	_check(int(inventory_signals["value"]) == 0 and int(equipment_signals["value"]) == 0 and int(gem_signals["value"]) == 0, "failed stone removal emitted changes")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	inventory_signals["value"] = 0
	equipment_signals["value"] = 0
	gem_signals["value"] = 0
	_check(inventory.unsocket_gem("weapon", 3), "stone removal failed after freeing capacity")
	_check(inventory.get_item_count("stone_fire_1") == 1 and inventory.get_equipped("weapon").count_socketed_gems() == 0, "stone removal did not commit final state")
	_check(int(inventory_signals["value"]) == 1 and int(equipment_signals["value"]) == 1 and int(gem_signals["value"]) == 1, "stone removal emitted duplicate or missing signals")
	_check(not inventory.unsocket_gem("weapon", 3), "empty socket unsocketed")


func _find_item(inventory: InventoryData, item_id: String) -> int:
	for i in range(inventory.inventory_slots.size()):
		var item: ItemData = inventory.inventory_slots[i].get("item")
		if item != null and item.id == item_id:
			return i
	return -1


func _test_equipment_enhancement() -> void:
	var inventory := InventoryData.new()
	var template := ItemDatabase.get_item("emberforged_blade")
	inventory.add_item(template, 1)
	_check(inventory.equip_item(0), "enhancement equipment setup failed")
	inventory.add_item(ItemDatabase.get_item("stone_fire_1"), 1)
	_check(inventory.socket_gem("weapon", 0, 0), "enhancement stone setup failed")

	var weapon := inventory.get_equipped("weapon")
	var base_attack := weapon.get_scaled_attack_bonus()
	var cost := weapon.get_upgrade_cost()
	_check(cost == int(weapon.upgrade_base_cost * pow(weapon.upgrade_cost_rate, 1)), "level-1 upgrade cost did not follow configured curve")
	inventory.gold = cost + 25
	var stats := CharacterStats.new()
	stats.apply_equipment_bonuses(inventory)
	var attack_before := stats.attack_damage
	var signal_counts := {"gold": 0, "equipment": 0, "upgraded": 0}
	var observed := {"level": 0, "gold": -1, "gems": 0}
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
		observed["gems"] = inventory.get_equipped("weapon").count_socketed_gems()
	)

	_check(inventory.upgrade_equipment("weapon"), "valid equipment upgrade failed")
	weapon = inventory.get_equipped("weapon")
	_check(weapon.enhancement_level == 2, "upgrade did not increase displayed level")
	_check(inventory.gold == 25, "upgrade charged the wrong gold cost")
	_check(weapon.get_scaled_attack_bonus() == int(EquipmentBalance.compute("weapon", "sword", "epic", 2)["attack"]), "level-2 attack did not follow the equipment formula")
	_check(weapon.get_scaled_attack_bonus() > base_attack and stats.attack_damage > attack_before, "upgrade did not increase character attack")
	_check(weapon.get_gem_sockets()[0] == "stone_fire_1", "upgrade lost socketed stones")
	_check(template.enhancement_level == 1 and template.gems.is_empty(), "upgrade mutated the catalog template")
	_check(int(signal_counts["gold"]) == 1 and int(signal_counts["equipment"]) == 1 and int(signal_counts["upgraded"]) == 1, "upgrade emitted duplicate or missing signals")
	_check(int(observed["level"]) == 2 and int(observed["gold"]) == 25 and int(observed["gems"]) == 1, "upgrade signal exposed partial state")
	_check(inventory.count_equipment_at_or_above_level(2) == 1, "level query missed upgraded equipment")
	var stones_before := inventory.get_item_count("stone_fire_1")
	_check(inventory.unsocket_gem("weapon", 0), "upgraded equipment could not remove its stone")
	_check(inventory.get_equipped("weapon").enhancement_level == 2, "stone removal reset enhancement level")
	_check(inventory.get_item_count("stone_fire_1") == stones_before + 1, "stone removal did not return the stone")
	_check(inventory.socket_gem("weapon", 0, _find_item(inventory, "stone_fire_1")), "upgraded equipment could not resocket its stone")
	_check(inventory.get_equipped("weapon").enhancement_level == 2, "stone socketing reset enhancement level")

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
	capped.gems = weapon.gems.duplicate()
	capped.enhancement_level = capped.max_upgrade_level
	inventory._set_equipped("weapon", capped)
	inventory.gold = 999999
	_check(not inventory.upgrade_equipment("weapon"), "max-level equipment upgraded")
	_check(capped.enhancement_level == capped.max_upgrade_level, "max-level rejection changed equipment")

	var locked := ItemDatabase.get_item_copy("ashwood_blade")
	locked.can_upgrade = false
	locked.max_upgrade_level = 1
	inventory._set_equipped("weapon", locked)
	_check(not inventory.upgrade_equipment("weapon"), "non-upgradeable equipment upgraded")


func _test_equipment_quest_objectives() -> void:
	var inventory := InventoryData.new()
	var rare_weapon := ItemDatabase.get_item_copy("emberforged_blade")
	rare_weapon.rarity = ItemData.ItemRarity.UNCOMMON
	rare_weapon.enhancement_level = 5
	var epic_armor := ItemDatabase.get_item_copy("ironbark_plate")
	epic_armor.rarity = ItemData.ItemRarity.EPIC
	epic_armor.enhancement_level = 3
	var common_helmet := ItemDatabase.get_item_copy("ironbark_helm")
	common_helmet.rarity = ItemData.ItemRarity.COMMON
	common_helmet.enhancement_level = 2
	inventory._set_equipped("weapon", rare_weapon)
	inventory._set_equipped("armor", epic_armor)
	inventory._set_equipped("helmet", common_helmet)

	_check(inventory.count_equipped_items() == 3, "equipped-count query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_rarity(ItemData.ItemRarity.UNCOMMON) == 2, "uncommon equipment query missed uncommon-or-better items")
	_check(inventory.count_equipment_at_or_above_rarity(ItemData.ItemRarity.EPIC) == 1, "epic equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_rarity(-1) == 0, "invalid rarity query was accepted")
	_check(inventory.count_equipment_at_or_above_level(3) == 2, "level-3 equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_level(5) == 1, "level-5 equipment query returned the wrong total")
	_check(inventory.count_equipment_at_or_above_level(0) == 0, "invalid equipment-level query was accepted")

	_check(QuestService.get_state_objective_value({"type": "equipped_count", "target": "any"}, inventory) == 3, "equipped-count quest objective returned the wrong value")
	_check(QuestService.get_state_objective_value({"type": "equipped_rarity", "target": ItemData.ItemRarity.UNCOMMON}, inventory) == 2, "rarity quest objective returned the wrong value")
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
	_check(all_recipes.size() == 9, "recipe catalog changed unexpectedly")
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

	var existing := RecipeDatabase.get_recipe("stone_fire")
	_check(not RecipeDatabase.register_recipe(existing, false), "duplicate recipe id overwrote the catalog")
	_check(RecipeDatabase.get_recipe("stone_fire") == existing, "duplicate registration replaced the original recipe")


func _test_crafting_transaction() -> void:
	var inventory := _full_inventory_with_craft_materials()
	var panel := CraftingPanel.new()
	panel.player_inventory = inventory
	panel.selected_recipe = RecipeDatabase.get_recipe("stone_fire")
	panel.selected_tier = 1
	_check(not panel._execute_craft(), "craft succeeded without output capacity")
	_check(inventory.get_item_count("fire_shard") == 4, "failed craft consumed fire shards")
	_check(inventory.get_item_count("iron_ore") == 3, "failed craft consumed iron ore")
	inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(panel._execute_craft(), "craft failed after freeing a slot")
	_check(inventory.get_item_count("stone_fire_1") == 1, "craft did not add its output")
	panel.free()


func _test_tutorial_t01_claim_transaction() -> void:
	SaveService.delete_save()
	GameState.reset_profile()
	QuestService.reset()
	var quest_index := GameContent.get_main_quest_index("t01")
	var next_index := GameContent.get_main_quest_index("t02")
	_check(quest_index == 1 and next_index == 2, "tutorial t01/t02 chain position drifted")
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	QuestService.main_index = quest_index
	QuestService.main_progress = 10
	QuestService.main_ready = true
	var authority_rng := RandomNumberGenerator.new()
	authority_rng.seed = 305
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 305
	var expected_reward := RewardBoxCatalog.resolve("starter_weapon", expected_rng)
	_check(QuestService.set_reward_authority_rng(authority_rng), "quest reward authority RNG injection failed")
	GameState.current_zone = "invalid_zone"
	var state_before_failed_prepare := authority_rng.state
	_check(not QuestService.claim("t01"), "invalid snapshot prepared t01")
	_check(authority_rng.state == state_before_failed_prepare, "failed t01 prepare consumed RNG")
	_check(SaveService.get_pending_claim().is_empty(), "failed t01 prepare left a journal")
	GameState.current_zone = "town"
	_check(not QuestService.claim("t01"), "full inventory accepted the t01 weapon")
	var pending := SaveService.get_pending_claim()
	_check(pending.get("claim_id", "") == "main:t01", "t01 did not prepare its journal")
	_check(pending.get("reward", {}) == expected_reward, "t01 journal did not preserve the rolled starter weapon")
	var state_after_prepare := authority_rng.state
	_check(not QuestService.claim("t01"), "full inventory retried t01 successfully")
	_check(authority_rng.state == state_after_prepare, "t01 retry rerolled its reward")

	_player.inventory = InventoryData.new()
	QuestService.reset()
	_check(SaveService.load_game(), "t01 pending claim did not reload")
	_check(QuestService.main_index == quest_index and QuestService.main_ready, "t01 state did not recover")
	_check(SaveService.get_pending_claim().get("reward", {}) == expected_reward, "t01 reward changed after reload")
	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("t01"), "t01 did not retry after freeing capacity")
	_check(QuestService.main_index == next_index and SaveService.get_pending_claim().is_empty(), "t01 did not advance to t02")
	var expected_id: String = (expected_reward["items"] as Dictionary).keys()[0]
	var rewarded := _player.inventory.get_item_at(InventoryData.INVENTORY_SIZE - 1).get("item") as ItemData
	_check(rewarded != null and rewarded.id == expected_id, "t01 granted the wrong starter weapon")
	_check(not QuestService.claim("t01"), "completed t01 granted twice")


func _test_quest_claim_transaction() -> void:
	GameState.reset_profile()
	QuestService.reset()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	var q02_index := GameContent.get_main_quest_index("q02")
	QuestService.main_index = q02_index
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[q02_index]["obj"]["count"])
	QuestService.main_ready = true
	_check(not QuestService.claim("q02"), "quest advanced without reward capacity")
	_check(QuestService.main_index == q02_index and QuestService.main_ready, "failed quest claim changed state")
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
	QuestService.reset()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	QuestService.dailies["d_boss"]["progress"] = 1
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
	_check(_player.inventory.gold == gold_before, "failed automatic daily retry granted a partial reward")

	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("d_boss"), "stale pending daily claim did not retry")
	_check(_player.inventory.gold == gold_before + 300, "daily retry granted incorrect gold")
	_check(_player.inventory.get_item_count("stone_guard_1") == 2, "daily retry omitted its item reward")
	_check(bool(QuestService.dailies["d_boss"]["claimed"]), "daily retry did not mark the saved quest claimed")
	_check(SaveService.get_pending_claim().is_empty(), "successful daily retry did not clear its journal")

	QuestService.get_tracker_rows()
	_check(QuestService.daily_date != stale_date, "completed stale daily state did not reset")
	_check(not QuestService.claim("d_boss"), "completed daily journal granted twice after reset")
	_check(_player.inventory.get_item_count("stone_guard_1") == 2, "duplicate daily claim changed the reward")


func _test_building_collection_transaction() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
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
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE - 2)
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
