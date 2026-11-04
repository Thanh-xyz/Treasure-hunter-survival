class_name WorldProps
extends RefCounted
## Atlas regions inside the existing tileset sheets + helpers to place props.
## Every prop's origin is at its base (feet) so parent y-sorting works.

const PLANT_SHEET := preload("res://assets/tilesets/TX Plant.png")
const PROPS_SHEET := preload("res://assets/tilesets/TX Props.png")
const THS_TREE_CLUSTER := preload("res://assets/treasure_hunter/field/tree_cluster.png")
const THS_TREE_MEDIUM := preload("res://assets/treasure_hunter/field/tree_medium.png")
const THS_BUSH := preload("res://assets/treasure_hunter/field/bush.png")
const THS_STUMP := preload("res://assets/treasure_hunter/field/stump.png")
const SOURCE_CAPTURE_SCALE := 0.5

static var _ground_tileset: TileSet = null

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
	var source_texture := _source_texture_for(key)
	if source_texture != null:
		var source_sprite := Sprite2D.new()
		source_sprite.texture = source_texture
		source_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var source_scale := scale * SOURCE_CAPTURE_SCALE * _source_scale_for(key)
		source_sprite.scale = Vector2(source_scale, source_scale)
		source_sprite.position = Vector2(0, -source_texture.get_height() * source_scale * 0.5 + 2.0)
		return source_sprite
	var entry: Array = REGIONS.get(key, REGIONS["rock_1"])
	var spr := Sprite2D.new()
	spr.texture = PLANT_SHEET if entry[0] == "plant" else PROPS_SHEET
	spr.region_enabled = true
	var rect: Rect2 = entry[1]
	spr.region_rect = rect
	var source_scale := scale * _source_scale_for(key)
	spr.scale = Vector2(source_scale, source_scale)
	spr.position = Vector2(0, -rect.size.y * source_scale * 0.5 + 2.0)
	return spr


static func _source_texture_for(key: String) -> Texture2D:
	match key:
		"tree_1", "tree_3":
			return THS_TREE_CLUSTER
		"tree_2":
			return THS_TREE_MEDIUM
		"bush_1", "bush_2", "bush_3", "bush_4", "bush_5":
			return THS_BUSH
		"stump":
			return THS_STUMP
		_:
			return null


static func _source_scale_for(key: String) -> float:
	match key:
		"tree_1", "tree_3":
			return 1.9
		"tree_2":
			return 2.1
		"bush_1", "bush_2", "bush_3", "bush_4", "bush_5":
			return 2.0
		"stump":
			return 0.7
		"rock_big", "rock_1", "rock_2", "pebble":
			return 1.15
		_:
			return 1.0


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


## Clean-room ground atlas. The field source is visually dominated by flat,
## muted grass, so the variants only add a few low-contrast pixel marks.
static func make_ground_tileset() -> TileSet:
	if _ground_tileset != null:
		return _ground_tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var grass := TileSetAtlasSource.new()
	grass.texture = _make_grass_atlas()
	grass.texture_region_size = Vector2i(16, 16)
	for y in range(7):
		for x in range(16):
			grass.create_tile(Vector2i(x, y))
	ts.add_source(grass, 0)
	var stone := TileSetAtlasSource.new()
	stone.texture = _make_road_tile()
	stone.texture_region_size = Vector2i(16, 16)
	stone.create_tile(Vector2i(0, 0))
	ts.add_source(stone, 1)
	_ground_tileset = ts
	return _ground_tileset


static func _make_grass_atlas() -> ImageTexture:
	var image := Image.create(16 * 16, 7 * 16, false, Image.FORMAT_RGBA8)
	var base := Color("3c784a")
	var dark := Color("326c42")
	var light := Color("478454")
	image.fill(base)
	for tile_y in range(7):
		for tile_x in range(16):
			var origin := Vector2i(tile_x * 16, tile_y * 16)
			var variant := tile_y * 16 + tile_x
			# Deterministic, sparse accents keep repetition invisible in motion.
			if variant % 3 == 0:
				image.set_pixelv(origin + Vector2i(3 + variant % 8, 5 + variant % 6), dark)
			if variant % 5 == 0:
				var p := origin + Vector2i(10 - variant % 5, 11 - variant % 4)
				image.set_pixelv(p, light)
				image.set_pixelv(p + Vector2i(1, -1), light)
			if variant % 11 == 0:
				image.set_pixelv(origin + Vector2i(13, 3), dark)
	return ImageTexture.create_from_image(image)


static func _make_road_tile() -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color("756a52"))
	var dark := Color("5e5747")
	var light := Color("8b7d5e")
	for x in range(16):
		image.set_pixel(x, 7, dark)
	image.set_pixel(5, 2, light)
	image.set_pixel(6, 2, light)
	image.set_pixel(12, 11, dark)
	image.set_pixel(3, 13, light)
	return ImageTexture.create_from_image(image)
