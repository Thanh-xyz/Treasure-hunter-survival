class_name ReferenceEquipmentRewardResolver
extends RefCounted

## Selects a reference equipment card without inventing its authoritative stats.
## Exact stats must be supplied separately before a canonical reward is created.

const INVALID_CARD_ID := -1
const MAX_TOTAL_WEIGHT := 9223372036854775807


static func select(options: Array, rng: RandomNumberGenerator) -> Dictionary:
	if rng == null:
		return {}
	var normalized := _normalize_options(options)
	if normalized.is_empty():
		return {}
	var roll := rng.randi_range(1, _total_weight(normalized))
	return {"roll": roll, "card_id": _select(normalized, roll)}


static func select_roll(options: Array, roll: int) -> Dictionary:
	var normalized := _normalize_options(options)
	if normalized.is_empty():
		return {}
	var total_weight := _total_weight(normalized)
	if roll < 1 or roll > total_weight:
		return {}
	return {"roll": roll, "card_id": _select(normalized, roll)}


static func finalize(options: Array, selection: Dictionary, stats: Dictionary) -> Dictionary:
	if selection.size() != 2 or not selection.get("roll") is int or not selection.get("card_id") is int:
		return {}
	var expected := select_roll(options, int(selection["roll"]))
	if expected.is_empty() or expected != selection:
		return {}
	var card_id := int(selection["card_id"])
	var normalized_stats := ReferenceEquipmentCatalog.normalize_payload(card_id, stats)
	if normalized_stats.is_empty():
		return {}
	return RewardBoxResolver.normalize_reward({
		"equipment": [{"card_id": card_id, "stats": normalized_stats}],
	})


static func _normalize_options(options: Array) -> Array[Dictionary]:
	if options.is_empty():
		return []
	var normalized: Array[Dictionary] = []
	var seen_cards := {}
	var total_weight := 0
	for value: Variant in options:
		if not value is Dictionary:
			return []
		var option := value as Dictionary
		if option.size() != 2:
			return []
		var weight := _positive_integer(option.get("weight"))
		var card_id := _positive_integer(option.get("card_id"))
		if (
			weight <= 0
			or not ReferenceEquipmentCatalog.has_card(card_id)
			or seen_cards.has(card_id)
			or weight > MAX_TOTAL_WEIGHT - total_weight
		):
			return []
		seen_cards[card_id] = true
		total_weight += weight
		normalized.append({"weight": weight, "card_id": card_id})
	return normalized


static func _total_weight(options: Array[Dictionary]) -> int:
	var total := 0
	for option: Dictionary in options:
		total += int(option["weight"])
	return total


static func _select(options: Array[Dictionary], roll: int) -> int:
	for option: Dictionary in options:
		roll -= int(option["weight"])
		if roll <= 0:
			return int(option["card_id"])
	return INVALID_CARD_ID


static func _positive_integer(value: Variant) -> int:
	if value is int:
		return value if value > 0 else -1
	if value is float and is_finite(value) and value == floor(value):
		return int(value) if value > 0 else -1
	return -1
