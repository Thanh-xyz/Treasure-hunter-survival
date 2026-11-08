class_name CharacterStatCalculator
extends RefCounted
## Pure character stat totals (EQUIPMENT_SYSTEM_PROPOSAL.md §5).
##
##   final.hp         = base.hp         + Σ equipped.hp         + Σ stones.hp
##   final.attack     = base.attack     + Σ equipped.attack     + Σ stones.attack
##   final.move_speed = base.move_speed + min(Σ equipped.move_speed, cap) + Σ stones.move_speed
##   final.defense    = base.defense                            + Σ stones.defense
##
## Totals are always recomputed from the current equipped set, never incremented, so equipping
## and unequipping any number of times can't double count.

const KEYS := ["hp", "attack", "move_speed", "defense"]


## `equipped`: slot -> stat block. `stones`: array of stat blocks from socketed stones.
static func compute(base: Dictionary, equipped: Dictionary, stones: Array = []) -> Dictionary:
	var total := {}
	for key: String in KEYS:
		total[key] = int(base.get(key, 0))
	var equipment_speed := 0
	for slot: String in equipped:
		var block: Dictionary = equipped[slot]
		total["hp"] += int(block.get("hp", 0))
		total["attack"] += int(block.get("attack", 0))
		equipment_speed += int(block.get("move_speed", 0))
	var cap := EquipmentBalance.max_equipment_move_speed()
	if cap > 0:
		equipment_speed = mini(equipment_speed, cap)
	total["move_speed"] += equipment_speed
	for stone: Dictionary in stones:
		for key: String in KEYS:
			total[key] += int(stone.get(key, 0))
	return total


## What happens if `candidate` replaces whatever is in `slot`.
## Returns {"before", "after", "delta"} totals; delta = after − before for every key.
static func preview_swap(base: Dictionary, equipped: Dictionary, slot: String, candidate: Dictionary,
		stones: Array = []) -> Dictionary:
	var before := compute(base, equipped, stones)
	var next := equipped.duplicate(true)
	if candidate.is_empty():
		next.erase(slot)
	else:
		next[slot] = candidate
	var after := compute(base, next, stones)
	var delta := {}
	for key: String in KEYS:
		delta[key] = int(after[key]) - int(before[key])
	return {"before": before, "after": after, "delta": delta}
