class_name PixelArt
extends RefCounted
## Runtime pixel-art generator.
##
## All new creatures (slimes, bats, boars, pets, mounts) and UI glyphs are
## authored as ASCII sprites below and converted to ImageTexture at runtime.
## This keeps the art original, classic and editable as plain text.
##
## Rules:
##   - '.' or ' ' = transparent
##   - every other char is looked up in the palette (Dictionary char -> Color)
##   - rows shorter than the widest row are padded with transparency

static var _cache: Dictionary = {}


## Build (or fetch cached) texture for sprite `sprite_id` with palette `palette_id`.
static func get_texture(sprite_id: String, palette_id: String = "") -> Texture2D:
	var key := sprite_id + "|" + palette_id
	if _cache.has(key):
		return _cache[key]
	var rows: Array = SPRITES.get(sprite_id, SPRITES["unknown"])
	var pal_key := palette_id if palette_id != "" else sprite_id
	var palette: Dictionary = PALETTES.get(pal_key, PALETTES["unknown"])
	var tex := build(rows, palette)
	_cache[key] = tex
	return tex


static func build(rows: Array, palette: Dictionary) -> ImageTexture:
	var h := rows.size()
	var w := 1
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, maxi(h, 1), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row: String = rows[y]
		for x in range(row.length()):
			var c := row[x]
			if c == "." or c == " ":
				continue
			if palette.has(c):
				img.set_pixel(x, y, palette[c])
			else:
				img.set_pixel(x, y, Color.MAGENTA)
	return ImageTexture.create_from_image(img)


## Shared palette helpers
static func _pal(body: Color, light: Color, dark: Color, extra: Color = Color.WHITE) -> Dictionary:
	return {
		"#": Color("1b1420"),     # outline
		"b": body,
		"h": light,
		"d": dark,
		"x": extra,
		"w": Color("f4f1e8"),     # white (eyes, tusks)
		"k": Color("1b1420"),     # pupil
		"r": Color("c8413c"),     # red accent
		"y": Color("f2c94c"),     # gold accent
	}


