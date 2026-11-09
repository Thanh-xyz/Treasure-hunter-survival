class_name StatusEffects
extends RefCounted
## Timed status effects on a player (plan phase D): burn and poison deal damage per tick,
## slow and freeze reduce move speed. Re-applying keeps the stronger magnitude and the longer
## time left (no stacking). Pure: owned by the local Player and, for remote peers, by the LAN host.

const DATA_PATH := "res://data/combat/statuses.json"
## Frame deltas accumulate float error; a tick due "now" must not slip to the next frame.
const TICK_EPSILON := 0.0001

static var _data: Dictionary = {}

## kind -> {"time": float, "magnitude": float, "tick_left": float}
var active: Dictionary = {}


static func definitions() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = (parsed as Dictionary).get("statuses", {})
	return _data


static func is_known(kind: String) -> bool:
	return definitions().has(kind)


static func color_of(kind: String) -> Color:
	return Color(str((definitions().get(kind, {}) as Dictionary).get("color", "ffffff")))


func apply(kind: String, duration: float, magnitude: float) -> bool:
	if not is_known(kind) or duration <= 0.0 or magnitude <= 0.0:
		return false
	var current: Dictionary = active.get(kind, {})
	var tick := float((definitions()[kind] as Dictionary).get("tick", 0.0))
	active[kind] = {
		"time": maxf(duration, float(current.get("time", 0.0))),
		"magnitude": maxf(magnitude, float(current.get("magnitude", 0.0))),
		"tick_left": float(current.get("tick_left", tick)),
	}
	return true


func has(kind: String) -> bool:
	return active.has(kind)


func clear() -> void:
	active.clear()


## Advance time; returns the damage that ticked this frame (burn + poison).
func tick(delta: float) -> int:
	var damage := 0
	for kind: String in active.keys():
		var e: Dictionary = active[kind]
		var period := float((definitions()[kind] as Dictionary).get("tick", 0.0))
		if period > 0.0:
			e["tick_left"] = float(e["tick_left"]) - delta
			while float(e["tick_left"]) <= TICK_EPSILON and float(e["time"]) > TICK_EPSILON:
				damage += roundi(float(e["magnitude"]))
				e["tick_left"] = float(e["tick_left"]) + period
		e["time"] = float(e["time"]) - delta
		if float(e["time"]) <= TICK_EPSILON:
			active.erase(kind)
	return damage


## 1.0 = normal speed; the strongest of slow / freeze applies, capped per data.
func speed_multiplier() -> float:
	var slow := 0.0
	for kind: String in ["slow", "freeze"]:
		if active.has(kind):
			var cap := float((definitions()[kind] as Dictionary).get("max_slow", 60.0))
			slow = maxf(slow, minf(float(active[kind]["magnitude"]), cap))
	return 1.0 - slow / 100.0
