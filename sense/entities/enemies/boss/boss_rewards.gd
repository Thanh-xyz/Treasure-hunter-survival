class_name BossRewards
extends RefCounted
## Boss reward split (brainstorm sheet 06 §8). Pure.
##   participation: every participant who dealt >= min_contribution of max HP
##   final hit:     one extra roll for the killer (not the whole loot)
##   contribution:  one roll with probability share × contribution_roll_scale (capped at 1)
## Standing near the boss without dealing damage earns nothing.


## contributions: participant id -> damage dealt. Returns participant id -> Array of
## {"item_id", "quantity"}; participants below the threshold are absent.
static func compute(boss_id: String, contributions: Dictionary, max_hp: int, killer: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var tables: Dictionary = BossCatalog.boss(boss_id).get("rewards", {})
	var min_share := float(BossCatalog.data().get("min_contribution", 0.02))
	var scale := float(BossCatalog.data().get("contribution_roll_scale", 1.5))
	var total := 0.0
	for who: Variant in contributions:
		total += maxf(float(contributions[who]), 0.0)
	var out := {}
	for who: Variant in contributions:
		var dealt := float(contributions[who])
		if dealt < float(max_hp) * min_share:
			continue
		var rewards: Array = []
		_roll_into(rewards, str(tables.get("participation", "")), rng)
		if who == killer:
			_roll_into(rewards, str(tables.get("final_hit", "")), rng)
		var share := dealt / maxf(total, 1.0)
		if rng.randf() < minf(share * scale, 1.0):
			_roll_into(rewards, str(tables.get("contribution", "")), rng)
		out[who] = rewards
	return out


static func _roll_into(rewards: Array, table_id: String, rng: RandomNumberGenerator) -> void:
	var r := LootTableData.roll(table_id, rng)
	if not r.is_empty():
		rewards.append(r)
