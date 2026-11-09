extends Node
## Plan phase C: pets (sheet 03) and mounts (sheet 04).

var _failures: Array[String] = []
var _player: StubPlayer


class StubPlayer:
	extends Node2D
	var inventory := InventoryData.new()
	func get_inventory() -> InventoryData:
		return inventory


func _ready() -> void:
	_player = StubPlayer.new()
	_player.add_to_group("player")
	add_child(_player)
	_test_data_valid()
	_test_pet_stats()
	_test_pet_levels()
	_test_eggs_and_duplicates()
	_test_egg_odds_and_distribution()
	_test_one_active_pet()
	_test_pet_sockets()
	_test_mount_levels_and_stats()
	_test_mount_evolution()
	_test_mount_visuals()
	_test_pets_never_attack()
	if _failures.is_empty():
		print("[COMPANION TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[COMPANION TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


func _reset() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()


func _test_data_valid() -> void:
	var errors := CompanionCatalog.validate()
	_check(errors.is_empty(), "companion data valid: %s" % [errors])
	_check(CompanionCatalog.species_ids().size() * CompanionCatalog.qualities().size() == 48, "12 species × 4 qualities = 48 variants")


func _test_pet_stats() -> void:
	var common := CompanionCatalog.pet_stats("ember_fox:common", 1)
	var legendary := CompanionCatalog.pet_stats("ember_fox:legendary", 1)
	_check(float(legendary["atk"]) > float(common["atk"]), "legendary is stronger than common")
	_check(float(CompanionCatalog.pet_stats("ember_fox:common", 10)["atk"]) > float(common["atk"]), "levels raise stats")
	_check(CompanionCatalog.pet_stats("ember_fox:common", 99) == CompanionCatalog.pet_stats("ember_fox:common", 10), "levels clamp at the cap")
	_check(float(CompanionCatalog.pet_stats("lucky_cat:legendary", 10)["magnet"]) == float(CompanionCatalog.pet_stats("lucky_cat:common", 1)["magnet"]), "magnet is not scaled")
	_check(CompanionCatalog.pet_stats("ember_fox:rare", 1).is_empty() and not CompanionCatalog.is_pet_key("ember_fox"), "invalid keys rejected")
	_reset()
	var base := GameState.compute_base_stats()
	GameState.equip_pet("ember_fox:common")
	_check(GameState.compute_base_stats()["atk"] > base["atk"], "active pet adds attack to the character")
	var fire := 0.0
	for e: Dictionary in GameState.companion_passive_effects():
		if e["effect"] == ItemData.PassiveEffect.BURN_ON_HIT:
			fire += float(e["value"])
	_check(fire > 0.0, "ember fox fire stat becomes a burn modifier")


func _test_pet_levels() -> void:
	_reset()
	var key := "ember_fox:common"
	_player.inventory.diamonds = 4
	_check(not GameState.level_up_pet(key), "level up refused without enough diamonds")
	_check(GameState.pet_level(key) == 1 and _player.inventory.diamonds == 4, "failed level up changed nothing")
	_player.inventory.diamonds = 10000
	var spent := 0
	for lv in range(1, 10):
		spent += CompanionCatalog.pet_level_cost(lv)
		_check(GameState.level_up_pet(key), "level %d → %d" % [lv, lv + 1])
	_check(GameState.pet_level(key) == 10 and _player.inventory.diamonds == 10000 - spent, "diamond cost table followed to Lv.10")
	_check(not GameState.level_up_pet(key) and CompanionCatalog.pet_level_cost(10) == -1, "level 10 is the cap")
	_check(_player.inventory.get_item_count("pet_treat") == 0 and ItemDatabase.get_item("pet_treat") == null, "pet treats are retired")


func _test_eggs_and_duplicates() -> void:
	_reset()
	_player.inventory.gold = 500
	_check(GameState.buy_egg("egg_forest"), "buy a forest egg")
	_check(_player.inventory.gold == 0 and _player.inventory.get_item_count("egg_forest") == 1, "egg price charged")
	_check(not GameState.buy_egg("egg_forest"), "cannot buy without gold")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var first := GameState.hatch_egg("egg_forest", rng)
	_check(not first.is_empty() and GameState.pets.has(first["key"]) and not bool(first["duplicate"]), "hatching adds a new pet")
	_check(_player.inventory.get_item_count("egg_forest") == 0, "hatching consumes the egg")
	_check(GameState.hatch_egg("egg_forest", rng).is_empty(), "no egg, no hatch")
	# Force a duplicate: own every forest outcome, then hatch
	for sp: String in CompanionCatalog.egg("egg_forest")["species"]:
		for q: String in CompanionCatalog.qualities():
			GameState.pets[CompanionCatalog.pet_key(sp, q)] = GameState._new_pet_record()
	var count_before := GameState.pets.size()
	_player.inventory.add_item(ItemDatabase.get_item("egg_forest"), 1)
	var diamonds_before := _player.inventory.diamonds
	var dup := GameState.hatch_egg("egg_forest", rng)
	_check(bool(dup["duplicate"]) and GameState.pets.size() == count_before, "duplicate does not add a second record")
	_check(_player.inventory.diamonds == diamonds_before + CompanionCatalog.duplicate_diamonds(dup["quality"]), "duplicate pays its quality's diamonds")
	_check(CompanionCatalog.duplicate_diamonds("common") == 2 and CompanionCatalog.duplicate_diamonds("legendary") == 40, "duplicate table from sheet 03")


func _test_egg_odds_and_distribution() -> void:
	for egg_id: String in CompanionCatalog.egg_ids():
		var odds := CompanionCatalog.egg_odds(egg_id)
		for part: String in ["species", "quality"]:
			var total := 0.0
			for row: Dictionary in odds[part]:
				total += float(row["percent"])
			_check(absf(total - 100.0) < 0.01, "%s %s odds sum to 100%%" % [egg_id, part])
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var legendary := 0
	var n := 20000
	for i in range(n):
		var r := CompanionCatalog.roll_egg("egg_forest", rng)
		_check(r["species"] in CompanionCatalog.egg("egg_forest")["species"], "forest egg hatches only forest species")
		if r["quality"] == "legendary":
			legendary += 1
		if not _failures.is_empty():
			return
	_check(absf(float(legendary) / n - 0.01) < 0.004, "legendary rate matches the 1%% table (%d/%d)" % [legendary, n])


func _test_one_active_pet() -> void:
	_reset()
	GameState.pets["dusk_owl:epic"] = GameState._new_pet_record()
	GameState.equip_pet("ember_fox:common")
	GameState.equip_pet("dusk_owl:epic")
	_check(GameState.active_pet == "dusk_owl:epic", "equipping a pet replaces the active one")
	var stats := GameState.active_companion_stats()
	_check(not stats.has("atk") and stats.has("crit_chance"), "only the active pet's stats count")
	GameState.equip_pet("not_owned:common")
	_check(GameState.active_pet == "dusk_owl:epic", "cannot equip an unowned pet")


func _test_pet_sockets() -> void:
	_reset()
	var key := "ember_fox:common"
	GameState.equip_pet(key)
	_player.inventory.add_item(ItemDatabase.get_item("stone_guard_2"), 1)
	var def_before: int = GameState.compute_base_stats()["def"]
	_check(GameState.companion_sockets("pet", key).size() == 8, "pets have exactly 8 sockets")
	_check(bool(GameState.socket_companion_gem("pet", key, 0, 0)["ok"]), "socket a stone into the pet")
	_check(_player.inventory.get_item_count("stone_guard_2") == 0, "stone left the bag")
	_check(GameState.compute_base_stats()["def"] == def_before + roundi(GemCatalog.value_of("stone_guard_2")), "pet Guardian Stone adds DEF")
	_check(not bool(GameState.socket_companion_gem("pet", key, 0, 0)["ok"]), "occupied socket refused")
	_check(GameState.unsocket_companion_gem("pet", key, 0) and _player.inventory.get_item_count("stone_guard_2") == 1, "unsocket returns the stone")
	_player.inventory.add_item(ItemDatabase.get_item("stone_critical_1"), 1)
	GameState.socket_companion_gem("pet", key, 2, _find(_player.inventory, "stone_critical_1"))
	var crit := 0.0
	for e: Dictionary in _player.inventory.get_all_gem_passive_effects(GameState.active_companion_sockets()):
		if e["effect"] == ItemData.PassiveEffect.CRIT_CHANCE:
			crit += float(e["value"])
	_check(is_equal_approx(crit, GemCatalog.value_of("stone_critical_1")), "pet stones feed combat modifiers")
	# Full bag: unsocketing must not lose the stone
	_player.inventory.add_item(ItemDatabase.get_item("ashwood_blade"), InventoryData.INVENTORY_SIZE)
	_check(not GameState.unsocket_companion_gem("pet", key, 2), "full bag refuses unsocket")
	_check(GameState.companion_sockets("pet", key)[2] == "stone_critical_1", "refused unsocket keeps the stone")


func _test_mount_levels_and_stats() -> void:
	_reset()
	_player.inventory.gold = 1000
	_check(GameState.unlock_mount("tusk_boar"), "claim tusk boar with gold")
	_check(not GameState.unlock_mount("frost_wolf"), "diamond mount refused without diamonds")
	_player.inventory.diamonds = 200
	_check(GameState.unlock_mount("frost_wolf") and _player.inventory.diamonds == 0, "frost wolf costs 200 diamonds")
	GameState.select_mount("tusk_boar")
	var walk: Dictionary = GameState.compute_base_stats()
	GameState.set_mounted(true)
	var ride: Dictionary = GameState.compute_base_stats()
	_check(ride["atk"] > walk["atk"] and ride["speed_mult"] > walk["speed_mult"], "riding adds the mount's attack and speed")
	_player.inventory.diamonds = 10
	_check(GameState.level_up_mount("tusk_boar") and GameState.mount_level("tusk_boar") == 2, "train mount with diamonds")
	_check(GameState.compute_base_stats()["atk"] >= ride["atk"], "mount level does not reduce stats")
	GameState.set_mounted(false)


func _test_mount_evolution() -> void:
	_check(CompanionCatalog.evolution_chance(1, 0) == 0.05 and CompanionCatalog.evolution_chance(2, 0) == 0.08, "first stones: 5%, 2 stones: 8%")
	_check(CompanionCatalog.evolution_chance(8, 0) == 0.25 and CompanionCatalog.evolution_chance(8, 3) == 0.0, "8 stones 25%; form 3 is final")
	_reset()
	_player.inventory.gold = 0
	GameState.mounts["dust_pony"] = GameState._new_mount_record()
	GameState.active_mount = "dust_pony"
	_player.inventory.add_item(ItemDatabase.get_item("stone_guard_1"), 8)
	var result := GameState.socket_companion_gem("mount", "dust_pony", 0, 0, _rng_first(0.01))
	_check(bool(result["ok"]) and bool(result["evolved"]) and GameState.mount_form("dust_pony") == 1, "a lucky socket evolves the mount")
	result = GameState.socket_companion_gem("mount", "dust_pony", 1, 0, _rng_first(0.0, 0.99))
	_check(bool(result["ok"]) and not bool(result["evolved"]) and GameState.mount_form("dust_pony") == 1, "an unlucky socket keeps the form")
	_check(GameState.companion_sockets("mount", "dust_pony")[0] == "stone_guard_1", "evolution keeps socketed stones")
	_check(GameState.unsocket_companion_gem("mount", "dust_pony", 0) and GameState.mount_form("dust_pony") == 1, "removing stones never undoes evolution")
	for i in range(5):
		GameState.socket_companion_gem("mount", "dust_pony", 2 + i, 0, _rng_first(0.01))
	_check(GameState.mount_form("dust_pony") == CompanionCatalog.mount_max_form(), "form stops at 3")
	_check(CompanionCatalog.mount_stats("tusk_boar", 1, 3)["atk"] > CompanionCatalog.mount_stats("tusk_boar", 1, 0)["atk"], "forms add a little power")


func _test_mount_visuals() -> void:
	for id: String in CompanionCatalog.mount_ids():
		for form in range(4):
			var look := MountVisual.describe(id, CompanionCatalog.mount(id)["skins"][0], form)
			_check(MonsterVisualCatalog.get_frames(look["art"]) != null, "%s form %d has frames" % [id, form])
		_check(MountVisual.describe(id, {}, 0)["aura"].a == 0.0 and MountVisual.describe(id, {}, 3)["aura"].a > 0.0, "%s aura only when evolved" % id)
	_check(MountVisual.describe("dust_pony", CompanionCatalog.mount("dust_pony")["skins"][2], 0)["art"] == "actor.animal.ninja.horse_black", "skin can swap to another sheet")


func _test_pets_never_attack() -> void:
	var source := FileAccess.get_file_as_string("res://sense/entities/pets/pet_follower.gd")
	_check(not source.contains("Combat.") and not source.contains("apply_hit") and not source.contains("heal("), "pet follower has no combat code")


func _find(inv: InventoryData, id: String) -> int:
	for i in range(inv.inventory_slots.size()):
		var item: ItemData = inv.inventory_slots[i].get("item")
		if item != null and item.id == id:
			return i
	return -1


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
		print("  FAIL: ", label)


## A fresh RNG whose first randf() is below `below` (or above `above`), to force evolution outcomes.
func _rng_first(below: float, above: float = -1.0) -> RandomNumberGenerator:
	for seed in range(1, 200000):
		var probe := RandomNumberGenerator.new()
		probe.seed = seed
		var v := probe.randf()
		if (above < 0.0 and v < below) or (above >= 0.0 and v > above):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			return rng
	return RandomNumberGenerator.new()
