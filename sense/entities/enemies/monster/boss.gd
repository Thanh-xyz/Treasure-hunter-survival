class_name Boss
extends Monster
## Multi-phase boss built on Monster.
##
## Phase 1 (HP > 50%): chase + melee, special every ~4.5s
## Phase 2 (HP <= 50%): enraged (+30% speed), adds summon + projectile nova
##
## Specials (weighted by phase and boss ai):
##   slam     — 3 telegraph circles around the target
##   leap     — (slime) big telegraph at target, boss jumps there
##   nova     — ring of projectiles
##   summon   — spawns adds around the boss
## Emits GameEvent.boss_* signals so the HUD can show a boss bar.

const SPECIAL_INTERVAL := 4.5

var phase: int = 1
var _special_timer: float = 3.0
var _leap_from: Vector2
var _leap_to: Vector2
var _adds: Array = []


func _ready() -> void:
	super._ready()
	leash_range = 420.0
	GameEvent.boss_spawned.emit(def_id, self)
	_emit_state()
	hp_changed.connect(func(_h: int, _m: int) -> void: _on_hp_changed())


func _emit_state() -> void:
	GameEvent.boss_state_changed.emit(def_id, hp, max_hp, phase)


func _on_hp_changed() -> void:
	if phase == 1 and hp <= max_hp / 2 and hp > 0:
		phase = 2
		speed *= 1.3
		_special_timer = 0.5
		GameEvent.toast.emit("%s is enraged!" % def.get("name", "Boss"), Color(1, 0.4, 0.3))
	_emit_state()


func _think(delta: float) -> void:
	if state == "return":
		_do_return()
		return
	if global_position.distance_to(home) > leash_range:
		_set_state("return")
		return
	match state:
		"leap_windup":
			if state_time >= 0.9:
				_set_state("leap")
		"leap":
			var k := clampf(state_time / 0.35, 0.0, 1.0)
			global_position = _leap_from.lerp(_leap_to, k)
			visual.position.y = -visual_height * 0.5 - sin(k * PI) * 40.0
			if k >= 1.0:
				visual.position.y = -visual_height * 0.5
				_set_state("recover")
		"special":
			if state_time >= 0.6:
				_set_state("idle")
		"recover":
			if state_time >= 0.7:
				_set_state("idle")
		"windup":
			if state_time >= 0.5:
				if target and _dist_to_target() <= attack_range + body_radius + 14.0:
					target.take_damage(damage)
				_set_state("recover")
		_:
			if target == null:
				_wander()
				return
			_special_timer -= delta
			if _special_timer <= 0.0:
				_special_timer = SPECIAL_INTERVAL * (0.7 if phase == 2 else 1.0)
				_do_special()
				return
			if _dist_to_target() <= attack_range + body_radius and attack_cooldown <= 0.0:
				facing = _dir_to_target()
				attack_cooldown = 1.3
				_set_state("windup")
				_play_anim("attack")
			else:
				_move_toward_target()


func _do_special() -> void:
	var options: Array[String] = ["slam"]
	if def.get("ai", "") == "boss_slime":
		options.append("leap")
	if phase == 2:
		options.append_array(["nova", "summon"])
		_adds = _adds.filter(func(a) -> bool: return is_instance_valid(a))
		if _adds.size() >= 4:
			options.erase("summon")
	var pick: String = options[randi() % options.size()]
	match pick:
		"slam":
			_special_slam()
		"leap":
			_special_leap()
		"nova":
			_special_nova()
		"summon":
			_special_summon()


func _special_slam() -> void:
	_set_state("special")
	_play_anim("attack")
	var center := target.global_position if target else global_position
	Telegraph.create(get_tree(), center, 30.0, 0.9, damage * 1.2)
	for i in range(2):
		var off := Vector2.from_angle(randf() * TAU) * randf_range(36.0, 64.0)
		Telegraph.create(get_tree(), center + off, 26.0, 1.1, damage)


func _special_leap() -> void:
	if target == null:
		return
	_leap_from = global_position
	_leap_to = target.global_position
	Telegraph.create(get_tree(), _leap_to, 44.0, 1.25, damage * 1.6)
	_set_state("leap_windup")


func _special_nova() -> void:
	_set_state("special")
	var from := global_position + Vector2(0, -visual_height * 0.4)
	var count := 14
	var offset := randf() * TAU
	for i in range(count):
		var dir := Vector2.from_angle(offset + TAU * i / count)
		Projectile.fire(get_tree(), from, dir, 110.0, damage * 0.7, "enemy", "bolt_enemy")


func _special_summon() -> void:
	_set_state("special")
	var add_id := "slime" if def.get("ai", "") == "boss_slime" else "skeleton_grunt"
	var root := Combat.world_root(get_tree())
	for i in range(3):
		var m := Monster.create(add_id)
		root.add_child(m)
		m.global_position = global_position + Vector2.from_angle(TAU * i / 3.0) * 40.0
		m.home = m.global_position
		m.target = target
		_adds.append(m)
	GameEvent.toast.emit("%s summons minions!" % def.get("name", "Boss"), Color(1, 0.6, 0.3))


func _die() -> void:
	if _dead:
		return
	GameEvent.boss_defeated.emit(def_id)
	GameEvent.toast.emit("%s defeated!" % def.get("name", "Boss"), Color(1, 0.85, 0.3))
	GameEvent.boss_state_changed.emit(def_id, 0, max_hp, phase)
	super._die()
