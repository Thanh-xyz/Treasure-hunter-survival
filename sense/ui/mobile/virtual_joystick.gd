class_name VirtualJoystick
extends Control
## Floating virtual joystick (multi-touch). Touching anywhere inside this
## control's rect anchors the stick there; dragging feeds ui_left/right/up/down
## action strengths so the existing player controller works unchanged.

@export var radius: float = 90.0
@export var dead_zone: float = 0.18

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _rest_center: Vector2 = Vector2.ZERO
var enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rest_center = Vector2(size.x * 0.5, size.y * 0.55)
	_center = _rest_center
	resized.connect(func() -> void:
		_rest_center = Vector2(size.x * 0.5, size.y * 0.55)
		if _touch_index < 0:
			_center = _rest_center
		queue_redraw())


func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		if _touch_index >= 0:
			_release()
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var local := get_global_transform_with_canvas().affine_inverse() * st.position
		if st.pressed and _touch_index < 0 and Rect2(Vector2.ZERO, size).has_point(local):
			_touch_index = st.index
			_center = local
			_knob = Vector2.ZERO
			get_viewport().set_input_as_handled()
			queue_redraw()
		elif not st.pressed and st.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_index:
			var local := get_global_transform_with_canvas().affine_inverse() * sd.position
			_knob = (local - _center).limit_length(radius)
			_apply()
			get_viewport().set_input_as_handled()
			queue_redraw()


func _release() -> void:
	_touch_index = -1
	_knob = Vector2.ZERO
	_center = _rest_center
	_apply()
	queue_redraw()


func _apply() -> void:
	var v := _knob / radius
	if v.length() < dead_zone:
		v = Vector2.ZERO
	_set_action("ui_left", maxf(0.0, -v.x))
	_set_action("ui_right", maxf(0.0, v.x))
	_set_action("ui_up", maxf(0.0, -v.y))
	_set_action("ui_down", maxf(0.0, v.y))


func _set_action(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	elif Input.is_action_pressed(action):
		Input.action_release(action)


func _draw() -> void:
	var alpha: float = float(GameState.settings.get("joystick_opacity", 0.7))
	draw_circle(_center, radius, Color(0.05, 0.03, 0.03, 0.35 * alpha))
	draw_arc(_center, radius, 0, TAU, 48, Color(0.85, 0.66, 0.3, 0.8 * alpha), 4.0)
	draw_circle(_center + _knob, radius * 0.42, Color(0.98, 0.93, 0.82, 0.55 * alpha))
	draw_arc(_center + _knob, radius * 0.42, 0, TAU, 32, Color(0.85, 0.66, 0.3, alpha), 3.0)
