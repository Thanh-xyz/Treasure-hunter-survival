extends Node2D
## Headless tests for the survival RPG systems (progression, collections,
## homestead, quests, save, monsters). Run via res://tests/LegacySystemTests.tscn
## (runs after the legacy phases) or alone via res://tests/SurvivalTests.tscn.

var _failures: Array[String] = []
var _stub_player: Node2D


class StubPlayer:
	extends Node2D
	var inventory := InventoryData.new()
	var stats := CharacterStats.new()
	var damage_taken: int = 0
	var dig_swings: int = 0
	func get_inventory() -> InventoryData:
		return inventory
	func take_damage(amount: int) -> void:
		damage_taken += amount
	func heal(_amount: int) -> void:
		pass
	func is_dead() -> bool:
		return false
	func can_auto_dig() -> bool:
		return true
	func play_auto_dig_swing(_target_position: Vector2) -> bool:
		dig_swings += 1
		return true


class ResolvedHitTarget:
	extends Node2D
	var hp: int = 7
	var hurtbox: HurtboxComponent

	func setup() -> void:
		hurtbox = HurtboxComponent.new()
		hurtbox.invincibility_time = 0.05
		add_child(hurtbox)
		hurtbox.resolved_damage_received.connect(_on_resolved_damage)

	func _on_resolved_damage(amount: int, critical: bool, _knockback: float, _from_position: Vector2) -> void:
		var applied := mini(amount, hp)
		hp -= applied
		hurtbox.confirm_resolved_damage(applied, critical)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		push_error("[SURVIVAL TEST] FAIL: " + msg)


func run_all() -> bool:
	SaveService.enabled = false
	SaveService.SAVE_PATH = "user://saves/test_profile.json"
	_stub_player = StubPlayer.new()
	_stub_player.add_to_group("player")
	add_child(_stub_player)

	_test_pixel_art()
	_test_progression()
	_test_inventory_transactions()
	_test_economy_and_collections()
	_test_buildings()
	_test_quests()
	await _test_ground_dig()
	await _test_resource_node_overflow()
	_test_save_roundtrip()
	await _test_monster_kill()
	await _test_menu_keeps_world_running()
	await _test_auto_farm_toggle()
	_test_combat_roll()
	await _test_resolved_combat_hit()
	await _test_player_combat_modifiers()

	_stub_player.queue_free()
	SaveService.delete_save()
	GameState.reset_profile()
	QuestService.reset()
	if _failures.is_empty():
		print("[SURVIVAL TEST] ALL PASSED")
		return true
	print("[SURVIVAL TEST] %d FAILURES" % _failures.size())
	for f in _failures:
		print("  - ", f)
	return false


func _test_pixel_art() -> void:
	for key in ["slime", "bat", "boar", "mushroom", "mosquito", "snail", "field_stump", "hud_helmet", "hud_heart", "hud_sword", "hud_boot", "hud_world", "hud_coin", "pet_fox", "pet_turtle", "pet_owl", "pet_cat", "mount_pony", "mount_stag", "mount_boar", "mount_tortoise", "altar", "bolt"]:
		var tex := PixelArt.get_texture(key)
		_check(tex != null and tex.get_width() > 4 and tex.get_height() > 4, "pixel art %s builds" % key)
	_check(PixelArt.get_texture("slime", "slime_king") != PixelArt.get_texture("slime"), "palette variants are distinct textures")


func _test_progression() -> void:
	GameState.reset_profile()
	_check(GameState.level == 1, "fresh profile is level 1")
	var need := GameState.xp_needed()
	GameState.add_xp(need + 5)
	_check(GameState.level == 2, "levels up after enough XP")
	_check(GameState.xp == 5, "XP carries over")
	var s := GameState.compute_base_stats()
	var base: Dictionary = GameContent.HEROES["warden"]["base"]
	var growth: Dictionary = GameContent.HEROES["warden"]["growth"]
	_check(s["hp"] == int(base["hp"]) + int(growth["hp"]), "level 2 HP includes growth")
	GameState.equip_pet("ember_fox")
	var s2 := GameState.compute_base_stats()
	_check(s2["atk"] > s["atk"], "pet passive adds attack")
	var stats := CharacterStats.new()
	GameState.apply_to_stats(stats)
	_check(stats.max_health == s2["hp"], "apply_to_stats sets max HP")
	_check(stats.current_health == stats.max_health, "full HP stays full")


