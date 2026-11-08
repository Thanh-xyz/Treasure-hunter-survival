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
static var _guest_frames: SpriteFrames = null
static var _guest_portrait: Texture2D = null


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


## Clean-room starter avatar at the source capture's compact world scale.
## The original 96x80 soldier sheet remains in the project for legacy scenes,
## but the survival player uses these editable pixel frames at runtime.
static func make_guest_frames() -> SpriteFrames:
	if _guest_frames != null:
		return _guest_frames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var pal := {
		"#": Color("1f2a22"),
		"s": Color("f2d8b3"),
		"h": Color("f2d8b3"),
		"e": Color("453b38"),
		"t": Color("d9c2a7"),
		"d": Color("705947"),
		"b": Color("453b38"),
	}
	var down_a := [
		".....######.....",
		"...##hhhhhh##...",
		"..#hhhhhhhhhh#..",
		".#hhhhhhhhhhhh#.",
		"#hhhhhhhhhhhhhh#",
		"#hhhhehhhhhehhh#",
		"#hhhhhhhhhhhhhh#",
		".#hhhhhhhhhhhh#.",
		"..##hhhhhhhh##..",
		"....########....",
		".....#tttt#.....",
		"....#tttttt#....",
		"...h#tttttt#h...",
		"...h#tttttt#h...",
		"....#tttttt#....",
		"....#t####t#....",
		"....#dd##dd#....",
		"...##d#..#d##...",
		"...#bb#..#bb#...",
		"...####..####...",
	]
	var down_b := down_a.duplicate()
	down_b[17] = "....#dd##dd#...."
	down_b[18] = "....#bb##bb#...."
	down_b[19] = "....####.####..."
	var up_a := [
		".....######.....",
		"...##hhhhhh##...",
		"..#hhhhhhhhhh#..",
		".#hhhhhhhhhhhh#.",
		"#hhhhhhhhhhhhhh#",
		"#hhhhhhhhhhhhhh#",
		"#hhhhhhhhhhhhhh#",
		".#hhhhhhhhhhhh#.",
		"..##hhhhhhhh##..",
		"....########....",
		".....#tttt#.....",
		"....#tttttt#....",
		"...h#tttttt#h...",
		"...h#tttttt#h...",
		"....#tttttt#....",
		"....#t####t#....",
		"....#dd##dd#....",
		"...##d#..#d##...",
		"...#bb#..#bb#...",
		"...####..####...",
	]
	var up_b := up_a.duplicate()
	up_b[17] = "....#dd##dd#...."
	up_b[18] = "....#bb##bb#...."
	up_b[19] = "....####.####..."
	var side_a := [
		"......#####.....",
		"....##hhhhh#....",
		"...#hhhhhhhh#...",
		"..#hhhhhhhhhh#..",
		"..#hhhhhhhehh#..",
		"..#hhhhhhhhhh#..",
		"...#hhhhhhhhhh#.",
		"....##hhhh##....",
		"......#####.....",
		"......#ttt#.....",
		".....#ttttt#....",
		"....#ttttthh#...",
		".....#ttttth#...",
		".....#ttttt#....",
		"......#tt#......",
		".....#d##d#.....",
		".....#d..#d.....",
		".....#b..#b.....",
		".....##..##.....",
	]
	var side_b := side_a.duplicate()
	side_b[16] = "......#dd#......"
	side_b[17] = "......#bb#......"
	side_b[18] = "......####......"
	var attack_down := down_a.duplicate()
	attack_down[11] = "...h#tttttt#h..."
	attack_down[12] = "..hh#tttttt#hh.."
	attack_down[13] = "...h#tttttt#h..."
	var attack_side := side_a.duplicate()
	attack_side[10] = ".....#ttttthh#.."
	attack_side[11] = "....#ttttthhhh#."
	attack_side[12] = ".....#ttttthh#.."
	var attack_up := up_a.duplicate()
	attack_up[10] = "...hh#tttt#hh..."
	attack_up[11] = "..hh#tttttt#hh.."
	var death := [
		"......................",
		"..........####........",
		"...#######ssss##......",
		".##ttttttssssssss#....",
		"#ttttttttssessess#....",
		"#ttttttttssssssss#....",
		".##dddddd##ssss##.....",
		"...######..####.......",
	]
	_add_frames(frames, "idle_down", [down_a], pal, 2.0, true)
	_add_frames(frames, "idle_up", [up_a], pal, 2.0, true)
	_add_frames(frames, "idle_right", [side_a], pal, 2.0, true)
	_add_frames(frames, "idle_left", [_mirror_rows(side_a)], pal, 2.0, true)
	_add_frames(frames, "move_down", [down_a, down_b], pal, 6.0, true)
	_add_frames(frames, "move_up", [up_a, up_b], pal, 6.0, true)
	_add_frames(frames, "move_right", [side_a, side_b], pal, 6.0, true)
	_add_frames(frames, "move_left", [_mirror_rows(side_a), _mirror_rows(side_b)], pal, 6.0, true)
	for diagonal in ["left_down", "right_down"]:
		_add_frames(frames, "idle_" + diagonal, [down_a], pal, 2.0, true)
		_add_frames(frames, "move_" + diagonal, [down_a, down_b], pal, 6.0, true)
	for diagonal in ["left_up", "right_up"]:
		_add_frames(frames, "idle_" + diagonal, [up_a], pal, 2.0, true)
		_add_frames(frames, "move_" + diagonal, [up_a, up_b], pal, 6.0, true)
	_add_frames(frames, "attack_down", [down_a, attack_down], pal, 8.0, false)
	_add_frames(frames, "attack_up", [up_a, attack_up], pal, 8.0, false)
	_add_frames(frames, "attack_right", [side_a, attack_side], pal, 8.0, false)
	_add_frames(frames, "attack_left", [_mirror_rows(side_a), _mirror_rows(attack_side)], pal, 8.0, false)
	_add_frames(frames, "death", [death], pal, 1.0, false)
	_guest_frames = frames
	return _guest_frames


