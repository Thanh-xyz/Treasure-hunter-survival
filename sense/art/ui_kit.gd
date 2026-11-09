class_name UiKit
extends RefCounted
## Original Cinderwild "Ember" UI kit (ART_BIBLE.md §6).
##
## Every panel, button, tab and frame is a tiny ASCII pattern in ArtPalette colours, upscaled by
## UI_PX and used as a 9-slice StyleBoxTexture, so edges stay pixel-crisp at any size.
## Asset IDs are listed in STYLE_IDS / TEXTURE_IDS.

const UI_PX := 3   ## UI units per art pixel (720-wide logical viewport → 240 art px)

## pattern rows, 9-slice margin (art px), alpha for the body key ("" = opaque)
const PATTERNS := {
	"ui.panel.default": {"margin": 2, "body": "d", "alpha": 0.94, "rows": [
		"oooooo", "ommmmo", "omddoo", "omddoo", "oooooo", "oooooo"]},
	"ui.panel.highlight": {"margin": 2, "body": "d", "alpha": 0.94, "rows": [
		"oooooo", "oYYYYo", "oyddyo", "oyddyo", "oyyyyo", "oooooo"]},
	"ui.panel.dark": {"margin": 2, "body": "o", "alpha": 0.86, "rows": [
		"mmmmmm", "mddddm", "mdoodm", "mdoodm", "mddddm", "mmmmmm"]},
	"ui.button.primary": {"margin": 2, "rows": [
		"oooooo", "oYYYYo", "oEEEEo", "oEEEEo", "oeeeeo", "oooooo"]},
	"ui.button.primary.hover": {"margin": 2, "rows": [
		"oooooo", "ozzzzo", "oyyyyo", "oyyyyo", "oeeeeo", "oooooo"]},
	"ui.button.primary.pressed": {"margin": 2, "rows": [
		"oooooo", "oeeeeo", "orrrro", "orrrro", "orrrro", "oooooo"]},
	"ui.button.secondary": {"margin": 2, "rows": [
		"oooooo", "oiiiio", "oFFFFo", "oFFFFo", "offffo", "oooooo"]},
	"ui.button.secondary.hover": {"margin": 2, "rows": [
		"oooooo", "owwwwo", "oiiiio", "oiiiio", "offffo", "oooooo"]},
	"ui.button.secondary.pressed": {"margin": 2, "rows": [
		"oooooo", "offffo", "oFFFFo", "oFFFFo", "oFFFFo", "oooooo"]},
	"ui.button.disabled": {"margin": 2, "rows": [
		"oooooo", "ollllo", "oSSSSo", "oSSSSo", "osssso", "oooooo"]},
	"ui.tab.active": {"margin": 2, "rows": [
		"oooooo", "oyyyyo", "ommmmo", "ommmmo", "ommmmo", "ommmmo"]},
	"ui.tab.inactive": {"margin": 2, "rows": [
		"oooooo", "ommmmo", "oddddo", "oddddo", "oddddo", "oooooo"]},
	"ui.frame.portrait": {"margin": 3, "center": false, "rows": [
		"oooooooo", "oyyyyyyo", "oyooooyo", "oyo..oyo", "oyo..oyo", "oyooooyo", "oyyyyyyo", "oooooooo"]},
	"ui.frame.action": {"margin": 2, "center": false, "rows": [
		"oooooo", "ommmmo", "om..so", "om..so", "osssso", "oooooo"]},
	"ui.frame.hotbar": {"margin": 2, "body": "o", "alpha": 0.78, "rows": [
		"oooooo", "oAAAAo", "oAooAo", "oAooAo", "oAAAAo", "oooooo"]},
}

## Rarity slot frames: one shape per tier so colour isn't the only signal (ART_BIBLE §3).
const RARITY_NAMES := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const RARITY_KEYS := ["l", "v", "F", "P", "y", "E"]

static var _styles: Dictionary = {}
static var _textures: Dictionary = {}


static func style_ids() -> Array:
	var ids: Array = PATTERNS.keys()
	for name: String in RARITY_NAMES:
		ids.append("ui.frame.slot." + name)
	return ids


static func texture_ids() -> Array:
	return ["ui.joystick.ring", "ui.joystick.handle", "ui.title.background", "ui.title.logo"]


