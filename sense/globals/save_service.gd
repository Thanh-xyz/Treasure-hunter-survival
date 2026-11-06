extends Node
## SaveService — versioned local profile save (autoload).
##
## File: user://saves/profile.json (+ .bak of the previous good save).
## Writes are atomic: write .tmp -> move current to .bak -> rename .tmp.
## Autosaves every AUTOSAVE_INTERVAL seconds, on zone change and on app
## pause/close.

signal saved
signal loaded

const SAVE_VERSION := 2
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
	if not _validate_snapshot(data):
		push_warning("[SaveService] Refusing to write an invalid snapshot")
		return false
	var json := JSON.stringify(data, "  ")
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("[SaveService] Cannot write %s (err %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	f.store_string(json)
	f.close()
	var written: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp_path))
	if not written is Dictionary or not _validate_snapshot(written):
		push_warning("[SaveService] Temporary save validation failed")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
		return false
	var abs_save := ProjectSettings.globalize_path(SAVE_PATH)
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_bak := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	var moved_current := false
	if FileAccess.file_exists(SAVE_PATH):
		if _is_valid_save_file(SAVE_PATH):
			if FileAccess.file_exists(SAVE_PATH + ".bak"):
				var remove_err := DirAccess.remove_absolute(abs_bak)
				if remove_err != OK:
					push_warning("[SaveService] Cannot rotate backup: %d" % remove_err)
					DirAccess.remove_absolute(abs_tmp)
					return false
			var backup_err := DirAccess.rename_absolute(abs_save, abs_bak)
			if backup_err != OK:
				push_warning("[SaveService] Cannot preserve current save: %d" % backup_err)
				DirAccess.remove_absolute(abs_tmp)
				return false
			moved_current = true
		else:
			var remove_invalid_err := DirAccess.remove_absolute(abs_save)
			if remove_invalid_err != OK:
				push_warning("[SaveService] Cannot replace invalid current save: %d" % remove_invalid_err)
				DirAccess.remove_absolute(abs_tmp)
				return false
	var err := DirAccess.rename_absolute(abs_tmp, abs_save)
	if err != OK:
		push_warning("[SaveService] rename failed: %d" % err)
		if moved_current and FileAccess.file_exists(SAVE_PATH + ".bak"):
			var restore_err := DirAccess.rename_absolute(abs_bak, abs_save)
			if restore_err != OK:
				push_warning("[SaveService] backup restore failed: %d" % restore_err)
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
		if parsed is Dictionary:
			var migrated := _migrate(parsed)
			if not migrated.is_empty() and _validate_snapshot(migrated):
				return migrated
		push_warning("[SaveService] Corrupt save at %s, trying backup" % path)
	return {}


## Upgrade older save formats here when SAVE_VERSION changes.
func _migrate(data: Dictionary) -> Dictionary:
	var raw_version: Variant = data.get("version", 0)
	if not _is_integer(raw_version):
		return {}
	var v := int(raw_version)
	if v < 0 or v > SAVE_VERSION:
		return {}
	if v < 1:
		data["version"] = 1
		v = 1
	if v < 2:
		# Version 2 adds optional per-item enhancement levels. Missing levels are
		# intentionally interpreted as the catalog default (display level 1).
		data["version"] = 2
	return data


func _is_valid_save_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	var migrated := _migrate(parsed)
	return not migrated.is_empty() and _validate_snapshot(migrated)


func _validate_snapshot(data: Dictionary) -> bool:
	if not _is_integer(data.get("version", -1)) or int(data.get("version", -1)) != SAVE_VERSION:
		return false
	if not data.get("profile") is Dictionary:
		return false
	if data.has("quests") and not data["quests"] is Dictionary:
		return false
	if data.has("inventory"):
		if not data["inventory"] is Dictionary or not _validate_inventory(data["inventory"]):
			return false
	if data.has("hp") and (not _is_integer(data["hp"]) or int(data["hp"]) < -1):
		return false
	if data.has("saved_at") and (not _is_number(data["saved_at"]) or float(data["saved_at"]) < 0.0):
		return false
	return _validate_profile(data["profile"]) and _validate_quests(data.get("quests", {}))


