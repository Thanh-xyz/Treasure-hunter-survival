class_name UiTheme
extends RefCounted
## Pixel MMO theme measured from direct Treasure Hunter 4.3.6 device captures:
## muted grey-purple panels, near-black slots, pale double trim and amber text.

const FONT := preload("res://assets/Font/Pixellari.ttf")
const C_PANEL := Color(0.29, 0.27, 0.31, 0.96)
const C_PANEL_LIGHT := Color(0.12, 0.12, 0.13, 0.94)
const C_TRIM := Color(0.56, 0.56, 0.57)
const C_TEXT := Color(0.95, 0.94, 0.86)
const C_MUTED := Color(0.67, 0.65, 0.68)
const C_GOOD := Color(0.34, 0.95, 0.34)
const C_BAD := Color(1.0, 0.24, 0.18)
const C_GOLD := Color(1.0, 0.72, 0.10)
const C_STEEL := Color(0.34, 0.34, 0.36)

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
	t.set_stylebox("panel", "PanelContainer", box(C_PANEL, C_TRIM))
	t.set_stylebox("panel", "Panel", box(C_PANEL, C_TRIM))
	t.set_stylebox("normal", "Button", box(C_PANEL_LIGHT, C_TRIM, 3))
	t.set_stylebox("hover", "Button", box(C_PANEL_LIGHT.lightened(0.10), C_GOLD, 3))
	t.set_stylebox("pressed", "Button", box(Color(0.30, 0.15, 0.05), C_GOLD, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.12, 0.11, 0.1), C_STEEL, 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_GOLD)
	t.set_color("font_pressed_color", "Button", C_GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.45, 0.4))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color(0.02, 0.02, 0.02))
	t.set_constant("outline_size", "Label", 3)
	t.set_stylebox("background", "ProgressBar", box(Color(0.08, 0.06, 0.06), Color(0.05, 0.03, 0.03), 2, 1))
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
