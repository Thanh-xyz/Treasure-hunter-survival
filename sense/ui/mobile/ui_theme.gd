class_name UiTheme
extends RefCounted
## Classic pixel RPG theme built in code: dark wood panels, gold trim,
## Pixellari font. Shared by every new mobile UI panel.

const FONT := preload("res://assets/Font/Pixellari.ttf")
const C_PANEL := Color(0.16, 0.11, 0.09, 0.96)
const C_PANEL_LIGHT := Color(0.27, 0.19, 0.14, 1.0)
const C_TRIM := Color(0.85, 0.66, 0.3)
const C_TEXT := Color(0.98, 0.93, 0.82)
const C_MUTED := Color(0.7, 0.62, 0.5)
const C_GOOD := Color(0.5, 0.95, 0.45)
const C_BAD := Color(1.0, 0.45, 0.4)
const C_GOLD := Color(1.0, 0.85, 0.3)

static var _theme: Theme = null


static func box(bg: Color, border: Color, width: int = 3, radius: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
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
	t.set_stylebox("hover", "Button", box(C_PANEL_LIGHT.lightened(0.12), C_GOLD, 3))
	t.set_stylebox("pressed", "Button", box(C_PANEL_LIGHT.darkened(0.25), C_GOLD, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.2, 0.17, 0.15), Color(0.4, 0.35, 0.3), 3))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_GOLD)
	t.set_color("font_pressed_color", "Button", C_GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.45, 0.4))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color(0.06, 0.04, 0.05))
	t.set_constant("outline_size", "Label", 4)
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
