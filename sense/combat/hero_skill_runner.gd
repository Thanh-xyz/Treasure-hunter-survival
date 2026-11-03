class_name HeroSkillRunner
extends Node
## Executes the active hero's three signature skills (GameContent.HERO_SKILLS).
##
## Input actions: hero_skill_1..3 (keys Z/X/C, mobile skill buttons).
## Skill types: spin, dash, buff, fan, rain, meteor, ring, heal.

signal cooldowns_changed
signal skill_cast(index: int, skill_id: String)

const ACTIONS := ["hero_skill_1", "hero_skill_2", "hero_skill_3"]

var player: CharacterBody2D = null
var _cooldowns: Array[float] = [0.0, 0.0, 0.0]
var _buff_time: float = 0.0


func _ready() -> void:
	GameState.hero_changed.connect(func(_h: String) -> void: reset_cooldowns())


func reset_cooldowns() -> void:
	_cooldowns = [0.0, 0.0, 0.0]
	cooldowns_changed.emit()


func _process(delta: float) -> void:
	var changed := false
	for i in range(_cooldowns.size()):
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
			changed = true
	if _buff_time > 0.0:
		_buff_time -= delta
		if _buff_time <= 0.0 and player and player.stats:
			player.stats.attack_multiplier = 1.0
			player.refresh_hitbox_damage()
	if changed:
		cooldowns_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(ACTIONS.size()):
		if event.is_action_pressed(ACTIONS[i]):
			try_cast(i)
			get_viewport().set_input_as_handled()
			return


# =============================================================================
# QUERIES
# =============================================================================

func get_skill_id(index: int) -> String:
	var hero: Dictionary = GameContent.HEROES.get(GameState.hero_id, GameContent.HEROES["warden"])
	var skills: Array = hero["skills"]
	return skills[index] if index < skills.size() else ""


func get_skill_def(index: int) -> Dictionary:
	return GameContent.HERO_SKILLS.get(get_skill_id(index), {})


func is_unlocked(index: int) -> bool:
	var d := get_skill_def(index)
	return not d.is_empty() and GameState.level >= int(d.get("unlock_level", 1))


func get_cooldown(index: int) -> float:
	return _cooldowns[index]


func get_cooldown_ratio(index: int) -> float:
	var d := get_skill_def(index)
	if d.is_empty() or _cooldowns[index] <= 0.0:
		return 0.0
	return _cooldowns[index] / float(d["cd"])


# =============================================================================
# CASTING
# =============================================================================

func try_cast(index: int) -> bool:
	if player == null or player.is_dead():
		return false
	if index < 0 or index >= _cooldowns.size() or _cooldowns[index] > 0.0:
		return false
	if not is_unlocked(index):
		var d0 := get_skill_def(index)
		GameEvent.toast.emit("Unlocks at Lv.%d" % int(d0.get("unlock_level", 1)), Color(0.8, 0.8, 0.8))
		return false
	var d := get_skill_def(index)
	if not player.stats.use_stamina(float(d["cost"])):
		GameEvent.toast.emit("Not enough energy", Color(0.6, 0.8, 1))
		return false
	_cooldowns[index] = float(d["cd"])
	if player.has_method("on_hero_skill_cast"):
		player.on_hero_skill_cast()
	_execute(d)
	skill_cast.emit(index, get_skill_id(index))
	cooldowns_changed.emit()
	return true


func _atk() -> float:
	return float(player.stats.attack_damage)


func _origin() -> Vector2:
	return player.global_position + Vector2(0, 8)


func _aim_dir(max_dist: float = 170.0) -> Vector2:
	var t := Combat.nearest_monster(get_tree(), player.global_position, max_dist)
	if t != null:
		return (t.global_position - player.global_position).normalized()
	var ld: Vector2 = player.last_dir
	return ld.normalized() if ld.length() > 0.01 else Vector2.DOWN


func _aim_point(max_dist: float, fallback_dist: float) -> Vector2:
	var t := Combat.nearest_monster(get_tree(), player.global_position, max_dist)
	if t != null:
		return t.global_position
	return _origin() + _aim_dir(max_dist) * fallback_dist


func _execute(d: Dictionary) -> void:
	var tree := get_tree()
	match d["type"]:
		"spin":
			var r: float = d["radius"]
			Combat.hit_monsters_in_radius(tree, _origin(), r, _atk() * float(d["mult"]))
			RingFX.spawn(tree, _origin(), r, Color(1, 0.9, 0.5), 0.3)
		"dash":
			var dir := _aim_dir(float(d["distance"]) + 40.0)
			player.last_dir = dir
			var start := player.global_position
			player.move_and_collide(dir * float(d["distance"]))
			var end := player.global_position
			for n in tree.get_nodes_in_group("monster"):
				var m := n as Node2D
				if m == null or not Combat.is_alive_target(m):
					continue
				var closest := Geometry2D.get_closest_point_to_segment(m.global_position, start, end)
				if closest.distance_to(m.global_position) <= 18.0 + Combat.body_radius(m, 6.0):
					var rr := Combat.roll(_atk() * float(d["mult"]))
					m.apply_hit(rr["amount"], start, rr["crit"])
			RingFX.spawn(tree, end, 22.0, Color(0.8, 0.9, 1.0), 0.2)
		"buff":
			player.stats.attack_multiplier = float(d["atk_mult"])
			player.refresh_hitbox_damage()
			_buff_time = float(d["duration"])
			RingFX.spawn(tree, _origin(), 30.0, Color(1, 0.4, 0.3), 0.5)
			DamageNumber.spawn(tree, player.global_position + Vector2(0, -24), "ATK UP", Color(1, 0.5, 0.3), true)
		"fan":
			var aim := _aim_dir()
			var count: int = d["count"]
			var spread: float = d["spread"]
			for i in range(count):
				var t := 0.0 if count == 1 else (float(i) / float(count - 1) - 0.5)
				var dir := aim.rotated(t * spread)
				Projectile.fire(tree, player.global_position, dir, 260.0, _atk() * float(d["mult"]), "player", "bolt")
		"rain":
			var center := _aim_point(170.0, 60.0)
			var hits: int = d["hits"]
			for i in range(hits):
				var off := Vector2.from_angle(randf() * TAU) * randf_range(0.0, float(d["radius"]))
				Telegraph.create(tree, center + off, 18.0, 0.35 + 0.12 * i, _atk() * float(d["mult"]), "player")
		"meteor":
			var at := _aim_point(150.0, 50.0)
			Telegraph.create(tree, at, float(d["radius"]), float(d["delay"]), _atk() * float(d["mult"]), "player")
		"ring":
			var count2: int = d["count"]
			for i in range(count2):
				Projectile.fire(tree, player.global_position, Vector2.from_angle(TAU * i / count2), 200.0, _atk() * float(d["mult"]), "player", "bolt_frost")
		"heal":
			var amount := int(round(player.stats.max_health * float(d["heal_pct"])))
			player.heal(amount)
			RingFX.spawn(tree, _origin(), 26.0, Color(0.4, 1, 0.5), 0.5)
			DamageNumber.spawn(tree, player.global_position + Vector2(0, -24), "+%d" % amount, Color(0.4, 1, 0.5), true)
