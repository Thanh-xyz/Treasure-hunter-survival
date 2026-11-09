class_name ArtPalette
extends RefCounted
## Cinderwild master palette (docs/design/ART_BIBLE.md §3).
##
## Every original sprite, icon and UI texture uses only these colours. ASCII art in sense/art/
## uses the single-character keys below, so one letter always means the same colour.

const KEYS := {
	# Ink
	"o": Color("14101a"), "d": Color("2a2433"), "m": Color("4a4256"),
	# Stone / ash grey
	"s": Color("6b6470"), "S": Color("8f8994"), "l": Color("b7b2ba"),
	# Snow
	"W": Color("d9e3ec"), "w": Color("f4f7fb"),
	# Frost blue
	"f": Color("2c4a6e"), "F": Color("4f7fae"), "i": Color("8fbde0"),
	# Meadow green
	"G": Color("1f3d2b"), "g": Color("356b3c"), "v": Color("5ea04f"), "V": Color("a3d16b"),
	# Earth brown
	"b": Color("3b2618"), "n": Color("6a4426"), "t": Color("9b6a3c"), "T": Color("c99b62"),
	# Ember (signature)
	"e": Color("5c1f17"), "r": Color("a3361f"), "E": Color("e0612a"), "y": Color("f59e3b"), "Y": Color("ffd36b"),
	# Ash-ember accent
	"a": Color("3a2a2a"), "A": Color("7a4a3a"),
	# Poison / arcane
	"p": Color("4b2a6e"), "P": Color("8a5ac8"),
	# Life red, gold
	"R": Color("b8263b"), "z": Color("ffe9a8"),
}

const RARITY := [
	Color("b7b2ba"),  # Common
	Color("5ea04f"),  # Uncommon
	Color("4f7fae"),  # Rare
	Color("8a5ac8"),  # Epic
	Color("f59e3b"),  # Legendary
	Color("e0612a"),  # Mythic
]


static func color(key: String) -> Color:
	return KEYS.get(key, Color.MAGENTA)


## True when `c` is a palette colour (alpha ignored), used by tests to enforce the art bible.
static func contains(c: Color) -> bool:
	for value: Color in KEYS.values():
		if is_equal_approx(value.r, c.r) and is_equal_approx(value.g, c.g) and is_equal_approx(value.b, c.b):
			return true
	return false


## Renders ASCII rows with the master palette. '.' and ' ' are transparent.
static func image_from_rows(rows: Array) -> Image:
	var height := rows.size()
	var width := 1
	for row: String in rows:
		width = maxi(width, row.length())
	var img := Image.create(width, maxi(height, 1), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(height):
		var row: String = rows[y]
		for x in range(row.length()):
			var key := row[x]
			if key == "." or key == " ":
				continue
			img.set_pixel(x, y, color(key))
	return img


## Nearest-neighbour integer upscale (keeps pixels crisp at UI size).
static func upscale(img: Image, factor: int) -> Image:
	var out := img.duplicate() as Image
	out.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return out
