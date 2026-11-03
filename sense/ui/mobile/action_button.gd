class_name ActionButton
extends Control
## Round touch button that presses an InputMap action while held (multi-touch
## safe). Shows an icon/label and an optional cooldown sweep.

signal tapped

@export var action: String = ""
@export var radius: float = 44.0
@export var caption: String = ""
@export var base_color: Color = Color(0.27, 0.19, 0.14)

var icon: Texture2D = null
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
		var inside := local.distance_to(size * 0.5) <= radius * 1.1
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
	draw_circle(c, radius, Color(fill, 0.85 * alpha))
	draw_arc(c, radius, 0, TAU, 40, Color(0.85, 0.66, 0.3, alpha), 4.0)
	if icon:
		var isz := Vector2(radius, radius) * 1.0
		draw_texture_rect(icon, Rect2(c - isz * 0.5, isz), false, Color(1, 1, 1, alpha * (0.4 if locked else 1.0)))
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
		draw_circle(c, radius, Color(0, 0, 0, 0.35))
	if badge != "":
		var fs3 := 18
		draw_circle(c + Vector2(radius * 0.72, -radius * 0.72), 13, Color(0.75, 0.2, 0.18))
		var w3 := FONT.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, fs3).x
		draw_string(FONT, c + Vector2(radius * 0.72 - w3 * 0.5, -radius * 0.72 + 6), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3, Color.WHITE)
