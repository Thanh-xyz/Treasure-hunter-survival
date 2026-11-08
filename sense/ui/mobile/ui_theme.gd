class_name UiTheme
extends RefCounted
## Cinderwild "Ember" theme (docs/design/ART_BIBLE.md §6). Colours come from ArtPalette;
## panels, buttons and tabs use the 9-slice styles from UiKit via ArtCatalog.

const FONT := preload("res://assets/Font/Pixellari.ttf")
const C_PANEL := Color("2a2433f0")        # ink d, 94%
const C_PANEL_LIGHT := Color("14101aef")  # ink o, 94%
const C_TRIM := Color("4a4256")           # ink m
const C_TEXT := Color("f4f7fb")           # snow w
const C_MUTED := Color("b7b2ba")          # grey l
const C_GOOD := Color("a3d16b")           # meadow V
const C_BAD := Color("b8263b")            # life red
const C_GOLD := Color("ffd36b")           # ember Y
const C_STEEL := Color("6b6470")          # grey s

static var _theme: Theme = null


static func box(bg: Color, border: Color, width: int = 3, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.anti_aliasing = false
	return sb


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 22
	t.set_stylebox("panel", "PanelContainer", ArtCatalog.stylebox("ui.panel.default"))
	t.set_stylebox("panel", "Panel", ArtCatalog.stylebox("ui.panel.default"))
	t.set_stylebox("normal", "Button", ArtCatalog.stylebox("ui.button.primary"))
	t.set_stylebox("hover", "Button", ArtCatalog.stylebox("ui.button.primary.hover"))
	t.set_stylebox("pressed", "Button", ArtCatalog.stylebox("ui.button.primary.pressed"))
	t.set_stylebox("disabled", "Button", ArtCatalog.stylebox("ui.button.disabled"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_TEXT)
	t.set_color("font_pressed_color", "Button", C_GOLD)
	t.set_color("font_disabled_color", "Button", C_STEEL)
	t.set_color("font_outline_color", "Button", Color("14101a"))
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color("14101a"))
	t.set_constant("outline_size", "Label", 3)
	t.set_stylebox("background", "ProgressBar", box(Color("14101a"), Color("2a2433"), 2, 0))
	t.set_stylebox("fill", "ProgressBar", box(C_GOLD, C_GOLD, 0, 1))
	_theme = t
	return t


static func label(text: String, size: int = 22, color: Color = C_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


static func bar(fill: Color, height: float = 10.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, height)
	pb.add_theme_stylebox_override("fill", box(fill, fill, 0, 1))
	return pb