func _test_inventory_transactions() -> void:
	var inv := InventoryData.new()
	var fire_shard := ItemDatabase.get_item("fire_shard")
	var iron_ore := ItemDatabase.get_item("iron_ore")
	var output := ItemDatabase.get_item_copy("flame_augment_t1")
	inv.add_item(fire_shard, 4)
	inv.add_item(iron_ore, 3)
	inv.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE - 2)
	var removals: Array[Dictionary] = [
		{"item": fire_shard, "quantity": 3},
		{"item": iron_ore, "quantity": 2},
	]
	var additions: Array[Dictionary] = [{"item": output, "quantity": 1}]
	_check(not inv.transact_items(removals, additions), "full inventory rejects atomic craft transaction")
	_check(inv.get_item_count("fire_shard") == 4, "failed transaction preserves first ingredient")
	_check(inv.get_item_count("iron_ore") == 3, "failed transaction preserves second ingredient")
	_check(inv.get_item_count("flame_augment_t1") == 0, "failed transaction does not add output")

	inv.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(inv.transact_items(removals, additions), "transaction succeeds when output fits")
	_check(inv.get_item_count("fire_shard") == 1, "successful transaction consumes first ingredient")
	_check(inv.get_item_count("iron_ore") == 1, "successful transaction consumes second ingredient")
	_check(inv.get_item_count("flame_augment_t1") == 1, "successful transaction adds output")

	var remove_inv := InventoryData.new()
	remove_inv.add_item(ItemDatabase.get_item("wood"), 5)
	_check(not remove_inv.remove_item(ItemDatabase.get_item("wood"), 6), "insufficient removal is rejected")
	_check(remove_inv.get_item_count("wood") == 5, "insufficient removal preserves the full stack")
	_check(not remove_inv.remove_item_at(0, -1), "negative slot removal is rejected")
	_check(remove_inv.get_item_count("wood") == 5, "negative slot removal cannot increase a stack")


func _test_economy_and_collections() -> void:
	GameState.reset_profile()
	var inv: InventoryData = _stub_player.inventory
	inv.gold = 0
	_check(not GameState.spend({"gold": 10}), "cannot spend without gold")
	GameState.grant({"gold": 5000, "items": {"hero_shard": 20, "pet_treat": 30}})
	_check(inv.gold == 5000, "grant adds gold")
	_check(inv.get_item_count("hero_shard") == 20, "grant adds items")
	var gold_before_cost := inv.gold
	var treats_before_cost := inv.get_item_count("pet_treat")
	_check(not GameState.spend({"gold": 25, "pet_treat": treats_before_cost + 1}), "mixed cost rejects insufficient items")
	_check(inv.gold == gold_before_cost and inv.get_item_count("pet_treat") == treats_before_cost, "failed mixed cost is atomic")
	_check(GameState.spend({"gold": 25, "pet_treat": 1}), "valid mixed cost succeeds")
	_check(inv.gold == gold_before_cost - 25 and inv.get_item_count("pet_treat") == treats_before_cost - 1, "valid mixed cost charges exactly")

	# Heroes
	GameState.level = 5
	_check(GameState.unlock_hero("ranger"), "unlock ranger at Lv.5 with gold")
	_check(GameState.select_hero("ranger"), "select owned hero")
	var before: int = GameState.compute_base_stats()["atk"]
	_check(GameState.upgrade_hero_star("ranger"), "star up with shards")
	_check(GameState.heroes["ranger"]["stars"] == 2, "ranger is 2 stars")
	_check(GameState.compute_base_stats()["atk"] >= before, "stars do not reduce attack")
	_check(not GameState.unlock_hero("mystic"), "mystic locked below Lv.8")

	# Pets
	_check(GameState.unlock_pet("moss_turtle"), "adopt turtle")
	GameState.equip_pet("moss_turtle")
	for i in range(4):
		GameState.level_up_pet("moss_turtle")
	_check(GameState.pets["moss_turtle"]["level"] == 5, "turtle reaches Lv.5")
	_check(GameState.pet_stage("moss_turtle") == 1, "turtle evolved at Lv.5")

	# Mounts
	GameState.level = 3
	_check(GameState.unlock_mount("dust_pony"), "claim pony at Lv.3")
	var slow: float = GameState.compute_base_stats()["speed_mult"]
	GameState.set_mounted(true)
	_check(GameState.compute_base_stats()["speed_mult"] > slow, "mounting increases speed")
	_check(GameState.buy_or_select_skin("dust_pony", 1), "buy pony skin")
	_check(GameState.mount_skin_palette("dust_pony") == "mount_pony_snow", "skin palette applied")
	GameState.set_mounted(false)