const SPRITES := {
	"unknown": [
		"#####",
		"#bbb#",
		"#b#b#",
		"#bbb#",
		"#####",
	],
	# ---------------------------------------------------------------- monsters
	"slime": [
		".....######.....",
		"...##hhhbbb##...",
		"..#hhbbbbbbbb#..",
		".#hbbbbbbbbbbb#.",
		".#bbbwkbbbwkbb#.",
		"#bbbbwkbbbwkbbb#",
		"#bbbbbbbbbbbbbb#",
		"#dbbbbbddbbbbbd#",
		"#ddbbbbbbbbbbdd#",
		".#dddddddddddd#.",
		"..############..",
	],
	"bat": [
		"#..............#",
		"##............##",
		"#h#....##....#h#",
		"#hb#..#bb#..#bh#",
		"#hbb##bbbb##bbh#",
		"#hbbbbwkkwbbbbh#",
		".#hbbbbbbbbbbh#.",
		"..#hbb#ww#bbh#..",
		"...#b#....#b#...",
		"....#......#....",
	],
	"boar": [
		"......########......",
		"....##bbbbbbbb##....",
		"...#hhbbbbbbbbbb#...",
		"..#hbbbbbbbbbbbbb##.",
		".#bbbbbbbbbbbbbbkbb#",
		"#bbbbbbbbbbbbbbbbbbw",
		"#bbbbbbbbbbbbbbbbdd#",
		"#dbbbbbbbbbbbbbbbd#.",
		".#ddbbbbbbbbbbbdd#..",
		"..#dd#.#dd#.#dd#....",
		"..#dd#.#dd#.#dd#....",
		"...##...##...##.....",
	],
	"mushroom": [
		"....########....",
		"..##rrrwwrrr##..",
		".#rrwwrrrrwwrr#.",
		"#rrrrrrrrrrrrrr#",
		"#rwwrrrrrwwrrrr#",
		"################",
		"...#bbbbbbbb#...",
		"...#bwkbbwkb#...",
		"...#bbbbbbbb#...",
		"...#dbbbbbbd#...",
		"....########....",
	],
	# -------------------------------------------------------------------- pets
	"pet_fox": [
		".#......#.....",
		"#h#....#h#....",
		"#bb#..#bb#....",
		"#bbb##bbb#....",
		"#bwkbbwkb#....",
		".#bbbkbbb#..##",
		"..#hwwwh#..#bh#",
		"..#bbbbbb##bbh#",
		"..#bbbbbbbbbb#.",
		"..#b#b##b#b##..",
		"...#.#..#.#....",
	],
	"pet_turtle": [
		"....######......",
		"..##hhbbhh##....",
		".#hbbddbbddb#.##",
		"#bbdbbbbbbdbb#bw#",
		"#bbbbddbbbbbb#xk#",
		"#dbbbbbbbbbbd#xx#",
		".############xx#.",
		".#xx#.....#xx#.#.",
		".####.....####...",
	],
	"pet_owl": [
		".#.....#..",
		"#h#...#h#.",
		"#bbbbbbb#.",
		"#wwbbbww#.",
		"#wkbybkw#.",
		"#bbbybbb#.",
		"#hbbbbbh#.",
		"#hhbbbhh#.",
		".#bdbdb#..",
		"..#y.y#...",
	],
	"pet_cat": [
		"#.....#.....",
		"##...##.....",
		"#b###b#.....",
		"#bbbbb#...#.",
		"#wkbwk#..#b#",
		"#bbrbb#..#b#",
		".#bbb#####b#",
		".#bbbbbbbb#.",
		".#bbbbbbbb#.",
		".#b#b##b#b#.",
		"..#.#..#.#..",
	],
	# ------------------------------------------------------------------ mounts
	"mount_pony": [
		"................##......",
		"...............#hb#.....",
		"..............#bbbb#....",
		"..............#bkbbb#...",
		"..............#bbbbbb#..",
		"..###########dbbb#####..",
		".#hhbbbbbbbbbbbbb#......",
		"#dhbbbbbbbbbbbbbb#......",
		"#d#bbbbbbbbbbbbbb#......",
		"#d#dbbbbbbbbbbbbd#......",
		"..#dd#d#.....#dd#d#.....",
		"..#dd#d#.....#dd#d#.....",
		"..#dd#d#.....#dd#d#.....",
		"..#xx#x#.....#xx#x#.....",
	],
	"mount_stag": [
		"..............#..#......",
		"..............#.#.#.....",
		"...............###......",
		"...............#hb#.....",
		"..............#bbbb#....",
		"..............#bkbbb#...",
		"..............#bbbbbb#..",
		"..###########dbbb#####..",
		".#hhbbwbbbbwbbbbb#......",
		"#dhbbbbbbbbbbbbbb#......",
		"..#bbbbwbbbbbwbbd#......",
		"..#dd#d#.....#dd#d#.....",
		"..#dd#d#.....#dd#d#.....",
		"..#xx#x#.....#xx#x#.....",
	],
	"mount_boar": [
		".........#########......",
		".......##bbbbbbbbb##....",
		"......#hhbbbbbbbbbbb#...",
		".....#hbbbbbbbbbbbbbb##.",
		"....#bbbbbbbbbbbbbbbkbb#",
		"...#bbbbbbbbbbbbbbbbbbbw",
		"...#bbbbbbbbbbbbbbbbbdd#",
		"...#dbbbbbbbbbbbbbbbbd#.",
		"....#ddbbbbbbbbbbbbdd#..",
		".....#dd#..#dd#.#dd#....",
		".....#dd#..#dd#.#dd#....",
		"......##....##...##.....",
	],
	"mount_tortoise": [
		"........##########......",
		"......##hhbbhhbbhh##....",
		".....#hbbddbbddbbddb#...",
		"....#bbdbbbbbbbbbbdbb#..",
		"....#bbbbddbbbbddbbbb####",
		"....#dbbbbbbbbbbbbbbd#xxk#",
		"....##################xxx#",
		".....#xx#........#xx#.###.",
		".....#xx#........#xx#.....",
		".....####........####.....",
	],
	# ------------------------------------------------------------------- props
	"altar": [
		"....########....",
		"..##hhhhhhhh##..",
		".#hbbbbbbbbbbh#.",
		"#hbbrrbbbbrrbbh#",
		"#bbbrrbbbbrrbbb#",
		"#dbbbbbbbbbbbbd#",
		"#ddbbbbbbbbbbdd#",
		".#dddddddddddd#.",
		"..############..",
	],
	"plot": [
		"#..##..##..##..#",
		"................",
		"#..............#",
		"#..............#",
		"................",
		"#..............#",
		"#..............#",
		"................",
		"#..##..##..##..#",
	],
	"bolt": [
		"..##..",
		".#hh#.",
		"#hbbh#",
		"#hbbh#",
		".#hh#.",
		"..##..",
	],
}