static func make_guest_portrait() -> Texture2D:
	if _guest_portrait != null:
		return _guest_portrait
	var rows := [
		"........########........",
		".....###hhhhhhhh###.....",
		"...##hhhhhhhhhhhhhh##...",
		"..#hhhhhhhhhhhhhhhhhh#..",
		".#hhhhhhhhhhhhhhhhhhhh#.",
		"#hhhhhhhhhhhhhhhhhhhhhh#",
		"#hhhhhhhhhhhhhhhhhhhhhh#",
		"#hhhhhehhhhhhhhhehhhhhh#",
		"#hhhhhhhhhhhhhhhhhhhhhh#",
		"#hhhhhhhhhhhhhhhhhhhhhh#",
		".#hhhhhhhhhhhhhhhhhhhh#.",
		"..#hhhhhhhhhhhhhhhhhh#..",
		"...##hhhhhhhhhhhhhh##...",
		".....###hhhhhhhh###.....",
		"........########........",
		".........#tttt#.........",
		".......##tttttt##.......",
		".....##tttttttttt##.....",
		"...##tttttttttttttt##...",
		"..#tttttttttttttttttt#..",
		".######################.",
	]
	var canvas: Array = []
	for _i in range(3):
		canvas.append("................................")
	for row: String in rows:
		canvas.append("...." + row + "....")
	while canvas.size() < 32:
		canvas.append("................................")
	_guest_portrait = build(canvas, {
		"#": Color("1f2a22"), "h": Color("f2d8b3"),
		"e": Color("453b38"), "t": Color("d9c2a7"),
	})
	return _guest_portrait