static func stylebox(id: String) -> StyleBox:
	if _styles.has(id):
		return _styles[id]
	var spec := _spec(id)
	if spec.is_empty():
		return null
	var tex := _pattern_texture(id, spec)
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m := int(spec["margin"]) * UI_PX
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = m + UI_PX * 2
	sb.content_margin_right = m + UI_PX * 2
	sb.content_margin_top = m + UI_PX
	sb.content_margin_bottom = m + UI_PX
	if id.ends_with(".pressed"):
		sb.content_margin_top += UI_PX
		sb.content_margin_bottom -= UI_PX
	sb.draw_center = bool(spec.get("center", true))
	_styles[id] = sb
	return sb


## The 9-slice source texture and margin (UI units) for NinePatchRect consumers.
static func nine_patch(id: String) -> Dictionary:
	var sb := stylebox(id) as StyleBoxTexture
	if sb == null:
		return {}
	return {"texture": sb.texture, "margin": int(sb.texture_margin_left)}


static func texture(id: String) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var img: Image = null
	match id:
		"ui.joystick.ring":
			img = _circle(32, "o", "m", 0.55, "d", 0.30)
		"ui.joystick.handle":
			img = _circle(14, "o", "E", 1.0, "E", 1.0, "Y")
		"ui.title.background":
			img = TitleArt.background_image()
		"ui.title.logo":
			var logo := TitleArt.logo_image()
			_textures[id] = ImageTexture.create_from_image(ArtPalette.upscale(logo, 10))
			return _textures[id]
		_:
			return null
	var tex := ImageTexture.create_from_image(ArtPalette.upscale(img, UI_PX))
	_textures[id] = tex
	return tex


# --- internals ---------------------------------------------------------------

static func _spec(id: String) -> Dictionary:
	if PATTERNS.has(id):
		return PATTERNS[id]
	if id.begins_with("ui.frame.slot."):
		var tier := RARITY_NAMES.find(id.trim_prefix("ui.frame.slot."))
		if tier >= 0:
			return {"margin": 2, "body": "d", "alpha": 0.9, "rows": _slot_rows(tier)}
	return {}


static func _slot_rows(tier: int) -> Array:
	var c: String = RARITY_KEYS[tier]
	var rows := [
		"oooooooo",
		"o" + c.repeat(6) + "o",
		"o" + c + "dddd" + c + "o",
		"o" + c + "dddd" + c + "o",
		"o" + c + "dddd" + c + "o",
		"o" + c + "dddd" + c + "o",
		"o" + c.repeat(6) + "o",
		"oooooooo",
	]
	match tier:
		1:  # notched corners
			rows[0] = ".oooooo."
			rows[7] = ".oooooo."
		2:  # two-tone double edge
			rows[0] = "ffffffff"
			rows[7] = "ffffffff"
			for y in range(1, 7):
				rows[y] = "f" + rows[y].substr(1, 6) + "f"
		3:  # studded corners
			rows[1] = "oY" + c.repeat(4) + "Yo"
			rows[6] = "oY" + c.repeat(4) + "Yo"
		4, 5:  # flame tips (mythic: brighter studs)
			var tip := "Y" if tier == 4 else "z"
			rows[0] = "o" + tip + "oooo" + tip + "o"
			rows[1] = "o" + tip + c.repeat(4) + tip + "o"
			rows[6] = "o" + tip + c.repeat(4) + tip + "o"
	return rows


static func _pattern_texture(id: String, spec: Dictionary) -> Texture2D:
	var img := ArtPalette.image_from_rows(spec["rows"])
	var body := str(spec.get("body", ""))
	if not body.is_empty():
		var alpha := float(spec.get("alpha", 1.0))
		var body_color := ArtPalette.color(body)
		var m := int(spec["margin"])
		for y in range(m, img.get_height() - m):
			for x in range(m, img.get_width() - m):
				if img.get_pixel(x, y).is_equal_approx(body_color):
					img.set_pixel(x, y, Color(body_color, alpha))
	return ImageTexture.create_from_image(ArtPalette.upscale(img, UI_PX))


## Filled disc with outline; optional top-left highlight key.
static func _circle(diameter: int, outline: String, band: String, band_alpha: float,
		fill: String, fill_alpha: float, highlight: String = "") -> Image:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := diameter / 2.0
	for y in range(diameter):
		for x in range(diameter):
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			if d > r:
				continue
			var key := fill
			var a := fill_alpha
			if d > r - 1.0:
				key = outline
				a = 1.0
			elif d > r - 4.0:
				key = band
				a = band_alpha
			if not highlight.is_empty() and key == fill and x + 0.5 < r and y + 0.5 < r * 0.8 and d < r * 0.55:
				key = highlight
			img.set_pixel(x, y, Color(ArtPalette.color(key), a))
	return img
