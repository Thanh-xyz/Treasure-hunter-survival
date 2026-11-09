class_name Boss
extends Monster
## Multi-phase boss built on Monster (brainstorm sheet 06, plan phase E).
##
## Phases, ability pools, special intervals and reward tables come from
## res://data/bosses/bosses.json (BossCatalog); stats and art from GameContent.MONSTERS.
## Every dangerous ability is telegraphed before it deals damage:
##   slam   — warning circles at and around the target
##   leap   — big circle at the target, the boss lands there
##   wave   — rings that widen outward from the boss, one after another
##   nova   — a warning ring on the boss, then a ring of projectiles
##   line   — a warning band (breath / charge line), damage along it
##   rain   — several circles scattered around the target (fire rain, ice pillars)
##   summon — adds from the boss's summon_id (capped)
## Damage is tracked per participant; rewards follow BossRewards and each encounter id pays
## a profile only once (GameState.grant_boss_rewards / LanSession.grant_boss_reward).

const MAX_ADDS := 4

var phase: int = 1                 ## 1-based, for the HUD
var encounter_id: String = ""
var contributions: Dictionary = {} ## participant id (peer id, 1 = host/local) -> damage dealt
var boss_def: Dictionary = {}
var _phase_index: int = 0
var _special_timer: float = 3.0
var _leap_from: Vector2
var _leap_to: Vector2
var _adds: Array = []
var _base_speed: float = 0.0
var _base_damage: int = 0


func _ready() -> void:
	boss_def = BossCatalog.boss(def_id)
	_base_speed = speed
	_base_damage = damage
	if encounter_id.is_empty():
		encounter_id = "%s:%s:%d:%d" % [str(boss_def.get("type", "boss")), def_id, int(Time.get_unix_time_from_system()), randi() % 100000]
	super._ready()
	leash_range = 420.0
	_apply_phase(0, false)
	GameEvent.boss_spawned.emit(def_id, self)
	_emit_state()
	hp_changed.connect(func(_h: int, _m: int) -> void: _on_hp_changed())


func phase_name() -> String:
	var list := BossCatalog.phases(def_id)
	return str((list[_phase_index] as Dictionary).get("name", "")) if _phase_index < list.size() else ""


func _phase() -> Dictionary:
	var list := BossCatalog.phases(def_id)
	return list[_phase_index] if _phase_index < list.size() else {}


func _emit_state() -> void:
	GameEvent.boss_state_changed.emit(def_id, hp, max_hp, phase)


func _apply_phase(index: int, announce: bool) -> void:
	_phase_index = index
	phase = index + 1
	var p := _phase()
	speed = _base_speed * float(p.get("speed", 1.0))
	damage = maxi(1, roundi(float(_base_damage) * float(p.get("damage", 1.0))))
	if announce:
		_special_timer = 0.6
		GameEvent.toast.emit("%s: %s!" % [def.get("name", "Boss"), phase_name()], Color(1, 0.4, 0.3))
		RingFX.spawn(get_tree(), global_position, body_radius * 3.0, Color(1, 0.4, 0.3), 0.5)


func _on_hp_changed() -> void:
	if hp > 0:
		var index := BossCatalog.phase_index(def_id, float(hp) / float(maxi(max_hp, 1)))
		if index > _phase_index:
			_apply_phase(index, true)
	_emit_state()


## Track who dealt the damage (sheet 06 §8.3); runs before a killing blow pays out.
func _record_damage(applied: int, attacker_peer_id: int) -> void:
	if applied > 0 and not network_replica:
		contributions[attacker_peer_id] = int(contributions.get(attacker_peer_id, 0)) + applied


func _think(delta: float) -> void:
	if state == "return":
		_do_return()
		return
	if global_position.distance_to(home) > leash_range:
		_set_state("return")
		return
	match state:
		"leap_windup":
			if state_time >= float(BossCatalog.ability("leap").get("warn", 1.25)) - 0.35:
				_set_state("leap")
		"leap":
			var k := clampf(state_time / 0.35, 0.0, 1.0)
			global_position = _leap_from.lerp(_leap_to, k)
			visual.position.y = -visual_height * 0.5 - sin(k * PI) * 40.0
			if k >= 1.0:
				visual.position.y = -visual_height * 0.5
				_set_state("recover")
		"nova_warn":
			if state_time >= float(BossCatalog.ability("nova").get("warn", 0.7)):
				_fire_nova()
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
					_hit_target(target)
				_set_state("recover")
		_:
			if target == null:
				_wander()
				return
			_special_timer -= delta
			if _special_timer <= 0.0:
				_special_timer = float(_phase().get("interval", 4.5))
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
	var options: Array = (_phase().get("abilities", ["slam"]) as Array).duplicate()
	_adds = _adds.filter(func(a) -> bool: return is_instance_valid(a) and not (a as Monster).is_dead())
	if _adds.size() >= int(BossCatalog.ability("summon").get("max", MAX_ADDS)):
		options.erase("summon")
	if options.is_empty() or target == null:
		return
	match str(options[randi() % options.size()]):
		"slam":
			_special_slam()
		"leap":
			_special_leap()
		"wave":
			_special_wave()
		"nova":
			_set_state("nova_warn")
			_play_anim("attack")
		"line":
			_special_line()
		"rain":
			_special_rain()
		"summon":
			_special_summon()


