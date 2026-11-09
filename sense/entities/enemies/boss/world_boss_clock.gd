class_name WorldBossClock
extends Node
## Announces world bosses to the player wherever they are (sheet 06 §6.1): a notice 5 and 1
## minutes before the slot and when the boss rises. Owned by Main; pure timetable in
## WorldBossSchedule.

var clock_override: Dictionary = {}
var _announced: Dictionary = {}
var _t: float = 0.0


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 1.0
	check(clock_override if not clock_override.is_empty() else Time.get_datetime_dict_from_system())


## Returns the messages emitted this tick (tests read them).
func check(dt: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var status := WorldBossSchedule.status_at(dt)
	if bool(status["active"]):
		var key := "up:" + str(status["encounter_id"])
		if not _announced.has(key):
			_announced[key] = true
			out.append("World boss %s has risen at the %s altar!" % [_name(status["boss_id"]), _zone(status["zone"])])
	for notice: Variant in WorldBossSchedule.notices():
		var lead := float(notice)
		var to_next := float(status["seconds_to_next"])
		if to_next <= lead and to_next > lead - 1.5:
			var key := "pre:%s:%d:%d" % [status["next_boss"], int(dt.get("hour", 0)), int(lead)]
			if not _announced.has(key):
				_announced[key] = true
				out.append("%s rises at the %s altar in %d min." % [_name(status["next_boss"]), _zone(status["next_zone"]), roundi(lead / 60.0)])
	for msg in out:
		GameEvent.toast.emit(msg, Color(1.0, 0.55, 0.35))
	return out


func _name(boss_id: Variant) -> String:
	return str(GameContent.MONSTERS.get(str(boss_id), {}).get("name", boss_id))


func _zone(zone_id: Variant) -> String:
	return str(GameContent.ZONES.get(str(zone_id), {}).get("name", zone_id))