func _test_buildings() -> void:
	GameState.reset_profile()
	var inv: InventoryData = _stub_player.inventory
	GameState.grant({"gold": 10000, "items": {"wood": 500, "stone": 500}})
	_check(GameState.build_or_upgrade(0, "lumber_mill"), "build lumber mill")
	_check(not GameState.build_or_upgrade(1, "lumber_mill"), "only one lumber mill")
	_check(GameState.build_or_upgrade(0, "lumber_mill"), "upgrade lumber mill")
	_check(GameState.plots[0]["level"] == 2, "lumber mill level 2")
	GameState.plots[0]["last_collect"] = Time.get_unix_time_from_system() - 3600.0
	var pending := GameState.building_pending(0)
	_check(pending == int(GameContent.BUILDINGS["lumber_mill"]["per_hour"][2]), "one hour of production")
	var wood_before := inv.get_item_count("wood")
	GameState.collect_building(0)
	_check(inv.get_item_count("wood") == wood_before + pending, "collect adds wood")
	var atk0: int = GameState.compute_base_stats()["atk"]
	_check(GameState.build_or_upgrade(1, "training_hall"), "build training hall")
	_check(GameState.compute_base_stats()["atk"] > atk0, "training hall adds attack")

	# A full bag must not discard stored production or reset its timer.
	var full_inv := InventoryData.new()
	full_inv.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	_stub_player.inventory = full_inv
	GameState.plots[2] = {
		"id": "lumber_mill",
		"level": 1,
		"last_collect": Time.get_unix_time_from_system() - 3600.0,
	}
	var stored_timestamp := float(GameState.plots[2]["last_collect"])
	_check(GameState.collect_building(2) == 0, "full inventory rejects building collection")
	_check(float(GameState.plots[2]["last_collect"]) == stored_timestamp, "failed collection preserves production timer")
	full_inv.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(GameState.collect_building(2) > 0, "building collection succeeds after freeing a slot")
	_check(full_inv.get_item_count("wood") > 0, "successful building collection grants resources")

	# Upgrading a producer must collect at its old rate before spending or leveling.
	GameState.reset_profile()
	var upgrade_inv := InventoryData.new()
	upgrade_inv.gold = 500
	upgrade_inv.add_item(ItemDatabase.get_item("wood"), 999)
	upgrade_inv.add_item(ItemDatabase.get_item("stone"), 20)
	upgrade_inv.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE - 2)
	_stub_player.inventory = upgrade_inv
	GameState.plots[0] = {
		"id": "lumber_mill",
		"level": 1,
		"last_collect": Time.get_unix_time_from_system() - 3600.0,
	}
	var upgrade_timestamp := float(GameState.plots[0]["last_collect"])
	_check(not GameState.build_or_upgrade(0, "lumber_mill"), "full inventory rejects producer upgrade")
	_check(int(GameState.plots[0]["level"]) == 1, "failed producer upgrade preserves level")
	_check(float(GameState.plots[0]["last_collect"]) == upgrade_timestamp, "failed producer upgrade preserves timer")
	_check(upgrade_inv.gold == 500 and upgrade_inv.get_item_count("stone") == 20, "failed producer upgrade preserves cost")
	upgrade_inv.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(GameState.build_or_upgrade(0, "lumber_mill"), "producer upgrade succeeds after freeing capacity")
	_check(int(GameState.plots[0]["level"]) == 2, "successful producer upgrade increases level")
	_check(upgrade_inv.gold == 100 and upgrade_inv.get_item_count("stone") == 0, "successful producer upgrade charges once")


func _test_quests() -> void:
	GameState.reset_profile()
	QuestService.reset()
	_stub_player.inventory = InventoryData.new()
	var q := QuestService.get_main_quest()
	_check(q["id"] == "q01", "first main quest is q01")
	_check(int(q["obj"]["count"]) == 1, "active dig tutorial does not match the runtime 0/1 objective")
	_check(q["reward"] == {"gold": 100}, "active dig tutorial reward does not match box 150")
	var q01_xp_before: int = GameState.xp
	var q01_gold_before: int = int(_stub_player.inventory.gold)
	GameEvent.ground_dug.emit("stone", 1)
	_check(QuestService.main_ready, "dig objective completes")
	_check(QuestService.claim("q01"), "claim q01")
	_check(GameState.xp == q01_xp_before, "q01 granted XP absent from box 150")
	_check(_stub_player.inventory.gold == q01_gold_before + 100, "q01 did not grant exactly 100 gold")
	_check(QuestService.get_main_quest()["id"] == "q02", "advances to q02")
	for i in range(8):
		GameEvent.enemy_killed.emit("slime", Vector2.ZERO, false)
	_check(QuestService.main_ready, "kill 8 slimes completes q02")
	_check(QuestService.dailies["d_hunt"]["progress"] == 8, "daily hunt counts kills")
	GameEvent.enemy_killed.emit("slime_king", Vector2.ZERO, true)
	_check(QuestService.dailies["d_boss"]["progress"] == 1, "daily boss counts boss kill")
	_check(QuestService.claim("d_boss"), "claim daily boss")
	_check(not QuestService.claim("d_boss"), "daily cannot be claimed twice")

	# q02 has an item reward; a full bag must keep the quest claimable.
	QuestService.reset()
	QuestService.main_index = 1
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[1]["obj"]["count"])
	QuestService.main_ready = true
	var full_inv := InventoryData.new()
	full_inv.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	_stub_player.inventory = full_inv
	var xp_before := GameState.xp
	var gold_before := full_inv.gold
	_check(not QuestService.claim("q02"), "full inventory rejects quest item reward")
	_check(QuestService.main_index == 1 and QuestService.main_ready, "failed claim preserves quest state")
	_check(GameState.xp == xp_before and full_inv.gold == gold_before, "failed claim grants no partial XP or gold")
	full_inv.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("q02"), "quest claim succeeds after freeing a slot")
	_check(QuestService.main_index == 2, "successful claim advances quest")
	_check(full_inv.get_item_count("health_potion") == 3, "successful claim grants full item reward")
	_stub_player.inventory = InventoryData.new()