func _validate_profile(profile: Dictionary) -> bool:
	if profile.has("level") and (not _is_integer(profile["level"]) or int(profile["level"]) < 1 or int(profile["level"]) > GameContent.MAX_LEVEL):
		return false
	for key in ["xp", "kills_total"]:
		if profile.has(key) and (not _is_integer(profile[key]) or int(profile[key]) < 0):
			return false
	for key in ["heroes", "pets", "mounts", "boss_kills", "settings"]:
		if profile.has(key) and not profile[key] is Dictionary:
			return false
	for key in ["hero_id", "active_pet", "active_mount", "current_zone"]:
		if profile.has(key) and not profile[key] is String:
			return false
	var heroes: Dictionary = profile.get("heroes", {})
	for hero_id: Variant in heroes:
		var hero: Variant = heroes[hero_id]
		if not GameContent.HEROES.has(str(hero_id)) or not hero is Dictionary:
			return false
		if not _is_integer(hero.get("stars", 0)) or int(hero.get("stars", 0)) < 1 or int(hero.get("stars", 0)) > GameContent.HERO_MAX_STARS:
			return false
	if profile.has("hero_id"):
		var selected_hero := str(profile["hero_id"])
		if not GameContent.HEROES.has(selected_hero) or (profile.has("heroes") and not heroes.has(selected_hero)):
			return false
	var pets: Dictionary = profile.get("pets", {})
	for pet_id: Variant in pets:
		var pet: Variant = pets[pet_id]
		if not GameContent.PETS.has(str(pet_id)) or not pet is Dictionary:
			return false
		if not _is_integer(pet.get("level", 0)) or int(pet.get("level", 0)) < 1 or int(pet.get("level", 0)) > GameContent.PET_MAX_LEVEL:
			return false
	if profile.has("active_pet"):
		var active_pet := str(profile["active_pet"])
		if active_pet != "" and not pets.has(active_pet):
			return false
	if profile.has("plots") and not profile["plots"] is Array:
		return false
	if profile.has("plots"):
		if profile["plots"].size() > GameState.PLOT_COUNT:
			return false
		for plot: Variant in profile["plots"]:
			if not plot is Dictionary:
				return false
			if plot.is_empty():
				continue
			if not GameContent.BUILDINGS.has(str(plot.get("id", ""))):
				return false
			if not _is_integer(plot.get("level", 0)) or int(plot.get("level", 0)) < 1 or int(plot.get("level", 0)) > GameContent.BUILDING_MAX_LEVEL:
				return false
			if not _is_number(plot.get("last_collect", 0.0)) or float(plot.get("last_collect", 0.0)) < 0.0:
				return false
	if profile.has("mounts"):
		for mount_id: Variant in profile["mounts"]:
			if not GameContent.MOUNTS.has(str(mount_id)):
				return false
			var mount: Variant = profile["mounts"][mount_id]
			if not mount is Dictionary or not mount.get("skins", []) is Array:
				return false
			var available_skins: Array = GameContent.MOUNTS[str(mount_id)].get("skins", [])
			var owned_skins: Array = mount.get("skins", [])
			if owned_skins.is_empty() or not _is_integer(mount.get("skin", -1)):
				return false
			for skin: Variant in owned_skins:
				if not _is_integer(skin) or int(skin) < 0 or int(skin) >= available_skins.size():
					return false
			if not owned_skins.has(int(mount.get("skin", -1))):
				return false
	if profile.has("active_mount"):
		var active_mount := str(profile["active_mount"])
		if active_mount != "" and not profile.get("mounts", {}).has(active_mount):
			return false
	if profile.has("boss_kills"):
		for monster_id: Variant in profile["boss_kills"]:
			if not monster_id is String or not _is_integer(profile["boss_kills"][monster_id]) or int(profile["boss_kills"][monster_id]) < 0:
				return false
	if profile.has("settings") and not _validate_settings(profile["settings"]):
		return false
	if profile.has("current_zone") and not GameContent.ZONES.has(str(profile["current_zone"])):
		return false
	return true


func _validate_settings(settings: Dictionary) -> bool:
	if settings.has("joystick_opacity") and (not _is_number(settings["joystick_opacity"]) or float(settings["joystick_opacity"]) < 0.0 or float(settings["joystick_opacity"]) > 1.0):
		return false
	for key in ["left_handed", "damage_numbers", "compact_hud"]:
		if settings.has(key) and not settings[key] is bool:
			return false
	if settings.has("max_fps") and (not _is_integer(settings["max_fps"]) or int(settings["max_fps"]) < 30 or int(settings["max_fps"]) > 120):
		return false
	return true


