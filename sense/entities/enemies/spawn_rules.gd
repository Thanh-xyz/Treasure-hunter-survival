class_name SpawnRules
extends RefCounted
## Elite and random mini-boss spawn rules from res://data/monsters/spawn_rules.json
## (brainstorm sheet 05 §6-7, plan phase A). Pure: no scene access.

const DATA_PATH := "res://data/monsters/spawn_rules.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func elite_chance() -> float:
	return float((data().get("elite", {}) as Dictionary).get("chance", 0.0))


static func elite_cap() -> int:
	return int((data().get("elite", {}) as Dictionary).get("max_alive_per_zone", 0))


## Rolled once per normal spawn, never per frame. Respects the per-zone cap.
static func roll_elite(rng: RandomNumberGenerator, elites_alive: int) -> bool:
	if elites_alive >= elite_cap():
		return false
	return rng.randf() < elite_chance()


static func mini_boss_config() -> Dictionary:
	return data().get("mini_boss", {})


## Per-zone random mini-boss timer. Call tick() from the authority only
## (offline game or LAN host). Returns true when a mini-boss should spawn now.
class MiniBossScheduler:
	extends RefCounted

	var check_interval: float
	var chance: float
	var max_active: int
	var respawn_cooldown: float
	var active: int = 0
	var _until_check: float
	var _cooldown_left: float = 0.0

	func _init(config: Dictionary = SpawnRules.mini_boss_config()) -> void:
		check_interval = float(config.get("check_interval", 600.0))
		chance = float(config.get("chance", 0.0))
		max_active = int(config.get("max_active_per_zone", 1))
		respawn_cooldown = float(config.get("respawn_cooldown", 0.0))
		_until_check = check_interval

	func tick(delta: float, rng: RandomNumberGenerator) -> bool:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
		_until_check -= delta
		if _until_check > 0.0:
			return false
		_until_check += check_interval
		if active >= max_active or _cooldown_left > 0.0:
			return false
		if rng.randf() >= chance:
			return false
		active += 1
		return true

	func on_defeated() -> void:
		active = maxi(active - 1, 0)
		_cooldown_left = respawn_cooldown

	func to_dict() -> Dictionary:
		return {"active": active, "until_check": _until_check, "cooldown_left": _cooldown_left}