func _test_ground_dig() -> void:
	var inv: InventoryData = _stub_player.inventory
	var before := inv.get_item_count("stone")
	var swings_before: int = _stub_player.dig_swings
	var spot := DigSpot.create(1234)
	spot.hits_required = 1
	spot.reward_pool = [{"item_id": "stone", "weight": 1, "min": 2, "max": 2}]
	add_child(spot)
	await get_tree().process_frame
	spot._player = _stub_player
	spot._dig_once()
	_check(_stub_player.dig_swings == swings_before + 1, "standing on a dig plot triggers an automatic swing")
	_check(spot._depleted, "dig plot depletes after required hits")
	_check(inv.get_item_count("stone") == before + 2, "dig reward is auto-collected into inventory")
	spot.queue_free()


func _test_resource_node_overflow() -> void:
	var previous_inventory: InventoryData = _stub_player.inventory
	var full_inventory := InventoryData.new()
	full_inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	_stub_player.inventory = full_inventory
	var gathered := {"quantity": 0}
	var on_gathered := func(gathered_item_id: String, quantity: int) -> void:
		if gathered_item_id == "wood":
			gathered["quantity"] += quantity
	GameEvent.resource_gathered.connect(on_gathered)

	var node := ResourceNode.create("wood", "tree_3", 0.42, 2)
	add_child(node)
	await get_tree().process_frame
	node.gather_hit()
	await get_tree().process_frame

	var overflow_drop: GameItem = null
	for child: Node in get_tree().current_scene.get_children():
		if child is GameItem and (child as GameItem).item_id == "wood":
			overflow_drop = child as GameItem
			break
	_check(full_inventory.get_item_count("wood") == 0, "full inventory cannot store gathered resources")
	_check(int(gathered["quantity"]) == 0, "uncollected resource advanced gather progress")
	_check(overflow_drop != null and overflow_drop.quantity > 0, "resource overflow was not preserved as a ground drop")

	GameEvent.resource_gathered.disconnect(on_gathered)
	if overflow_drop != null:
		overflow_drop.queue_free()
	node.queue_free()
	_stub_player.inventory = previous_inventory