static func _add_frames(frames: SpriteFrames, name: String, variants: Array, palette: Dictionary, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	for rows: Array in variants:
		frames.add_frame(name, build(rows, palette))


static func _mirror_rows(rows: Array) -> Array:
	var mirrored: Array = []
	for raw: Variant in rows:
		var row := String(raw)
		var reversed := ""
		for i in range(row.length() - 1, -1, -1):
			reversed += row[i]
		mirrored.append(reversed)
	return mirrored


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
	# Mossback Tortoise (Normal zone guard, original). ArtPalette colours.
	"mossback": [
		"......oooooooo......",
		"....oovvvVvvvvoo....",
		"...ovvVvvgvvVvvvo...",
		"..ovgvvvvvvvgvvvvo..",
		"..ovvvgvvVvvvvgvvo..",
		".onvvvvvvvvvvvvvvno.",
		"onggggggggggggggnoTo",
		".onnnnnnnnnnnnnnnno.",
		"oTTo.oTTo..oTTo.oTTo",
		"oooo.oooo..oooo.oooo",
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
	"mosquito": [
		"..#.........#.....",
		".#w#.......#w#....",
		"#www#..#..#www#...",
		".#ww###b###ww#....",
		"..###hbbbh###....",
		"....#bbkbb#.......",
		"...##bbbbb##......",
		"..#..#bbb#..#.....",
		".#...#bdb#...#....",
		".....#d#d#........",
		"....#d...d#.......",
		"...#.......#......",
	],
	"snail": [
		"..........#..#....",
		".........#w##w#...",
		".....######bb###..",
		"...##hhhhhhbbbb##.",
		"..#hhbbhhbbhbbbb#.",
		".#hbbhhbbhhbbbbbb#",
		".#hbbbbbbbbbbbbbb#",
		"..#ddddddddddbbb#.",
		"...#############..",
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
	"field_stump": [
		".......########.......",
		".....##hhhhhhhh##.....",
		"....#hhbbbbbbbbhh#....",
		"...#hbbddddddddbbh#...",
		"...#hbddbbbbbbddbh#...",
		"....#hbbbbbbbbbbh#....",
		".....############.....",
		"......#bbbbbbbb#......",
		".....#bbdbbbdbbb#.....",
		".....#bbdbbbdbbb#.....",
		"....#bbbdbbbdbbbb#....",
		"...#bbbbdbbbdbbbbb#...",
		"..#bbbbddbbbddbbbbb#..",
		".##bbbdddbbbdddbbbb##.",
		"#dddddddbbbbbdddddddd#",
		"######################",
	],
	"hud_helmet": [
		"....########....",
		"..##hhhhhhhh##..",
		".#hbbbbbbbbbbh#.",
		"#hbbbbbbbbbbbbh#",
		"#bbbbbbbbbbbbbb#",
		"#bb#############",
		"#bb#..........#.",
		"#bb#..........#.",
		".###..........#.",
		"..############..",
	],
	"hud_heart": [
		"..###....###....",
		".#####..#####...",
		"##############..",
		"##############..",
		".############...",
		"..##########....",
		"...########.....",
		"....######......",
		".....####.......",
		"......##........",
	],
	"hud_sword": [
		".............##.",
		"............#h#.",
		"...........#hh#.",
		"..........#hh#..",
		".........#hh#...",
		"........#hh#....",
		".......#hh#.....",
		"..#...#hh#......",
		".###.#hh#.......",
		"..####h#........",
		"...####.........",
		"..#b##..........",
		".#bb#...........",
		"..##............",
	],
	"hud_boot": [
		"....#####.......",
		"...#bbbbb#......",
		"...#bbbbb#......",
		"...#bbbbb#......",
		"...#bbbbb#......",
		"...#bbbbb###....",
		"...#bbbbbbbb#...",
		"..#bbbbbbbbbb#..",
		".#############..",
	],
	"hud_world": [
		".....######.....",
		"...##hhhhhh##...",
		"..#hhbbb##hhh#..",
		".#hbbbbb#hhhh#..",
		"#hhbbb##hhhhhh#.",
		"#hhhh##hhhbbb##.",
		"#hhh##hhhbbbb##.",
		"#hhhhhbbbbbbbh#.",
		".#hhhhbbbbbbh#..",
		"..#hhhhhhhhhh#..",
		"...##hhhhhh##...",
		".....######.....",
	],
	"hud_coin": [
		".....######.....",
		"...##hhhhhh##...",
		"..#hhbbbbbbhh#..",
		".#hhbbhbbbbhh#..",
		"#hhbbhhhbbbbhh#.",
		"#hhbbbhbbbbbhh#.",
		"#hhbbbhbbbbbhh#.",
		"#hhbbbbhhhbbhh#.",
		".#hhbbbbbbhh#...",
		"..#hhbbbbhh#....",
		"...##hhhh##.....",
		".....####.......",
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
	"mossback": {"o": Color("14101a"), "v": Color("5ea04f"), "V": Color("a3d16b"), "g": Color("356b3c"), "n": Color("6a4426"), "T": Color("9b6a3c")},
	"mushroom": {
		"#": Color("1b1420"), "r": Color("c8413c"), "w": Color("f4f1e8"), "b": Color("e8d7b0"),
		"d": Color("b39a6e"), "k": Color("1b1420"),
	},
	"mosquito": {
		"#": Color("1b1420"), "b": Color("8d9a86"), "h": Color("d7dcc9"),
		"d": Color("4b5548"), "w": Color("d8eee7"), "k": Color("c8413c"),
	},
	"snail": {
		"#": Color("1b1420"), "b": Color("8b69a8"), "h": Color("b899cf"),
		"d": Color("50395f"), "w": Color("e9e3cf"),
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
	"field_stump": {
		"#": Color("251a18"), "b": Color("7a4d2c"), "h": Color("b47b43"),
		"d": Color("4a2b20"),
	},
	"hud_helmet": {"#": Color("1b1420"), "b": Color("9a4e22"), "h": Color("e3a84d")},
	"hud_heart": {"#": Color("8a151a")},
	"hud_sword": {"#": Color("1b1420"), "b": Color("8a4e2e"), "h": Color("d8e1df")},
	"hud_boot": {"#": Color("1b1420"), "b": Color("d7c9aa")},
	"hud_world": {"#": Color("1b1420"), "b": Color("55a94e"), "h": Color("58bde0")},
	"hud_coin": {"#": Color("8a5313"), "b": Color("d99819"), "h": Color("ffd456")},
	"bolt": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("f2c94c")},
	"bolt_enemy": {"#": Color("1b1420"), "b": Color("ffd0d0"), "h": Color("c8413c")},
	"bolt_frost": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("6ab4e8")},
	"bolt_arcane": {"#": Color("1b1420"), "b": Color("ffffff"), "h": Color("b56aff")},
}