func _telegraph(pos: Vector2, radius: float, warn: float, mult: float) -> void:
	var t := Telegraph.create(get_tree(), pos, radius, warn, float(damage) * mult)
	if t:
		t.on_hit = boss_def.get("on_hit", {})


func _special_slam() -> void:
	var a := BossCatalog.ability("slam")
	_set_state("special")
	_play_anim("attack")
	var center := target.global_position
	_telegraph(center, float(a["radius"]), float(a["warn"]), float(a["mult"]))
	for i in range(int(a.get("extra", 2))):
		var off := Vector2.from_angle(randf() * TAU) * randf_range(36.0, 64.0)
		_telegraph(center + off, float(a["radius"]) * 0.85, float(a["warn"]) + 0.2, float(a["mult"]) * 0.8)


func _special_leap() -> void:
	var a := BossCatalog.ability("leap")
	_leap_from = global_position
	_leap_to = target.global_position
	_telegraph(_leap_to, float(a["radius"]), float(a["warn"]), float(a["mult"]))
	_set_state("leap_windup")


## Shockwave rings that widen from the boss, one after another (sheet 06: "3 vòng sóng").
func _special_wave() -> void:
	var a := BossCatalog.ability("wave")
	_set_state("special")
	_play_anim("attack")
	for i in range(int(a.get("rings", 3))):
		var radius := float(a["radius"]) + float(a.get("ring_step", 26.0)) * i
		_telegraph(global_position, radius, float(a["warn"]) + float(a.get("ring_gap", 0.35)) * i, float(a["mult"]))


func _fire_nova() -> void:
	var a := BossCatalog.ability("nova")
	var from := global_position + Vector2(0, -visual_height * 0.4)
	var count := int(a.get("count", 14))
	var offset := randf() * TAU
	for i in range(count):
		var shot := Projectile.fire(get_tree(), from, Vector2.from_angle(offset + TAU * i / count), float(a.get("speed", 110.0)), float(damage) * float(a["mult"]), "enemy", "bolt_enemy")
		if shot:
			shot.on_hit = boss_def.get("on_hit", {})


## Breath / charge: a warned band from the boss toward the target.
func _special_line() -> void:
	var a := BossCatalog.ability("line")
	_set_state("special")
	_play_anim("attack")
	var t := Telegraph.create_line(get_tree(), global_position, _dir_to_target(), float(a["length"]), float(a["width"]) * 0.5, float(a["warn"]), float(damage) * float(a["mult"]))
	if t:
		t.on_hit = boss_def.get("on_hit", {})


func _special_rain() -> void:
	var a := BossCatalog.ability("rain")
	_set_state("special")
	var center := target.global_position
	for i in range(int(a.get("count", 6))):
		var off := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(20.0, float(a.get("spread", 90.0)))
		_telegraph(center + off, float(a["radius"]), float(a["warn"]) + randf_range(0.0, 0.5), float(a["mult"]))


func _special_summon() -> void:
	_set_state("special")
	var add_id := str(boss_def.get("summon_id", "slime"))
	var root := Combat.world_root(get_tree())
	var count := int(BossCatalog.ability("summon").get("count", 3))
	for i in range(count):
		var m := Monster.create(add_id)
		m.network_zone_id = network_zone_id
		root.add_child(m)
		m.global_position = global_position + Vector2.from_angle(TAU * i / float(count)) * 40.0
		m.home = m.global_position
		m.target = target
		_adds.append(m)
	GameEvent.toast.emit("%s summons minions!" % def.get("name", "Boss"), Color(1, 0.6, 0.3))


func _draw() -> void:
	super._draw()
	if state == "nova_warn" and not _dead:
		var k := clampf(state_time / maxf(float(BossCatalog.ability("nova").get("warn", 0.7)), 0.01), 0.0, 1.0)
		draw_arc(Vector2(0, -visual_height * 0.4), body_radius * (1.0 + 1.5 * k), 0.0, TAU, 40, Color(1, 0.25, 0.2, 0.9), 2.0)


## Bosses pay through the encounter split instead of the per-monster loot list.
func _grant_rewards(killer_peer_id: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var split := BossRewards.compute(def_id, contributions, max_hp, killer_peer_id, rng)
	for who: Variant in split:
		if int(who) == 1 or not LanSession.is_host():
			GameState.grant_boss_rewards(encounter_id, split[who])
		else:
			LanSession.grant_boss_reward(int(who), encounter_id, split[who])
	var g: Vector2i = def.get("gold", Vector2i(0, 0))
	var gold := randi_range(g.x, g.y)
	if gold > 0:
		if LanSession.is_host():
			LanSession.spawn_authoritative_gold(global_position, gold)
		else:
			ItemSpawner.spawn_gold(get_tree(), global_position, gold, global_position)


func _die() -> void:
	if _dead:
		return
	GameEvent.boss_defeated.emit(def_id)
	GameEvent.toast.emit("%s defeated!" % def.get("name", "Boss"), Color(1, 0.85, 0.3))
	GameEvent.boss_state_changed.emit(def_id, 0, max_hp, phase)
	super._die()
