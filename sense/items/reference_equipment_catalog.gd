class_name ReferenceEquipmentCatalog
extends RefCounted

## Evidence-backed Treasure Hunter equipment definitions. Materialization accepts
## exact authoritative/replayed stats, including verified zero-valued suppressed stats.

const STAT_KEYS := [&"health", &"damage", &"speed"]
const _CARDS := {
	28: {
		"runtime_item_id": "th_weapon_28",
		"source_name": "Weapons_0",
		"asset_id": "item.weapon.card_28.icon",
		"can_upgrade": true,
		"upgrade_base_cost": 10,
		"upgrade_rate": 1.4,
		"ranges": {
			"health": {"min": 2.0, "max": 20.0},
			"damage": {"min": 5.0, "max": 50.0},
			"speed": {"min": 0.05, "max": 0.1},
		},
	},
	29: {
		"runtime_item_id": "th_weapon_29",
		"source_name": "Weapons_1",
		"asset_id": "item.weapon.card_29.icon",
		"can_upgrade": true,
		"upgrade_base_cost": 10,
		"upgrade_rate": 1.4,
		"ranges": {
			"health": {"min": 20.0, "max": 150.0},
			"damage": {"min": 3.0, "max": 25.0},
			"speed": {"min": 0.05, "max": 1.0},
		},
	},
	30: {
		"runtime_item_id": "th_weapon_30",
		"source_name": "Weapons_2",
		"asset_id": "item.weapon.card_30.icon",
		"can_upgrade": true,
		"upgrade_base_cost": 10,
		"upgrade_rate": 1.4,
		"ranges": {
			"health": {"min": 2.0, "max": 20.0},
			"damage": {"min": 3.0, "max": 35.0},
			"speed": {"min": 0.1, "max": 2.0},
		},
	},
}


static func get_card_ids() -> Array[int]:
	var card_ids: Array[int] = []
	for card_id: int in _CARDS:
		card_ids.append(card_id)
	card_ids.sort()
	return card_ids


static func has_card(card_id: int) -> bool:
	return _CARDS.has(card_id)


static func get_definition(card_id: int) -> Dictionary:
	if not _CARDS.has(card_id):
		return {}
	return (_CARDS[card_id] as Dictionary).duplicate(true)


static func get_runtime_item_id(card_id: int) -> String:
	return str((_CARDS.get(card_id, {}) as Dictionary).get("runtime_item_id", ""))


static func get_card_id_for_runtime_item(item_id: String) -> int:
	for card_id: int in _CARDS:
		if str((_CARDS[card_id] as Dictionary)["runtime_item_id"]) == item_id:
			return card_id
	return -1


static func is_valid_instance_data(item_id: String, card_id: int, asset_id: String, stats: Dictionary) -> bool:
	if not _CARDS.has(card_id):
		return false
	var definition := _CARDS[card_id] as Dictionary
	return (
		str(definition["runtime_item_id"]) == item_id
		and str(definition["asset_id"]) == asset_id
		and is_valid_payload(card_id, stats)
	)


static func is_valid_payload(card_id: int, stats: Dictionary) -> bool:
	return not normalize_payload(card_id, stats).is_empty()


static func normalize_payload(card_id: int, stats: Dictionary) -> Dictionary:
	if not _CARDS.has(card_id) or not ItemData.is_valid_reference_stats(stats):
		return {}
	var ranges: Dictionary = (_CARDS[card_id] as Dictionary)["ranges"]
	var normalized := {}
	var non_zero_count := 0
	for key: StringName in STAT_KEYS:
		var value := float(stats.get(key, stats.get(String(key))))
		if value == 0.0:
			normalized[String(key)] = 0.0
			continue
		var allowed := ranges[String(key)] as Dictionary
		if value < float(allowed["min"]) or value > float(allowed["max"]):
			return {}
		normalized[String(key)] = value
		non_zero_count += 1
	return normalized if non_zero_count > 0 else {}


static func materialize(card_id: int, stats: Dictionary) -> ItemData:
	var normalized_stats := normalize_payload(card_id, stats)
	if normalized_stats.is_empty():
		return null
	var definition := _CARDS[card_id] as Dictionary
	var item := ItemDatabase.get_item_copy(str(definition["runtime_item_id"])) as ItemData
	if item == null or item.item_type != ItemData.ItemType.WEAPON:
		return null
	if not item.set_reference_instance_data(card_id, str(definition["asset_id"]), normalized_stats):
		return null
	return item
