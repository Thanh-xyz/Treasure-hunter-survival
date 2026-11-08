class_name EquipmentBalance
extends RefCounted
## Equipment stat formula driven by res://data/equipment/balance.json
## (docs/plans/EQUIPMENT_SYSTEM_PROPOSAL.md §3).
##
##   points        = base_points × slot_budget[slot]                    (level 1, common)
##   budget        = points × rarity_multiplier × (1 + growth × (level − 1))
##   stat points   = points × base_share + (budget − points) × growth_share
##   stat          = stat points ÷ points_per_unit
##
## Pure and deterministic: the same inputs give the same stats offline, on a LAN host and in tests.

const BALANCE_PATH := "res://data/equipment/balance.json"
const STATS := ["hp", "attack", "move_speed"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = _load_json(BALANCE_PATH)
	return _data


## For tests: inject a balance table (pass {} to reload from disk).
static func set_data_for_tests(value: Dictionary) -> void:
	_data = value


static func slots() -> Array:
	return data().get("slot_order", [])


static func rarities() -> Array:
	return data().get("rarity_order", [])


static func max_level() -> int:
	return int((data().get("level", {}) as Dictionary).get("max", 1))


static func lines_for_slot(slot: String) -> Array:
	var out: Array = []
	var lines: Dictionary = data().get("lines", {})
	for line: String in lines:
		if slot in (lines[line] as Dictionary).get("slots", []):
			out.append(line)
	return out


static func is_valid(slot: String, line: String, rarity: String, level: int) -> bool:
	var d := data()
	var level_cfg: Dictionary = d.get("level", {})
	return (
		slot in slots()
		and line in lines_for_slot(slot)
		and (d.get("rarity_multiplier", {}) as Dictionary).has(rarity)
		and level >= int(level_cfg.get("min", 1))
		and level <= int(level_cfg.get("max", 1))
	)


## {"hp": int, "attack": int, "move_speed": int}, or {} for an invalid combination.
static func compute(slot: String, line: String, rarity: String, level: int) -> Dictionary:
	if not is_valid(slot, line, rarity, level):
		return {}
	var d := data()
	var points := float(d["base_points"]) * float(d["slot_budget"][slot])
	var growth := float(d["level"]["growth_per_level"])
	var budget := points * float(d["rarity_multiplier"][rarity]) * (1.0 + growth * (level - 1))
	var extra := budget - points
	var shares := _shares(slot, line)
	var per_unit: Dictionary = d["points_per_unit"]
	var out := {}
	for stat: String in STATS:
		var stat_points := points * float(shares["base_share"][stat]) + extra * float(shares["growth_share"][stat])
		out[stat] = roundi(stat_points / float(per_unit[stat]))
	return out


## Total stat points of a stat block, using the same conversion as the formula.
static func power(stats: Dictionary) -> float:
	var per_unit: Dictionary = data().get("points_per_unit", {})
	var total := 0.0
	for stat: String in STATS:
		total += float(stats.get(stat, 0)) * float(per_unit.get(stat, 0.0))
	return total


static func budget(slot: String, rarity: String, level: int) -> float:
	var d := data()
	return float(d["base_points"]) * float(d["slot_budget"][slot]) \
		* float(d["rarity_multiplier"][rarity]) * (1.0 + float(d["level"]["growth_per_level"]) * (level - 1))


static func max_equipment_move_speed() -> int:
	return int(data().get("max_equipment_move_speed", 0))


static func _shares(slot: String, line: String) -> Dictionary:
	var spec: Dictionary = (data()["lines"][line] as Dictionary).duplicate(true)
	var override: Dictionary = (data().get("slot_line_overrides", {}) as Dictionary).get("%s/%s" % [slot, line], {})
	for key: String in override:
		spec[key] = override[key]
	return spec


static func _load_json(path: String) -> Dictionary:
	var parsed: Variant = null
	var res := load(path)
	if res is JSON:
		parsed = (res as JSON).data
	else:
		parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("[EquipmentBalance] cannot read %s" % path)
		return {}
	return parsed
