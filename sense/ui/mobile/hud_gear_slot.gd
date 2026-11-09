class_name HudGearSlot
extends Button
## One square on the HUD side rails (owner request 2026-11-09): an equipment slot, the pet,
## the mount or the special skill. Shows the equipped thing's icon with a rarity-coloured frame,
## or a faded placeholder when empty.

const SIZE := Vector2(90, 90)

var slot_id: String = ""
var _icon: TextureRect
var _border: Panel
var _caption: Label
var _style := StyleBoxFlat.new()


func setup(id: String, caption: String) -> HudGearSlot:
	slot_id = id
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = SIZE
	size = SIZE
	tooltip_text = caption
	for state in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var background := ColorRect.new()
	background.color = UiTheme.C_PANEL
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_border = Panel.new()
	_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style.bg_color = Color(0, 0, 0, 0)
	_style.set_border_width_all(4)
	_style.set_corner_radius_all(6)
	_border.add_theme_stylebox_override("panel", _style)
	add_child(_border)
	_icon = TextureRect.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 14
	_icon.offset_top = 10
	_icon.offset_right = -14
	_icon.offset_bottom = -22
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_caption = UiTheme.label(caption, 14, UiTheme.C_MUTED)
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -24
	_caption.offset_bottom = -4
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	show_empty()
	return self


func show_item(texture: Texture2D, border: Color, caption: String = "", tint: Color = Color.WHITE) -> void:
	_icon.texture = texture
	_icon.modulate = tint
	_style.border_color = border
	if not caption.is_empty():
		_caption.text = caption
	_caption.add_theme_color_override("font_color", UiTheme.C_TEXT)


func show_empty(caption: String = "", locked: bool = false) -> void:
	_icon.texture = null
	_style.border_color = Color(0.25, 0.25, 0.3) if locked else Color(0.45, 0.42, 0.38)
	if not caption.is_empty():
		_caption.text = caption
	_caption.add_theme_color_override("font_color", UiTheme.C_MUTED)


func icon_texture() -> Texture2D:
	return _icon.texture
