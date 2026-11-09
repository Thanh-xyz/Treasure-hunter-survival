class_name WorldBossSchedule
extends RefCounted
## World boss timetable (brainstorm sheet 06 §6): fixed local hours on the host clock, each
## event lasts `duration` seconds, notices before it starts. Pure: pass a datetime dictionary
## (Time.get_datetime_dict_from_system()) so tests can use any clock.

const DAY := 86400


static func config() -> Dictionary:
	return BossCatalog.data().get("world_schedule", {})


static func duration() -> float:
	return float(config().get("duration", 900.0))


## {"active": bool, "boss_id", "zone", "seconds_left", "encounter_id",
##  "next_boss", "next_zone", "seconds_to_next"} for the given local datetime.
static func status_at(dt: Dictionary) -> Dictionary:
	var now := int(dt.get("hour", 0)) * 3600 + int(dt.get("minute", 0)) * 60 + int(dt.get("second", 0))
	var out := {"active": false, "boss_id": "", "zone": "", "seconds_left": 0.0, "encounter_id": "",
		"next_boss": "", "next_zone": "", "seconds_to_next": INF}
	for slot: Array in config().get("slots", []):
		var start := int(slot[0]) * 3600
		var boss_id := str(slot[1])
		var since := now - start
		if since >= 0 and float(since) < duration():
			out["active"] = true
			out["boss_id"] = boss_id
			out["zone"] = str(BossCatalog.boss(boss_id).get("zone", ""))
			out["seconds_left"] = duration() - float(since)
			out["encounter_id"] = "world:%s:%04d-%02d-%02d:%02d" % [boss_id, int(dt.get("year", 0)), int(dt.get("month", 0)), int(dt.get("day", 0)), int(slot[0])]
		var until := posmod(start - now, DAY)
		if until > 0 and float(until) < float(out["seconds_to_next"]):
			out["seconds_to_next"] = float(until)
			out["next_boss"] = boss_id
			out["next_zone"] = str(BossCatalog.boss(boss_id).get("zone", ""))
	return out


static func notices() -> Array:
	return config().get("notices", [])
