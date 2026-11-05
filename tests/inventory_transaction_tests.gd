extends Node

var _failures: Array[String] = []
var _player: StubPlayer


class StubPlayer:
	extends Node
	var inventory := InventoryData.new()
	func get_inventory() -> InventoryData:
		return inventory


func _ready() -> void:
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
	_test_inventory_removal_invariants()
	_test_recipe_catalog_validation()
	_test_crafting_transaction()
	_test_quest_claim_transaction()
	_test_building_collection_transaction()
	_test_building_upgrade_transaction()
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


func _test_economy_transaction() -> void:
	_player.inventory = InventoryData.new()
	_player.inventory.gold = 100
	_player.inventory.add_item(ItemDatabase.get_item("wood"), 10)
	var inventory_signals := {"value": 0}
	var gold_signals := {"value": 0}
	_player.inventory.inventory_changed.connect(func() -> void: inventory_signals["value"] += 1)
	_player.inventory.gold_changed.connect(func(_amount: int) -> void: gold_signals["value"] += 1)
	inventory_signals["value"] = 0
	gold_signals["value"] = 0

	_check(not GameState.spend({"gold": 50, "wood": 11}), "mixed cost succeeded without enough items")
	_check(_player.inventory.gold == 100, "failed mixed cost consumed gold")
	_check(_player.inventory.get_item_count("wood") == 10, "failed mixed cost consumed items")
	_check(int(inventory_signals["value"]) == 0 and int(gold_signals["value"]) == 0, "failed mixed cost emitted changes")

	_check(not GameState.spend({"gold": 50, "missing_item": 1}), "unknown cost item was accepted")
	_check(_player.inventory.gold == 100 and _player.inventory.get_item_count("wood") == 10, "invalid cost changed economy state")

	_check(GameState.spend({"gold": 50, "wood": 4}), "valid mixed cost failed")
	_check(_player.inventory.gold == 50, "valid mixed cost charged incorrect gold")
	_check(_player.inventory.get_item_count("wood") == 6, "valid mixed cost charged incorrect item quantity")
	_check(int(inventory_signals["value"]) == 1 and int(gold_signals["value"]) == 1, "mixed cost did not emit one final-state signal per domain")


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


func _test_quest_claim_transaction() -> void:
	GameState.reset_profile()
	QuestService.reset()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	QuestService.main_index = 1
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[1]["obj"]["count"])
	QuestService.main_ready = true
	var xp_before := GameState.xp
	_check(not QuestService.claim("q02"), "quest advanced without reward capacity")
	_check(QuestService.main_index == 1 and QuestService.main_ready, "failed quest claim changed state")
	_check(GameState.xp == xp_before, "failed quest claim granted partial XP")
	_player.inventory.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("q02"), "quest failed after freeing reward capacity")
	_check(_player.inventory.get_item_count("health_potion") == 3, "quest did not grant full item reward")


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
