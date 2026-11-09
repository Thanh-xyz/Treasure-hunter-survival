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
	# Companions (pets and mounts, plan phase C)
	"actor.monster.ninja.owl": "Monster/Owl/Owl.png",
	"actor.monster.ninja.owl2": "Monster/Owl2/Owl2.png",
	"actor.monster.ninja.axolot": "Monster/Axolot/SpriteSheet.png",
	"actor.monster.ninja.dragon": "Monster/Dragon/SpriteSheet.png",
	"actor.monster.ninja.dragon_yellow": "Monster/DragonYellow/SpriteSheet.png",
	"actor.monster.ninja.kappa_green": "Monster/KappaGreen/SpriteSheet.png",
	"actor.monster.ninja.beast2": "Monster/Beast2/Beast2.png",
	# Phase D roster and mini-bosses
	"actor.monster.ninja.bear": "Monster/Bear/SpriteSheet.png",
	"actor.monster.ninja.spirit": "Monster/Spirit/SpriteSheet.png",
	"actor.monster.ninja.beast": "Monster/Beast/Beast.png",
	"actor.monster.ninja.reptile2": "Monster/Reptile2/Reptile2.png",
	"actor.monster.ninja.panda": "Monster/Panda/SpriteSheet.png",
}

## action -> [file, frame count, seconds, loop]; frame size is shared by the sheet's actions.
const STRIP_SHEETS := {
	# Animal side-view strips (2 frames) used by pets and mounts, plan phase C
	"actor.animal.ninja.dog_orange": {"frame_size": Vector2i(18, 16), "actions": {
		"idle": ["Animal/DogOrange/SpriteSheet.png", 1, 0.5, true],
		"move": ["Animal/DogOrange/SpriteSheet.png", 2, 0.4, true],
		"attack": ["Animal/DogOrange/SpriteSheet.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.dog_white": {"frame_size": Vector2i(18, 17), "actions": {
		"idle": ["Animal/DogBlack/SpriteSheetWhite.png", 1, 0.5, true],
		"move": ["Animal/DogBlack/SpriteSheetWhite.png", 2, 0.4, true],
		"attack": ["Animal/DogBlack/SpriteSheetWhite.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.dog_black": {"frame_size": Vector2i(18, 17), "actions": {
		"idle": ["Animal/DogBlack/SpriteSheet.png", 1, 0.5, true],
		"move": ["Animal/DogBlack/SpriteSheet.png", 2, 0.4, true],
		"attack": ["Animal/DogBlack/SpriteSheet.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.cat_orange": {"frame_size": Vector2i(22, 17), "actions": {
		"idle": ["Animal/CatOrange/SpriteSheet.png", 1, 0.5, true],
		"move": ["Animal/CatOrange/SpriteSheet.png", 2, 0.4, true],
		"attack": ["Animal/CatOrange/SpriteSheet.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.hamster_dark": {"frame_size": Vector2i(15, 14), "actions": {
		"idle": ["Animal/Hamster/SpriteSheetDark.png", 1, 0.5, true],
		"move": ["Animal/Hamster/SpriteSheetDark.png", 2, 0.4, true],
		"attack": ["Animal/Hamster/SpriteSheetDark.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.hamster_brown": {"frame_size": Vector2i(15, 13), "actions": {
		"idle": ["Animal/Hamster/SpriteSheetBrown.png", 1, 0.5, true],
		"move": ["Animal/Hamster/SpriteSheetBrown.png", 2, 0.4, true],
		"attack": ["Animal/Hamster/SpriteSheetBrown.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.hamster_gray": {"frame_size": Vector2i(15, 15), "actions": {
		"idle": ["Animal/Hamster/SpriteSheetGray.png", 1, 0.5, true],
		"move": ["Animal/Hamster/SpriteSheetGray.png", 2, 0.4, true],
		"attack": ["Animal/Hamster/SpriteSheetGray.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.parrot_red": {"frame_size": Vector2i(16, 16), "actions": {
		"idle": ["Animal/Parrot/SpriteSheetRed.png", 1, 0.5, true],
		"move": ["Animal/Parrot/SpriteSheetRed.png", 2, 0.4, true],
		"attack": ["Animal/Parrot/SpriteSheetRed.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.parrot_blue": {"frame_size": Vector2i(16, 16), "actions": {
		"idle": ["Animal/Parrot/SpriteSheetBlue.png", 1, 0.5, true],
		"move": ["Animal/Parrot/SpriteSheetBlue.png", 2, 0.4, true],
		"attack": ["Animal/Parrot/SpriteSheetBlue.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.horse_brown": {"frame_size": Vector2i(23, 16), "actions": {
		"idle": ["Animal/Horse/SpriteSheetBrownSide.png", 1, 0.5, true],
		"move": ["Animal/Horse/SpriteSheetBrownSide.png", 2, 0.4, true],
		"attack": ["Animal/Horse/SpriteSheetBrownSide.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.horse_black": {"frame_size": Vector2i(23, 16), "actions": {
		"idle": ["Animal/Horse/SpriteSheetBlackSide.png", 1, 0.5, true],
		"move": ["Animal/Horse/SpriteSheetBlackSide.png", 2, 0.4, true],
		"attack": ["Animal/Horse/SpriteSheetBlackSide.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.donkey_grey": {"frame_size": Vector2i(23, 16), "actions": {
		"idle": ["Animal/Donkey/SpriteSheeGreySide.png", 1, 0.5, true],
		"move": ["Animal/Donkey/SpriteSheeGreySide.png", 2, 0.4, true],
		"attack": ["Animal/Donkey/SpriteSheeGreySide.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.lion_orange": {"frame_size": Vector2i(30, 16), "actions": {
		"idle": ["Animal/Lion/SpriteSheetOrangeSide.png", 1, 0.5, true],
		"move": ["Animal/Lion/SpriteSheetOrangeSide.png", 2, 0.4, true],
		"attack": ["Animal/Lion/SpriteSheetOrangeSide.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.lion_red": {"frame_size": Vector2i(30, 16), "actions": {
		"idle": ["Animal/Lion/SpriteSheetRedSide.png", 1, 0.5, true],
		"move": ["Animal/Lion/SpriteSheetRedSide.png", 2, 0.4, true],
		"attack": ["Animal/Lion/SpriteSheetRedSide.png", 2, 0.3, true],
	}},
	"actor.animal.ninja.hyena": {"frame_size": Vector2i(14, 13), "actions": {
		"idle": ["Animal/Hyena/SpriteSheet.png", 1, 0.5, true],
		"move": ["Animal/Hyena/SpriteSheet.png", 2, 0.4, true],
		"attack": ["Animal/Hyena/SpriteSheet.png", 2, 0.3, true],
	}},
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
	# Phase E bosses (CC0 Ninja Adventure)
	"actor.boss.ninja.giant_bamboo": {"frame_size": Vector2i(62, 62), "actions": {
		"idle": ["Boss/GiantBamboo/Idle.png", 6, 0.8, true],
		"move": ["Boss/GiantBamboo/Walk.png", 12, 1.0, true],
		"attack": ["Boss/GiantBamboo/Attack.png", 5, 0.5, true],
	}},
	"actor.boss.ninja.squid_red": {"frame_size": Vector2i(76, 79), "actions": {
		"idle": ["Boss/SquidRed/Idle.png", 4, 0.8, true],
		"move": ["Boss/SquidRed/Walk.png", 4, 0.6, true],
		"attack": ["Boss/SquidRed/Attack.png", 6, 0.6, true],
	}},
	"actor.boss.ninja.giant_blue_samurai": {"frame_size": Vector2i(48, 48), "actions": {
		"idle": ["Boss/GiantBlueSamurai/Idle.png", 12, 1.0, true],
		"move": ["Boss/GiantBlueSamurai/Walk.png", 12, 0.8, true],
		"attack": ["Boss/GiantBlueSamurai/Hit.png", 8, 0.5, true],
	}},
	"actor.boss.ninja.tengu_red": {"frame_size": Vector2i(82, 82), "actions": {
		"idle": ["Boss/TenguRed/Idle.png", 6, 0.8, true],
		"move": ["Boss/TenguRed/Walk.png", 10, 0.8, true],
		"attack": ["Boss/TenguRed/Attack.png", 15, 1.0, true],
	}},
	"actor.boss.ninja.demon_cyclop": {"frame_size": Vector2i(50, 50), "actions": {
		"idle": ["Boss/DemonCyclop/Idle.png", 5, 0.8, true],
		"move": ["Boss/DemonCyclop/Walk.png", 6, 0.7, true],
		"attack": ["Boss/DemonCyclop/Hit.png", 3, 0.5, true],
	}},
}


## Sheets from packs whose layout is not a Ninja grid or strip (plan "appearance & art" pass):
## anim -> {"fps", "loop", "frames": [[res path, x, y], ...]}; every frame is frame_size big.
## Gridwright Jam Pack (licence: assets/gridwright/LICENSE.txt), THE PACK (assets/the_pack/READ ME.txt).
const CUSTOM_SHEETS := {
	"actor.boss.gridwright.slime_king": {"frame_size": Vector2i(96, 96), "anims": {
		"idle": {"fps": 8.0, "loop": true, "frames": [["res://assets/gridwright/Bosses/slime_king_normal_right.png", 0, 0], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 96, 0], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 192, 0], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 288, 0], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 384, 0], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 480, 0]]},
		"move": {"fps": 10.0, "loop": true, "frames": [["res://assets/gridwright/Bosses/slime_king_normal_right.png", 0, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 96, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 192, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 288, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 384, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 480, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 576, 96], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 672, 96]]},
		"attack": {"fps": 12.0, "loop": true, "frames": [["res://assets/gridwright/Bosses/slime_king_normal_right.png", 0, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 96, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 192, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 288, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 384, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 480, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 576, 192], ["res://assets/gridwright/Bosses/slime_king_normal_right.png", 672, 192]]},
	}},
	"actor.animal.gridwright.sparrow": {"frame_size": Vector2i(16, 16), "anims": {
		"idle_down": {"fps": 3.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 0, 0], ["res://assets/gridwright/Animals/sparrow.png", 16, 0]]},
		"move_down": {"fps": 10.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 32, 0], ["res://assets/gridwright/Animals/sparrow.png", 48, 0], ["res://assets/gridwright/Animals/sparrow.png", 64, 0], ["res://assets/gridwright/Animals/sparrow.png", 80, 0]]},
		"idle_left": {"fps": 3.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 0, 16], ["res://assets/gridwright/Animals/sparrow.png", 16, 16]]},
		"move_left": {"fps": 10.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 32, 16], ["res://assets/gridwright/Animals/sparrow.png", 48, 16], ["res://assets/gridwright/Animals/sparrow.png", 64, 16], ["res://assets/gridwright/Animals/sparrow.png", 80, 16]]},
		"idle_right": {"fps": 3.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 0, 32], ["res://assets/gridwright/Animals/sparrow.png", 16, 32]]},
		"move_right": {"fps": 10.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 32, 32], ["res://assets/gridwright/Animals/sparrow.png", 48, 32], ["res://assets/gridwright/Animals/sparrow.png", 64, 32], ["res://assets/gridwright/Animals/sparrow.png", 80, 32]]},
		"idle_up": {"fps": 3.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 0, 48], ["res://assets/gridwright/Animals/sparrow.png", 16, 48]]},
		"move_up": {"fps": 10.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 32, 48], ["res://assets/gridwright/Animals/sparrow.png", 48, 48], ["res://assets/gridwright/Animals/sparrow.png", 64, 48], ["res://assets/gridwright/Animals/sparrow.png", 80, 48]]},
		"idle": {"fps": 3.0, "loop": true, "frames": [["res://assets/gridwright/Animals/sparrow.png", 0, 0], ["res://assets/gridwright/Animals/sparrow.png", 16, 0]]},
	}},
	"actor.monster.thepack.tree": {"frame_size": Vector2i(100, 120), "anims": {
		"idle": {"fps": 4.0, "loop": true, "frames": [["res://assets/the_pack/Monsters/Tree/ground Up/09.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/10.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/11.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/10.png", 0, 0]]},
		"move": {"fps": 6.0, "loop": true, "frames": [["res://assets/the_pack/Monsters/Tree/ground Up/09.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/10.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/11.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/ground Up/10.png", 0, 0]]},
		"attack": {"fps": 12.0, "loop": true, "frames": [["res://assets/the_pack/Monsters/Tree/attact/01.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/02.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/03.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/04.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/05.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/06.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/07.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/08.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/09.png", 0, 0], ["res://assets/the_pack/Monsters/Tree/attact/10.png", 0, 0]]},
	}},
}

static var _cache: Dictionary = {}


static func has_asset(asset_id: String) -> bool:
	return GRID_SHEETS.has(asset_id) or STRIP_SHEETS.has(asset_id) or CUSTOM_SHEETS.has(asset_id)


static func asset_ids() -> Array:
	return GRID_SHEETS.keys() + STRIP_SHEETS.keys() + CUSTOM_SHEETS.keys()


## Segmented dragon bosses assembled by DragonVisual: asset id -> pack folder.
const DRAGON_PARTS := {
	"actor.boss.ninja.dragon_green": "Boss/DragonGreen/",
	"actor.boss.ninja.dragon_blue": "Boss/DragonBlue/",
}
const DRAGON_PART_FILES := ["Head.png", "Wing.png", "Body1.png", "Body2.png", "BodyEnd.png"]


## Every texture path the catalog can load (provenance tests read this).
static func texture_paths() -> Array:
	var paths: Array = []
	for folder: String in DRAGON_PARTS.values():
		for f: String in DRAGON_PART_FILES:
			paths.append(NINJA + folder + f)
	for rel: String in GRID_SHEETS.values():
		paths.append(NINJA + rel)
	for sheet: Dictionary in STRIP_SHEETS.values():
		for action: Array in (sheet["actions"] as Dictionary).values():
			if not paths.has(NINJA + str(action[0])):
				paths.append(NINJA + str(action[0]))
	for sheet: Dictionary in CUSTOM_SHEETS.values():
		for anim: Dictionary in (sheet["anims"] as Dictionary).values():
			for frame: Array in anim["frames"]:
				if not paths.has(str(frame[0])):
					paths.append(str(frame[0]))
	return paths


## {"frame_size": Vector2i} plus the source description; empty for unknown IDs.
static func get_definition(asset_id: String) -> Dictionary:
	if GRID_SHEETS.has(asset_id):
		return {"frame_size": Vector2i(16, 16), "texture_path": NINJA + str(GRID_SHEETS[asset_id])}
	if STRIP_SHEETS.has(asset_id):
		return (STRIP_SHEETS[asset_id] as Dictionary).duplicate(true)
	if CUSTOM_SHEETS.has(asset_id):
		return {"frame_size": CUSTOM_SHEETS[asset_id]["frame_size"]}
	return {}


static func get_frames(asset_id: String) -> SpriteFrames:
	if _cache.has(asset_id):
		return _cache[asset_id]
	var frames: SpriteFrames = null
	if GRID_SHEETS.has(asset_id):
		frames = _grid_frames(NINJA + str(GRID_SHEETS[asset_id]))
	elif STRIP_SHEETS.has(asset_id):
		frames = _strip_frames(STRIP_SHEETS[asset_id])
	elif CUSTOM_SHEETS.has(asset_id):
		frames = _custom_frames(CUSTOM_SHEETS[asset_id])
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


static func _custom_frames(sheet: Dictionary) -> SpriteFrames:
	var size: Vector2i = sheet["frame_size"]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name: String in sheet["anims"]:
		var anim: Dictionary = sheet["anims"][anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, bool(anim.get("loop", true)))
		frames.set_animation_speed(anim_name, float(anim.get("fps", 8.0)))
		for frame: Array in anim["frames"]:
			var texture := load(str(frame[0])) as Texture2D
			if texture == null:
				return null
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(Vector2(int(frame[1]), int(frame[2])), Vector2(size))
			frames.add_frame(anim_name, atlas_texture)
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
