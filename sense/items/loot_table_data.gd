class_name LootTableData
extends RefCounted
## Data-driven weighted loot tables from res://data/world/loot_tables.json (plan phase A).
## Pure: callers pass their own RandomNumberGenerator, so offline play, the LAN
## host and tests roll the same way.

const DATA_PATH := "res://data/world/loot_tables.json"
const CURRENCY_IDS := ["gold", "diamonds"]

static var _tables: Dictionary = {}


static func tables() -> Dictionary:
	if _tables.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_tables = (parsed as Dictionary).get("tables", {})
	return _tables


static func has_table(table_id: String) -> bool:
	return tables().has(table_id)


## Entries as dictionaries: {item_id, weight, min, max}.
static func entries(table_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Array in tables().get(table_id, []):
		result.append({"item_id": String(row[0]), "weight": int(row[1]), "min": int(row[2]), "max": int(row[3])})
	return result


static func is_currency(item_id: String) -> bool:
	return item_id in CURRENCY_IDS


## Picks one entry by weight. Returns {} when the pool is empty or has no weight.
static func pick(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for entry: Dictionary in pool:
		total += maxi(int(entry.get("weight", 0)), 0)
	if total <= 0:
		return {}
	var roll := rng.randi_range(1, total)
	for entry: Dictionary in pool:
		roll -= maxi(int(entry.get("weight", 0)), 0)
		if roll <= 0:
			return entry
	return pool.back()


## One roll: {"item_id": String, "quantity": int}, or {} for an unknown or empty table.
static func roll(table_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var entry := pick(entries(table_id), rng)
	if entry.is_empty():
		return {}
	return {"item_id": entry["item_id"], "quantity": rng.randi_range(int(entry["min"]), int(entry["max"]))}


## Validation for tests and tooling: every row is well-formed and references a known item.
static func validate() -> Array[String]:
	var errors: Array[String] = []
	if tables().is_empty():
		errors.append("no loot tables loaded from %s" % DATA_PATH)
	for table_id: String in tables():
		var rows: Array = tables()[table_id]
		if rows.is_empty():
			errors.append("%s: empty table" % table_id)
		for row: Variant in rows:
			if not (row is Array) or (row as Array).size() != 4:
				errors.append("%s: malformed row %s" % [table_id, row])
				continue
			var item_id := String(row[0])
			if not is_currency(item_id) and ItemDatabase.get_item(item_id) == null:
				errors.append("%s: unknown item %s" % [table_id, item_id])
			if int(row[1]) <= 0:
				errors.append("%s: %s weight must be > 0" % [table_id, item_id])
			if int(row[2]) < 1 or int(row[3]) < int(row[2]):
				errors.append("%s: %s bad quantity range" % [table_id, item_id])
	return errors
