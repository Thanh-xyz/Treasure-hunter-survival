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
	_test_save_roundtrip()
	await _test_monster_kill()
	await _test_menu_keeps_world_running()
	await _test_auto_farm_toggle()
	_test_combat_roll()

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


func _test_economy_and_collections() -> void:
	GameState.reset_profile()
	var inv: InventoryData = _stub_player.inventory
	inv.gold = 0
	_check(not GameState.spend({"gold": 10}), "cannot spend without gold")
	GameState.grant({"gold": 5000, "items": {"hero_shard": 20, "pet_treat": 30}})
	_check(inv.gold == 5000, "grant adds gold")
	_check(inv.get_item_count("hero_shard") == 20, "grant adds items")

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
	GameEvent.ground_dug.emit("stone", 1)
	_check(QuestService.main_ready, "dig objective completes")
	_check(QuestService.claim("q01"), "claim q01")
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


func _test_save_roundtrip() -> void:
	GameState.reset_profile()
	QuestService.reset()
	var inv: InventoryData = _stub_player.inventory
	SaveService.deserialize_inventory(inv, {"gold": 5000, "slots": [], "equipment": {}})
	inv.add_item(ItemDatabase.get_item("wood"), 42)
	inv.equip_item(_add_and_find(inv, "iron_sword"))
	GameState.level = 7
	_check(GameState.unlock_pet("lucky_cat"), "adopt lucky cat for save test")
	inv.gold = 1234
	GameState.plots[2] = {"id": "stable", "level": 2, "last_collect": 100.0}
	GameState.settings["compact_hud"] = true
	GameState.settings["max_fps"] = 30
	QuestService.main_index = 3
	SaveService.enabled = true
	_check(SaveService.save_game(), "save writes file")
	SaveService.enabled = false
	var snap := SaveService.read_snapshot()
	_check(snap.get("version", 0) == SaveService.SAVE_VERSION, "snapshot has version")

	# Wipe live state then load
	GameState.reset_profile()
	QuestService.reset()
	GameState.settings["compact_hud"] = false
	GameState.settings["max_fps"] = 120
	Engine.max_fps = 120
	inv.gold = 0
	SaveService.deserialize_inventory(inv, {"gold": 0, "slots": [], "equipment": {}})
	_check(SaveService.load_game(), "load succeeds")
	_check(GameState.level == 7, "level restored")
	_check(GameState.pets.has("lucky_cat"), "pets restored")
	_check(GameState.plots[2].get("id", "") == "stable", "buildings restored")
	_check(bool(GameState.settings.get("compact_hud", false)), "compact HUD setting restored")
	_check(int(GameState.settings.get("max_fps", 0)) == 30 and Engine.max_fps == 30, "FPS setting restored and applied")
	_check(QuestService.main_index == 3, "quest progress restored")
	_check(inv.gold == 1234, "gold restored")
	_check(inv.get_item_count("wood") == 42, "items restored")
	_check(inv.get_equipped("weapon") != null and inv.get_equipped("weapon").id == "iron_sword", "equipment restored")

	# Corrupt main file -> backup is used
	SaveService.enabled = true
	SaveService.save_game()
	SaveService.enabled = false
	var f := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	_check(not SaveService.read_snapshot().is_empty(), "falls back to .bak on corrupt save")


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
