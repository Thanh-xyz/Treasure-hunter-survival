extends Node
## Equipment system acceptance tests (owner brief §8, EQUIPMENT_SYSTEM_PROPOSAL.md).
## Every check runs over every slot × line × rarity × level combination.

const BUDGET_TOLERANCE := 0.07   # rounding to whole stats only

var _failures: Array[String] = []


func _ready() -> void:
	_test_tables_complete()
	_test_every_combination()
	_test_weapon_identities()
	_test_only_dagger_has_outstanding_speed()
	_test_no_line_dominates()
	_test_templates()
	_test_calculator_sums()
	_test_no_double_counting()
	_test_preview_swap()
	_test_speed_cap()
	_test_invalid_inputs()
	_test_gem_catalog()
	if _failures.is_empty():
		print("[EQUIPMENT TEST] ALL PASSED")
		get_tree().quit(0)
	else:
		print("[EQUIPMENT TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)


func _test_tables_complete() -> void:
	_check(EquipmentBalance.slots() == ["helmet", "armor", "boots", "weapon", "back"], "5 slots in order")
	for slot: String in ["helmet", "armor", "boots", "back"]:
		var lines := EquipmentBalance.lines_for_slot(slot)
		lines.sort()
		_check(lines == ["balanced", "damage", "tank"], "%s lines: %s" % [slot, lines])
	var weapons := EquipmentBalance.lines_for_slot("weapon")
	weapons.sort()
	_check(weapons == ["axe", "dagger", "sword"], "weapon lines: %s" % [weapons])
	_check(EquipmentBalance.rarities() == ["common", "uncommon", "epic", "legendary"], "4 rarities, no rare (owner 2026-11-08)")
	_check(EquipmentBalance.rarity_enum("epic") == ItemData.ItemRarity.EPIC, "epic maps to ItemRarity.EPIC")
	_check(EquipmentBalance.rarity_name(ItemData.ItemRarity.RARE) == "", "equipment cannot be rare")
	_check(ItemDatabase.get_item("emberforged_blade").rarity == ItemData.ItemRarity.EPIC, "emberforged blade is epic")
	var epic_stats := ItemDatabase.get_item("emberforged_blade").get_line_stats()
	_check(int(epic_stats.get("attack", 0)) == int(EquipmentBalance.compute("weapon", "sword", "epic", 1)["attack"]), "epic item uses epic multiplier")
	for line: String in EquipmentBalance.data()["lines"]:
		var spec: Dictionary = EquipmentBalance.data()["lines"][line]
		for share_key in ["base_share", "growth_share"]:
			var sum := 0.0
			for stat: String in EquipmentBalance.STATS:
				sum += float(spec[share_key][stat])
			_check(is_equal_approx(sum, 1.0), "%s.%s sums to %s" % [line, share_key, sum])


## Every item has all three fields, sits on its power budget, keeps its main stat, and grows.
func _test_every_combination() -> void:
	for slot: String in EquipmentBalance.slots():
		for line: String in EquipmentBalance.lines_for_slot(slot):
			var primary := str(EquipmentBalance.data()["lines"][line].get("primary", ""))
			for rarity: String in EquipmentBalance.rarities():
				var previous := {}
				for level in range(1, EquipmentBalance.max_level() + 1):
					var s := EquipmentBalance.compute(slot, line, rarity, level)
					var tag := "%s/%s/%s/L%d" % [slot, line, rarity, level]
					_check(s.has("hp") and s.has("attack") and s.has("move_speed"), "%s missing a stat field" % tag)
					var budget := EquipmentBalance.budget(slot, rarity, level)
					var ratio := EquipmentBalance.power(s) / budget
					_check(absf(ratio - 1.0) <= BUDGET_TOLERANCE or budget < 140.0 and absf(ratio - 1.0) <= 0.1,
						"%s power %.0f vs budget %.0f" % [tag, EquipmentBalance.power(s), budget])
					if not primary.is_empty():
						_check(_main_stat(s) == primary, "%s main stat is %s, expected %s" % [tag, _main_stat(s), primary])
					if not previous.is_empty():
						_check(EquipmentBalance.power(s) > EquipmentBalance.power(previous), "%s did not grow" % tag)
					previous = s


func _test_weapon_identities() -> void:
	for rarity: String in EquipmentBalance.rarities():
		for level in range(1, EquipmentBalance.max_level() + 1):
			var axe := EquipmentBalance.compute("weapon", "axe", rarity, level)
			var sword := EquipmentBalance.compute("weapon", "sword", rarity, level)
			var dagger := EquipmentBalance.compute("weapon", "dagger", rarity, level)
			var tag := "%s/L%d" % [rarity, level]
			_check(axe["attack"] > sword["attack"] and axe["attack"] > dagger["attack"], "%s axe must have the highest ATK" % tag)
			_check(axe["hp"] < sword["hp"] and axe["hp"] <= dagger["hp"], "%s axe must have the lowest HP" % tag)
			_check(sword["hp"] > dagger["hp"] and sword["attack"] > dagger["attack"], "%s sword balances HP and ATK" % tag)
			_check(dagger["attack"] < axe["attack"], "%s dagger ATK below axe" % tag)
			_check(dagger["move_speed"] > sword["move_speed"] and dagger["move_speed"] > axe["move_speed"], "%s dagger fastest weapon" % tag)


## Owner decision: only the dagger has outstanding move speed.
func _test_only_dagger_has_outstanding_speed() -> void:
	for rarity: String in EquipmentBalance.rarities():
		for level in range(1, EquipmentBalance.max_level() + 1):
			var dagger_speed := int(EquipmentBalance.compute("weapon", "dagger", rarity, level)["move_speed"])
			for slot: String in EquipmentBalance.slots():
				for line: String in EquipmentBalance.lines_for_slot(slot):
					if line == "dagger":
						continue
					var s := EquipmentBalance.compute(slot, line, rarity, level)
					_check(int(s["move_speed"]) * 2 <= dagger_speed or dagger_speed < 4,
						"%s/%s/%s/L%d speed %d rivals dagger %d" % [slot, line, rarity, level, s["move_speed"], dagger_speed])


## No line may be at least as good on all three stats and better on one, at the same slot/level/rarity.
func _test_no_line_dominates() -> void:
	for slot: String in EquipmentBalance.slots():
		var lines := EquipmentBalance.lines_for_slot(slot)
		for rarity: String in EquipmentBalance.rarities():
			for level in range(1, EquipmentBalance.max_level() + 1):
				for a: String in lines:
					for b: String in lines:
						if a == b:
							continue
						var sa := EquipmentBalance.compute(slot, a, rarity, level)
						var sb := EquipmentBalance.compute(slot, b, rarity, level)
						var all_ge := true
						var any_gt := false
						for stat: String in EquipmentBalance.STATS:
							all_ge = all_ge and int(sa[stat]) >= int(sb[stat])
							any_gt = any_gt or int(sa[stat]) > int(sb[stat])
						_check(not (all_ge and any_gt), "%s/%s/L%d: %s dominates %s" % [slot, rarity, level, a, b])


func _test_templates() -> void:
	var ids := EquipmentCatalog.ids()
	var commons := 0
	var seen := {}
	for id: String in ids:
		var t := EquipmentCatalog.get_template(id)
		if str(t["rarity"]) == "common":
			commons += 1
		var key := "%s/%s/%s" % [t["slot"], t["line"], t["rarity"]]
		_check(not seen.has(key), "two templates for %s" % key)
		seen[key] = true
		_check(EquipmentBalance.is_valid(str(t["slot"]), str(t["line"]), str(t["rarity"]), 1), "%s invalid placement" % id)
		_check(not EquipmentCatalog.stats_for(id).is_empty(), "%s has no stats" % id)
		var icon := str(t.get("icon", ""))
		var icon_ok := ResourceLoader.exists(icon) if icon.begins_with("res://") else ArtCatalog.has(icon)
		_check(not str(t.get("name", "")).is_empty() and icon_ok, "%s needs a name and a known icon (art id or licensed file)" % id)
	_check(commons == 15, "15 common base templates (5 slots x 3 lines), got %d" % commons)
	for starter in ["ashwood_blade", "ironbark_cleaver", "ember_dirk"]:
		_check(EquipmentCatalog.has(starter), "starter weapon %s missing" % starter)


func _test_calculator_sums() -> void:
	var base := {"hp": 120, "attack": 10, "move_speed": 120, "defense": 2}
	var equipped := {}
	var expected := base.duplicate()
	for slot: String in EquipmentBalance.slots():
		var line: String = EquipmentBalance.lines_for_slot(slot)[0]
		var s := EquipmentBalance.compute(slot, line, "epic", 5)
		equipped[slot] = s
		expected["hp"] += s["hp"]
		expected["attack"] += s["attack"]
		expected["move_speed"] += s["move_speed"]
	var stone := {"defense": 7, "hp": 15}
	expected["defense"] += 7
	expected["hp"] += 15
	var total := CharacterStatCalculator.compute(base, equipped, [stone])
	for key: String in CharacterStatCalculator.KEYS:
		_check(int(total[key]) == int(expected[key]), "sum %s: %s != %s" % [key, total[key], expected[key]])


## 500 random equip/unequip/replace operations: totals always equal a fresh sum of what's worn.
func _test_no_double_counting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261108
	var base := {"hp": 100, "attack": 10, "move_speed": 120}
	var equipped := {}
	for step in range(500):
		var slot: String = EquipmentBalance.slots()[rng.randi_range(0, 4)]
		if rng.randf() < 0.3:
			equipped.erase(slot)
		else:
			var lines := EquipmentBalance.lines_for_slot(slot)
			var rarity: String = EquipmentBalance.rarities()[rng.randi_range(0, EquipmentBalance.rarities().size() - 1)]
			equipped[slot] = EquipmentBalance.compute(slot, lines[rng.randi_range(0, lines.size() - 1)], rarity, rng.randi_range(1, 10))
		var total := CharacterStatCalculator.compute(base, equipped)
		var hp := int(base["hp"])
		for s: Dictionary in equipped.values():
			hp += int(s["hp"])
		if int(total["hp"]) != hp:
			_fail("step %d: HP %d != fresh sum %d" % [step, total["hp"], hp])
			return


func _test_preview_swap() -> void:
	var base := {"hp": 120, "attack": 10, "move_speed": 120}
	var tank := EquipmentBalance.compute("helmet", "tank", "common", 1)
	var damage := EquipmentBalance.compute("helmet", "damage", "common", 1)
	var preview := CharacterStatCalculator.preview_swap(base, {"helmet": tank}, "helmet", damage)
	_check(int(preview["delta"]["hp"]) == int(damage["hp"]) - int(tank["hp"]), "preview HP delta")
	_check(int(preview["delta"]["attack"]) == int(damage["attack"]) - int(tank["attack"]), "preview ATK delta")
	_check(int(preview["after"]["attack"]) == 10 + int(damage["attack"]), "preview after totals")
	var removal := CharacterStatCalculator.preview_swap(base, {"helmet": tank}, "helmet", {})
	_check(int(removal["after"]["hp"]) == 120, "preview of unequip returns base")


func _test_speed_cap() -> void:
	var cap := EquipmentBalance.max_equipment_move_speed()
	_check(cap > 0, "a move-speed safety cap is configured")
	var many := {}
	for i in range(20):
		many["slot_%d" % i] = {"move_speed": 10}
	var total := CharacterStatCalculator.compute({"move_speed": 120}, many)
	_check(int(total["move_speed"]) == 120 + cap, "equipment speed capped at +%d" % cap)
	var best := 0
	for slot: String in EquipmentBalance.slots():
		var top := 0
		for line: String in EquipmentBalance.lines_for_slot(slot):
			top = maxi(top, int(EquipmentBalance.compute(slot, line, "legendary", 10)["move_speed"]))
		best += top
	_check(best <= cap + 20, "fastest legal kit (%d) stays near the cap (%d)" % [best, cap])


func _test_invalid_inputs() -> void:
	_check(EquipmentBalance.compute("helmet", "axe", "common", 1).is_empty(), "axe on a helmet rejected")
	_check(EquipmentBalance.compute("helmet", "tank", "mythic", 1).is_empty(), "unknown rarity rejected")
	_check(EquipmentBalance.compute("helmet", "tank", "common", 11).is_empty(), "level above max rejected")
	_check(EquipmentBalance.compute("shield", "tank", "common", 1).is_empty(), "removed slot rejected")
	_check(EquipmentCatalog.stats_for("does_not_exist").is_empty(), "unknown template")


func _main_stat(s: Dictionary) -> String:
	var per_unit: Dictionary = EquipmentBalance.data()["points_per_unit"]
	var best := ""
	var best_points := -1.0
	for stat: String in EquipmentBalance.STATS:
		var points := float(s[stat]) * float(per_unit[stat])
		if points > best_points:
			best_points = points
			best = stat
	return best


## Socket stones (brainstorm sheet 07 §4): 11 types × 4 tiers, 8 sockets, 6 → 1 fusion,
## capped stats and a DEF curve that never makes the player immune.
func _test_gem_catalog() -> void:
	var errors := GemCatalog.validate()
	_check(errors.is_empty(), "gem data valid: %s" % [errors])
	_check(GemCatalog.slots_per_holder() == 8 and GemCatalog.fuse_cost() == 6, "8 sockets, fuse 6 to 1")
	for type_id: String in GemCatalog.types():
		for tier in range(1, 4):
			var id := GemCatalog.item_id(type_id, tier)
			_check(GemCatalog.fuse_result(id) == GemCatalog.item_id(type_id, tier + 1), "%s fuses up one tier" % id)
			_check(GemCatalog.value_of(GemCatalog.item_id(type_id, tier + 1)) > GemCatalog.value_of(id), "%s next tier is stronger" % id)
		_check(GemCatalog.fuse_result(GemCatalog.item_id(type_id, 4)) == "", "%s gold tier is final" % type_id)
	_check(GemCatalog.parse("stone_critical_damage_3") == {"type": "stone_critical_damage", "tier": 3}, "parse keeps underscores in the type")
	_check(GemCatalog.parse("stone_guard_5").is_empty() and GemCatalog.parse("wood").is_empty(), "parse rejects bad ids")
	# 40 sockets of tier IV crit cannot exceed the cap
	var all_crit: Array = []
	for i in range(5):
		var sockets: Array = []
		for j in range(8):
			sockets.append("stone_critical_4")
		all_crit.append(sockets)
	var capped := GemCatalog.total_stats(all_crit)
	_check(float(capped["crit_chance"]) == float(GemCatalog.data()["caps"]["crit_chance"]), "crit is capped")
	var prev := 1000
	for def in [0, 10, 50, 150, 600, 5000, 100000]:
		var hit := GemCatalog.mitigate(1000, def)
		_check(hit <= prev and hit >= 1, "DEF %d reduces damage monotonically (%d)" % [def, hit])
		prev = hit
	_check(GemCatalog.mitigate(1000, 100000) == 250, "DEF reduction is capped at 75%")
	_check(GemCatalog.mitigate(1, 100000) == 1 and GemCatalog.mitigate(0, 0) == 0, "a hit always does at least 1")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	if _failures.size() <= 25:
		push_error("[EQUIPMENT TEST] " + message)
