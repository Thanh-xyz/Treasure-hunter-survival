class_name RewardBoxResolver
extends RefCounted

## Resolves one guaranteed weighted reward without mutating gameplay state.
## Callers own the RNG so offline and future host-authoritative flows can replay rolls.

const REWARD_KEYS := [&"xp", &"gold", &"diamonds", &"items"]


static func resolve(entries: Array, rng: RandomNumberGenerator) -> Dictionary:
	if rng == null or entries.is_empty():
		return {}
	var normalized_entries := _normalize_entries(entries)
	if normalized_entries.is_empty():
		return {}
	var total_weight := _total_weight(normalized_entries)
	return _select(normalized_entries, rng.randi_range(1, total_weight))


## Resolves a recorded 1-based roll. Useful for exact boundary tests and replay tools.
static func resolve_roll(entries: Array, roll: int) -> Dictionary:
	var normalized_entries := _normalize_entries(entries)
	var total_weight := _total_weight(normalized_entries)
	if roll < 1 or roll > total_weight:
		return {}
	return _select(normalized_entries, roll)


static func _normalize_entries(entries: Array) -> Array[Dictionary]:
	var normalized_entries: Array[Dictionary] = []
	for value: Variant in entries:
		if not value is Dictionary:
			return []
		var entry := value as Dictionary
		var weight := _positive_integer(entry.get("weight"))
		if weight <= 0 or not entry.get("reward") is Dictionary:
			return []
		var reward := _normalize_reward(entry["reward"])
		if reward.is_empty():
			return []
		normalized_entries.append({"weight": weight, "reward": reward})
	return normalized_entries


static func _total_weight(entries: Array[Dictionary]) -> int:
	var total := 0
	for entry: Dictionary in entries:
		total += int(entry["weight"])
	return total


static func _select(entries: Array[Dictionary], roll: int) -> Dictionary:
	for entry: Dictionary in entries:
		roll -= int(entry["weight"])
		if roll <= 0:
			return (entry["reward"] as Dictionary).duplicate(true)
	return {}


static func _normalize_reward(reward: Dictionary) -> Dictionary:
	var normalized := {}
	for raw_key: Variant in reward:
		if not raw_key is String and not raw_key is StringName:
			return {}
		var key := StringName(raw_key)
		if key not in REWARD_KEYS:
			return {}
		if key == &"items":
			if not reward[raw_key] is Dictionary:
				return {}
			var items := _normalize_items(reward[raw_key])
			if items.is_empty() and not (reward[raw_key] as Dictionary).is_empty():
				return {}
			if not items.is_empty():
				normalized["items"] = items
			continue
		var amount := _non_negative_integer(reward[raw_key])
		if amount < 0:
			return {}
		if amount > 0:
			normalized[String(key)] = amount
	return normalized


static func _normalize_items(raw_items: Dictionary) -> Dictionary:
	var items := {}
	for raw_item_id: Variant in raw_items:
		if not raw_item_id is String and not raw_item_id is StringName:
			return {}
		var item_id := String(raw_item_id)
		var quantity := _positive_integer(raw_items[raw_item_id])
		if item_id.is_empty() or quantity <= 0 or ItemDatabase.get_item(item_id) == null:
			return {}
		items[item_id] = quantity
	return items


static func _positive_integer(value: Variant) -> int:
	var parsed := _whole_integer(value)
	return parsed if parsed > 0 else -1


static func _non_negative_integer(value: Variant) -> int:
	var parsed := _whole_integer(value)
	return parsed if parsed >= 0 else -1


static func _whole_integer(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return -1
