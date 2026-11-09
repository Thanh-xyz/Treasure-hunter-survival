extends Node
## Builds a review contact sheet of the original UI kit (icons ×3, every 9-slice style stretched
## to button/panel sizes, rarity frames, joystick). Pure Image composition, so it runs headless.
##   godot --headless --path . res://tests/RenderArtSheet.tscn -- --output=/tmp/art_sheet.png

const BG := Color("1c1822")
const PAD := 12

var _output := "user://art_sheet.png"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
	var sheet := Image.create(720, 1100, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	var y := PAD
	# Icons at 3× in rows of 8, on light and dark tiles.
	var x := PAD
	for name: String in UiIcons.names():
		var icon := UiIcons.texture(name, 3).get_image()
		_blit(sheet, icon, Vector2i(x, y))
		x += 48 + PAD
		if x + 48 > 720 - PAD:
			x = PAD
			y += 48 + PAD
	y += 48 + PAD * 2
	# 9-slice styles stretched to realistic sizes.
	x = PAD
	for id: String in UiKit.style_ids():
		var size := Vector2i(210, 60)
		if id.begins_with("ui.panel") or id == "ui.frame.hotbar":
			size = Vector2i(210, 120)
		elif id.begins_with("ui.frame.slot") or id == "ui.frame.portrait":
			size = Vector2i(72, 72)
		if x + size.x > 720 - PAD:
			x = PAD
			y += 120 + PAD
		var np := UiKit.nine_patch(id)
		_blit(sheet, _nine_slice(np["texture"].get_image(), int(np["margin"]), size), Vector2i(x, y))
		x += size.x + PAD
	y += 120 + PAD
	x = PAD
	for id: String in UiKit.texture_ids():
		_blit(sheet, UiKit.texture(id).get_image(), Vector2i(x, y))
		x += UiKit.texture(id).get_width() + PAD
	var err := sheet.save_png(_output)
	print("[ART SHEET] saved %s (err %d)" % [_output, err])
	get_tree().quit(0 if err == OK else 1)


func _blit(dst: Image, src: Image, at: Vector2i) -> void:
	src.convert(Image.FORMAT_RGBA8)
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)


## Minimal 9-slice: corners copied, edges and centre stretched with nearest-neighbour.
func _nine_slice(src: Image, m: int, size: Vector2i) -> Image:
	src.convert(Image.FORMAT_RGBA8)
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var sw := src.get_width()
	var sh := src.get_height()
	var xs := [0, m, sw - m, sw]
	var ys := [0, m, sh - m, sh]
	var xd := [0, m, size.x - m, size.x]
	var yd := [0, m, size.y - m, size.y]
	for row in range(3):
		for col in range(3):
			var part := src.get_region(Rect2i(xs[col], ys[row], xs[col + 1] - xs[col], ys[row + 1] - ys[row]))
			var w: int = xd[col + 1] - xd[col]
			var h: int = yd[row + 1] - yd[row]
			if w <= 0 or h <= 0 or part.get_width() == 0 or part.get_height() == 0:
				continue
			part.resize(w, h, Image.INTERPOLATE_NEAREST)
			out.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i(xd[col], yd[row]))
	return out
