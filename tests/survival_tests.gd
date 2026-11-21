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
	await _test_item_pickup_delivery()
	await _test_fixed_chest_gold()
	_test_save_roundtrip()
	await _test_monster_kill()
	await _test_turtle_runtime()
	await _test_snailu_runtime()
	await _test_mosqui_runtime()
	await _test_menu_keeps_world_running()
	await _test_auto_farm_toggle()
	_test_combat_roll()
	await _test_resolved_combat_hit()
	await _test_player_combat_modifiers()
	await _test_dead_consumable_use()

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
	_check(QuestService.get_main_quest()["id"] == "q305", "q01 did not advance to source quest 305")
	for i in range(9):
		GameEvent.ground_dug.emit("stone", 1)
	_check(QuestService.main_progress == 9 and not QuestService.main_ready, "q305 completed before ten digs")
	GameEvent.ground_dug.emit("stone", 1)
	_check(QuestService.main_ready, "ten digs did not complete q305")
	var q305_rng := RandomNumberGenerator.new()
	q305_rng.seed = 305
	QuestService.set_reward_authority_rng(q305_rng)
	_check(QuestService.claim("q305"), "claim q305")
	_check(QuestService.get_main_quest()["id"] == "q306", "q305 did not advance to q306")
	_check(
		_stub_player.inventory.get_item_count("th_weapon_28")
		+ _stub_player.inventory.get_item_count("th_weapon_29")
		+ _stub_player.inventory.get_item_count("th_weapon_30") == 1,
		"q305 did not grant exactly one Box 149 weapon",
	)
	GameEvent.enemy_killed.emit("slime", Vector2.ZERO, false)
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "wrong monster completed q306")
	GameEvent.enemy_killed.emit("turtle", Vector2.ZERO, false)
	_check(QuestService.main_progress == 1 and QuestService.main_ready, "Turtle kill did not complete q306")
	_stub_player.inventory._set_equipped("weapon", ItemDatabase.get_item_copy("iron_sword"))
	_stub_player.inventory._set_equipped("helmet", ItemDatabase.get_item_copy("iron_helmet"))
	var diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q306"), "claim q306")
	_check(_stub_player.inventory.diamonds == diamonds_before + 1, "q306 did not grant exactly one Diamond")
	_check(QuestService.get_main_quest()["id"] == "q307", "q306 did not advance to q307")
	_check(QuestService.main_progress == 2 and not QuestService.main_ready, "q307 ignored the two equipped items on activation")
	_check(not QuestService.claim("q306") and _stub_player.inventory.diamonds == diamonds_before + 1, "q306 granted twice")
	_stub_player.inventory._set_equipped("armor", ItemDatabase.get_item_copy("leather_armor"))
	QuestService.refresh_state_objectives(_stub_player.inventory)
	_check(QuestService.main_progress == 3 and QuestService.main_ready, "third equipped item did not complete q307")
	var q307_diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q307"), "claim q307")
	_check(_stub_player.inventory.diamonds == q307_diamonds_before + 1, "q307 did not grant exactly one Diamond")
	_check(QuestService.get_main_quest()["id"] == "q308", "q307 did not advance to q308")
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "level-1 equipment completed q308")
	_check(not QuestService.claim("q307") and _stub_player.inventory.diamonds == q307_diamonds_before + 1, "q307 granted twice")
	var q308_upgrade_cost: int = _stub_player.inventory.get_equipped("weapon").get_upgrade_cost()
	var gold_before_upgrade: int = _stub_player.inventory.gold
	_check(_stub_player.inventory.upgrade_equipment("weapon"), "authoritative equipment upgrade failed for q308")
	_check(_stub_player.inventory.get_equipped("weapon").enhancement_level == 2, "q308 upgrade did not reach displayed level 2")
	_check(_stub_player.inventory.gold == gold_before_upgrade - q308_upgrade_cost, "q308 setup upgrade charged the wrong Gold")
	QuestService.refresh_state_objectives(_stub_player.inventory)
	_check(QuestService.main_progress == 1 and QuestService.main_ready, "level-2 equipment did not complete q308")
	var q308_gold_before: int = _stub_player.inventory.gold
	_check(QuestService.claim("q308"), "claim q308")
	_check(_stub_player.inventory.gold == q308_gold_before + 200, "q308 did not grant exactly 200 Gold")
	_check(QuestService.get_main_quest()["id"] == "q310", "q308 did not advance to q310")
	_check(not QuestService.claim("q308") and _stub_player.inventory.gold == q308_gold_before + 200, "q308 granted twice")
	GameEvent.enemy_killed.emit("shroom", Vector2.ZERO, false)
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "legacy shroom kill completed q310")
	GameEvent.enemy_killed.emit("snailu", Vector2.ZERO, false)
	GameEvent.enemy_killed.emit("snailu", Vector2.ZERO, false)
	_check(QuestService.main_progress == 2 and not QuestService.main_ready, "q310 completed before three Snailu kills")
	GameEvent.enemy_killed.emit("snailu", Vector2.ZERO, false)
	_check(QuestService.main_progress == 3 and QuestService.main_ready, "three Snailu kills did not complete q310")
	var q310_diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q310"), "claim q310")
	_check(_stub_player.inventory.diamonds == q310_diamonds_before + 1, "q310 did not grant exactly one Diamond")
	_check(QuestService.get_main_quest()["id"] == "q311", "q310 did not advance to q311")
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "Common equipment completed q311")
	_check(not QuestService.claim("q310") and _stub_player.inventory.diamonds == q310_diamonds_before + 1, "q310 granted twice")
	_check(_stub_player.inventory.add_item(ItemDatabase.get_item_copy("fire_blade"), 1) == 0, "q311 Rare equipment setup failed")
	var rare_weapon_index := -1
	for i in range(_stub_player.inventory.inventory_slots.size()):
		var slot_item: ItemData = _stub_player.inventory.get_item_at(i).item
		if slot_item != null and slot_item.id == "fire_blade":
			rare_weapon_index = i
			break
	_check(rare_weapon_index >= 0 and _stub_player.inventory.equip_item(rare_weapon_index), "q311 could not equip Rare equipment")
	QuestService.refresh_state_objectives(_stub_player.inventory)
	_check(QuestService.main_progress == 1 and QuestService.main_ready, "Rare equipment did not complete q311")
	var q311_diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q311"), "claim q311")
	_check(_stub_player.inventory.diamonds == q311_diamonds_before + 1, "q311 did not grant exactly one Diamond")
	_check(QuestService.get_main_quest()["id"] == "q312", "q311 did not advance to q312")
	_check(not QuestService.claim("q311") and _stub_player.inventory.diamonds == q311_diamonds_before + 1, "q311 granted twice")
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "level-1 equipment completed q312")
	_stub_player.inventory.gold = 10000
	for expected_level in range(2, 5):
		_check(_stub_player.inventory.upgrade_equipment("weapon"), "q312 setup upgrade failed")
		_check(_stub_player.inventory.get_equipped("weapon").enhancement_level == expected_level, "q312 setup upgrade level mismatch")
	QuestService.refresh_state_objectives(_stub_player.inventory)
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "level-4 equipment completed q312")
	_check(not QuestService.claim("q312"), "q312 allowed an incomplete claim")
	_check(_stub_player.inventory.upgrade_equipment("weapon"), "q312 level-5 upgrade failed")
	QuestService.refresh_state_objectives(_stub_player.inventory)
	_check(QuestService.main_progress == 1 and QuestService.main_ready, "level-5 equipment did not complete q312")
	var q312_gold_before: int = _stub_player.inventory.gold
	var q312_diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q312"), "claim q312")
	_check(_stub_player.inventory.gold == q312_gold_before + 300, "q312 did not grant exactly 300 Gold")
	_check(_stub_player.inventory.diamonds == q312_diamonds_before, "q312 granted unexpected Diamonds")
	_check(QuestService.get_main_quest()["id"] == "q313", "q312 did not advance to q313")
	_check(not QuestService.claim("q312") and _stub_player.inventory.gold == q312_gold_before + 300, "q312 granted twice")
	GameEvent.enemy_killed.emit("slime", Vector2.ZERO, false)
	_check(QuestService.main_progress == 0 and not QuestService.main_ready, "legacy slime kill completed q313")
	GameEvent.enemy_killed.emit("mosqui", Vector2.ZERO, false)
	GameEvent.enemy_killed.emit("mosqui", Vector2.ZERO, false)
	_check(QuestService.main_progress == 2 and not QuestService.main_ready, "q313 completed before three kills")
	GameEvent.enemy_killed.emit("mosqui", Vector2.ZERO, false)
	_check(QuestService.main_ready, "three Mosqui kills did not complete q313")
	var q313_diamonds_before: int = _stub_player.inventory.diamonds
	_check(QuestService.claim("q313"), "claim q313")
	_check(_stub_player.inventory.diamonds == q313_diamonds_before + 1, "q313 did not grant exactly one Diamond")
	_check(QuestService.get_main_quest()["id"] == "q02", "q313 did not advance to q02")
	_check(not QuestService.claim("q313") and _stub_player.inventory.diamonds == q313_diamonds_before + 1, "q313 granted twice")
	for i in range(8):
		GameEvent.enemy_killed.emit("slime", Vector2.ZERO, false)
	_check(QuestService.main_ready, "kill 8 slimes completes q02")
	_check(QuestService.dailies["d_hunt"]["progress"] == 18, "daily hunt counts all monster kills")
	GameEvent.enemy_killed.emit("slime_king", Vector2.ZERO, true)
	_check(QuestService.dailies["d_boss"]["progress"] == 1, "daily boss counts boss kill")
	_check(QuestService.claim("d_boss"), "claim daily boss")
	_check(not QuestService.claim("d_boss"), "daily cannot be claimed twice")

	# q02 has an item reward; a full bag must keep the quest claimable.
	QuestService.reset()
	var q02_index := GameContent.get_main_quest_index("q02")
	QuestService.main_index = q02_index
	QuestService.main_progress = int(GameContent.MAIN_QUESTS[q02_index]["obj"]["count"])
	QuestService.main_ready = true
	var full_inv := InventoryData.new()
	full_inv.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE)
	_stub_player.inventory = full_inv
	var xp_before := GameState.xp
	var gold_before := full_inv.gold
	_check(not QuestService.claim("q02"), "full inventory rejects quest item reward")
	_check(QuestService.main_index == q02_index and QuestService.main_ready, "failed claim preserves quest state")
	_check(GameState.xp == xp_before and full_inv.gold == gold_before, "failed claim grants no partial XP or gold")
	full_inv.remove_item_at(InventoryData.INVENTORY_SIZE - 1)
	_check(QuestService.claim("q02"), "quest claim succeeds after freeing a slot")
	_check(QuestService.main_index == q02_index + 1, "successful claim advances quest")
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
	var enhanced_weapon := ReferenceEquipmentCatalog.materialize(
		28,
		{"health": 13.9, "damage": 29.8, "speed": 0.08}
	)
	_check(enhanced_weapon != null and inv.add_item(enhanced_weapon, 1) == 0, "reference equipment setup failed")
	inv.equip_item(_find_slot(inv, "th_weapon_28"))
	enhanced_weapon = inv.get_equipped("weapon").duplicate() as ItemData
	inv._set_equipped("weapon", enhanced_weapon)
	GameState.level = 7
	_check(GameState.unlock_pet("lucky_cat"), "adopt lucky cat for save test")
	inv.gold = 1234
	inv.diamonds = 17
	GameState.plots[2] = {"id": "stable", "level": 2, "last_collect": 100.0}
	GameState.settings["compact_hud"] = true
	GameState.settings["max_fps"] = 30
	var saved_quest_index := GameContent.get_main_quest_index("q04")
	QuestService.main_index = saved_quest_index
	SaveService.enabled = true
	_check(SaveService.save_game(), "save writes file")
	SaveService.enabled = false
	var snap := SaveService.read_snapshot()
	_check(snap.get("version", 0) == SaveService.SAVE_VERSION, "snapshot has version")
	_check(snap.get("quests", {}).get("main_quest_id", "") == "q04", "snapshot stores stable main quest id")
	var level_one_inventory := InventoryData.new()
	_check(SaveService.deserialize_inventory(level_one_inventory, {
		"gold": 0,
		"slots": [{"id": "th_weapon_28", "qty": 1, "reference": {
			"card_id": 28,
			"asset_id": "item.weapon.card_28.icon",
			"stats": {"health": 13.9, "damage": 29.8, "speed": 0.08},
		}}],
		"equipment": {},
	}), "level-one reference equipment payload hydrates")
	var level_one_item := level_one_inventory.get_item_at(0).get("item") as ItemData
	_check(level_one_item != null and level_one_item != ItemDatabase.get_item("th_weapon_28"), "level-one reference equipment reused catalog template")
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
	_check(QuestService.main_index == saved_quest_index, "quest progress restored")
	_check(QuestService.get_main_quest().get("id", "") == "q04", "stable quest id restored the active quest")
	_check(inv.gold == 1234, "gold restored")
	_check(inv.diamonds == 17, "diamonds restored")
	_check(inv.get_item_count("wood") == 42, "items restored")
	_check(inv.get_equipped("weapon") != null and inv.get_equipped("weapon").id == "th_weapon_28", "equipment restored")
	_check(inv.get_equipped("weapon").enhancement_level == 1, "equipment enhancement level restored")
	_check(inv.get_equipped("weapon") != ItemDatabase.get_item("th_weapon_28"), "enhanced save reused the catalog template")
	_check(inv.get_equipped("weapon").source_card_id == 28, "reference card identity restored")
	_check(inv.get_equipped("weapon").source_asset_id == "item.weapon.card_28.icon", "reference asset identity restored")
	_check(inv.get_equipped("weapon").get_reference_stats() == {
		"health": 13.9,
		"damage": 29.8,
		"speed": 0.08,
	}, "reference decimal stat payload restored")
	_check(ItemDatabase.get_item("th_weapon_28").source_card_id == -1, "reference payload mutated catalog template")

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

	for legacy_version in [0, 1, 2, 3, 4]:
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

	var invalid_pending_type := snap.duplicate(true)
	invalid_pending_type["pending_claim"] = []
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_pending_type))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "non-dictionary pending claim falls back to backup")
	var invalid_pending_state := snap.duplicate(true)
	invalid_pending_state["pending_claim"] = {
		"version": 1,
		"claim_id": "main:q04",
		"source_kind": "main",
		"source_id": "q04",
		"reward": GameContent.MAIN_QUESTS[saved_quest_index]["reward"],
	}
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(invalid_pending_state))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "unready pending claim falls back to backup")
	var tampered_pending_reward := invalid_pending_state.duplicate(true)
	tampered_pending_reward["quests"]["main_ready"] = true
	tampered_pending_reward["pending_claim"]["reward"] = {"items": {"missing_item": 1}}
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(tampered_pending_reward))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "tampered pending reward falls back to backup")
	var tampered_pending_equipment := invalid_pending_state.duplicate(true)
	tampered_pending_equipment["quests"]["main_ready"] = true
	tampered_pending_equipment["pending_claim"]["reward"] = {
		"equipment": [{"card_id": 28, "stats": {"health": 13.9, "damage": 29.8}}],
	}
	f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(tampered_pending_equipment))
	f.close()
	_check(SaveService.read_snapshot().get("inventory", {}).get("gold", -1) == 1234, "invalid pending equipment falls back to backup")

	QuestService.from_dict({"main_index": 0, "main_quest_id": "q04", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == GameContent.get_main_quest_index("q04"), "stable quest id takes precedence over stale index")
	QuestService.from_dict({"main_index": 0, "main_quest_id": "q311", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == GameContent.get_main_quest_index("q311"), "stable q311 save did not restore by quest id")
	QuestService.from_dict({"main_index": 0, "main_quest_id": "q312", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == GameContent.get_main_quest_index("q312"), "stable q312 save did not restore by quest id")
	QuestService.from_dict({"main_index": 0, "main_quest_id": "q313", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == GameContent.get_main_quest_index("q313"), "stable q313 save did not restore by quest id")
	QuestService.from_dict({"main_index": 2, "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == 10, "legacy quest save did not shift across inserted q305-q313")
	QuestService.from_dict({"main_index": 1, "main_quest_id": "removed_quest", "main_progress": 0, "main_ready": false})
	_check(QuestService.main_index == 1, "unknown stable quest id did not preserve explicit fallback index")

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
	var mismatched_reference_items: Array[Dictionary] = [
		{"id": "iron_sword", "reference": {"card_id": 28, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 13.9, "damage": 29.8, "speed": 0.08}}},
		{"id": "th_weapon_28", "reference": {"card_id": 999, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 13.9, "damage": 29.8, "speed": 0.08}}},
		{"id": "th_weapon_28", "reference": {"card_id": 29, "asset_id": "item.weapon.card_29.icon", "stats": {"health": 20, "damage": 3, "speed": 0.05}}},
		{"id": "th_weapon_28", "reference": {"card_id": 28, "asset_id": "item.weapon.card_29.icon", "stats": {"health": 13.9, "damage": 29.8, "speed": 0.08}}},
		{"id": "th_weapon_28", "reference": {"card_id": 28, "asset_id": "item.weapon.card_28.icon", "stats": {"health": 20.1, "damage": 29.8, "speed": 0.08}}},
	]
	for mismatched: Dictionary in mismatched_reference_items:
		_check(not SaveService.deserialize_inventory(inv, {
			"gold": 999,
			"slots": [{"id": mismatched["id"], "qty": 1, "reference": mismatched["reference"]}],
			"equipment": {},
		}), "mismatched reference identity was accepted: %s" % str(mismatched))
	_check(not SaveService.deserialize_inventory(inv, {
		"gold": 999,
		"slots": [{"id": "th_weapon_28", "qty": 1}],
		"equipment": {},
	}), "reference runtime item was accepted without instance data")
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


func _test_turtle_runtime() -> void:
	var asset_id := "actor.monster.turtle.default"
	_check(MonsterVisualCatalog.has_asset(asset_id), "Turtle stable art ID is not registered")
	var definition := MonsterVisualCatalog.get_definition(asset_id)
	_check(definition.get("frame_size", Vector2i.ZERO) == Vector2i(64, 64), "Turtle frame size drifted")
	var frames := MonsterVisualCatalog.get_frames(asset_id)
	_check(frames != null, "Turtle atlas did not build SpriteFrames")
	var expected := {
		"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.7083333731, "loop": true},
		"move": {"row": 1, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.4583333135, "loop": true},
		"attack": {"row": 2, "frames": [0, 1, 2, 4, 4, 5], "duration": 0.6666666865, "loop": true},
		"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
	}
	for animation_name: String in expected:
		var expected_animation: Dictionary = expected[animation_name]
		var sequence: Array = expected_animation["frames"]
		_check(frames.has_animation(animation_name), "Turtle animation missing: %s" % animation_name)
		_check(frames.get_frame_count(animation_name) == sequence.size(), "Turtle frame count drifted: %s" % animation_name)
		_check(frames.get_animation_loop(animation_name) == bool(expected_animation["loop"]), "Turtle loop flag drifted: %s" % animation_name)
		_check(is_equal_approx(frames.get_animation_speed(animation_name), float(sequence.size()) / float(expected_animation["duration"])), "Turtle clip duration drifted: %s" % animation_name)
		for frame_index in range(sequence.size()):
			var atlas := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
			var expected_region := Rect2(float(int(sequence[frame_index]) * 64), float(int(expected_animation["row"]) * 64), 64.0, 64.0)
			_check(atlas != null and atlas.region == expected_region, "Turtle atlas region drifted: %s[%d]" % [animation_name, frame_index])

	var turtle_def: Dictionary = GameContent.MONSTERS["turtle"]
	_check(int(turtle_def.get("source_card_id", 0)) == 33, "Turtle source Card ID drifted")
	_check(int(turtle_def["hp"]) == 100 and int(turtle_def["dmg"]) == 20, "Turtle source stats drifted")
	_check(float(turtle_def["spd"]) == 0.0, "Turtle must remain stationary")
	_check(float(turtle_def["range"]) == 70.0 and float(turtle_def["aggro"]) == 200.0, "Turtle source-scaled ranges drifted")
	_check(is_equal_approx(float(turtle_def["attack_interval"]), 1.0), "Turtle attack gate drifted")

	var turtle := Monster.create("turtle")
	turtle.position = Vector2(300, 300)
	turtle.set_physics_process(false)
	add_child(turtle)
	_check(turtle.visual is AnimatedSprite2D, "Turtle does not use the atlas visual")
	_check((turtle.visual as AnimatedSprite2D).sprite_frames == frames, "Turtle visual did not consume the stable catalog")
	_check(turtle.max_hp == 100 and turtle.damage == 20 and turtle.speed == 0.0, "Turtle runtime stats drifted")
	_check(is_equal_approx(turtle.attack_cooldown, 1.0), "Turtle initial attack gate drifted")

	_stub_player.damage_taken = 0
	_stub_player.global_position = turtle.global_position + Vector2(71, 0)
	turtle.target = _stub_player
	turtle.attack_cooldown = 0.0
	turtle._think_stationary_melee(0.0)
	_check(_stub_player.damage_taken == 0 and turtle.state == "idle", "Turtle attacked outside its range")
	_check(turtle.velocity == Vector2.ZERO and turtle.global_position == Vector2(300, 300), "Turtle moved while targeting")

	_stub_player.global_position = turtle.global_position + Vector2(70, 0)
	turtle._think_stationary_melee(0.0)
	_check(_stub_player.damage_taken == 20 and turtle.state == "windup", "Turtle did not attack when its 1.0s gate opened")
	turtle._think_stationary_melee(0.0)
	_check(_stub_player.damage_taken == 20, "Turtle attacked twice during one attack clip")
	turtle.state_time = float(turtle_def["attack_duration"])
	turtle._think_stationary_melee(0.0)
	_check(turtle.state == "idle", "Turtle attack state did not end after one verified clip")

	var turtle_position := turtle.global_position
	turtle.apply_hit(1, turtle.global_position - Vector2(20, 0))
	_check(turtle._knock == Vector2.ZERO and turtle.global_position == turtle_position, "Turtle accepted knockback")
	var killed: Array[String] = []
	var cb := func(id: String, _position: Vector2, _is_boss: bool) -> void: killed.append(id)
	GameEvent.enemy_killed.connect(cb)
	var xp_before := GameState.xp
	turtle.apply_hit(turtle.hp, Vector2.ZERO)
	_check(turtle.is_dead() and killed.has("turtle"), "Turtle death did not emit its stable gameplay ID")
	_check(GameState.xp == xp_before, "Turtle granted unverified XP")
	GameEvent.enemy_killed.disconnect(cb)
	await get_tree().create_timer(float(turtle_def["death_duration"]) + 0.05).timeout


func _test_snailu_runtime() -> void:
	var asset_id := "actor.monster.snailu.atlas"
	_check(MonsterVisualCatalog.has_asset(asset_id), "Snailu stable art ID is not registered")
	var definition := MonsterVisualCatalog.get_definition(asset_id)
	_check(definition.get("frame_size", Vector2i.ZERO) == Vector2i(64, 64), "Snailu frame size drifted")
	var frames := MonsterVisualCatalog.get_frames(asset_id)
	_check(frames != null, "Snailu atlas did not build SpriteFrames")
	var expected := {
		"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.7083333731, "loop": true},
		"move": {
			"row": 1,
			"frames": [Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)],
			"duration": 0.4583333135,
			"loop": true,
		},
		"attack": {"row": 2, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.6666666865, "loop": true},
		"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
	}
	for animation_name: String in expected:
		var expected_animation: Dictionary = expected[animation_name]
		var sequence: Array = expected_animation["frames"]
		_check(frames.has_animation(animation_name), "Snailu animation missing: %s" % animation_name)
		_check(frames.get_frame_count(animation_name) == sequence.size(), "Snailu frame count drifted: %s" % animation_name)
		_check(frames.get_animation_loop(animation_name) == bool(expected_animation["loop"]), "Snailu loop flag drifted: %s" % animation_name)
		_check(is_equal_approx(frames.get_animation_speed(animation_name), float(sequence.size()) / float(expected_animation["duration"])), "Snailu clip duration drifted: %s" % animation_name)
		for frame_index in range(sequence.size()):
			var frame_value: Variant = sequence[frame_index]
			var coordinates: Vector2i
			if frame_value is Vector2i:
				coordinates = frame_value
			else:
				coordinates = Vector2i(int(frame_value), int(expected_animation["row"]))
			var atlas := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
			var expected_region := Rect2(float(coordinates.x * 64), float(coordinates.y * 64), 64.0, 64.0)
			_check(atlas != null and atlas.region == expected_region, "Snailu atlas region drifted: %s[%d]" % [animation_name, frame_index])

	var snailu_def: Dictionary = GameContent.MONSTERS["snailu"]
	_check(GameContent.MONSTERS.has("shroom") and GameContent.MONSTERS["shroom"] != snailu_def, "legacy shroom identity was replaced by Snailu")
	_check(int(snailu_def.get("source_card_id", 0)) == 34, "Snailu source Card ID drifted")
	_check(int(snailu_def["hp"]) == 200 and int(snailu_def["dmg"]) == 30, "Snailu source stats drifted")
	_check(float(snailu_def["range"]) == 70.0 and float(snailu_def["aggro"]) == 200.0, "Snailu source-scaled ranges drifted")
	_check(is_equal_approx(float(snailu_def["attack_interval"]), 1.0), "Snailu attack gate drifted")
	_check(snailu_def["gold"] == Vector2i(40, 50) and snailu_def["loot"].is_empty(), "Snailu approved loot boundary drifted")

	var snailu := Monster.create("snailu")
	snailu.position = Vector2(300, 300)
	snailu.set_physics_process(false)
	add_child(snailu)
	_check(snailu.visual is AnimatedSprite2D, "Snailu does not use the atlas visual")
	_check((snailu.visual as AnimatedSprite2D).sprite_frames == frames, "Snailu visual did not consume the stable catalog")
	_check(snailu.max_hp == 200 and snailu.damage == 30 and snailu.xp_reward == 0, "Snailu runtime stats drifted")
	var body_shape: CollisionShape2D = null
	for child in snailu.get_children():
		if child is CollisionShape2D:
			body_shape = child
			break
	_check(body_shape != null and body_shape.shape is CircleShape2D and is_equal_approx((body_shape.shape as CircleShape2D).radius, 30.0), "Snailu source collider radius drifted")

	_stub_player.global_position = snailu.global_position + Vector2(71, 0)
	snailu.target = _stub_player
	snailu.attack_cooldown = 0.0
	snailu._think_reference_melee(0.0)
	_check(snailu.state == "idle" and snailu.velocity.length() > 0.0, "Snailu did not chase outside exact attack range")
	_stub_player.global_position = snailu.global_position + Vector2(70, 0)
	snailu.velocity = Vector2.ZERO
	snailu._think_reference_melee(0.0)
	_check(snailu.state == "windup" and is_equal_approx(snailu.attack_cooldown, 1.0), "Snailu did not open its 1.0s attack gate at exact range")
	var damage_before: int = _stub_player.damage_taken
	snailu.state_time = 0.4
	snailu._think_reference_melee(0.0)
	snailu._think_reference_melee(0.0)
	_check(_stub_player.damage_taken == damage_before + 30 and snailu.state == "windup", "Snailu attack did not apply exactly one hit during the full clip")
	snailu.state_time = float(snailu_def["attack_duration"])
	snailu._think_reference_melee(0.0)
	_check(snailu.state == "recover", "Snailu attack clip did not finish at the verified duration")

	var killed: Array[String] = []
	var cb := func(id: String, _position: Vector2, _is_boss: bool) -> void: killed.append(id)
	GameEvent.enemy_killed.connect(cb)
	var xp_before := GameState.xp
	snailu.apply_hit(snailu.hp, Vector2.ZERO)
	_check(snailu.is_dead() and killed.has("snailu"), "Snailu death did not emit its stable gameplay ID")
	_check(GameState.xp == xp_before, "Snailu invented an unverified XP reward")
	await get_tree().process_frame
	var dropped_gold := 0
	var spawned_gold: Array[GameItem] = []
	for child in get_tree().current_scene.get_children():
		if child is GameItem and child.content_type == GameItem.ContentType.GOLD and child.global_position.distance_to(snailu.global_position) < 80.0:
			spawned_gold.append(child)
			dropped_gold += child.value
	_check(dropped_gold >= 40 and dropped_gold <= 50, "Snailu Gold drop escaped the verified 40-50 range")
	for item in spawned_gold:
		item.queue_free()
	await get_tree().create_timer(float(snailu_def["death_duration"]) + 0.05).timeout
	GameEvent.enemy_killed.disconnect(cb)
	_stub_player.global_position = Vector2.ZERO


## Verify the additive source-backed Mosqui encounter without changing legacy slime.
func _test_mosqui_runtime() -> void:
	var asset_id := "actor.monster.mosqui.atlas"
	_check(MonsterVisualCatalog.has_asset(asset_id), "Mosqui stable art ID is not registered")
	var definition := MonsterVisualCatalog.get_definition(asset_id)
	_check(definition.get("frame_size", Vector2i.ZERO) == Vector2i(64, 64), "Mosqui frame size drifted")
	var frames := MonsterVisualCatalog.get_frames(asset_id)
	_check(frames != null, "Mosqui atlas did not build SpriteFrames")
	var expected := {
		"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.375, "loop": true},
		"move": {
			"row": 1,
			"frames": [0, 1, 2, 3, 4, 5, 0],
			"duration": 0.2916666567,
			"loop": true,
		},
		"attack": {"row": 2, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.6666666865, "loop": true},
		"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
	}
	for animation_name: String in expected:
		var expected_animation: Dictionary = expected[animation_name]
		var sequence: Array = expected_animation["frames"]
		_check(frames.has_animation(animation_name), "Mosqui animation missing: %s" % animation_name)
		_check(frames.get_frame_count(animation_name) == sequence.size(), "Mosqui frame count drifted: %s" % animation_name)
		_check(frames.get_animation_loop(animation_name) == bool(expected_animation["loop"]), "Mosqui loop flag drifted: %s" % animation_name)
		_check(is_equal_approx(frames.get_animation_speed(animation_name), float(sequence.size()) / float(expected_animation["duration"])), "Mosqui clip duration drifted: %s" % animation_name)
		for frame_index in range(sequence.size()):
			var frame_value: Variant = sequence[frame_index]
			var coordinates: Vector2i
			if frame_value is Vector2i:
				coordinates = frame_value
			else:
				coordinates = Vector2i(int(frame_value), int(expected_animation["row"]))
			var atlas := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
			var expected_region := Rect2(float(coordinates.x * 64), float(coordinates.y * 64), 64.0, 64.0)
			_check(atlas != null and atlas.region == expected_region, "Mosqui atlas region drifted: %s[%d]" % [animation_name, frame_index])

	var mosqui_def: Dictionary = GameContent.MONSTERS["mosqui"]
	_check(GameContent.MONSTERS.has("slime") and GameContent.MONSTERS["slime"] != mosqui_def, "legacy slime identity was replaced by Mosqui")
	_check(int(mosqui_def.get("source_card_id", 0)) == 37, "Mosqui source Card ID drifted")
	_check(int(mosqui_def["hp"]) == 400 and int(mosqui_def["dmg"]) == 40, "Mosqui source stats drifted")
	_check(float(mosqui_def["range"]) == 70.0 and float(mosqui_def["aggro"]) == 200.0, "Mosqui source-scaled ranges drifted")
	_check(is_equal_approx(float(mosqui_def["attack_interval"]), 1.0), "Mosqui attack gate drifted")
	_check(mosqui_def["gold"] == Vector2i(60, 70) and mosqui_def["loot"].is_empty(), "Mosqui approved loot boundary drifted")

	var mosqui := Monster.create("mosqui")
	mosqui.position = Vector2(300, 300)
	mosqui.set_physics_process(false)
	add_child(mosqui)
	_check(mosqui.visual is AnimatedSprite2D, "Mosqui does not use the atlas visual")
	_check((mosqui.visual as AnimatedSprite2D).sprite_frames == frames, "Mosqui visual did not consume the stable catalog")
	_check(mosqui.max_hp == 400 and mosqui.damage == 40 and mosqui.xp_reward == 0, "Mosqui runtime stats drifted")
	var body_shape: CollisionShape2D = null
	for child in mosqui.get_children():
		if child is CollisionShape2D:
			body_shape = child
			break
	_check(body_shape != null and body_shape.shape is CircleShape2D and is_equal_approx((body_shape.shape as CircleShape2D).radius, 30.0), "Mosqui source collider radius drifted")

	_stub_player.global_position = mosqui.global_position + Vector2(71, 0)
	mosqui.target = _stub_player
	mosqui.attack_cooldown = 0.0
	mosqui._think_reference_melee(0.0)
	_check(mosqui.state == "idle" and mosqui.velocity.length() > 0.0, "Mosqui did not chase outside exact attack range")
	_stub_player.global_position = mosqui.global_position + Vector2(70, 0)
	mosqui.velocity = Vector2.ZERO
	mosqui._think_reference_melee(0.0)
	_check(mosqui.state == "windup" and is_equal_approx(mosqui.attack_cooldown, 1.0), "Mosqui did not open its 1.0s attack gate at exact range")
	var damage_before: int = _stub_player.damage_taken
	mosqui.state_time = 0.4
	mosqui._think_reference_melee(0.0)
	mosqui._think_reference_melee(0.0)
	_check(_stub_player.damage_taken == damage_before + 40 and mosqui.state == "windup", "Mosqui attack did not apply exactly one hit during the full clip")
	mosqui.state_time = float(mosqui_def["attack_duration"])
	mosqui._think_reference_melee(0.0)
	_check(mosqui.state == "recover", "Mosqui attack clip did not finish at the verified duration")

	var killed: Array[String] = []
	var cb := func(id: String, _position: Vector2, _is_boss: bool) -> void: killed.append(id)
	GameEvent.enemy_killed.connect(cb)
	var xp_before := GameState.xp
	mosqui.apply_hit(mosqui.hp, Vector2.ZERO)
	_check(mosqui.is_dead() and killed.has("mosqui"), "Mosqui death did not emit its stable gameplay ID")
	_check(GameState.xp == xp_before, "Mosqui invented an unverified XP reward")
	await get_tree().process_frame
	var dropped_gold := 0
	var spawned_gold: Array[GameItem] = []
	for child in get_tree().current_scene.get_children():
		if child is GameItem and child.content_type == GameItem.ContentType.GOLD and child.global_position.distance_to(mosqui.global_position) < 80.0:
			spawned_gold.append(child)
			dropped_gold += child.value
	_check(dropped_gold >= 60 and dropped_gold <= 70, "Mosqui Gold drop escaped the verified 60-70 range")
	for item in spawned_gold:
		item.queue_free()
	await get_tree().create_timer(float(mosqui_def["death_duration"]) + 0.05).timeout
	GameEvent.enemy_killed.disconnect(cb)
	_stub_player.global_position = Vector2.ZERO


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


## Neither item-use route may spend consumables or apply effects while dead.
func _test_dead_consumable_use() -> void:
	var local_player = preload("res://sense/entities/player/player.tscn").instantiate()
	local_player.set_physics_process(false)
	add_child(local_player)
	await get_tree().process_frame
	local_player.buff_component.set_process(false)
	var inventory: InventoryData = local_player.inventory
	var stats: CharacterStats = local_player.stats
	var panel: InventoryPanel = local_player.inventory_panel
	var notifications := {"inventory": 0, "health": 0, "stamina": 0, "buffs": 0, "item_used": 0}
	inventory.inventory_changed.connect(func() -> void: notifications["inventory"] += 1)
	stats.health_changed.connect(func(_current: int, _maximum: int) -> void: notifications["health"] += 1)
	stats.stamina_changed.connect(func(_current: float, _maximum: float) -> void: notifications["stamina"] += 1)
	local_player.buff_component.buffs_changed.connect(func() -> void: notifications["buffs"] += 1)
	panel.item_used.connect(func(_result: Dictionary) -> void: notifications["item_used"] += 1)
	var previous_shop_open: bool = GameEvent.is_shop_open
	GameEvent.is_shop_open = false
	for use_panel in [false, true]:
		for item_id: String in ["health_potion", "stamina_potion", "vitality_tonic_t1"]:
			local_player.buff_component.clear_all_buffs()
			local_player.reset_player()
			inventory.add_item(ItemDatabase.get_item(item_id), 2)
			stats.current_stamina = 10.0
			stats.current_health = 0
			var route := "inventory" if use_panel else "hotbar"
			var context := "%s dead %s" % [route, item_id]
			var before := inventory.get_item_count(item_id)
			for key: String in notifications:
				notifications[key] = 0
			var index := _find_slot(inventory, item_id)
			if use_panel:
				panel._on_inventory_slot_right_clicked(index)
			else:
				local_player._on_hotbar_item_used(0, ItemDatabase.get_item(item_id), index)
			_check(inventory.get_item_count(item_id) == before, context + " consumed an item")
			_check(stats.current_health == 0 and local_player.is_dead(), context + " changed death/HP state")
			_check(is_equal_approx(stats.current_stamina, 10.0), context + " restored stamina")
			_check(local_player.buff_component.active_buffs.is_empty(), context + " applied a buff")
			_check(notifications == {"inventory": 0, "health": 0, "stamina": 0, "buffs": 0, "item_used": 0}, context + " emitted mutation/effect notifications")
			_check(not local_player.quick_use_potion(), context + " allowed quick potion while dead")

			# The same routes work again after the normal respawn lifecycle.
			local_player.respawn()
			stats.current_health = 25
			stats.current_stamina = 10.0
			before = inventory.get_item_count(item_id)
			for key: String in notifications:
				notifications[key] = 0
			index = _find_slot(inventory, item_id)
			if use_panel:
				panel._on_inventory_slot_right_clicked(index)
			else:
				local_player._on_hotbar_item_used(0, ItemDatabase.get_item(item_id), index)
			_check(not local_player.is_dead() and inventory.get_item_count(item_id) == before - 1, route + " did not consume exactly one item after respawn")
			_check(stats.current_health == (75 if item_id == "health_potion" else 25), route + " living consumable changed the wrong HP amount")
			_check(is_equal_approx(stats.current_stamina, 60.0 if item_id == "stamina_potion" else 10.0), route + " living consumable changed the wrong stamina amount")
			_check(local_player.buff_component.active_buffs.size() == (1 if item_id == "vitality_tonic_t1" else 0), route + " living consumable applied the wrong buff")
			_check(int(notifications["inventory"]) == 1 and int(notifications["item_used"]) == (1 if use_panel else 0), route + " living consumable notification count drifted")

	# Hotbar eligibility checks both the state machine and living stats.
	local_player.buff_component.clear_all_buffs()
	local_player.reset_player()
	inventory.add_item(ItemDatabase.get_item("health_potion"), 2)
	var potion_count := inventory.get_item_count("health_potion")
	local_player.die()
	local_player._on_hotbar_item_used(0, ItemDatabase.get_item("health_potion"), _find_slot(inventory, "health_potion"))
	_check(inventory.get_item_count("health_potion") == potion_count, "hotbar spent potion with DEATH state and positive HP")
	stats.current_health = 0
	local_player.current_state = local_player.State.IDLE
	local_player._on_hotbar_item_used(0, ItemDatabase.get_item("health_potion"), _find_slot(inventory, "health_potion"))
	_check(inventory.get_item_count("health_potion") == potion_count and stats.current_health == 0, "hotbar spent potion with nonliving stats before DEATH state")
	local_player.queue_free()

	# Panels without an actor retain their existing optional-stats behavior.
	var unbound_panel: InventoryPanel = preload("res://sense/ui/inventory/inventory_panel.tscn").instantiate()
	add_child(unbound_panel)
	var unbound_inventory := InventoryData.new()
	unbound_inventory.add_item(ItemDatabase.get_item("health_potion"), 1)
	unbound_panel.setup(unbound_inventory)
	var results: Array[Dictionary] = []
	unbound_panel.item_used.connect(func(result: Dictionary) -> void: results.append(result))
	unbound_panel._on_inventory_slot_right_clicked(0)
	_check(unbound_inventory.get_item_count("health_potion") == 0 and results.size() == 1 and bool(results[0].get("success", false)), "optional-stats inventory panel rejected normal consumable use")
	unbound_panel.queue_free()
	GameEvent.is_shop_open = previous_shop_open


## Pickup events must reflect delivered quantity and reject collectors without inventory.
func _test_item_pickup_delivery() -> void:
	var previous_inventory: InventoryData = _stub_player.inventory
	var invalid_collector := Node2D.new()
	add_child(invalid_collector)
	var pickup := GameItem.create_item("wood", 3)
	add_child(pickup)
	pickup.set_physics_process(false)
	var received: Array[int] = []
	pickup.collected.connect(func(_type: GameItem.ContentType, _id: String, amount: int) -> void: received.append(amount))
	await pickup._collect(invalid_collector)
	_check(not pickup._is_collected and received.is_empty(), "invalid collector consumed ground item")
	pickup.queue_free()
	invalid_collector.queue_free()

	var inventory := InventoryData.new()
	var wood: ItemData = ItemDatabase.get_item("wood")
	inventory.add_item(wood, wood.max_stack - 1)
	inventory.add_item(ItemDatabase.get_item("iron_sword"), InventoryData.INVENTORY_SIZE - 1)
	_stub_player.inventory = inventory
	var partial := GameItem.create_item("wood", 3)
	partial.position = Vector2(2000, 2000)
	add_child(partial)
	partial.set_physics_process(false)
	var actual: Array[int] = []
	partial.collected.connect(func(_type: GameItem.ContentType, _id: String, amount: int) -> void: actual.append(amount))
	var reenter := func() -> void: partial._collect(_stub_player)
	inventory.inventory_changed.connect(reenter)
	await partial._collect(_stub_player)
	inventory.inventory_changed.disconnect(reenter)
	_check(inventory.get_item_count("wood") == wood.max_stack, "partial pickup did not fill available stack")
	_check(actual == [1], "partial pickup reported requested rather than delivered quantity")
	await get_tree().process_frame
	var overflow := 0
	for child in get_tree().current_scene.get_children():
		if child is GameItem and child != partial and child.item_id == "wood" and child.global_position.distance_to(Vector2(2000, 2000)) < 30:
			overflow += child.quantity
			child.queue_free()
	_check(overflow == 2, "partial pickup did not conserve overflow items")
	partial.queue_free()
	var invalid_item := GameItem.create_item("", 1)
	add_child(invalid_item)
	invalid_item.set_physics_process(false)
	await invalid_item._collect(_stub_player)
	_check(not invalid_item._is_collected, "invalid item identifier was consumed")
	invalid_item.queue_free()
	_stub_player.inventory = previous_inventory


## Inclusive equal-endpoint gold ranges must grant their fixed value once.
func _test_fixed_chest_gold() -> void:
	var previous_inventory: InventoryData = _stub_player.inventory
	var inventory := InventoryData.new()
	_stub_player.inventory = inventory
	var chest := GameItem.create_chest([{"item_id": "wood", "quantity": 2}], 10)
	chest.gold_range = Vector2i(25, 25)
	chest.position = Vector2(2000, 2000)
	add_child(chest)
	chest.set_physics_process(false)
	var opened: Array[Array] = []
	chest.chest_opened.connect(func(items: Array[Dictionary]) -> void: opened.append(items.duplicate(true)))
	await chest._collect(_stub_player)
	_check(inventory.gold == 35, "fixed chest gold range was omitted")
	_check(inventory.get_item_count("wood") == 2, "fixed chest contents were lost")
	_check(opened.size() == 1 and opened[0] == [{"item_id": "gold", "quantity": 35}, {"item_id": "wood", "quantity": 2}], "chest event did not report fixed gold plus contents")
	await chest._collect(_stub_player)
	_check(inventory.gold == 35 and opened.size() == 1, "chest retry changed the expected one-time reward")
	chest.queue_free()
	_stub_player.inventory = previous_inventory
