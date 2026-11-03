class_name Projectile
extends Node2D
## Simple pixel projectile. team "player" damages monsters, team "enemy"
## damages players. Collision is distance-based (no physics bodies needed).

var velocity: Vector2 = Vector2.ZERO
var damage: float = 5.0
var team: String = "player"
var radius: float = 6.0
var lifetime: float = 1.6
var pierce: int = 0
var _hit: Array = []
var _sprite: Sprite2D


static func fire(tree: SceneTree, from: Vector2, dir: Vector2, speed: float, p_damage: float, p_team: String, palette: String = "bolt") -> Projectile:
	var p := Projectile.new()
	p.velocity = dir.normalized() * speed
	p.damage = p_damage
	p.team = p_team
	var root := Combat.world_root(tree)
	if root == null:
		return null
	root.add_child(p)
	p.global_position = from
	p._sprite = Sprite2D.new()
	p._sprite.texture = PixelArt.get_texture("bolt", palette)
	p.add_child(p._sprite)
	p.rotation = dir.angle()
	p.z_index = 20
	return p


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var group := "monster" if team == "player" else "player"
	for n in get_tree().get_nodes_in_group(group):
		var t := n as Node2D
		if t == null or _hit.has(t) or not Combat.is_alive_target(t):
			continue
		var reach := radius + Combat.body_radius(t, 6.0)
		if global_position.distance_to(t.global_position + Vector2(0, -6)) > reach:
			continue
		_hit.append(t)
		if team == "player":
			var r := Combat.roll(damage)
			t.apply_hit(r["amount"], global_position - velocity.normalized() * 8.0, r["crit"])
		else:
			t.take_damage(int(round(damage)))
		if pierce <= 0:
			queue_free()
			return
		pierce -= 1
