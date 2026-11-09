extends Node
## Plan phase D: zone rosters, status effects, telegraphed slams, shaman wards, summons,
## elites and random mini-bosses.

var _failures: Array[String] = []


class Dummy:
	extends Node2D
	var hits: Array[int] = []
	var statuses := StatusEffects.new()
	var dead := false
	func take_damage(amount: int) -> void:
		hits.append(amount)
	func apply_status(kind: String, duration: float, magnitude: float) -> void:
		statuses.apply(kind, duration, magnitude)
	func is_dead() -> bool:
		return dead
	func get_inventory() -> InventoryData:
		return InventoryData.new()


func _ready() -> void:
	_test_rosters()
	_test_status_effects()
	_test_on_hit()
	await _test_slam_is_telegraphed()
	await _test_support_ward()
	await _test_summon()
	_test_elite()
	await _test_mini_boss_spawn()
	if _failures.is_empty():
		print("[COMBAT TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[COMBAT TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


## Sheet 05 §16: 4 regular monsters per region, never shared; ≥2 mini-bosses per region.
func _test_rosters() -> void:
	var seen := {}
	for zone_id: String in ["greenwood", "cinderwaste", "frostvale"]:
		var zone: Dictionary = GameContent.ZONES[zone_id]
		var regular: Array = []
		for entry: Array in zone["spawns"]:
			if str(entry[0]) != "mossback":
				regular.append(str(entry[0]))
		_check(regular.size() == 4, "%s has 4 regular monsters (%s)" % [zone_id, regular])
		for id: String in regular:
			_check(not seen.has(id), "%s is not shared between regions" % id)
			seen[id] = zone_id
			_check(GameContent.MONSTERS.has(id), "%s defined" % id)
		var minis: Array = zone.get("mini_bosses", [])
		_check(minis.size() >= 2, "%s has at least 2 mini-bosses" % zone_id)
		for id: String in minis:
			_check(bool(GameContent.MONSTERS.get(id, {}).get("mini_boss", false)), "%s is a mini-boss" % id)
		_check(DigTileCatalog.region_for_field(zone_id) == str(zone.get("region", "")), "%s dig region matches" % zone_id)
	for id: String in GameContent.MONSTERS:
		var d: Dictionary = GameContent.MONSTERS[id]
		if d.get("visual", "") == "atlas":
			_check(MonsterVisualCatalog.has_asset(str(d.get("asset_id", ""))), "%s art is in the catalog" % id)
		for table: String in [str(d.get("bonus_table", ""))]:
			if not table.is_empty():
				_check(LootTableData.has_table(table), "%s bonus table exists" % id)
		var on_hit: Dictionary = d.get("on_hit", {})
		if not on_hit.is_empty():
			_check(StatusEffects.is_known(str(on_hit.get("status", ""))), "%s on-hit status known" % id)
	# Difficulty rises by region (sheet 05 §5)
	var avg := func(zone_id: String, key: String) -> float:
		var total := 0.0
		var n := 0
		for entry: Array in GameContent.ZONES[zone_id]["spawns"]:
			if str(entry[0]) != "mossback":
				total += float(GameContent.MONSTERS[entry[0]][key])
				n += 1
		return total / maxf(n, 1)
	for key: String in ["hp", "dmg"]:
		_check(avg.call("greenwood", key) < avg.call("cinderwaste", key) and avg.call("cinderwaste", key) < avg.call("frostvale", key), "average %s rises Meadow < Ash < Snow" % key)
	_check(LootTableData.validate().is_empty(), "loot tables still valid: %s" % [LootTableData.validate()])


func _test_status_effects() -> void:
	var s := StatusEffects.new()
	_check(not s.apply("nonsense", 2.0, 5.0), "unknown status refused")
	s.apply("burn", 3.0, 4.0)
	var dmg := 0
	for i in range(30):
		dmg += s.tick(0.1)
	_check(dmg == 12, "burn 4/s for 3 s deals 12 (got %d)" % dmg)
	_check(not s.has("burn"), "burn expires")
	s.apply("slow", 2.0, 30.0)
	s.apply("slow", 1.0, 10.0)
	_check(is_equal_approx(s.speed_multiplier(), 0.7), "re-applying keeps the stronger slow")
	s.apply("freeze", 1.0, 200.0)
	_check(is_equal_approx(s.speed_multiplier(), 0.1), "freeze is capped at 90%")
	s.tick(1.05)
	_check(is_equal_approx(s.speed_multiplier(), 0.7) and not s.has("freeze"), "freeze ends, slow remains")
	s.apply("poison", 2.0, 2.0)
	s.apply("poison", 2.0, 2.0)
	var poison := 0
	for i in range(25):
		poison += s.tick(0.1)
	_check(poison == 4, "poison does not stack (got %d)" % poison)


func _test_on_hit() -> void:
	var d := Dummy.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var landed := 0
	for i in range(1000):
		if Combat.apply_on_hit(d, {"status": "burn", "chance": 0.25, "duration": 1.0, "magnitude": 1}, rng):
			landed += 1
	_check(landed > 200 and landed < 300, "25%% on-hit chance lands about 250/1000 (%d)" % landed)
	_check(not Combat.apply_on_hit(Node.new(), {"status": "burn", "chance": 1.0}), "targets without apply_status are skipped")
	d.free()


## A slam never deals damage before its warning has finished filling (sheet 05/06).
func _test_slam_is_telegraphed() -> void:
	var player := Dummy.new()
	player.add_to_group("player")
	player.position = Vector2(420, 400)
	add_child(player)
	var bear := Monster.create("snow_bear")
	bear.position = Vector2(400, 400)
	add_child(bear)
	await get_tree().physics_frame
	bear.target = player
	bear._slam_cooldown = 0.0
	bear.attack_cooldown = 99.0
	var warn := float(GameContent.MONSTERS["snow_bear"]["slam"]["warn"])
	var saw_warning := false
	var hit_before_warning := false
	var elapsed := 0.0
	while elapsed < warn + 0.5:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if bear.state == "slam_warn":
			saw_warning = true
			if not player.hits.is_empty():
				hit_before_warning = true
	_check(saw_warning, "bear telegraphs its slam")
	_check(not hit_before_warning, "no slam damage during the warning")
	_check(player.hits.size() >= 1 and player.hits[0] > int(GameContent.MONSTERS["snow_bear"]["dmg"]), "slam lands after the warning with its multiplier (%s)" % [player.hits])
	bear.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_support_ward() -> void:
	var shaman := Monster.create("ice_shaman")
	shaman.position = Vector2(100, 100)
	var wolf := Monster.create("snow_wolf")
	wolf.position = Vector2(130, 100)
	add_child(shaman)
	add_child(wolf)
	await get_tree().physics_frame
	shaman._pulse_support(GameContent.MONSTERS["ice_shaman"]["support"])
	_check(is_equal_approx(wolf.damage_taken_mult, 0.8), "shaman wards nearby monsters")
	var before := wolf.hp
	wolf.apply_hit(100, Vector2.ZERO)
	_check(before - wolf.hp == 80, "warded monster takes 80%% damage (%d)" % (before - wolf.hp))
	shaman.queue_free()
	wolf.queue_free()
	await get_tree().process_frame


func _test_summon() -> void:
	var monarch := Monster.create("mini_boss_slime_monarch")
	monarch.position = Vector2(600, 600)
	add_child(monarch)
	await get_tree().physics_frame
	var slimes_before := _count_monsters("slime")
	monarch.apply_hit(int(monarch.max_hp * 0.6), Vector2.ZERO)
	for i in range(3):
		await get_tree().physics_frame
	_check(_count_monsters("slime") == slimes_before + 3, "Slime Monarch splits into 3 slimes at half HP")
	for i in range(3):
		await get_tree().physics_frame
	_check(_count_monsters("slime") == slimes_before + 3, "summon happens once")
	for n in get_tree().get_nodes_in_group("monster"):
		n.queue_free()
	await get_tree().process_frame


func _test_elite() -> void:
	var normal := Monster.create("snow_wolf")
	var elite := Monster.create("snow_wolf", true)
	_check(elite.max_hp > normal.max_hp and elite.damage > normal.damage, "elite is stronger")
	_check(LootTableData.has_table("elite_bonus"), "elite bonus loot table exists")
	_check(str(GameContent.MONSTERS["snow_wolf"]["elite_name"]) == "Frostfang Alpha", "elite names from sheet 06.2")
	normal.free()
	elite.free()


func _test_mini_boss_spawn() -> void:
	var map: FieldMap = load("res://sense/maps/field/cinderwaste.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	var boss := map.spawn_mini_boss("mini_boss_cinder_warlord")
	_check(boss != null and boss.is_mini_boss, "mini-boss spawns")
	var min_dist := float(SpawnRules.mini_boss_config()["min_distance_from_safe"])
	_check(boss != null and boss.position.distance_to(map.spawn_point) >= min_dist * 0.99, "mini-boss spawns away from the safe spawn")
	_check(map.spawn_mini_boss("mini_boss_ash_tyrant") == null, "only one mini-boss per zone")
	map.queue_free()
	await get_tree().process_frame


func _count_monsters(id: String) -> int:
	var n := 0
	for m in get_tree().get_nodes_in_group("monster"):
		if (m as Monster).def_id == id and not (m as Monster).is_dead():
			n += 1
	return n


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
		print("  FAIL: ", label)
