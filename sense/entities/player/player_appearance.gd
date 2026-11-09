class_name PlayerAppearance
extends RefCounted
## The Kindler's look from what is equipped (res://data/player/appearance.json). Pure lookup plus
## a SpriteFrames builder for Ninja Adventure character sheets (64×112: columns down, up, left,
## right; rows 0–3 walk, row 4 attack). Animation names match Player: idle_*, move_*, attack_*,
## including the diagonal keys the player asks for (mapped to the nearest side view).

const DATA_PATH := "res://data/player/appearance.json"
const CHARACTER_DIR := "res://assets/ninja_adventure/Actor/Character/"
const WEAPON_DIR := "res://assets/ninja_adventure/Items/Weapons/"
const COLUMNS := {"down": 0, "up": 1, "left": 2, "right": 3}
const DIAGONALS := {"left_up": "left", "left_down": "left", "right_up": "right", "right_down": "right"}

static var _data: Dictionary = {}
static var _frames_cache: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


## Outfit (character folder) for an equipped armor item, or the default outfit.
static func outfit_for(armor: ItemData) -> String:
	var fallback := str(data().get("default_outfit", "Boy"))
	if armor == null or armor.equipment_line.is_empty():
		return fallback
	var by_rarity: Dictionary = (data().get("outfits", {}) as Dictionary).get(armor.equipment_line, {})
	return str(by_rarity.get(EquipmentBalance.rarity_name(armor.rarity), fallback))


## Weapon art folder for the equipped weapon, or "" when unarmed.
static func weapon_for(weapon: ItemData) -> String:
	if weapon == null or weapon.equipment_line.is_empty():
		return ""
	var by_rarity: Dictionary = (data().get("weapons", {}) as Dictionary).get(weapon.equipment_line, {})
	return str(by_rarity.get(EquipmentBalance.rarity_name(weapon.rarity), ""))


static func outfits() -> Array[String]:
	var out: Array[String] = [str(data().get("default_outfit", "Boy"))]
	for line: String in data().get("outfits", {}):
		for outfit: Variant in (data()["outfits"][line] as Dictionary).values():
			if not str(outfit) in out:
				out.append(str(outfit))
	return out


static func sheet_path(outfit: String) -> String:
	return CHARACTER_DIR + outfit + "/SpriteSheet.png"


static func portrait(outfit: String) -> Texture2D:
	return load(CHARACTER_DIR + outfit + "/Faceset.png") as Texture2D


static func weapon_texture(weapon_art: String) -> Texture2D:
	return load(WEAPON_DIR + weapon_art + "/SpriteInHand.png") as Texture2D if not weapon_art.is_empty() else null


static func frames(outfit: String) -> SpriteFrames:
	if _frames_cache.has(outfit):
		return _frames_cache[outfit]
	var texture := load(sheet_path(outfit)) as Texture2D
	if texture == null:
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var keys: Array = COLUMNS.keys() + DIAGONALS.keys()
	for key: String in keys:
		var col: int = COLUMNS[DIAGONALS.get(key, key)]
		_add(sf, "idle_" + key, texture, [Vector2i(col, 0)], 2.0, true)
		_add(sf, "move_" + key, texture, [Vector2i(col, 0), Vector2i(col, 1), Vector2i(col, 2), Vector2i(col, 3)], 10.0, true)
		_add(sf, "attack_" + key, texture, [Vector2i(col, 4), Vector2i(col, 4)], 6.0, false)
	_add(sf, "death", texture, [Vector2i(0, 0)], 1.0, false)
	_frames_cache[outfit] = sf
	return sf


static func _add(sf: SpriteFrames, anim_name: String, texture: Texture2D, cells: Array, fps: float, loop: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, fps)
	for cell: Vector2i in cells:
		var at := AtlasTexture.new()
		at.atlas = texture
		at.region = Rect2(Vector2(cell * 16), Vector2(16, 16))
		sf.add_frame(anim_name, at)


static func validate() -> Array[String]:
	var errors: Array[String] = []
	for outfit in outfits():
		if not ResourceLoader.exists(sheet_path(outfit)):
			errors.append("outfit %s has no sprite sheet" % outfit)
		if not ResourceLoader.exists(CHARACTER_DIR + outfit + "/Faceset.png"):
			errors.append("outfit %s has no portrait" % outfit)
	for line: String in data().get("weapons", {}):
		for art: Variant in (data()["weapons"][line] as Dictionary).values():
			if not ResourceLoader.exists(WEAPON_DIR + str(art) + "/SpriteInHand.png"):
				errors.append("weapon art %s missing" % art)
	for line: String in ["tank", "damage", "balanced"]:
		for r in EquipmentBalance.rarities():
			if str(((data().get("outfits", {}) as Dictionary).get(line, {}) as Dictionary).get(r, "")).is_empty():
				errors.append("no outfit for %s/%s" % [line, r])
	return errors
