class_name WorldProps
extends RefCounted
## Atlas regions inside the existing tileset sheets + helpers to place props.
## Every prop's origin is at its base (feet) so parent y-sorting works.

const PLANT_SHEET := preload("res://assets/tilesets/TX Plant.png")
const PROPS_SHEET := preload("res://assets/tilesets/TX Props.png")
const GRASS_SHEET := preload("res://assets/tilesets/TX Tileset Grass.png")
const STONE_SHEET := preload("res://assets/tilesets/TX Tileset Stone Ground.png")

const REGIONS := {
	"tree_1": ["plant", Rect2(24, 14, 113, 139)],
	"tree_2": ["plant", Rect2(161, 17, 97, 136)],
	"tree_3": ["plant", Rect2(295, 31, 79, 120)],
	"bush_1": ["plant", Rect2(216, 185, 47, 42)],
	"bush_2": ["plant", Rect2(282, 186, 39, 45)],
	"bush_3": ["plant", Rect2(156, 190, 38, 32)],
	"bush_4": ["plant", Rect2(346, 190, 40, 35)],
	"bush_5": ["plant", Rect2(98, 195, 27, 25)],
	"tuft_1": ["plant", Rect2(8, 394, 17, 9)],
	"tuft_2": ["plant", Rect2(41, 394, 16, 10)],
	"tuft_3": ["plant", Rect2(73, 394, 15, 10)],
	"tuft_4": ["plant", Rect2(9, 426, 12, 10)],
	"rock_big": ["props", Rect2(3, 430, 57, 44)],
	"rock_1": ["props", Rect2(162, 482, 27, 27)],
	"rock_2": ["props", Rect2(130, 484, 27, 22)],
	"pebble": ["props", Rect2(68, 487, 24, 19)],
	"chest": ["props", Rect2(96, 30, 32, 31)],
	"barrel": ["props", Rect2(163, 86, 26, 39)],
	"crate": ["props", Rect2(160, 18, 32, 46)],
	"statue": ["props", Rect2(445, 20, 41, 73)],
	"pillar": ["props", Rect2(352, 174, 32, 77)],
	"stone_circle": ["props", Rect2(353, 269, 94, 72)],
	"signpost": ["props", Rect2(99, 160, 27, 32)],
	"grave": ["props", Rect2(225, 239, 30, 41)],
	"pot": ["props", Rect2(165, 217, 21, 34)],
}


static func make_sprite(key: String, scale: float = 1.0) -> Sprite2D:
	var entry: Array = REGIONS.get(key, REGIONS["rock_1"])
	var spr := Sprite2D.new()
	spr.texture = PLANT_SHEET if entry[0] == "plant" else PROPS_SHEET
	spr.region_enabled = true
	var rect: Rect2 = entry[1]
	spr.region_rect = rect
	spr.scale = Vector2(scale, scale)
	spr.position = Vector2(0, -rect.size.y * scale * 0.5 + 2.0)
	return spr


## Static obstacle with a sprite and a small collision footprint at its base.
static func make_obstacle(key: String, scale: float, footprint: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1  # WORLD
	body.collision_mask = 0
	body.add_child(make_sprite(key, scale))
	if footprint != Vector2.ZERO:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint
		shape.shape = rect
		shape.position = Vector2(0, -footprint.y * 0.5)
		body.add_child(shape)
	return body


## Ground TileSet: source 0 = grass sheet, source 1 = stone ground sheet
static func make_ground_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var grass := TileSetAtlasSource.new()
	grass.texture = GRASS_SHEET
	grass.texture_region_size = Vector2i(16, 16)
	for y in range(7):
		for x in range(16):
			grass.create_tile(Vector2i(x, y))
	ts.add_source(grass, 0)
	var stone := TileSetAtlasSource.new()
	stone.texture = STONE_SHEET
	stone.texture_region_size = Vector2i(16, 16)
	stone.create_tile(Vector2i(0, 0))
	ts.add_source(stone, 1)
	return ts
