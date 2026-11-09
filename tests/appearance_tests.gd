extends Node2D
## Owner request 2026-11-09: gear changes the look, auto attack / auto dig, licensed icons.

var _failures: Array[String] = []


func _ready() -> void:
	SaveService.enabled = false
	_test_data()
	_test_mapping()
	await _test_player_changes_look()
	await _test_auto_dig()
	_test_icons()
	if _failures.is_empty():
		print("[APPEARANCE TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[APPEARANCE TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


func _test_data() -> void:
	var errors := PlayerAppearance.validate()
	_check(errors.is_empty(), "appearance data valid: %s" % [errors])
	var frames := PlayerAppearance.frames("Knight")
	for key: String in ["down", "up", "left", "right", "left_up", "right_down"]:
		for action: String in ["idle_", "move_", "attack_"]:
			_check(frames.has_animation(action + key), "outfit frames have %s%s" % [action, key])
	_check(frames.get_frame_count("move_down") == 4 and not frames.get_animation_loop("attack_down"), "walk has 4 frames, attack plays once")


func _test_mapping() -> void:
	_check(PlayerAppearance.outfit_for(null) == "Boy", "no armor: default outfit")
	var tank := ItemDatabase.get_item_copy("ironbark_plate")
	_check(PlayerAppearance.outfit_for(tank) == "GladiatorBlue", "common tank armor")
	tank.rarity = ItemData.ItemRarity.LEGENDARY
	_check(PlayerAppearance.outfit_for(tank) == "KnightGold", "legendary tank armor")
	_check(PlayerAppearance.outfit_for(ItemDatabase.get_item("ember_harness")) == "NinjaRed", "damage armor")
	_check(PlayerAppearance.outfit_for(ItemDatabase.get_item("wayfarer_coat")) == "Hunter", "balanced armor")
	_check(PlayerAppearance.weapon_for(ItemDatabase.get_item("ironbark_cleaver")) == "Axe", "axe in hand")
	_check(PlayerAppearance.weapon_for(ItemDatabase.get_item("emberforged_blade")) == "BigSword", "epic sword is a big sword")
	_check(PlayerAppearance.weapon_for(null) == "", "unarmed")


func _test_player_changes_look() -> void:
	var player = preload("res://sense/entities/player/player.tscn").instantiate()
	player.set_physics_process(false)
	add_child(player)
	await get_tree().process_frame
	_check(player.current_outfit == "Boy", "starts in the default outfit (%s)" % player.current_outfit)
	_check(player.weapon_sprite.texture == null, "no weapon drawn when unarmed")
	var inv: InventoryData = player.inventory
	inv.add_item(ItemDatabase.get_item("ember_harness"), 1)
	inv.equip_item(_find(inv, "ember_harness"))
	_check(player.current_outfit == "NinjaRed", "wearing Ember Harness changes the outfit (%s)" % player.current_outfit)
	_check(player.anim.sprite_frames == PlayerAppearance.frames("NinjaRed"), "sprite uses the new outfit")
	inv.add_item(ItemDatabase.get_item("ironbark_cleaver"), 1)
	inv.equip_item(_find(inv, "ironbark_cleaver"))
	_check(player.weapon_sprite.texture == PlayerAppearance.weapon_texture("Axe"), "the axe is drawn in hand")
	inv.unequip_item("armor")
	_check(player.current_outfit == "Boy", "taking armor off restores the default look")
	_check(GameMenu.hero_portrait() == PlayerAppearance.portrait("Boy"), "HUD portrait follows the outfit")
	player.queue_free()
	await get_tree().process_frame


func _test_auto_dig() -> void:
	var player = preload("res://sense/entities/player/player.tscn").instantiate()
	add_child(player)
	player.global_position = Vector2(100, 100)
	var spot := DigSpot.create(3)
	spot.position = Vector2(180, 100)
	add_child(spot)
	await get_tree().physics_frame
	player.set_auto_dig(true)
	var start: float = player.global_position.distance_to(spot.global_position)
	for i in range(40):
		await get_tree().physics_frame
	_check(player.global_position.distance_to(spot.global_position) < start - 30.0, "auto dig walks toward the nearest plot")
	player.set_auto_dig(false)
	player.queue_free()
	spot.queue_free()
	await get_tree().process_frame


func _test_icons() -> void:
	for id: String in ["ironbark_helm", "ironbark_plate", "ashwood_blade", "ironbark_cleaver", "ember_dirk", "ironbark_pack", "stone_guard_1", "stone_fire_3", "card_snow_titan", "fragment_ash"]:
		var item := ItemDatabase.get_item(id)
		_check(item != null and item.get_icon() != null and item.icon_asset_id.begins_with("res://assets/"), "%s uses a licensed pack icon" % id)


func _find(inv: InventoryData, id: String) -> int:
	for i in range(inv.inventory_slots.size()):
		var it: ItemData = inv.inventory_slots[i].get("item")
		if it != null and it.id == id:
			return i
	return -1


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
		print("  FAIL: ", label)