func _test_save_roundtrip() -> void:
	GameState.reset_profile()
	QuestService.reset()
	var inv: InventoryData = _stub_player.inventory
	SaveService.deserialize_inventory(inv, {"gold": 5000, "slots": [], "equipment": {}})
	_check(inv.diamonds == 0, "legacy inventory without diamonds did not default to zero")
	inv.add_item(ItemDatabase.get_item("wood"), 42)
	inv.equip_item(_add_and_find(inv, "iron_sword"))
	var enhanced_weapon := inv.get_equipped("weapon").duplicate() as ItemData
	enhanced_weapon.enhancement_level = 3
	# This exercises the generic persistence carrier only; it does not map card
	# 28 to Emberfield's iron_sword gameplay identity.
	var rolled_stats := {"health": 13.9, "damage": 29.8, "speed": 0.08}
	_check(enhanced_weapon.set_reference_instance_data(
		28,
		"item.weapon.card_28.icon",
		rolled_stats
	), "reference equipment payload is accepted")
	rolled_stats["damage"] = 999.0
	_check(is_equal_approx(float(enhanced_weapon.get_reference_stats().get("damage", 0.0)), 29.8), "reference payload retained caller-owned dictionary")
	inv._set_equipped("weapon", enhanced_weapon)
	GameState.level = 7
	_check(GameState.unlock_pet("lucky_cat"), "adopt lucky cat for save test")
	inv.gold = 1234
	inv.diamonds = 17
	GameState.plots[2] = {"id": "stable", "level": 2, "last_collect": 100.0}
	GameState.settings["compact_hud"] = true
	GameState.settings["max_fps"] = 30
	QuestService.main_index = 3
	SaveService.enabled = true
	_check(SaveService.save_game(), "save writes file")
	SaveService.enabled = false
	var snap := SaveService.read_snapshot()
	_check(snap.get("version", 0) == SaveService.SAVE_VERSION, "snapshot has version")
	_check(snap.get("quests", {}).get("main_quest_id", "") == "q04", "snapshot stores stable main quest id")
	var level_one_inventory := InventoryData.new()
	_check(SaveService.deserialize_inventory(level_one_inventory, {
		"gold": 0,
		"slots": [{"id": "iron_sword", "qty": 1, "reference": {
			"card_id": 28,
			"asset_id": "item.weapon.card_28.icon",
			"stats": {"health": 13.9, "damage": 29.8, "speed": 0.08},
		}}],
		"equipment": {},
	}), "level-one reference equipment payload hydrates")
	var level_one_item := level_one_inventory.get_item_at(0).get("item") as ItemData
	_check(level_one_item != null and level_one_item != ItemDatabase.get_item("iron_sword"), "level-one reference equipment reused catalog template")
	_check(level_one_item != null and level_one_item.source_card_id == 28, "level-one reference equipment lost source identity")

	# Wipe live state then load
	GameState.reset_profile()
	QuestService.reset()
	GameState.settings["compact_hud"] = false
	GameState.settings["max_fps"] = 120
	Engine.max_fps = 120
	inv.gold = 0
	inv.diamonds = 0
	SaveService.deserialize_inventory(inv, {"gold": 0, "slots": [], "equipment": {}})
	_check(SaveService.load_game(), "load succeeds")
	_check(GameState.level == 7, "level restored")
	_check(GameState.pets.has("lucky_cat"), "pets restored")
	_check(GameState.plots[2].get("id", "") == "stable", "buildings restored")
	_check(bool(GameState.settings.get("compact_hud", false)), "compact HUD setting restored")
	_check(int(GameState.settings.get("max_fps", 0)) == 30 and Engine.max_fps == 30, "FPS setting restored and applied")
	_check(QuestService.main_index == 3, "quest progress restored")
	_check(QuestService.get_main_quest().get("id", "") == "q04", "stable quest id restored the active quest")
	_check(inv.gold == 1234, "gold restored")
	_check(inv.diamonds == 17, "diamonds restored")
	_check(inv.get_item_count("wood") == 42, "items restored")
	_check(inv.get_equipped("weapon") != null and inv.get_equipped("weapon").id == "iron_sword", "equipment restored")
	_check(inv.get_equipped("weapon").enhancement_level == 3, "equipment enhancement level restored")
	_check(inv.get_equipped("weapon") != ItemDatabase.get_item("iron_sword"), "enhanced save reused the catalog template")
	_check(inv.get_equipped("weapon").source_card_id == 28, "reference card identity restored")
	_check(inv.get_equipped("weapon").source_asset_id == "item.weapon.card_28.icon", "reference asset identity restored")
	_check(inv.get_equipped("weapon").get_reference_stats() == {
		"health": 13.9,
		"damage": 29.8,
		"speed": 0.08,
	}, "reference decimal stat payload restored")
	_check(ItemDatabase.get_item("iron_sword").source_card_id == -1, "reference payload mutated catalog template")

	# Corrupt main file -> backup is used
	SaveService.enabled = true
	SaveService.save_game()
	SaveService.enabled = false
	var f := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	_check(not SaveService.read_snapshot().is_empty(), "falls back to .bak on corrupt save")

	# Future and structurally invalid snapshots must also fall back to the good backup.
	var future := snap.duplicate(true)
	future["version"] = SaveService.SAVE_VERSION + 1
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(future))
	f.close()
	var recovered_future := SaveService.read_snapshot()
	_check(int(recovered_future.get("version", 0)) == SaveService.SAVE_VERSION, "future save version falls back to backup")
	var invalid_version := snap.duplicate(true)
	invalid_version["version"] = "1"
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_version))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "non-numeric save version falls back to backup")

	var invalid_inventory := snap.duplicate(true)
	invalid_inventory["inventory"] = {
		"gold": 10,
		"slots": [{"id": "wood", "qty": 1000}],
		"equipment": {},
	}
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_inventory))
	f.close()
	var recovered_inventory := SaveService.read_snapshot()
	_check(recovered_inventory.get("inventory", {}).get("gold", -1) == 1234, "invalid inventory falls back to backup")

	var invalid_diamonds := snap.duplicate(true)
	invalid_diamonds["inventory"]["diamonds"] = -1
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_diamonds))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("diamonds", -1) == 17, "invalid diamonds fall back to backup")

	for legacy_version in [0, 1, 2]:
		var legacy := snap.duplicate(true)
		legacy["version"] = legacy_version
		legacy["inventory"]["equipment"]["weapon"].erase("level")
		f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(legacy))
		f.close()
		var migrated := SaveService.read_snapshot()
		_check(int(migrated.get("version", 0)) == SaveService.SAVE_VERSION, "legacy save version %d did not migrate" % legacy_version)
		var legacy_inventory := InventoryData.new()
		_check(SaveService.deserialize_inventory(legacy_inventory, migrated["inventory"]), "migrated inventory hydrates")
		_check(legacy_inventory.get_equipped("weapon").enhancement_level == 1, "legacy equipment did not default to level 1")

	var invalid_profile := snap.duplicate(true)
	invalid_profile["profile"]["pets"]["lucky_cat"]["level"] = "max"
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_profile))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "invalid nested profile falls back to backup")

	var invalid_quests := snap.duplicate(true)
	invalid_quests["quests"]["main_ready"] = "yes"
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_quests))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "invalid quest flags fall back to backup")
	var invalid_quest_id := snap.duplicate(true)
	invalid_quest_id["quests"]["main_quest_id"] = 4
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_quest_id))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "non-string quest id falls back to backup")

	QuestService.from_dict({"main_index": 0, "main_quest_id": "q04", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == 3, "stable quest id takes precedence over stale index")
	QuestService.from_dict({"main_index": 2, "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == 2, "legacy quest save falls back to main index")
	QuestService.from_dict({"main_index": 1, "main_quest_id": "removed_quest", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == 1, "unknown quest id falls back to saved index")

	# Direct inventory hydration rejects malformed data without touching live state.
	var protected_gold := inv.gold
	var protected_diamonds := inv.diamonds
	var protected_wood := inv.get_item_count("wood")
	var protected_weapon_level := inv.get_equipped("weapon").enhancement_level
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"diamonds": -1,
		"slots": [],
		"equipment": {},
	}), "negative diamond wallet is rejected")
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"diamonds": 1.5,
		"slots": [],
		"equipment": {},
	}), "fractional diamond wallet is rejected")
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"slots": [{"id": "wood", "qty": 1000}],
		"equipment": {"helmet": {"id": "iron_sword", "qty": 1}},
	}), "invalid inventory hydration is rejected")
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"slots": [{"id": "wood", "qty": 1.5}],
		"equipment": {},
	}), "fractional inventory quantity is rejected")
	for invalid_level: Variant in [0, 11, 1.5, "2"]:
		_check(not SaveService.deserialize_inventory(inv, {
			"gold": 999,
			"slots": [],
			"equipment": {"weapon": {"id": "iron_sword", "qty": 1, "level": invalid_level}},
		}), "invalid equipment enhancement level was accepted: %s" % str(invalid_level))
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"slots": [{"id": "wood", "qty": 1, "level": 2}],
		"equipment": {},
	}), "non-upgradeable item accepted an enhancement level")
	var invalid_references: Array = [
		{"card_id": 0, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 1, "damage": 1, "speed": 0.1}},
		{"card_id": 28, "asset_id": "", "stats": {"health": 1, "damage": 1, "speed": 0.1}},
		{"card_id": 28, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 1, "damage": 1}},
		{"card_id": 28, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 1, "damage": 1, "speed": "fast"}},
		{"card_id": 28, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 1, "damage": 1, "speed": 0.1, "defense": 2}},
	]
	for invalid_reference: Dictionary in invalid_references:
		_check(not SaveService.deserialize_inventory(inv, {
			"gold": 999,
			"slots": [],
			"equipment": {"weapon": {"id": "iron_sword", "qty": 1, "reference": invalid_reference}},
		}), "invalid reference equipment payload was accepted: %s" % str(invalid_reference))
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"slots": [{"id": "wood", "qty": 1, "reference": {
			"card_id": 28,
			"asset_id": "item.weapon.card_28.icon",
			"stats": {"health": 1, "damage": 1, "speed": 0.1},
		}}],
		"equipment": {},
	}), "non-equipment item accepted a reference equipment payload")
	_check(inv.gold == protected_gold and inv.diamonds == protected_diamonds and inv.get_item_count("wood") == protected_wood, "rejected hydration preserves live inventory")
	_check(inv.get_equipped("weapon").enhancement_level == protected_weapon_level, "rejected hydration changed enhanced equipment")

	# Invalid live state cannot replace the last known-good save.
	var valid_zone := GameState.current_zone
	GameState.current_zone = "invalid_zone"
	SaveService.enabled = true
	_check(not SaveService.save_game(), "invalid snapshot is not written")
	SaveService.enabled = false
	GameState.current_zone = valid_zone
	_check(not SaveService.read_snapshot().is_empty(), "failed save preserves recoverable data")

	# A corrupt current file must not replace the known-good backup during rotation.
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	inv.gold = 2222
	SaveService.enabled = true
	_check(SaveService.save_game(), "valid save replaces corrupt primary")
	SaveService.enabled = false
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "corrupt primary never rotates over good backup")


