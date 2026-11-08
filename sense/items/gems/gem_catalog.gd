class_name GemCatalog
extends RefCounted
## Socket stones from res://data/gems/gems.json (brainstorm sheet 07 §4, plan phase B).
##
##   item id      = "<type>_<tier>"            e.g. stone_guard_2
##   stone value  = base_value × tier multiplier
##   fuse         = 6 × same type + same tier  → 1 × same type, tier + 1 (tier 4 is final)
##   defense      = damage × (1 − min(def ÷ (def + k), max_reduction))
##
## Pure and deterministic: shared by offline play, the LAN host and tests.

const DATA_PATH := "res://data/gems/gems.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func slots_per_holder() -> int:
	return int(data().get("slots_per_holder", 8))


static func fuse_cost() -> int:
	return int(data().get("fuse_cost", 6))


static func types() -> Array:
	var keys: Array = (data().get("types", {}) as Dictionary).keys()
	keys.sort()
	return keys


static func max_tier() -> int:
	return (data().get("tiers", []) as Array).size()


static func type_def(type_id: String) -> Dictionary:
	return (data().get("types", {}) as Dictionary).get(type_id, {})


static func tier_def(tier: int) -> Dictionary:
	var tiers: Array = data().get("tiers", [])
	return tiers[tier - 1] if tier >= 1 and tier <= tiers.size() else {}


static func item_id(type_id: String, tier: int) -> String:
	return "%s_%d" % [type_id, tier]


## All stone item ids, type-major order.
static func all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id: String in types():
		for tier in range(1, max_tier() + 1):
			ids.append(item_id(type_id, tier))
	return ids


## {"type": String, "tier": int} or {} when the id is not a stone.
static func parse(stone_id: String) -> Dictionary:
	var cut := stone_id.rfind("_")
	if cut <= 0:
		return {}
	var type_id := stone_id.substr(0, cut)
	var tier_text := stone_id.substr(cut + 1)
	if not tier_text.is_valid_int() or type_def(type_id).is_empty():
		return {}
	var tier := tier_text.to_int()
	if tier < 1 or tier > max_tier():
		return {}
	return {"type": type_id, "tier": tier}


static func is_stone(stone_id: String) -> bool:
	return not parse(stone_id).is_empty()


static func stat_of(stone_id: String) -> String:
	var p := parse(stone_id)
	return String(type_def(p["type"]).get("stat", "")) if not p.is_empty() else ""


static func value_of(stone_id: String) -> float:
	var p := parse(stone_id)
	if p.is_empty():
		return 0.0
	return float(type_def(p["type"]).get("base_value", 0.0)) * float(tier_def(p["tier"]).get("multiplier", 0.0))


## The id a fusion of this stone produces, or "" at the top tier / for non-stones.
static func fuse_result(stone_id: String) -> String:
	var p := parse(stone_id)
	if p.is_empty() or int(p["tier"]) >= max_tier():
		return ""
	return item_id(p["type"], int(p["tier"]) + 1)


## Sheet 07 §4.3 tier colour: white, blue, purple, gold.
static func tier_color(stone_id: String) -> Color:
	var p := parse(stone_id)
	return Color(String(tier_def(int(p["tier"])).get("color", "ffffff"))) if not p.is_empty() else Color.WHITE


static func display_name(stone_id: String) -> String:
	var p := parse(stone_id)
	if p.is_empty():
		return stone_id
	return "%s %s" % [type_def(p["type"]).get("name", p["type"]), tier_def(p["tier"]).get("name", str(p["tier"]))]


static func describe(stone_id: String) -> String:
	var p := parse(stone_id)
	if p.is_empty():
		return ""
	var t := type_def(p["type"])
	var value := value_of(stone_id)
	var shown := ("%d" % roundi(value)) if is_equal_approx(value, roundf(value)) else ("%.1f" % value)
	return "%s +%s%s" % [_stat_label(String(t.get("stat", ""))), shown, t.get("unit", "")]


static func _stat_label(stat: String) -> String:
	return {
		"defense": "DEF", "crit_chance": "Crit", "crit_damage": "Crit DMG", "life_steal": "Lifesteal",
		"dodge": "Dodge", "accuracy": "Accuracy", "regeneration": "Regen", "reflection": "Reflect",
		"fire_damage": "Fire", "ice_slow": "Frost", "poison_damage": "Poison",
	}.get(stat, stat)


static func stats() -> Array[String]:
	var out: Array[String] = []
	for type_id: String in types():
		out.append(String(type_def(type_id).get("stat", "")))
	return out


## Sum of every stone in the given socket arrays ("" = empty), capped per data.
## Returns every stat key (0.0 when absent).
static func total_stats(socket_arrays: Array) -> Dictionary:
	var totals := {}
	for stat in stats():
		totals[stat] = 0.0
	for sockets: Variant in socket_arrays:
		if not sockets is Array:
			continue
		for stone_id: Variant in sockets:
			var id := str(stone_id)
			if id.is_empty() or not is_stone(id):
				continue
			var stat := stat_of(id)
			totals[stat] = float(totals.get(stat, 0.0)) + value_of(id)
	var caps: Dictionary = data().get("caps", {})
	for stat: String in caps:
		totals[stat] = minf(float(totals.get(stat, 0.0)), float(caps[stat]))
	return totals


## Damage after defense. Always at least 1 for a positive hit.
static func mitigate(raw_damage: int, defense: int) -> int:
	if raw_damage <= 0:
		return 0
	var cfg: Dictionary = data().get("defense", {})
	var k := float(cfg.get("k", 150.0))
	var max_reduction := float(cfg.get("max_reduction", 0.75))
	var def := maxf(float(defense), 0.0)
	var reduction := minf(def / (def + k), max_reduction) if def > 0.0 else 0.0
	return maxi(roundi(float(raw_damage) * (1.0 - reduction)), 1)


## An empty socket array of the configured size.
static func empty_sockets() -> Array[String]:
	var sockets: Array[String] = []
	sockets.resize(slots_per_holder())
	sockets.fill("")
	return sockets


static func validate() -> Array[String]:
	var errors: Array[String] = []
	if types().size() != 11:
		errors.append("expected 11 stone types, got %d" % types().size())
	if max_tier() != 4:
		errors.append("expected 4 tiers, got %d" % max_tier())
	var prev := 0.0
	for tier in range(1, max_tier() + 1):
		var m := float(tier_def(tier).get("multiplier", 0.0))
		if m <= prev:
			errors.append("tier %d multiplier must rise" % tier)
		if tier > 1 and m >= prev * fuse_cost():
			errors.append("tier %d must be worth less than %d stones of tier %d" % [tier, fuse_cost(), tier - 1])
		prev = m
	for type_id: String in types():
		if float(type_def(type_id).get("base_value", 0.0)) <= 0.0:
			errors.append("%s needs base_value > 0" % type_id)
	return errors
