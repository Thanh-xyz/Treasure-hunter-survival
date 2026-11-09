class_name Combat
extends RefCounted
## Stateless combat helpers shared by player skills, pets, projectiles, bosses.
##
## Targets:
##   - monsters are in group "monster" and implement apply_hit(amount, from_pos, crit)
##   - players are in group "player" and implement take_damage(amount)

const CRIT_CHANCE := 0.08
const CRIT_MULT := 1.6
const VARIANCE := 0.12


## Returns {"amount": int, "crit": bool}. Bonus crit chance is in percentage points
## (8.0 = +8%); bonus crit damage adds percent of base damage to the multiplier (Ravager Stone).
static func roll(base: float, bonus_crit_chance_percent: float = 0.0, bonus_crit_damage_percent: float = 0.0) -> Dictionary:
	var v := base * randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var crit_chance := clampf(CRIT_CHANCE + bonus_crit_chance_percent / 100.0, 0.0, 1.0)
	var crit := randf() < crit_chance
	if crit:
		v *= crit_multiplier(bonus_crit_damage_percent)
	return {"amount": maxi(1, int(round(v))), "crit": crit}


static func crit_multiplier(bonus_crit_damage_percent: float) -> float:
	return CRIT_MULT + maxf(bonus_crit_damage_percent, 0.0) / 100.0


## Dodge chance after the attacker's accuracy, as a 0..1 probability.
static func dodge_probability(dodge_percent: float, attacker_accuracy_percent: float = 0.0) -> float:
	return clampf((dodge_percent - maxf(attacker_accuracy_percent, 0.0)) / 100.0, 0.0, 1.0)


static func roll_dodge(dodge_percent: float, attacker_accuracy_percent: float = 0.0) -> bool:
	var p := dodge_probability(dodge_percent, attacker_accuracy_percent)
	return p > 0.0 and randf() < p


## Roll a monster's on-hit status ({"status", "chance", "duration", "magnitude"}) on a player
## or LAN avatar that supports apply_status(). Returns true when it landed.
static func apply_on_hit(target: Node, on_hit: Dictionary, rng: RandomNumberGenerator = null) -> bool:
	if on_hit.is_empty() or target == null or not target.has_method("apply_status"):
		return false
	var roll := rng.randf() if rng != null else randf()
	if roll >= float(on_hit.get("chance", 1.0)):
		return false
	target.apply_status(str(on_hit.get("status", "")), float(on_hit.get("duration", 2.0)), float(on_hit.get("magnitude", 1.0)))
	return true


static func is_alive_target(n) -> bool:
	if n == null or not is_instance_valid(n) or n.is_queued_for_deletion():
		return false
	if n.has_method("is_dead") and n.is_dead():
		return false
	return true


static func nearest_in_group(tree: SceneTree, group: String, pos: Vector2, max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist
	for n in tree.get_nodes_in_group(group):
		var n2 := n as Node2D
		if n2 == null or not is_alive_target(n2):
			continue
		var d := pos.distance_to(n2.global_position)
		if d <= best_d:
			best_d = d
			best = n2
	return best


static func nearest_monster(tree: SceneTree, pos: Vector2, max_dist: float) -> Node2D:
	return nearest_in_group(tree, "monster", pos, max_dist)


## Damage every monster within radius. Returns number of monsters hit.
static func hit_monsters_in_radius(tree: SceneTree, center: Vector2, radius: float, base_damage: float) -> int:
	var hits := 0
	for n in tree.get_nodes_in_group("monster"):
		var m := n as Node2D
		if m == null or not is_alive_target(m):
			continue
		var reach := radius + body_radius(m, 8.0)
		if center.distance_to(m.global_position) <= reach:
			var r := roll(base_damage)
			m.apply_hit(r["amount"], center, r["crit"])
			hits += 1
	return hits


static func hit_players_in_radius(tree: SceneTree, center: Vector2, radius: float, damage: int) -> int:
	var hits := 0
	for n in tree.get_nodes_in_group("player"):
		var p := n as Node2D
		if p == null or not is_alive_target(p):
			continue
		if center.distance_to(p.global_position) <= radius + 6.0:
			p.take_damage(damage)
			hits += 1
	return hits


static func body_radius(n: Node, fallback: float) -> float:
	var v: Variant = n.get("body_radius")
	if v == null:
		return fallback
	return float(v)


## Root node to attach transient world effects to (the active map or scene root).
## Autoloads are fetched via the tree so this stays safe in static context.
static func world_root(tree: SceneTree) -> Node:
	var sts := tree.root.get_node_or_null("SceneTransitionService")
	if sts != null:
		var map: Node = sts.get_active_map_node()
		if map != null and map.is_inside_tree():
			return map
	return tree.current_scene


static func setting(tree: SceneTree, key: String, fallback: Variant) -> Variant:
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return fallback
	var settings: Dictionary = gs.get("settings")
	return settings.get(key, fallback)