func _add_and_find(inv: InventoryData, item_id: String) -> int:
	inv.add_item(ItemDatabase.get_item(item_id), 1)
	return _find_slot(inv, item_id)


func _find_slot(inv: InventoryData, item_id: String) -> int:
	for i in range(inv.inventory_slots.size()):
		var slot: Dictionary = inv.inventory_slots[i]
		if slot.item != null and slot.item.id == item_id:
			return i
	return -1


func _test_monster_kill() -> void:
	GameState.reset_profile()
	var killed: Array[String] = []
	var cb := func(id: String, _p: Vector2, _b: bool) -> void: killed.append(id)
	GameEvent.enemy_killed.connect(cb)
	var m := Monster.create("slime")
	m.position = Vector2(500, 500)
	add_child(m)
	await get_tree().process_frame
	_check(m.is_in_group("monster"), "monster joins group")
	_check(m.max_hp == int(GameContent.MONSTERS["slime"]["hp"]), "monster HP from data")
	_check(m.name_label != null and m.name_label.text == GameContent.MONSTERS["slime"]["name"], "monster nameplate matches field capture format")
	var elite := Monster.create("slime", true)
	_check(elite.max_hp > m.max_hp, "elite has more HP")
	elite.free()
	var xp_before := GameState.xp
	m.apply_hit(9999, Vector2.ZERO, false)
	_check(m.is_dead(), "monster dies at 0 HP")
	_check(killed.has("slime"), "enemy_killed emitted")
	_check(GameState.xp > xp_before or GameState.level > 1, "kill grants XP")
	GameEvent.enemy_killed.disconnect(cb)

	var boss := Monster.create("slime_king")
	_check(boss is Boss, "boss ids create Boss instances")
	boss.position = Vector2(800, 800)
	add_child(boss)
	await get_tree().process_frame
	boss.apply_hit(boss.max_hp / 2 + 1, Vector2.ZERO)
	_check((boss as Boss).phase == 2, "boss enters phase 2 at half HP")
	boss.queue_free()


