extends Node
## SaveService — versioned local profile save (autoload).
##
## File: user://saves/profile.json (+ .bak of the previous good save).
## Writes are atomic: write .tmp -> move current to .bak -> rename .tmp.
## Autosaves every AUTOSAVE_INTERVAL seconds, on zone change and on app
## pause/close.

signal saved
signal loaded

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
var SAVE_PATH: String = "user://saves/profile.json"  ## tests point this elsewhere
const AUTOSAVE_INTERVAL := 60.0

var _timer: float = 0.0
var enabled: bool = true   ## tests disable autosave


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer += delta
	if _timer >= AUTOSAVE_INTERVAL:
		_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if enabled:
			save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH + ".bak")


# =============================================================================
# SAVE
# =============================================================================

func build_snapshot() -> Dictionary:
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"profile": GameState.to_dict(),
		"quests": QuestService.to_dict(),
		"inventory": {},
		"hp": -1,
	}
	var player := GameState.get_player()
	if player != null:
		var inv: InventoryData = player.get_inventory()
		if inv != null:
			data["inventory"] = serialize_inventory(inv)
		var stats: CharacterStats = player.get("stats")
		if stats != null:
			data["hp"] = stats.current_health
	return data


func save_game() -> bool:
	if not enabled:
		return false
	var data := build_snapshot()
	var json := JSON.stringify(data, "  ")
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("[SaveService] Cannot write %s (err %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	f.store_string(json)
	f.close()
	var abs_save := ProjectSettings.globalize_path(SAVE_PATH)
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_bak := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			DirAccess.remove_absolute(abs_bak)
		DirAccess.rename_absolute(abs_save, abs_bak)
	var err := DirAccess.rename_absolute(abs_tmp, abs_save)
	if err != OK:
		push_warning("[SaveService] rename failed: %d" % err)
		return false
	saved.emit()
	return true


# =============================================================================
# LOAD
# =============================================================================

func read_snapshot() -> Dictionary:
	for path in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary and parsed.has("profile"):
			return _migrate(parsed)
		push_warning("[SaveService] Corrupt save at %s, trying backup" % path)
	return {}


## Upgrade older save formats here when SAVE_VERSION changes.
func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	if v < 1:
		data["version"] = 1
	return data


## Apply a snapshot to the live game. Returns false when there is no save.
func load_game() -> bool:
	var data := read_snapshot()
	if data.is_empty():
		return false
	GameState.from_dict(data.get("profile", {}))
	QuestService.from_dict(data.get("quests", {}))
	var player := GameState.get_player()
	if player != null:
		var inv: InventoryData = player.get_inventory()
		if inv != null and data.has("inventory"):
			deserialize_inventory(inv, data["inventory"])
		if player.has_method("refresh_profile_stats"):
			player.refresh_profile_stats()
		var stats: CharacterStats = player.get("stats")
		var hp := int(data.get("hp", -1))
		if stats != null and hp > 0:
			stats.current_health = hp
	loaded.emit()
	return true


func delete_save() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# =============================================================================
# INVENTORY (DE)SERIALIZATION
# =============================================================================

const EQUIP_SLOTS := ["helmet", "armor", "weapon", "shield", "boots", "accessory_1", "accessory_2"]


func _item_to_dict(item: ItemData, qty: int) -> Dictionary:
	var d := {"id": item.id, "qty": qty}
	if not item.applied_augments.is_empty():
		d["augments"] = item.applied_augments.duplicate()
	return d


func _item_from_dict(d: Dictionary) -> ItemData:
	var id := str(d.get("id", ""))
	var augments: Array = d.get("augments", [])
	if augments.is_empty():
		return ItemDatabase.get_item(id)
	var item: ItemData = ItemDatabase.get_item_copy(id)
	if item != null:
		item.applied_augments.clear()
		for a in augments:
			item.applied_augments.append(str(a))
	return item


func serialize_inventory(inv: InventoryData) -> Dictionary:
	var slots: Array = []
	for slot in inv.inventory_slots:
		if slot.item == null:
			slots.append({})
		else:
			slots.append(_item_to_dict(slot.item, int(slot.quantity)))
	var equipment := {}
	for slot_type in EQUIP_SLOTS:
		var item := inv.get_equipped(slot_type)
		if item != null:
			equipment[slot_type] = _item_to_dict(item, 1)
	return {"gold": inv.gold, "slots": slots, "equipment": equipment}


func deserialize_inventory(inv: InventoryData, d: Dictionary) -> void:
	inv.gold = int(d.get("gold", 0))
	var slots: Array = d.get("slots", [])
	for i in range(inv.inventory_slots.size()):
		var slot: Dictionary = inv.inventory_slots[i]
		slot.item = null
		slot.quantity = 0
		if i < slots.size():
			var sd: Dictionary = slots[i]
			if not sd.is_empty():
				var item := _item_from_dict(sd)
				if item != null:
					slot.item = item
					slot.quantity = int(sd.get("qty", 1))
	var equipment: Dictionary = d.get("equipment", {})
	for slot_type in EQUIP_SLOTS:
		var item: ItemData = null
		if equipment.has(slot_type):
			item = _item_from_dict(equipment[slot_type])
		inv._set_equipped(slot_type, item)
		inv.equipment_changed.emit(slot_type)
	inv.inventory_changed.emit()
