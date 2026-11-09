class_name Telegraph
extends Node2D
## Ground warning circle. Fills over `delay` seconds then deals damage once to
## everything of the opposing team inside `radius`. Used by bosses (team
## "enemy") and area skills like Meteor / Rain (team "player").

var radius: float = 32.0
var delay: float = 1.0
var damage: float = 10.0
var team: String = "enemy"
var color: Color = Color(0.9, 0.2, 0.15)
var _t: float = 0.0
var _done: bool = false
var _flash: float = 0.0
## Boss on-hit status rolled on every player caught (plan phase E).
var on_hit: Dictionary = {}
## "circle" or "line" (a band from the origin along `direction`, `length` long, `radius` half-width)
var shape: String = "circle"
var direction: Vector2 = Vector2.RIGHT
var length: float = 0.0


static func create_line(tree: SceneTree, from: Vector2, dir: Vector2, p_length: float, half_width: float, p_delay: float, p_damage: float) -> Telegraph:
	var t := create(tree, from, half_width, p_delay, p_damage)
	if t:
		t.shape = "line"
		t.direction = dir.normalized()
		t.length = p_length
	return t


## Players inside the warned area right now.
func _victims() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as Node2D
		if p == null or not Combat.is_alive_target(p):
			continue
		var rel := p.global_position - global_position
		if shape == "line":
			var along := rel.dot(direction)
			if along >= -6.0 and along <= length + 6.0 and absf(rel.dot(direction.orthogonal())) <= radius + 6.0:
				out.append(p)
		elif rel.length() <= radius + 6.0:
			out.append(p)
	return out


static func create(tree: SceneTree, pos: Vector2, p_radius: float, p_delay: float, p_damage: float, p_team: String = "enemy") -> Telegraph:
	var root := Combat.world_root(tree)
	if root == null:
		return null
	var t := Telegraph.new()
	t.radius = p_radius
	t.delay = p_delay
	t.damage = p_damage
	t.team = p_team
	if p_team == "player":
		t.color = Color(1.0, 0.75, 0.2)
	t.z_index = -1
	root.add_child(t)
	t.global_position = pos
	return t


func _process(delta: float) -> void:
	if _done:
		_flash -= delta
		if _flash <= 0.0:
			queue_free()
		queue_redraw()
		return
	_t += delta
	if _t >= delay:
		_done = true
		_flash = 0.18
		if team == "enemy":
			for p in _victims():
				p.take_damage(int(round(damage)))
				Combat.apply_on_hit(p, on_hit)
		else:
			Combat.hit_monsters_in_radius(get_tree(), global_position, radius, damage)
	queue_redraw()


func _draw() -> void:
	if shape == "line":
		_draw_line_warning()
		return
	if _done:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 0.8, clampf(_flash / 0.18, 0, 1) * 0.7))
		return
	var k := clampf(_t / delay, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.18))
	draw_circle(Vector2.ZERO, radius * k, Color(color, 0.35))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(color, 0.9), 1.5)


func _draw_line_warning() -> void:
	var side := direction.orthogonal() * radius
	var end := direction * length
	var poly := PackedVector2Array([side, end + side, end - side, -side])
	if _done:
		draw_colored_polygon(poly, Color(1, 1, 0.8, clampf(_flash / 0.18, 0, 1) * 0.6))
		return
	var k := clampf(_t / delay, 0.0, 1.0)
	draw_colored_polygon(poly, Color(color, 0.18))
	var fill := PackedVector2Array([side, direction * length * k + side, direction * length * k - side, -side])
	draw_colored_polygon(fill, Color(color, 0.32))
	draw_polyline(PackedVector2Array([side, end + side, end - side, -side, side]), Color(color, 0.9), 1.5)
