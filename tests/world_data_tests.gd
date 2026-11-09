extends Node
## Plan phase A: data-driven dig tiles, loot tables and spawn rules
## (docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md §4).

var _failures: Array[String] = []


func _ready() -> void:
	_test_loot_tables_valid()
	_test_dig_tiles_valid()
	_test_loot_roll_deterministic()
	_test_loot_roll_distribution()
	_test_tile_pick_and_respawn()
	_test_relic_tiles_rarer_and_harder()
	_test_field_regions()
	_test_dig_spot_uses_tile()
	_test_dig_spot_currency_reward()
	_test_elite_rules()
	_test_mini_boss_scheduler()
	if _failures.is_empty():
		print("[WORLD DATA TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[WORLD DATA TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


func _test_loot_tables_valid() -> void:
	var errors := LootTableData.validate()
	_check(errors.is_empty(), "loot tables valid: %s" % [errors])


func _test_dig_tiles_valid() -> void:
	var errors := DigTileCatalog.validate()
	_check(errors.is_empty(), "dig tiles valid: %s" % [errors])


func _test_loot_roll_deterministic() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 77
	b.seed = 77
	for i in range(50):
		_check(LootTableData.roll("meadow_ruin", a) == LootTableData.roll("meadow_ruin", b), "same seed gives same loot (%d)" % i)
	_check(LootTableData.roll("no_such_table", a).is_empty(), "unknown table rolls nothing")


func _test_loot_roll_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var counts := {}
	var n := 20000
	for i in range(n):
		var r := LootTableData.roll("meadow_soil", rng)
		counts[r["item_id"]] = int(counts.get(r["item_id"], 0)) + 1
		var entry: Dictionary = {}
		for e: Dictionary in LootTableData.entries("meadow_soil"):
			if e["item_id"] == r["item_id"]:
				entry = e
		_check(int(r["quantity"]) >= int(entry["min"]) and int(r["quantity"]) <= int(entry["max"]), "quantity in range")
		if not _failures.is_empty():
			return
	var total := 0
	for e: Dictionary in LootTableData.entries("meadow_soil"):
		total += int(e["weight"])
	for e: Dictionary in LootTableData.entries("meadow_soil"):
		var expected := float(e["weight"]) / float(total)
		var actual := float(counts.get(e["item_id"], 0)) / float(n)
		_check(absf(expected - actual) < 0.02, "%s rate %.3f ≈ %.3f" % [e["item_id"], actual, expected])


func _test_tile_pick_and_respawn() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for region: String in ["meadow", "ash", "snow"]:
		var allowed := DigTileCatalog.region_tiles(region)
		var seen := {}
		for i in range(2000):
			var tile := DigTileCatalog.pick_tile(region, rng)
			_check(tile in allowed, "%s picks only its own tiles (%s)" % [region, tile])
			seen[tile] = true
			if not _failures.is_empty():
				return
		_check(seen.size() == 4, "%s eventually picks all 4 tile types" % region)
	for tile_id: String in DigTileCatalog.data()["tiles"]:
		var span: Array = DigTileCatalog.get_tile(tile_id)["respawn"]
		for i in range(20):
			var t := DigTileCatalog.roll_respawn(tile_id, rng)
			_check(t >= float(span[0]) and t <= float(span[1]), "%s respawn in range" % tile_id)


func _test_relic_tiles_rarer_and_harder() -> void:
	var order := ["meadow", "ash", "snow"]
	var prev_hits := 0
	for region: String in order:
		var tiles := DigTileCatalog.region_tiles(region)
		var relic := DigTileCatalog.get_tile(tiles[3])
		for i in range(3):
			var common := DigTileCatalog.get_tile(tiles[i])
			_check(int(relic["weight"]) < int(common["weight"]), "%s relic rarer than %s" % [region, tiles[i]])
			_check(int(relic["hits"]) > int(common["hits"]), "%s relic harder than %s" % [region, tiles[i]])
		var soil_hits := int(DigTileCatalog.get_tile(tiles[0])["hits"])
		_check(soil_hits > prev_hits, "%s soil durability rises by region" % region)
		prev_hits = soil_hits
	for region: String in order:
		var has_diamond := false
		for e: Dictionary in LootTableData.entries(String(DigTileCatalog.get_tile(DigTileCatalog.region_tiles(region)[3])["loot"])):
			has_diamond = has_diamond or e["item_id"] == "diamonds"
		_check(has_diamond, "%s relic can drop diamonds" % region)


func _test_field_regions() -> void:
	_check(DigTileCatalog.region_for_field("greenwood") == "meadow", "greenwood is meadow")
	_check(DigTileCatalog.region_for_field("frostvale") == "snow", "frostvale is snow")
	for zone_id: String in GameContent.ZONES:
		if GameContent.ZONES[zone_id].has("dig_spots"):
			_check(int(GameContent.ZONES[zone_id]["dig_spots"]) >= 60, "%s has a dense dig field" % zone_id)


func _test_dig_spot_uses_tile() -> void:
	var spot := DigSpot.create(5, "volcanic_rock")
	_check(spot.tile_id == "volcanic_rock", "dig spot keeps its tile")
	_check(spot.hits_required == 5, "volcanic rock needs 5 hits")
	_check(spot.respawn_time >= 70.0 and spot.respawn_time <= 130.0, "volcanic rock respawn range")
	var starter := DigSpot.create(5)
	_check(starter.tile_id == DigTileCatalog.starter_tile(), "default tile is the starter tile")
	var allowed := {}
	for e: Dictionary in LootTableData.entries("ash_rock"):
		allowed[e["item_id"]] = true
	for i in range(100):
		var r := spot._roll_reward()
		_check(allowed.has(r["item_id"]), "volcanic rock loot comes from ash_rock (%s)" % r["item_id"])
	spot.free()
	starter.free()


func _test_dig_spot_currency_reward() -> void:
	var player := _StubPlayer.new()
	add_child(player)
	var spot := DigSpot.create(1)
	add_child(spot)
	var gold_before := player.inventory.gold
	spot._award_reward(player, "gold", 7)
	_check(player.inventory.gold == gold_before + 7, "gold loot is currency, not an item")
	var diamonds_before := player.inventory.diamonds
	spot._award_reward(player, "diamonds", 2)
	_check(player.inventory.diamonds == diamonds_before + 2, "diamond loot is currency")
	spot.queue_free()
	player.queue_free()


func _test_elite_rules() -> void:
	_check(SpawnRules.elite_chance() >= 0.03 and SpawnRules.elite_chance() <= 0.05, "elite chance 3-5%")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var hits := 0
	var n := 20000
	for i in range(n):
		if SpawnRules.roll_elite(rng, 0):
			hits += 1
	_check(absf(float(hits) / n - SpawnRules.elite_chance()) < 0.006, "elite rate matches config")
	for i in range(500):
		_check(not SpawnRules.roll_elite(rng, SpawnRules.elite_cap()), "no elite at the cap")
		if not _failures.is_empty():
			return


func _test_mini_boss_scheduler() -> void:
	var always := SpawnRules.MiniBossScheduler.new({"check_interval": 10.0, "chance": 1.0, "max_active_per_zone": 1, "respawn_cooldown": 30.0})
	var rng := RandomNumberGenerator.new()
	_check(not always.tick(9.9, rng), "no check before the interval")
	_check(always.tick(0.2, rng), "spawns at the first check when chance is 1")
	_check(not always.tick(10.0, rng), "max one active per zone")
	always.on_defeated()
	_check(not always.tick(10.0, rng), "respawn cooldown blocks the next check")
	_check(not always.tick(10.0, rng), "cooldown still running")
	_check(always.tick(10.0, rng), "spawns again after cooldown")
	var never := SpawnRules.MiniBossScheduler.new({"check_interval": 10.0, "chance": 0.0})
	for i in range(100):
		_check(not never.tick(10.0, rng), "chance 0 never spawns")
	var cfg := SpawnRules.mini_boss_config()
	_check(float(cfg.get("check_interval", 0)) == 600.0 and float(cfg.get("chance", 0)) == 0.10, "sheet 05: check every 10 min at 10%")
	var real := SpawnRules.MiniBossScheduler.new()
	rng.seed = 3
	var spawns := 0
	for i in range(6000):
		if real.tick(600.0, rng):
			spawns += 1
			real.on_defeated()
	_check(spawns > 300 and spawns < 900, "real config spawns at a plausible rate (%d/6000)" % spawns)


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
		print("  FAIL: ", label)


class _StubPlayer extends Node2D:
	var inventory := InventoryData.new()

	func get_inventory() -> InventoryData:
		return inventory