const PALETTES := {
	"unknown": {"#": Color.BLACK, "b": Color.MAGENTA},
	# monsters
	"slime": {
		"#": Color("1b1420"), "b": Color("5fbf4a"), "h": Color("a5e86b"), "d": Color("2f7a3a"),
		"w": Color("f4f1e8"), "k": Color("1b1420"),
	},
	"slime_frost": {
		"#": Color("1b1420"), "b": Color("6ab4e8"), "h": Color("c4ecff"), "d": Color("2f5f9a"),
		"w": Color("f4f1e8"), "k": Color("1b1420"),
	},
	"slime_magma": {
		"#": Color("1b1420"), "b": Color("e0662f"), "h": Color("ffc15e"), "d": Color("8a2a1e"),
		"w": Color("fff4c4"), "k": Color("1b1420"),
	},
	"slime_king": {
		"#": Color("1b1420"), "b": Color("8a4fc4"), "h": Color("d3a5ff"), "d": Color("4a2478"),
		"w": Color("f4f1e8"), "k": Color("c8413c"),
	},
	"bat": {
		"#": Color("1b1420"), "b": Color("5a4a78"), "h": Color("8f7ab5"), "d": Color("2b2140"),
		"w": Color("f2c94c"), "k": Color("c8413c"),
	},
	"boar": {
		"#": Color("1b1420"), "b": Color("8a5a3c"), "h": Color("b98563"), "d": Color("4f2f22"),
		"w": Color("f4f1e8"), "k": Color("1b1420"),
	},
	"mushroom": {
		"#": Color("1b1420"), "r": Color("c8413c"), "w": Color("f4f1e8"), "b": Color("e8d7b0"),
		"d": Color("b39a6e"), "k": Color("1b1420"),
	},
	# pets (stage palettes are generated by tint in PetFollower)
	"pet_fox": {
		"#": Color("1b1420"), "b": Color("e0762f"), "h": Color("ffb36b"), "w": Color("f4f1e8"),
		"k": Color("1b1420"), "d": Color("8a3a1e"),
	},
	"pet_turtle": {
		"#": Color("1b1420"), "b": Color("4f8a3c"), "h": Color("8fc46b"), "d": Color("2f5a28"),
		"x": Color("d8c48a"), "w": Color("f4f1e8"), "k": Color("1b1420"),
	},
	"pet_owl": {
		"#": Color("1b1420"), "b": Color("8a6a4c"), "h": Color("c4a67e"), "d": Color("4f3a28"),
		"w": Color("f4f1e8"), "k": Color("1b1420"), "y": Color("f2c94c"),
	},
	"pet_cat": {
		"#": Color("1b1420"), "b": Color("e8d7b0"), "w": Color("6ab4e8"), "k": Color("1b1420"),
		"r": Color("e88a9a"),
	},
	# mounts
	"mount_pony": {
		"#": Color("1b1420"), "b": Color("b98563"), "h": Color("e0b38a"), "d": Color("4f2f22"),
		"k": Color("1b1420"), "x": Color("2b2140"),
	},
	"mount_pony_snow": {
		"#": Color("1b1420"), "b": Color("e8e4dc"), "h": Color("ffffff"), "d": Color("8a8a9a"),
		"k": Color("1b1420"), "x": Color("4a4a5a"),
	},
	"mount_pony_night": {
		"#": Color("0e0a12"), "b": Color("3a3048"), "h": Color("5f5078"), "d": Color("f2c94c"),
		"k": Color("c8413c"), "x": Color("f2c94c"),
	},
	"mount_stag": {
		"#": Color("1b1420"), "b": Color("6a8ab5"), "h": Color("c4dcff"), "d": Color("2f4a78"),
		"w": Color("f4f1e8"), "k": Color("1b1420"), "x": Color("1b1420"),
	},
	"mount_boar": {
		"#": Color("1b1420"), "b": Color("6a3a2c"), "h": Color("a5634c"), "d": Color("3a1e16"),
		"w": Color("f4f1e8"), "k": Color("c8413c"),
	},
	"mount_tortoise": {
		"#": Color("1b1420"), "b": Color("6a7a5a"), "h": Color("a5b58a"), "d": Color("3a4a2f"),
		"x": Color("c4b58a"), "k": Color("1b1420"),
	},
	# props
	"altar": {
		"#": Color("1b1420"), "b": Color("7a7a8a"), "h": Color("b5b5c4"), "d": Color("4a4a5a"),
		"r": Color("c8413c"),
	},
	"plot": {"#": Color(0.95, 0.85, 0.5, 0.8)},
	"bolt": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("f2c94c")},
	"bolt_enemy": {"#": Color("1b1420"), "b": Color("ffd0d0"), "h": Color("c8413c")},
	"bolt_frost": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("6ab4e8")},
	"bolt_arcane": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("b56aff")},
}
