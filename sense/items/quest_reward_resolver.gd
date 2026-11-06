class_name QuestRewardResolver
extends RefCounted

## Materializes a quest reward before it enters the durable pending-claim
## journal. Random boxes therefore become exact retry-safe reward payloads.


static func resolve(quest: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var direct_reward: Variant = quest.get("reward", {})
	if not direct_reward is Dictionary:
		return {}
	var box_id := _positive_integer(quest.get("reward_box_id", -1))
	if quest.has("reward_box_id"):
		if box_id <= 0 or not (direct_reward as Dictionary).is_empty() or rng == null:
			return {}
		if RewardBoxCatalog.has_box(box_id):
			return RewardBoxCatalog.resolve(box_id, rng)
		if RewardBoxCatalog.has_equipment_box(box_id):
			return RewardBoxCatalog.resolve_common_equipment(box_id, rng)
		return {}
	return RewardBoxResolver.normalize_reward(direct_reward)


static func _positive_integer(value: Variant) -> int:
	if value is int:
		return value if value > 0 else -1
	if value is float and is_finite(value) and value == floor(value):
		return int(value) if value > 0 else -1
	return -1
