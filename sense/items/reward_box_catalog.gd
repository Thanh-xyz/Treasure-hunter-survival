class_name RewardBoxCatalog
extends RefCounted

## Original Cinderwild reward tables, keyed by stable string IDs. Quest rows name a table with
## `reward_table`; the roll is materialized into the pending-claim journal before it is granted.
## (Replaces the reference game's numeric box IDs, retired in save v6.)

const _TABLES := {
	"starter_weapon": [
		{"weight": 1, "reward": {"items": {"ashwood_blade": 1}}},
		{"weight": 1, "reward": {"items": {"ironbark_cleaver": 1}}},
		{"weight": 1, "reward": {"items": {"ember_dirk": 1}}},
	],
	"diamond_1": [
		{"weight": 100, "reward": {"diamonds": 1}},
	],
	"mossback_bounty": [
		{"weight": 100, "reward": {"gold": 30, "diamonds": 1}},
	],
	"gold_200": [
		{"weight": 100, "reward": {"gold": 200}},
	],
	"smith_kit": [
		{"weight": 100, "reward": {"gold": 50, "items": {"health_potion": 2}}},
	],
}


static func has_table(table_id: String) -> bool:
	return _TABLES.has(table_id)


static func table_ids() -> Array:
	return _TABLES.keys()


static func get_entries(table_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not _TABLES.has(table_id):
		return entries
	for value: Variant in _TABLES[table_id]:
		entries.append((value as Dictionary).duplicate(true))
	return entries


static func resolve(table_id: String, rng: RandomNumberGenerator) -> Dictionary:
	return RewardBoxResolver.resolve(get_entries(table_id), rng)
