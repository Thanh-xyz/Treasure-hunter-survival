class_name ActionButton
extends Control
## Square pixel-art hotbar slot that presses an InputMap action while held.

signal tapped

@export var action: String = ""
@export var radius: float = 44.0
@export var caption: String = ""
@export var base_color: Color = Color(0.08, 0.08, 0.09)

var icon: Texture2D = null
var radar_icon: bool = false
var cooldown_ratio: float = 0.0     ## 0 = ready, 1 = full cooldown
var cooldown_text: String = ""
var locked: bool = false
var badge: String = ""
var enabled: bool = true

var _touch_index: int = -1
var _pressed: bool = false
const FONT := preload("res://assets/Font/Pixellari.ttf")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 2, radius * 2)
	size = custom_minimum_size


func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		if _pressed:
			_set_pressed(false)
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var local := get_global_transform_with_canvas().affine_inverse() * st.position
		var inside := Rect2(Vector2.ZERO, size).grow(radius * 0.08).has_point(local)
		if st.pressed and inside and _touch_index < 0:
			_touch_index = st.index
			_set_pressed(true)
			tapped.emit()
			get_viewport().set_input_as_handled()
		elif not st.pressed and st.index == _touch_index:
			_touch_index = -1
			_set_pressed(false)


func _set_pressed(value: bool) -> void:
	_pressed = value
	if action != "" and InputMap.has_action(action):
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = value
		ev.strength = 1.0 if value else 0.0
		Input.parse_input_event(ev)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var alpha: float = float(GameState.settings.get("joystick_opacity", 0.7)) * 0.4 + 0.6
	var fill := base_color.lightened(0.2) if _pressed else base_color
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, Color(fill, 0.94 * alpha))
	draw_rect(outer, Color(0.04, 0.04, 0.05, alpha), false, 5.0)
	draw_rect(outer.grow(-5.0), Color(UiTheme.C_TRIM, alpha), false, 3.0)
	if icon:
		var isz := Vector2(radius, radius) * 0.95
		draw_texture_rect(icon, Rect2(c - isz * 0.5, isz), false, Color(1, 1, 1, alpha * (0.4 if locked else 1.0)))
	if radar_icon:
		var ink := Color(0.72, 0.71, 0.74, alpha * (0.4 if locked else 1.0))
		for ring_radius in [radius * 0.16, radius * 0.32, radius * 0.48]:
			draw_arc(c, ring_radius, 0.0, TAU, 28, ink, 2.5)
		draw_line(c - Vector2(radius * 0.48, 0), c + Vector2(radius * 0.48, 0), ink, 2.0)
		draw_line(c - Vector2(0, radius * 0.48), c + Vector2(0, radius * 0.48), ink, 2.0)
		draw_circle(c, radius * 0.07, ink)
	if caption != "":
		var fs := int(clampf(radius * 0.42, 14, 30))
		var w := FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		var pos := c + Vector2(-w * 0.5, fs * 0.35 + (radius * 0.45 if icon else 0.0))
		draw_string_outline(FONT, pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.06, 0.04, 0.05, alpha))
		draw_string(FONT, pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.98, 0.93, 0.82, alpha * (0.5 if locked else 1.0)))
	if cooldown_ratio > 0.0:
		var pts := PackedVector2Array([c])
		var steps := 32
		for i in range(steps + 1):
			var a := -PI / 2 + TAU * cooldown_ratio * float(i) / float(steps)
			pts.append(c + Vector2.from_angle(a) * radius)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
		if cooldown_text != "":
			var fs2 := int(radius * 0.5)
			var w2 := FONT.get_string_size(cooldown_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x
			draw_string_outline(FONT, c + Vector2(-w2 * 0.5, fs2 * 0.35), cooldown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, 5, Color.BLACK)
			draw_string(FONT, c + Vector2(-w2 * 0.5, fs2 * 0.35), cooldown_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color.WHITE)
	if locked:
		draw_rect(outer.grow(-5.0), Color(0, 0, 0, 0.45))
	if badge != "":
		var fs3 := 18
		draw_circle(c + Vector2(radius * 0.72, -radius * 0.72), 13, Color(0.75, 0.2, 0.18))
		var w3 := FONT.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, fs3).x
		draw_string(FONT, c + Vector2(radius * 0.72 - w3 * 0.5, -radius * 0.72 + 6), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3, Color.WHITE)
