class_name ArtCatalog
extends RefCounted
## Single lookup for original Cinderwild art by stable asset ID (AGENTS.md: reference assets by
## ID, not path). Every ID here has an `original` record in docs/architecture/asset-manifest.json.
##
##   ui.icon.<name>          16×16 icons            → texture(id, scale)
##   ui.panel.* / ui.button.* / ui.tab.* / ui.frame.*   9-slice styles → stylebox(id), nine_patch(id)
##   ui.joystick.ring/handle textures               → texture(id)

const ICON_PREFIX := "ui.icon."


static func all_ids() -> Array:
	var ids: Array = []
	for name: String in UiIcons.names():
		ids.append(ICON_PREFIX + name)
	ids.append_array(UiKit.style_ids())
	ids.append_array(UiKit.texture_ids())
	return ids


static func has(id: String) -> bool:
	return all_ids().has(id)


static func texture(id: String, scale: int = 1) -> Texture2D:
	if id.begins_with(ICON_PREFIX):
		return UiIcons.texture(id.trim_prefix(ICON_PREFIX), scale)
	var tex := UiKit.texture(id)
	if tex == null:
		push_warning("[ArtCatalog] unknown texture id: %s" % id)
	return tex


static func stylebox(id: String) -> StyleBox:
	var sb := UiKit.stylebox(id)
	if sb == null:
		push_warning("[ArtCatalog] unknown style id: %s" % id)
	return sb


static func nine_patch(id: String) -> Dictionary:
	return UiKit.nine_patch(id)
