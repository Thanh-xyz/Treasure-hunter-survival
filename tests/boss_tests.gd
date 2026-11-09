extends Node2D
## Plan phase E: boss data, phases, telegraphed abilities, world schedule, rewards split,
## encounter claims, summon cards and fragments.

var _failures: Array[String] = []
var _player: StubPlayer


class StubPlayer:
	extends Node2D
	var inventory := InventoryData.new()
	var hits: Array[int] = []
	func get_inventory() -> InventoryData:
		return inventory
	func take_damage(amount: int) -> void:
		hits.append(amount)
	func apply_status(_k: String, _d: float, _m: float) -> void:
		pass
	func is_dead() -> bool:
		return false


func _ready() -> void:
	SaveService.enabled = false
	_player = StubPlayer.new()
	_player.add_to_group("player")
	_player.position = Vector2(900, 900)
	add_child(_player)
	_test_data()
	_test_schedule()
	_test_rewards_split()
	_test_claims()
	await _test_phases_and_contribution()
	await _test_abilities_are_telegraphed()
	await _test_world_boss_on_schedule()
	await _test_cards_and_fragments()
	_test_clock_notices()
	_test_save_validation()
	if _failures.is_empty():
		print("[BOSS TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[BOSS TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


func _test_data() -> void:
	var errors := BossCatalog.validate()
	_check(errors.is_empty(), "boss data valid: %s" % [errors])
	_check(LootTableData.validate().is_empty(), "loot tables valid: %s" % [LootTableData.validate()])
	for zone: String in ["greenwood", "cinderwaste", "frostvale"]:
		var found := false
		for slot: Array in WorldBossSchedule.config()["slots"]:
			found = found or str(BossCatalog.boss(str(slot[1]))["zone"]) == zone
		_check(found, "%s has a scheduled world boss" % zone)
	_check(BossCatalog.phase_index("slime_king", 1.0) == 0 and BossCatalog.phase_index("slime_king", 0.69) == 1 and BossCatalog.phase_index("slime_king", 0.2) == 2, "phase thresholds 100/70/30")


func _test_schedule() -> void:
	var s := WorldBossSchedule.status_at({"year": 2026, "month": 11, "day": 9, "hour": 9, "minute": 5, "second": 0})
	_check(bool(s["active"]) and s["boss_id"] == "slime_king" and s["zone"] == "greenwood", "09:05 Mire King is up")
	_check(is_equal_approx(float(s["seconds_left"]), 600.0), "15-minute window: 10 min left at 09:05")
	_check(s["encounter_id"] == "world:slime_king:2026-11-09:09", "stable encounter id")
	s = WorldBossSchedule.status_at({"year": 2026, "month": 11, "day": 9, "hour": 9, "minute": 15, "second": 0})
	_check(not bool(s["active"]), "window closes after 15 minutes")
	s = WorldBossSchedule.status_at({"year": 2026, "month": 11, "day": 9, "hour": 8, "minute": 58, "second": 0})
	_check(s["next_boss"] == "slime_king" and is_equal_approx(float(s["seconds_to_next"]), 120.0), "two minutes before 09:00")
	s = WorldBossSchedule.status_at({"year": 2026, "month": 11, "day": 9, "hour": 23, "minute": 59, "second": 30})
	_check(s["next_boss"] == "frost_leviathan" and is_equal_approx(float(s["seconds_to_next"]), 30.0), "midnight slot wraps the day")


func _test_rewards_split() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var split := BossRewards.compute("slime_king", {1: 900, 7: 290, 9: 10}, 1200, 1, rng)
	_check(split.has(1) and split.has(7), "real contributors are paid")
	_check(not split.has(9), "a participant below 2% of max HP gets nothing")
	_check((split[1] as Array).size() >= 2, "the killer gets participation + final hit")
	var killer_bonus := 0
	var trials := 400
	for i in range(trials):
		var r := BossRewards.compute("slime_king", {1: 600, 7: 600}, 1200, 7, rng)
		killer_bonus += (r[7] as Array).size() - (r[1] as Array).size()
	_check(killer_bonus > trials * 0.5, "final hit adds rewards on average")


func _test_claims() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	var rewards := [{"item_id": "stone_guard_1", "quantity": 2}]
	_check(GameState.grant_boss_rewards("world:slime_king:2026-11-09:09", rewards), "first claim pays")
	_check(_player.inventory.get_item_count("stone_guard_1") == 2, "reward items arrive")
	_check(not GameState.grant_boss_rewards("world:slime_king:2026-11-09:09", rewards), "same encounter never pays twice")
	_check(_player.inventory.get_item_count("stone_guard_1") == 2, "duplicate claim changed nothing")
	var restored := GameState.to_dict()
	GameState.reset_profile()
	GameState.from_dict(restored)
	_check(GameState.has_claimed("world:slime_king:2026-11-09:09"), "claims survive save/load")
	for i in range(GameState.BOSS_CLAIMS_CAP + 10):
		GameState.grant_boss_rewards("test:%d" % i, [])
	_check(GameState.boss_claims.size() == GameState.BOSS_CLAIMS_CAP, "claim list is capped")


func _test_phases_and_contribution() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	var boss := Monster.create("slime_king") as Boss
	boss.position = Vector2(400, 400)
	add_child(boss)
	await get_tree().physics_frame
	var base_speed := boss.speed
	boss.apply_hit(int(boss.max_hp * 0.35), Vector2.ZERO, false, 1)
	_check(boss.phase == 2 and boss.phase_name() == "Mire Rage" and boss.speed > base_speed, "phase 2 at 65%% HP (phase %d)" % boss.phase)
	boss.apply_hit(int(boss.max_hp * 0.4), Vector2.ZERO, false, 5)
	_check(boss.phase == 3 and boss.phase_name() == "King of the Mire", "phase 3 under 30% HP")
	var enc := boss.encounter_id
	boss.apply_hit(boss.max_hp, Vector2.ZERO, false, 1)
	_check(int(boss.contributions.get(1, 0)) + int(boss.contributions.get(5, 0)) == boss.max_hp, "every point of damage is attributed, final blow included")
	_check(GameState.has_claimed(enc), "the local participant was paid for this encounter")
	for i in range(3):
		await get_tree().process_frame


func _test_abilities_are_telegraphed() -> void:
	for ability: String in ["slam", "leap", "wave", "line", "rain"]:
		_player.hits.clear()
		var boss := Monster.create("frost_leviathan") as Boss
		boss.position = _player.position + Vector2(0, -60)
		add_child(boss)
		await get_tree().physics_frame
		boss.set_physics_process(false)
		boss.target = _player
		var before := _telegraphs().size()
		match ability:
			"slam": boss._special_slam()
			"leap": boss._special_leap()
			"wave": boss._special_wave()
			"line": boss._special_line()
			"rain": boss._special_rain()
		var created := _telegraphs().slice(before)
		_check(created.size() >= 1, "%s creates a warning" % ability)
		var min_delay := INF
		for t: Telegraph in created:
			min_delay = minf(min_delay, t.delay)
		_check(min_delay >= 0.5, "%s warns at least 0.5 s before hitting (%.2f)" % [ability, min_delay])
		await get_tree().process_frame
		_check(_player.hits.is_empty(), "%s deals no damage while warning" % ability)
		await get_tree().create_timer(min_delay + 0.6).timeout
		if ability != "leap":
			_check(not _player.hits.is_empty(), "%s lands after its warning on a player who stayed put" % ability)
		boss.queue_free()
		for t in _telegraphs():
			t.queue_free()
		await get_tree().process_frame
	_check(float(BossCatalog.ability("nova")["warn"]) > 0.0, "nova has a warning ring")


func _test_world_boss_on_schedule() -> void:
	GameState.reset_profile()
	var map: FieldMap = load("res://sense/maps/field/greenwood.tscn").instantiate()
	map.clock_override = {"year": 2026, "month": 11, "day": 9, "hour": 9, "minute": 1, "second": 0}
	add_child(map)
	await get_tree().process_frame
	map._process_world_boss(1.0)
	var boss := map._boss as Boss
	_check(boss != null and boss.def_id == "slime_king" and boss.encounter_id == "world:slime_king:2026-11-09:09", "Mire King rises at 09:01 in Greenwood")
	boss.apply_hit(boss.max_hp * 2, Vector2.ZERO, false, 1)
	await get_tree().process_frame
	map._process_world_boss(1.0)
	_check(map._boss == null or map._boss.is_dead(), "a defeated world boss does not respawn in the same slot")
	map.clock_override = {"year": 2026, "month": 11, "day": 9, "hour": 12, "minute": 3, "second": 0}
	map._process_world_boss(1.0)
	_check(map._boss == null or map._boss.is_dead(), "the 12:00 boss belongs to Cinderwaste, not Greenwood")
	map.queue_free()
	await get_tree().process_frame
	var again: FieldMap = load("res://sense/maps/field/greenwood.tscn").instantiate()
	again.clock_override = {"year": 2026, "month": 11, "day": 9, "hour": 9, "minute": 5, "second": 0}
	add_child(again)
	await get_tree().process_frame
	again._process_world_boss(1.0)
	_check(again._boss == null, "a claimed encounter stays done after leaving and returning")
	again.queue_free()
	await get_tree().process_frame


func _test_cards_and_fragments() -> void:
	GameState.reset_profile()
	_player.inventory = InventoryData.new()
	_player.inventory.add_item(ItemDatabase.get_item("fragment_meadow"), 9)
	_check(not GameState.combine_card_fragments("fragment_meadow"), "9 fragments are not enough")
	_player.inventory.add_item(ItemDatabase.get_item("fragment_meadow"), 1)
	_check(GameState.combine_card_fragments("fragment_meadow") and _player.inventory.get_item_count("card_meadow_guardian") == 1, "10 fragments make a Meadow Guardian Card")
	_check(GameState.use_boss_card("card_meadow_guardian") != "", "no field map: the card is refused")
	_check(_player.inventory.get_item_count("card_meadow_guardian") == 1, "a refused card is kept")
	var map: FieldMap = load("res://sense/maps/field/greenwood.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	_check(GameState.use_boss_card("card_meadow_guardian") == "", "card works in Greenwood")
	_check(_player.inventory.get_item_count("card_meadow_guardian") == 0, "card consumed once the boss appeared")
	_check(map._card_boss != null and map._card_boss.def_id == "verdant_treant", "Verdant Treant summoned")
	_player.inventory.add_item(ItemDatabase.get_item("card_meadow_guardian"), 1)
	_check(GameState.use_boss_card("card_meadow_guardian") != "" and _player.inventory.get_item_count("card_meadow_guardian") == 1, "second card refused and kept while the boss lives")
	_player.inventory.add_item(ItemDatabase.get_item("card_snow_titan"), 1)
	_check(GameState.use_boss_card("card_snow_titan") != "" and _player.inventory.get_item_count("card_snow_titan") == 1, "Snow card refused in Meadow and kept")
	map.queue_free()
	await get_tree().process_frame


func _test_clock_notices() -> void:
	var clock := WorldBossClock.new()
	var at := func(h: int, m: int, s: int) -> Array[String]:
		return clock.check({"year": 2026, "month": 11, "day": 9, "hour": h, "minute": m, "second": s})
	_check((at.call(8, 55, 0) as Array).size() == 1, "5-minute notice")
	_check((at.call(8, 55, 1) as Array).is_empty(), "notice is not repeated")
	_check((at.call(8, 59, 0) as Array).size() == 1, "1-minute notice")
	_check((at.call(9, 0, 0) as Array).size() == 1, "rise notice")
	_check((at.call(9, 0, 1) as Array).is_empty(), "rise notice once")
	clock.free()


func _test_save_validation() -> void:
	_check(SaveService._validate_profile({"boss_claims": ["world:x"]}), "profile with boss claims is valid")
	_check(not SaveService._validate_profile({"boss_claims": [3]}), "non-string claim rejected")
	_check(not SaveService._validate_profile({"boss_claims": "x"}), "claims must be a list")


func _telegraphs() -> Array:
	var out: Array = []
	for n in Combat.world_root(get_tree()).get_children():
		if n is Telegraph and not n.is_queued_for_deletion():
			out.append(n)
	return out


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
		print("  FAIL: ", label)
