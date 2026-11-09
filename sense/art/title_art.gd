class_name TitleArt
extends RefCounted
## Original title-screen art: a generated ember-and-ash backdrop and the CINDERWILD pixel logo.
## Every pixel comes from ArtPalette. Asset IDs: ui.title.background, ui.title.logo.

const BG_SIZE := Vector2i(240, 534)   # art pixels; ×3 = 720×1602 UI units

## 5×7 glyphs for the logo (original letterforms).
const GLYPHS := {
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	"N": ["#...#", "##..#", "#.#.#", "#.#.#", "#..##", "#...#", "#...#"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
}
## Logo fill by glyph row: bright gold on top, deep ember below.
const LOGO_ROW_KEYS := ["Y", "Y", "y", "y", "E", "E", "r"]


static func logo_image(text: String = "CINDERWILD") -> Image:
	var w := text.length() * 6 - 1 + 4
	var h := 7 + 4
	var fill := Image.create(w, h, false, Image.FORMAT_RGBA8)
	fill.fill(Color(0, 0, 0, 0))
	var x0 := 2
	for ch in text:
		var glyph: Array = GLYPHS.get(ch, [])
		for gy in range(glyph.size()):
			for gx in range(5):
				if String(glyph[gy])[gx] == "#":
					fill.set_pixel(x0 + gx, 2 + gy, ArtPalette.color(LOGO_ROW_KEYS[gy]))
		x0 += 6
	# Ink outline (8-neighbour) and a 1 px deep-ember drop shadow, drawn under the fill.
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := ArtPalette.color("o")
	var shadow := ArtPalette.color("e")
	for y in range(h):
		for x in range(w):
			if fill.get_pixel(x, y).a == 0.0:
				continue
			for dy in range(-1, 3):
				for dx in range(-1, 3):
					var px := x + dx
					var py := y + dy
					if px < 0 or py < 0 or px >= w or py >= h:
						continue
					var key_color := shadow if (dx == 2 or dy == 2) else ink
					if out.get_pixel(px, py).a == 0.0 or key_color == ink:
						out.set_pixel(px, py, key_color)
	for y in range(h):
		for x in range(w):
			var c := fill.get_pixel(x, y)
			if c.a > 0.0:
				out.set_pixel(x, y, c)
	return out


static func background_image() -> Image:
	var w := BG_SIZE.x
	var h := BG_SIZE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Sky: stepped ink → ash → ember glow bands with checker dither at each boundary.
	var bands := [[0, "o"], [150, "d"], [250, "a"], [305, "A"], [330, "r"]]
	for y in range(h):
		var key := "o"
		var next_key := ""
		for i in range(bands.size()):
			if y >= int(bands[i][0]):
				key = bands[i][1]
				next_key = bands[i + 1][1] if i + 1 < bands.size() else ""
		for x in range(w):
			var k := key
			if not next_key.is_empty():
				var boundary := 0
				for b in bands:
					if int(b[0]) > y:
						boundary = int(b[0])
						break
				if boundary - y <= 6 and (x + y) % 2 == 0 and boundary - y <= 3 + (x % 4):
					k = next_key
			img.set_pixel(x, y, ArtPalette.color(k))
	# Far ash hills, near meadow hills, ground.
	for x in range(w):
		var far := int(332.0 + 14.0 * sin(x * 0.045) + 7.0 * sin(x * 0.13 + 1.7))
		var near := int(372.0 + 18.0 * sin(x * 0.03 + 2.1) + 6.0 * sin(x * 0.11))
		for y in range(far, h):
			img.set_pixel(x, y, ArtPalette.color("m"))
		for y in range(near, h):
			img.set_pixel(x, y, ArtPalette.color("G" if y < near + 3 else "g"))
		for y in range(maxi(near + 40, 420), h):
			img.set_pixel(x, y, ArtPalette.color("G"))
	# Grass tufts and drifting embers (seeded, so the screen is identical every launch).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7_011_2026
	for i in range(140):
		var gx := rng.randi_range(0, w - 1)
		var gy := rng.randi_range(380, h - 2)
		img.set_pixel(gx, gy, ArtPalette.color("v"))
		img.set_pixel(gx, gy - 1, ArtPalette.color("V") if rng.randf() < 0.3 else ArtPalette.color("v"))
	for i in range(90):
		var ex := rng.randi_range(0, w - 1)
		var ey := int(lerpf(40.0, 360.0, sqrt(rng.randf())))
		var key := "Y" if rng.randf() < 0.25 else ("y" if rng.randf() < 0.6 else "E")
		img.set_pixel(ex, ey, ArtPalette.color(key))
		if rng.randf() < 0.35 and ey + 1 < h:
			img.set_pixel(ex, ey + 1, ArtPalette.color("r"))
	return img
