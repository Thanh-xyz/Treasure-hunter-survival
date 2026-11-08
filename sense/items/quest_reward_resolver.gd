class_name QuestRewardResolver
extends RefCounted

## Materializes a quest reward before it enters the durable pending-claim
## journal. Random boxes therefore become exact retry-safe reward payloads.


static func resolve(quest: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var direct_reward: Variant = quest.get("reward", {})
	if not direct_reward is Dictionary:
		return {}
	if quest.has("reward_table"):
		var table_id := str(quest["reward_table"])
		if not RewardBoxCatalog.has_table(table_id) or not (direct_reward as Dictionary).is_empty() or rng == null:
			return {}
		return RewardBoxCatalog.resolve(table_id, rng)
	return RewardBoxResolver.normalize_reward(direct_reward)
