class_name MonsterVisualCatalog
extends RefCounted
## Runtime adapter from stable art IDs to data-driven monster SpriteFrames.
##
## Art comes from the CC0 "Ninja Adventure" pack (assets/ninja_adventure, see its LICENSE.txt).
## Two sheet layouts are described as data:
##   GRID_SHEETS   4×4 sheets of 16 px frames: column = facing (down, up, left, right), row = step
##   STRIP_SHEETS  one horizontal strip per action (bosses), frame size given per sheet
## Animation names follow Monster._play_anim(): idle/move/attack, optionally suffixed _down/_up/...

const NINJA := "res://assets/ninja_adventure/Actor/"
const FACINGS := ["down", "up", "left", "right"]

const GRID_SHEETS := {
	"actor.monster.ninja.slime": "Monster/Slime/Slime.png",
	"actor.monster.ninja.blue_bat": "Monster/BlueBat/SpriteSheet.png",
	"actor.monster.ninja.snake": "Monster/Snake/Snake.png",
	"actor.monster.ninja.mushroom": "Monster/Mushroom/mushroom.png",
	"actor.monster.ninja.flam": "Monster/Flam/SpriteSheet.png",
	"actor.monster.ninja.flam2": "Monster/Flam2/SpriteSheet.png",
	"actor.monster.ninja.skull": "Monster/Skull/SpriteSheet.png",
	"actor.monster.ninja.skull_blue": "Monster/SkullBlue/SpriteSheet.png",
}

## action -> [file, frame count, seconds, loop]; frame size is shared by the sheet's actions.
const STRIP_SHEETS := {
	"actor.monster.ninja.wild_boar": {"frame_size": Vector2i(17, 16), "actions": {
		"idle": ["Animal/WildBoar/SpriteSheet.png", 1, 0.5, true],
		"move": ["Animal/WildBoar/SpriteSheet.png", 2, 0.4, true],
		"attack": ["Animal/WildBoar/SpriteSheet.png", 2, 0.3, true],
	}},
	"actor.boss.ninja.giant_slime": {"frame_size": Vector2i(62, 52), "actions": {
		"idle": ["Boss/GiantSlime/Idle.png", 5, 0.8, true],
		"move": ["Boss/GiantSlime/Idle.png", 5, 0.6, true],
		"attack": ["Boss/GiantSlime/Jump.png", 13, 1.0, true],
		"hit": ["Boss/GiantSlime/Hit.png", 5, 0.4, false],
	}},
	"actor.boss.ninja.giant_spirit": {"frame_size": Vector2i(50, 50), "actions": {
		"idle": ["Boss/GiantSpirit/Idle.png", 5, 0.8, true],
		"move": ["Boss/GiantSpirit/Idle.png", 5, 0.6, true],
		"attack": ["Boss/GiantSpirit/Hit.png", 3, 0.5, true],
	}},
	"actor.boss.ninja.demon_cyclop": {"frame_size": Vector2i(50, 50), "actions": {
		"idle": ["Boss/DemonCyclop/Idle.png", 5, 0.8, true],
		"move": ["Boss/DemonCyclop/Walk.png", 6, 0.7, true],
		"attack": ["Boss/DemonCyclop/Hit.png", 3, 0.5, true],
	}},
}

static var _cache: Dictionary = {}


static func has_asset(asset_id: String) -> bool:
	return GRID_SHEETS.has(asset_id) or STRIP_SHEETS.has(asset_id)


static func asset_ids() -> Array:
	return GRID_SHEETS.keys() + STRIP_SHEETS.keys()


## Every texture path the catalog can load (provenance tests read this).
static func texture_paths() -> Array:
	var paths: Array = []
	for rel: String in GRID_SHEETS.values():
		paths.append(NINJA + rel)
	for sheet: Dictionary in STRIP_SHEETS.values():
		for action: Array in (sheet["actions"] as Dictionary).values():
			if not paths.has(NINJA + str(action[0])):
				paths.append(NINJA + str(action[0]))
	return paths


## {"frame_size": Vector2i} plus the source description; empty for unknown IDs.
static func get_definition(asset_id: String) -> Dictionary:
	if GRID_SHEETS.has(asset_id):
		return {"frame_size": Vector2i(16, 16), "texture_path": NINJA + str(GRID_SHEETS[asset_id])}
	if STRIP_SHEETS.has(asset_id):
		return (STRIP_SHEETS[asset_id] as Dictionary).duplicate(true)
	return {}


static func get_frames(asset_id: String) -> SpriteFrames:
	if _cache.has(asset_id):
		return _cache[asset_id]
	var frames: SpriteFrames = null
	if GRID_SHEETS.has(asset_id):
		frames = _grid_frames(NINJA + str(GRID_SHEETS[asset_id]))
	elif STRIP_SHEETS.has(asset_id):
		frames = _strip_frames(STRIP_SHEETS[asset_id])
	if frames != null:
		_cache[asset_id] = frames
	return frames


static func _grid_frames(path: String) -> SpriteFrames:
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for col in range(FACINGS.size()):
		var facing: String = FACINGS[col]
		_add(frames, "idle_" + facing, texture, Vector2i(16, 16), [Vector2i(col, 0)], 0.5, true)
		_add(frames, "move_" + facing, texture, Vector2i(16, 16),
			[Vector2i(col, 0), Vector2i(col, 1), Vector2i(col, 2), Vector2i(col, 3)], 0.6, true)
		_add(frames, "attack_" + facing, texture, Vector2i(16, 16),
			[Vector2i(col, 1), Vector2i(col, 3)], 0.3, true)
	_add(frames, "idle", texture, Vector2i(16, 16), [Vector2i(0, 0)], 0.5, true)
	return frames


static func _strip_frames(sheet: Dictionary) -> SpriteFrames:
	var frame_size: Vector2i = sheet["frame_size"]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var actions: Dictionary = sheet["actions"]
	for action: String in actions:
		var spec: Array = actions[action]
		var texture := load(NINJA + str(spec[0])) as Texture2D
		if texture == null:
			return null
		var cells: Array = []
		for i in range(int(spec[1])):
			cells.append(Vector2i(i, 0))
		_add(frames, action, texture, frame_size, cells, float(spec[2]), bool(spec[3]))
	return frames


static func _add(frames: SpriteFrames, anim_name: String, texture: Texture2D, frame_size: Vector2i,
		cells: Array, seconds: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, float(cells.size()) / maxf(seconds, 0.01))
	for cell: Vector2i in cells:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(Vector2(cell * frame_size), Vector2(frame_size))
		frames.add_frame(anim_name, atlas_texture)