func _test_menu_keeps_world_running() -> void:
	var menu := GameMenu.new()
	add_child(menu)
	await get_tree().process_frame
	menu.open("system")
	_check(menu.visible, "mobile menu opens")
	_check(not get_tree().paused, "mobile menu does not pause world simulation")
	menu.close()
	menu.queue_free()


func _test_auto_farm_toggle() -> void:
	var player_scene: PackedScene = preload("res://sense/entities/player/player.tscn")
	var local_player = player_scene.instantiate()
	local_player.set_physics_process(false)
	add_child(local_player)
	await get_tree().process_frame
	var target := Monster.create("slime")
	target.position = local_player.position + Vector2(90, 0)
	add_child(target)
	await get_tree().process_frame
	local_player.set_auto_farm(true)
	_check(local_player.auto_farm_enabled, "auto-farm can be enabled")
	var before: Vector2 = local_player.position
	_check(local_player._drive_auto_farm(), "auto-farm acquires a nearby monster")
	_check(local_player.position != before, "auto-farm moves toward an out-of-range monster")
	target.position = local_player.position + Vector2(10, 0)
	local_player._drive_auto_farm()
	_check(local_player.current_state == local_player.State.ATTACK, "auto-farm attacks in range")
	local_player.set_auto_farm(false)
	_check(not local_player.auto_farm_enabled, "auto-farm can be disabled")
	local_player.die()
	local_player.toggle_auto_farm()
	_check(not local_player.auto_farm_enabled, "auto-farm stays disabled while dead")
	target.queue_free()
	local_player.queue_free()


func _test_combat_roll() -> void:
	for i in range(200):
		var r := Combat.roll(100.0)
		var amount: int = r["amount"]
		_check(amount >= 88 and amount <= int(ceil(112.0 * Combat.CRIT_MULT)) + 1, "roll within variance/crit bounds")
	for i in range(20):
		_check(bool(Combat.roll(100.0, 100.0)["crit"]), "100-point crit bonus always resolves critical")


