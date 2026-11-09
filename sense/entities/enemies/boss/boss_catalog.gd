class_name BossCatalog
extends RefCounted
## Boss behaviour, schedule, cards and rewards from res://data/bosses/bosses.json
## (brainstorm sheet 06, plan phase E). Pure data access; stats and art stay in
## GameContent.MONSTERS.

const DATA_PATH := "res://data/bosses/bosses.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func boss(boss_id: String) -> Dictionary:
	return (data().get("bosses", {}) as Dictionary).get(boss_id, {})


static func boss_ids() -> Array:
	return (data().get("bosses", {}) as Dictionary).keys()


static func phases(boss_id: String) -> Array:
	return boss(boss_id).get("phases", [])


## Index of the phase for an HP fraction: the last phase whose threshold is >= hp_frac.
static func phase_index(boss_id: String, hp_frac: float) -> int:
	var index := 0
	var list := phases(boss_id)
	for i in range(list.size()):
		if hp_frac <= float((list[i] as Dictionary).get("hp", 1.0)) + 0.0001:
			index = i
	return index


static func ability(ability_id: String) -> Dictionary:
	return (data().get("abilities", {}) as Dictionary).get(ability_id, {})


static func cards() -> Dictionary:
	return data().get("cards", {})


static func card(card_id: String) -> Dictionary:
	return cards().get(card_id, {})


static func fragments() -> Dictionary:
	return data().get("fragments", {})


## The card a fragment combines into, or "".
static func card_for_fragment(fragment_id: String) -> String:
	for card_id: String in cards():
		if str((cards()[card_id] as Dictionary).get("fragment", "")) == fragment_id:
			return card_id
	return ""


static func validate() -> Array[String]:
	var errors: Array[String] = []
	for boss_id: String in boss_ids():
		if not GameContent.MONSTERS.has(boss_id):
			errors.append("%s has no MONSTERS entry" % boss_id)
		var list := phases(boss_id)
		if list.size() < 2 or list.size() > 3:
			errors.append("%s needs 2-3 phases (sheet 06)" % boss_id)
		var prev := 2.0
		for p: Dictionary in list:
			if float(p.get("hp", 0.0)) >= prev:
				errors.append("%s phase thresholds must fall" % boss_id)
			prev = float(p.get("hp", 0.0))
			for a: String in p.get("abilities", []):
				if ability(a).is_empty():
					errors.append("%s uses unknown ability %s" % [boss_id, a])
				elif a != "summon" and float(ability(a).get("warn", 0.0)) <= 0.0:
					errors.append("ability %s has no warning time" % a)
		for key: String in ["participation", "final_hit", "contribution"]:
			var table := str((boss(boss_id).get("rewards", {}) as Dictionary).get(key, ""))
			if not LootTableData.has_table(table):
				errors.append("%s %s table %s missing" % [boss_id, key, table])
	for slot: Array in (data().get("world_schedule", {}) as Dictionary).get("slots", []):
		if str(boss(str(slot[1])).get("type", "")) != "world":
			errors.append("schedule slot %s is not a world boss" % [slot])
	for card_id: String in cards():
		var c: Dictionary = cards()[card_id]
		if boss(str(c.get("boss", ""))).is_empty():
			errors.append("%s summons unknown boss" % card_id)
		if ItemDatabase.get_item(card_id) == null:
			errors.append("%s has no item" % card_id)
		if c.has("fragment") and ItemDatabase.get_item(str(c["fragment"])) == null:
			errors.append("%s fragment item missing" % card_id)
	return errors
