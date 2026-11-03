class_name RingFX
extends Node2D
## Expanding ring flash used by spins, novas and level-ups.

var max_radius: float = 40.0
var color: Color = Color(1, 0.9, 0.5)
var duration: float = 0.3
var _t: float = 0.0


static func spawn(tree: SceneTree, pos: Vector2, p_radius: float, p_color: Color = Color(1, 0.9, 0.5), p_duration: float = 0.3) -> void:
	var root := Combat.world_root(tree)
	if root == null:
		return
	var fx := RingFX.new()
	fx.max_radius = p_radius
	fx.color = p_color
	fx.duration = p_duration
	fx.z_index = 30
	root.add_child(fx)
	fx.global_position = pos


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var r := max_radius * (0.3 + 0.7 * k)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color, 1.0 - k), 3.0)
	draw_circle(Vector2.ZERO, r, Color(color, (1.0 - k) * 0.18))
