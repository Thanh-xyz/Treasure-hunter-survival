class_name DigTileCatalog
extends RefCounted
## Breakable ground tile types per region from res://data/world/dig_tiles.json
## (brainstorm sheet 08 §4, plan phase A). Pure and deterministic given an RNG.

const DATA_PATH := "res://data/world/dig_tiles.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func region_for_field(field_zone_id: String) -> String:
	return String((data().get("field_regions", {}) as Dictionary).get(field_zone_id, "meadow"))


static func region_tiles(region_id: String) -> Array:
	return ((data().get("regions", {}) as Dictionary).get(region_id, {}) as Dictionary).get("tiles", [])


static func get_tile(tile_id: String) -> Dictionary:
	return (data().get("tiles", {}) as Dictionary).get(tile_id, {})


static func starter_tile() -> String:
	return String(data().get("starter_tile", "soft_soil"))


## Weighted tile choice for one plot in a region.
static func pick_tile(region_id: String, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	for tile_id: String in region_tiles(region_id):
		pool.append({"tile_id": tile_id, "weight": int(get_tile(tile_id).get("weight", 0))})
	var picked := LootTableData.pick(pool, rng)
	return String(picked.get("tile_id", starter_tile()))


## Respawn seconds drawn from the tile's [min, max] range.
static func roll_respawn(tile_id: String, rng: RandomNumberGenerator) -> float:
	var span: Array = get_tile(tile_id).get("respawn", [60, 60])
	return rng.randf_range(float(span[0]), float(span[1]))


static func validate() -> Array[String]:
	var errors: Array[String] = []
	var tiles: Dictionary = data().get("tiles", {})
	for region_id: String in ["meadow", "ash", "snow"]:
		var ids := region_tiles(region_id)
		if ids.size() != 4:
			errors.append("%s: expected 4 tile types, got %d" % [region_id, ids.size()])
		for tile_id: String in ids:
			if not tiles.has(tile_id):
				errors.append("%s: unknown tile %s" % [region_id, tile_id])
	for tile_id: String in tiles:
		var tile: Dictionary = tiles[tile_id]
		if int(tile.get("hits", 0)) < 1:
			errors.append("%s: hits must be >= 1" % tile_id)
		var span: Array = tile.get("respawn", [])
		if span.size() != 2 or float(span[0]) <= 0.0 or float(span[1]) < float(span[0]):
			errors.append("%s: bad respawn range" % tile_id)
		if not LootTableData.has_table(String(tile.get("loot", ""))):
			errors.append("%s: unknown loot table %s" % [tile_id, tile.get("loot", "")])
	if not tiles.has(starter_tile()):
		errors.append("starter tile %s missing" % starter_tile())
	return errors