func _test_resolved_combat_hit() -> void:
	var target := ResolvedHitTarget.new()
	target.setup()
	add_child(target)
	var attacker := Node2D.new()
	var hitbox := HitboxComponent.new()
	hitbox.check_line_of_sight = false
	hitbox.resolves_damage = true
	hitbox.damage = 100
	hitbox.bonus_crit_chance_percent = 100.0
	attacker.add_child(hitbox)
	add_child(attacker)
	await get_tree().process_frame
	var result := {"count": 0, "amount": 0, "critical": false}
	hitbox.hit_resolved.connect(func(_hurtbox: Area2D, amount: int, critical: bool) -> void:
		result["count"] += 1
		result["amount"] = amount
		result["critical"] = critical
	)
	hitbox._on_area_entered(target.hurtbox)
	_check(target.hp == 0, "resolved hit applies once")
	_check(result["count"] == 1, "accepted resolved hit emits once")
	_check(result["amount"] == 7, "resolved hit reports damage actually applied")
	_check(result["critical"], "resolved hit preserves critical result")
	hitbox._on_area_entered(target.hurtbox)
	_check(result["count"] == 1, "invincibility rejects duplicate hit events")

	var stats := CharacterStats.new()
	stats.current_health = 50
	var processor := PassiveEffectProcessor.new()
	processor.get_owner_stats_func = func() -> CharacterStats: return stats
	processor.get_passive_effects_func = func() -> Array[Dictionary]:
		return [
			{"effect": ItemData.PassiveEffect.LIFE_STEAL, "value": 10.0},
			{"effect": ItemData.PassiveEffect.LIFE_STEAL, "value": 20.0},
		]
	add_child(processor)
	processor.on_hit_landed(target.hurtbox, 7)
	_check(stats.current_health == 52, "lifesteal aggregates and uses confirmed damage")
	processor.queue_free()
	attacker.queue_free()
	target.queue_free()


func _test_player_combat_modifiers() -> void:
	var player_scene: PackedScene = preload("res://sense/entities/player/player.tscn")
	var local_player = player_scene.instantiate()
	local_player.set_physics_process(false)
	add_child(local_player)
	await get_tree().process_frame
	_check(local_player.attack_hitbox.resolves_damage, "player melee uses resolved-hit path")
	local_player.inventory.add_item(ItemDatabase.get_item_copy("fire_blade"), 1)
	local_player.inventory.equip_item(0)
	local_player.inventory.add_item(ItemDatabase.get_item("crit_augment_t1"), 1)
	local_player.inventory.add_item(ItemDatabase.get_item("lifesteal_augment_t1"), 1)
	var crit_slot := _find_slot(local_player.inventory, "crit_augment_t1")
	var life_slot := _find_slot(local_player.inventory, "lifesteal_augment_t1")
	_check(local_player.inventory.apply_augment("weapon", crit_slot), "crit augment applies")
	life_slot = _find_slot(local_player.inventory, "lifesteal_augment_t1")
	_check(local_player.inventory.apply_augment("weapon", life_slot), "lifesteal augment applies")
	var modifiers: Dictionary = local_player.get_lan_combat_modifiers()
	_check(is_equal_approx(float(modifiers["crit_chance"]), 8.0), "equipped crit augment reaches combat resolver")
	_check(is_equal_approx(float(modifiers["life_steal"]), 5.0), "equipped lifesteal reaches authority profile")
	_check(is_equal_approx(local_player.attack_hitbox.bonus_crit_chance_percent, 8.0), "melee hitbox refreshes crit chance")
	var attack_before_upgrade: int = local_player.stats.attack_damage
	var upgrade_event := {"seen": false, "level": 0, "cost": 0}
	var on_equipment_upgraded := func(slot_type: String, item_id: String, level: int, cost: int) -> void:
		if slot_type == "weapon" and item_id == "fire_blade":
			upgrade_event["seen"] = true
			upgrade_event["level"] = level
			upgrade_event["cost"] = cost
	GameEvent.equipment_upgraded.connect(on_equipment_upgraded)
	var upgrade_cost: int = local_player.inventory.get_equipped("weapon").get_upgrade_cost()
	local_player.inventory.gold = upgrade_cost
	_check(local_player.inventory.upgrade_equipment("weapon"), "player equipment enhancement succeeds")
	_check(local_player.stats.attack_damage > attack_before_upgrade, "player stats refresh after equipment enhancement")
	_check(bool(upgrade_event["seen"]) and int(upgrade_event["level"]) == 2 and int(upgrade_event["cost"]) == upgrade_cost, "player did not forward the stable equipment upgrade event")
	GameEvent.equipment_upgraded.disconnect(on_equipment_upgraded)
	local_player.queue_free()
