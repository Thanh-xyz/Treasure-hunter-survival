extends Node
## Original art catalog checks: every ID builds, icons follow the art bible size, every pixel uses
## the master palette, and every ID has an `original` provenance record.

const MANIFEST_PATH := "res://docs/architecture/asset-manifest.json"

var _failures: Array[String] = []


func _ready() -> void:
	var manifest := _manifest_statuses()
	for id: String in ArtCatalog.all_ids():
		var img := _image_for(id)
		if img == null:
			_fail("%s did not build" % id)
			continue
		if id.begins_with(ArtCatalog.ICON_PREFIX):
			_check(img.get_width() == UiIcons.SIZE and img.get_height() == UiIcons.SIZE,
				"%s is %dx%d, expected 16x16" % [id, img.get_width(), img.get_height()])
		_check_palette(id, img)
		_check(manifest.get(id, "") == "original", "%s has no `original` manifest record" % id)
	_check(ArtCatalog.texture("ui.icon.gold", 3).get_width() == UiIcons.SIZE * 3, "icon scaling broken")
	_check(not ArtCatalog.has("ui.icon.__missing__"), "unknown id reported as present")
	var sb := ArtCatalog.stylebox("ui.button.primary") as StyleBoxTexture
	_check(sb != null and sb.texture_margin_left == 2 * UiKit.UI_PX, "button 9-slice margin")
	_finish()


func _image_for(id: String) -> Image:
	if id.begins_with(ArtCatalog.ICON_PREFIX) or id in UiKit.texture_ids():
		var tex := ArtCatalog.texture(id)
		return tex.get_image() if tex != null else null
	var sb := ArtCatalog.stylebox(id) as StyleBoxTexture
	return sb.texture.get_image() if sb != null and sb.texture != null else null


func _check_palette(id: String, img: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and not ArtPalette.contains(c):
				_fail("%s uses off-palette colour %s at %d,%d" % [id, c.to_html(false), x, y])
				return


func _manifest_statuses() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	var out := {}
	if parsed is Dictionary:
		for record: Dictionary in parsed.get("assets", []):
			out[str(record.get("asset_id", ""))] = str((record.get("provenance", {}) as Dictionary).get("status", ""))
	return out


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("[ART CATALOG TEST] " + message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ART CATALOG TEST] ALL PASSED (%d ids)" % ArtCatalog.all_ids().size())
		get_tree().quit(0)
	else:
		print("[ART CATALOG TEST] %d FAILED" % _failures.size())
		get_tree().quit(1)
