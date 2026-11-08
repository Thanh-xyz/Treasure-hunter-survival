class_name EquipmentCatalog
extends RefCounted
## Equipment templates from res://data/equipment/templates.json. A template names an item and
## places it in the balance tables (slot, line, rarity). Its stats come from EquipmentBalance,
## so new items never need code.

const TEMPLATES_PATH := "res://data/equipment/templates.json"

static var _templates: Dictionary = {}   # id -> template
static var _order: Array = []


static func _ensure() -> void:
	if not _templates.is_empty():
		return
	var parsed: Variant = null
	var res := load(TEMPLATES_PATH)
	if res is JSON:
		parsed = (res as JSON).data
	else:
		parsed = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATES_PATH))
	if not parsed is Dictionary:
		push_error("[EquipmentCatalog] cannot read %s" % TEMPLATES_PATH)
		return
	for template: Dictionary in parsed.get("templates", []):
		var id := str(template.get("id", ""))
		if id.is_empty() or _templates.has(id):
			push_error("[EquipmentCatalog] missing or duplicate id: %s" % id)
			continue
		_templates[id] = template
		_order.append(id)


static func ids() -> Array:
	_ensure()
	return _order.duplicate()


static func has(id: String) -> bool:
	_ensure()
	return _templates.has(id)


static func get_template(id: String) -> Dictionary:
	_ensure()
	return (_templates.get(id, {}) as Dictionary).duplicate(true)


## Stats of template `id` at `level`, honouring an optional `stat_override` block.
static func stats_for(id: String, level: int = 1) -> Dictionary:
	var t := get_template(id)
	if t.is_empty():
		return {}
	if t.get("stat_override") is Dictionary:
		var o: Dictionary = t["stat_override"]
		return {"hp": int(o.get("hp", 0)), "attack": int(o.get("attack", 0)), "move_speed": int(o.get("move_speed", 0))}
	return EquipmentBalance.compute(str(t["slot"]), str(t["line"]), str(t["rarity"]), level)
