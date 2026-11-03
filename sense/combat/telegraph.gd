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
			Combat.hit_players_in_radius(get_tree(), global_position, radius, int(round(damage)))
		else:
			Combat.hit_monsters_in_radius(get_tree(), global_position, radius, damage)
	queue_redraw()


func _draw() -> void:
	if _done:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 0.8, clampf(_flash / 0.18, 0, 1) * 0.7))
		return
	var k := clampf(_t / delay, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.18))
	draw_circle(Vector2.ZERO, radius * k, Color(color, 0.35))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(color, 0.9), 1.5)
