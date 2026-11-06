class_name RewardBoxCatalog
extends RefCounted

## Evidence-backed Treasure Hunter reward boxes that do not depend on unmapped items.
## Numeric keys preserve the source Box.json IDs for later quest/content migration.

const _BOXES := {
	98: [
		{"weight": 100, "reward": {"diamonds": 1}},
	],
	150: [
		{"weight": 100, "reward": {"gold": 100}},
	],
	151: [
		{"weight": 100, "reward": {"gold": 200}},
	],
	152: [
		{"weight": 100, "reward": {"gold": 300}},
	],
}

## Equipment boxes keep selection separate because exact instance stats are
## supplied by an offline/host authority, not guessed from Card.json ranges.
const _EQUIPMENT_BOXES := {
	149: [
		{"weight": 34, "card_id": 28},
		{"weight": 33, "card_id": 29},
		{"weight": 33, "card_id": 30},
	],
}


static func has_box(box_id: int) -> bool:
	return _BOXES.has(box_id)


static func get_entries(box_id: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not _BOXES.has(box_id):
		return entries
	for value: Variant in _BOXES[box_id]:
		entries.append((value as Dictionary).duplicate(true))
	return entries


static func resolve(box_id: int, rng: RandomNumberGenerator) -> Dictionary:
	return RewardBoxResolver.resolve(get_entries(box_id), rng)


static func has_equipment_box(box_id: int) -> bool:
	return _EQUIPMENT_BOXES.has(box_id)


static func get_equipment_options(box_id: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not _EQUIPMENT_BOXES.has(box_id):
		return options
	for value: Variant in _EQUIPMENT_BOXES[box_id]:
		options.append((value as Dictionary).duplicate(true))
	return options


static func select_equipment(box_id: int, rng: RandomNumberGenerator) -> Dictionary:
	var selection := ReferenceEquipmentRewardResolver.select(get_equipment_options(box_id), rng)
	if selection.is_empty():
		return {}
	selection["box_id"] = box_id
	return selection


static func select_equipment_roll(box_id: int, roll: int) -> Dictionary:
	var selection := ReferenceEquipmentRewardResolver.select_roll(get_equipment_options(box_id), roll)
	if selection.is_empty():
		return {}
	selection["box_id"] = box_id
	return selection


static func finalize_equipment_reward(selection: Dictionary, stats: Dictionary) -> Dictionary:
	if selection.size() != 3 or not selection.get("box_id") is int:
		return {}
	var box_id := int(selection["box_id"])
	var resolver_selection := selection.duplicate(true)
	resolver_selection.erase("box_id")
	return ReferenceEquipmentRewardResolver.finalize(
		get_equipment_options(box_id),
		resolver_selection,
		stats,
	)