func _validate_quests(quests: Dictionary) -> bool:
	for key in ["main_index", "main_progress"]:
		if quests.has(key) and (not _is_integer(quests[key]) or int(quests[key]) < 0):
			return false
	if quests.has("main_index") and int(quests["main_index"]) > GameContent.MAIN_QUESTS.size():
		return false
	if quests.has("main_ready") and not quests["main_ready"] is bool:
		return false
	if quests.has("daily_date") and not quests["daily_date"] is String:
		return false
	if quests.has("dailies") and not quests["dailies"] is Dictionary:
		return false
	if quests.has("dailies"):
		for quest_id: Variant in quests["dailies"]:
			var state: Variant = quests["dailies"][quest_id]
			if not quest_id is String or not state is Dictionary:
				return false
			if state.has("progress") and (not _is_integer(state["progress"]) or int(state["progress"]) < 0):
				return false
			if state.has("claimed") and not state["claimed"] is bool:
				return false
	return true


func _validate_inventory(data: Dictionary) -> bool:
	if data.has("gold") and (not _is_integer(data["gold"]) or int(data["gold"]) < 0):
		return false
	var slots: Variant = data.get("slots", [])
	if not slots is Array or slots.size() > InventoryData.INVENTORY_SIZE:
		return false
	for entry: Variant in slots:
		if not entry is Dictionary or (not entry.is_empty() and not _validate_item_entry(entry)):
			return false
	var equipment: Variant = data.get("equipment", {})
	if not equipment is Dictionary:
		return false
	for slot_type: Variant in equipment:
		if not EQUIP_SLOTS.has(str(slot_type)):
			return false
		var entry: Variant = equipment[slot_type]
		if not entry is Dictionary or not _validate_item_entry(entry, str(slot_type)):
			return false
	return true


func _validate_item_entry(entry: Dictionary, equipment_slot: String = "") -> bool:
	if not entry.get("id") is String:
		return false
	var item := ItemDatabase.get_item(str(entry.get("id", ""))) as ItemData
	if item == null or not _is_integer(entry.get("qty", 1)):
		return false
	var quantity := int(entry.get("qty", 1))
	if quantity <= 0 or (item.stackable and quantity > item.max_stack) or (not item.stackable and quantity != 1):
		return false
	if equipment_slot != "" and (quantity != 1 or not _item_fits_slot(item, equipment_slot)):
		return false
	var raw_level: Variant = entry.get("level", 1)
	if not _is_integer(raw_level):
		return false
	var level := int(raw_level)
	if level < 1 or level > item.max_upgrade_level:
		return false
	if level > 1 and not item.has_valid_upgrade_configuration():
		return false
	var augments: Variant = entry.get("augments", [])
	if not augments is Array or augments.size() > item.get_augment_slot_count():
		return false
	var active_skills := 0
	for augment_id: Variant in augments:
		if not augment_id is String:
			return false
		var augment := ItemDatabase.get_item(str(augment_id)) as ItemData
		if augment == null or not augment.is_augment():
			return false
		if augment.augment_type == ItemData.AugmentType.ACTIVE_SKILL:
			active_skills += 1
			if active_skills > 1:
				return false
	return true


func _item_fits_slot(item: ItemData, slot_type: String) -> bool:
	match slot_type:
		"helmet": return item.item_type == ItemData.ItemType.HELMET
		"armor": return item.item_type == ItemData.ItemType.ARMOR
		"weapon": return item.item_type == ItemData.ItemType.WEAPON
		"shield": return item.item_type == ItemData.ItemType.SHIELD
		"boots": return item.item_type == ItemData.ItemType.BOOTS
		"accessory_1", "accessory_2": return item.item_type == ItemData.ItemType.ACCESSORY
		_: return false


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _is_integer(value: Variant) -> bool:
	return value is int or (value is float and value == roundf(value))


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
	if item.enhancement_level > 1:
		d["level"] = item.enhancement_level
	if not item.applied_augments.is_empty():
		d["augments"] = item.applied_augments.duplicate()
	return d


func _item_from_dict(d: Dictionary) -> ItemData:
	var id := str(d.get("id", ""))
	var augments: Array = d.get("augments", [])
	var level := int(d.get("level", 1))
	if augments.is_empty() and level == 1:
		return ItemDatabase.get_item(id)
	var item: ItemData = ItemDatabase.get_item_copy(id)
	if item != null:
		item.enhancement_level = level
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


func deserialize_inventory(inv: InventoryData, d: Dictionary) -> bool:
	if inv == null or not _validate_inventory(d):
		return false
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
	return true
