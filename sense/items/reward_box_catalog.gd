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
