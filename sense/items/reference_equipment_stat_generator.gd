class_name ReferenceEquipmentStatGenerator
extends RefCounted

## Replays the verified Treasure Hunter Common equipment roll with one
## caller-owned RNG so offline saves and future host authority stay deterministic.

const STAT_ORDER := [&"health", &"speed", &"damage"]
const OUTER_ROLL_MAX := 999
const SUPPRESSION_INDEX_MAX := 2
const VALUE_SCALE := 1000.0
const COMMON_RANGE_FRACTION := 0.25


static func generate_common(card_id: int, rng: RandomNumberGenerator) -> Dictionary:
	if rng == null or not ReferenceEquipmentCatalog.has_card(card_id):
		return {}
	var draws: Array[int] = [rng.randi_range(0, OUTER_ROLL_MAX)]
	var suppression_count := _suppression_count(draws[0])
	for _index: int in suppression_count:
		draws.append(rng.randi_range(0, SUPPRESSION_INDEX_MAX))
	var suppressed := _suppressed_indices(draws, suppression_count)
	var bounds := _common_bounds(card_id)
	if bounds.is_empty():
		return {}
	for stat_index: int in STAT_ORDER.size():
		if suppressed.has(stat_index):
			continue
		var stat_bounds := bounds[String(STAT_ORDER[stat_index])] as Dictionary
		draws.append(rng.randi_range(int(stat_bounds["lower"]), int(stat_bounds["upper"]) - 1))
	return replay_common(card_id, draws)


## Draws are ordered exactly as the adapted authority stream: outer roll,
## suppression indices, then non-suppressed values in health/speed/damage order.
static func replay_common(card_id: int, draws: Array) -> Dictionary:
	if not ReferenceEquipmentCatalog.has_card(card_id) or draws.is_empty():
		return {}
	var outer_roll := _bounded_integer(draws[0], 0, OUTER_ROLL_MAX)
	if outer_roll < 0:
		return {}
	var suppression_count := _suppression_count(outer_roll)
	var expected_min_size := 1 + suppression_count
	if draws.size() < expected_min_size:
		return {}
	for index: int in range(1, expected_min_size):
		if _bounded_integer(draws[index], 0, SUPPRESSION_INDEX_MAX) < 0:
			return {}
	var suppressed := _suppressed_indices(draws, suppression_count)
	var expected_size := expected_min_size + STAT_ORDER.size() - suppressed.size()
	if draws.size() != expected_size:
		return {}
	var bounds := _common_bounds(card_id)
	if bounds.is_empty():
		return {}
	var stats := {}
	var draw_index := expected_min_size
	for stat_index: int in STAT_ORDER.size():
		var key := String(STAT_ORDER[stat_index])
		if suppressed.has(stat_index):
			stats[key] = 0.0
			continue
		var stat_bounds := bounds[key] as Dictionary
		var value_roll := _bounded_integer(
			draws[draw_index],
			int(stat_bounds["lower"]),
			int(stat_bounds["upper"]) - 1,
		)
		if value_roll < 0:
			return {}
		stats[key] = value_roll / VALUE_SCALE
		draw_index += 1
	return stats if ReferenceEquipmentCatalog.is_valid_payload(card_id, stats) else {}


static func _suppression_count(outer_roll: int) -> int:
	if outer_roll <= 499:
		return 2
	if outer_roll <= 899:
		return 1
	return 0


static func _suppressed_indices(draws: Array, suppression_count: int) -> Dictionary:
	var suppressed := {}
	for index: int in suppression_count:
		suppressed[int(draws[index + 1])] = true
	return suppressed


static func _common_bounds(card_id: int) -> Dictionary:
	var definition := ReferenceEquipmentCatalog.get_definition(card_id)
	if definition.is_empty() or not definition.get("ranges") is Dictionary:
		return {}
	var ranges := definition["ranges"] as Dictionary
	var bounds := {}
	for key: StringName in STAT_ORDER:
		if not ranges.get(String(key)) is Dictionary:
			return {}
		var stat_range := ranges[String(key)] as Dictionary
		var minimum := _float32(float(stat_range.get("min", NAN)))
		var maximum := _float32(float(stat_range.get("max", NAN)))
		if not is_finite(minimum) or not is_finite(maximum) or minimum >= maximum:
			return {}
		var width := _float32(maximum - minimum)
		var common_max := _float32(minimum + _float32(width * _float32(COMMON_RANGE_FRACTION)))
		var lower := int(_float32(minimum * _float32(VALUE_SCALE)))
		var upper := int(_float32(common_max * _float32(VALUE_SCALE)))
		if lower >= upper:
			return {}
		bounds[String(key)] = {"lower": lower, "upper": upper}
	return bounds


static func _float32(value: float) -> float:
	return PackedFloat32Array([value])[0]


static func _bounded_integer(value: Variant, minimum: int, maximum: int) -> int:
	if value is int:
		return value if value >= minimum and value <= maximum else -1
	if value is float and is_finite(value) and value == floor(value):
		var parsed := int(value)
		return parsed if parsed >= minimum and parsed <= maximum else -1
	return -1
