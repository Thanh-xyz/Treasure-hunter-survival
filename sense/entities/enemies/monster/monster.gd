class_name Monster
extends CharacterBody2D
## Data-driven monster built entirely in code from GameContent.MONSTERS.
##
## AI archetypes (def["ai"]):
##   melee   — chase, wind-up, strike
##   flyer   — like melee, wobbly flight, ignores walls
##   ranged  — keeps distance, fires projectiles
##   charger — telegraphs a line, then dashes through the target
##   stationary_melee — scans and attacks without moving or chasing
##   timed_melee — source-scaled range/cadence with a complete attack clip
##   boss_*  — handled by Boss (subclass)
##
## Damage in:  player hitbox -> HurtboxComponent -> apply_hit()
##             skills/pets/projectiles call apply_hit() directly
## Damage out: target.take_damage(int)  (players implement take_damage)

signal hp_changed(hp: int, max_hp: int)
signal monster_died(monster: Monster)

const SKELETON_SCENE_PATH := "res://sense/entities/enemies/skeleton/skeleton.tscn"
const NAME_FONT := preload("res://assets/Font/Pixellari.ttf")
const TARGET_SCAN_INTERVAL := 0.3

static var _skeleton_frames: SpriteFrames = null

var def_id: String = ""
var def: Dictionary = {}
var elite: bool = false
var is_boss: bool = false
var max_hp: int = 10
var hp: int = 10
var damage: int = 1
var speed: float = 30.0
var xp_reward: int = 1
var level: int = 1
var attack_range: float = 16.0
var aggro_range: float = 120.0
var body_radius: float = 7.0
var visual_height: float = 16.0
var leash_range: float = 280.0

var home: Vector2 = Vector2.ZERO
var target: Node2D = null
var facing: Vector2 = Vector2.DOWN
var state: String = "idle"
var state_time: float = 0.0
var attack_cooldown: float = 0.0
var network_id: int = 0
var network_zone_id: String = ""
var network_replica: bool = false
var network_target_position: Vector2 = Vector2.ZERO

var visual: Node2D = null
var hurtbox: HurtboxComponent = null
var name_label: Label = null

var _dead: bool = false
var _scan_timer: float = 0.0
var _flash: float = 0.0
var _t: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO
var _knock: Vector2 = Vector2.ZERO
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_hit: bool = false
var _attack_hit_applied: bool = false
var _base_visual_scale: Vector2 = Vector2.ONE
var _last_attacker_peer_id: int = 1


static func create(id: String, p_elite: bool = false) -> Monster:
	var m: Monster
	var d: Dictionary = GameContent.MONSTERS.get(id, {})
	if d.get("boss", false):
		m = Boss.new()
	else:
		m = Monster.new()
	m.setup(id, p_elite)
	return m


func setup(id: String, p_elite: bool) -> void:
	def_id = id
	def = GameContent.MONSTERS.get(id, GameContent.MONSTERS["slime"])
	elite = p_elite
	is_boss = def.get("boss", false)
	max_hp = int(def["hp"])
	damage = int(def["dmg"])
	speed = float(def["spd"])
	xp_reward = int(def["xp"])
	level = int(def.get("level", 1))
	attack_range = float(def.get("range", 16.0))
	aggro_range = float(def.get("aggro", 120.0))
	if elite:
		max_hp = int(max_hp * GameContent.ELITE_HP_MULT)
		damage = int(damage * GameContent.ELITE_DMG_MULT)
		xp_reward = int(xp_reward * GameContent.ELITE_XP_MULT)
		level += 2
	hp = max_hp


func _ready() -> void:
	add_to_group("monster")
	add_to_group("enemy")
	home = global_position
	collision_layer = CollisionLayers.Layer.ENEMY
	collision_mask = 0 if def.get("ai", "") == "flyer" else CollisionLayers.Layer.WORLD
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_build_visual()
	_build_body()
	_build_hurtbox()
	_build_nameplate()
	attack_cooldown = float(def["attack_interval"]) if def.has("attack_interval") else randf_range(0.2, 1.0)
	network_target_position = global_position
	if network_replica:
		collision_layer = 0
		collision_mask = 0
	if LanSession.is_host() and not network_replica:
		LanSession.register_enemy(self)


# =============================================================================
# CONSTRUCTION
# =============================================================================

func _build_visual() -> void:
	var s: float = float(def.get("scale", 1.0)) * (1.25 if elite else 1.0)
	var visual_kind := String(def.get("visual", "pixel"))
	if visual_kind == "skeleton":
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = _get_skeleton_frames()
		anim.scale = Vector2(s, s)
		anim.position = Vector2(0, -32.0 * s)
		anim.self_modulate = def.get("tint", Color.WHITE)
		if anim.sprite_frames and anim.sprite_frames.has_animation("idle_down"):
			anim.play("idle_down")
		elif anim.sprite_frames and anim.sprite_frames.has_animation("move_down"):
			anim.play("move_down")
		visual = anim
		visual_height = 70.0 * s
		body_radius = 14.0 * s
	elif visual_kind == "atlas":
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = MonsterVisualCatalog.get_frames(String(def.get("asset_id", "")))
		anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim.scale = Vector2(s, s)
		var frame_size := Vector2i(64, 64)
		var asset_definition := MonsterVisualCatalog.get_definition(String(def.get("asset_id", "")))
		if not asset_definition.is_empty():
			frame_size = asset_definition.get("frame_size", frame_size)
		anim.position = Vector2(0, -float(frame_size.y) * s * 0.5)
		anim.self_modulate = def.get("tint", Color.WHITE)
		if anim.sprite_frames != null and anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		visual = anim
		visual_height = float(frame_size.y) * s
		body_radius = maxf(6.0, float(frame_size.x) * s * 0.4)
	else:
		var spr := Sprite2D.new()
		var texture_path := String(def.get("texture", ""))
		if texture_path != "":
			spr.texture = load(texture_path) as Texture2D
		if spr.texture == null:
			spr.texture = PixelArt.get_texture(def.get("sprite", "slime"), def.get("palette", ""))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var h := float(spr.texture.get_height())
		spr.scale = Vector2(s, s)
		spr.position = Vector2(0, -h * s * 0.5)
		visual = spr
		visual_height = h * s
		body_radius = maxf(6.0, float(spr.texture.get_width()) * s * 0.4)
	if elite:
		visual.modulate = Color(1.15, 1.0, 0.7)
	_base_visual_scale = visual.scale
	add_child(visual)


func _build_body() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(def.get("collision_radius", maxf(4.0, body_radius * 0.5)))
	shape.shape = circle
	shape.position = Vector2(0, -2)
	add_child(shape)


func _build_hurtbox() -> void:
	hurtbox = HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.invincibility_time = 0.15
	hurtbox.collision_layer = CollisionLayers.Layer.ENEMY_HURTBOX
	hurtbox.collision_mask = CollisionLayers.Layer.PLAYER_HITBOX
	hurtbox.monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius + 4.0
	shape.shape = circle
	shape.position = Vector2(0, -visual_height * 0.45)
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.damage_received.connect(_on_hurtbox_damage)
	hurtbox.resolved_damage_received.connect(_on_hurtbox_resolved_damage)


func _build_nameplate() -> void:
	name_label = Label.new()
	name_label.text = ("Elite " if elite else "") + str(def.get("name", def_id))
	name_label.add_theme_font_override("font", NAME_FONT)
	name_label.add_theme_font_size_override("font_size", 18)
	var col := Color(1, 0.85, 0.3) if elite else Color(1, 0.95, 0.9)
	if is_boss:
		col = Color(1, 0.45, 0.4)
	name_label.add_theme_color_override("font_color", col)
	name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(200, 22)
	name_label.scale = Vector2(0.55, 0.55)
	name_label.position = Vector2(-55, -visual_height - 19)
	name_label.z_index = 50
	add_child(name_label)


static func _get_skeleton_frames() -> SpriteFrames:
	if _skeleton_frames != null:
		return _skeleton_frames
	var scene := load(SKELETON_SCENE_PATH) as PackedScene
	if scene == null:
		return null
	var inst := scene.instantiate()
	var anim := inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		_skeleton_frames = anim.sprite_frames.duplicate(true) as SpriteFrames
		for a in _skeleton_frames.get_animation_names():
			if String(a).begins_with("attack") or a == "death":
				_skeleton_frames.set_animation_loop(a, false)
	inst.free()
	return _skeleton_frames


# =============================================================================
# MAIN LOOP
# =============================================================================

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if network_replica:
		global_position = global_position.lerp(network_target_position, minf(delta * 12.0, 1.0))
		visible = network_zone_id == GameState.current_zone
		_update_visual()
		queue_redraw()
		return
	_t += delta
	state_time += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	_flash = maxf(0.0, _flash - delta)
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = TARGET_SCAN_INTERVAL
		_update_target()

	velocity = Vector2.ZERO
	_think(delta)
	if _knock.length() > 1.0:
		velocity += _knock
		_knock = _knock.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()
	_update_visual()
	queue_redraw()


func _update_target() -> void:
	var drop_range := aggro_range if def.get("ai", "") == "stationary_melee" else aggro_range * 1.8
	if target != null and (not Combat.is_alive_target(target) or global_position.distance_to(target.global_position) > drop_range):
		target = null
	if target == null:
		target = Combat.nearest_in_group(get_tree(), "player", global_position, aggro_range)


## Override point for bosses
func _think(delta: float) -> void:
	if state == "return":
		_do_return()
		return
	if global_position.distance_to(home) > leash_range and state != "charge":
		_set_state("return")
		return
	match def.get("ai", "melee"):
		"stationary_melee":
			_think_stationary_melee(delta)
		"timed_melee":
			_think_timed_melee(delta)
		"ranged":
			_think_ranged(delta)
		"charger":
			_think_charger(delta)
		_:
			_think_melee(delta)


func _set_state(s: String) -> void:
	state = s
	state_time = 0.0
	if s == "windup":
		_attack_hit_applied = false


func _dist_to_target() -> float:
	if target == null:
		return INF
	return global_position.distance_to(target.global_position)


func _dir_to_target() -> Vector2:
	if target == null:
		return facing
	return (target.global_position - global_position).normalized()


func _move_toward_target(mult: float = 1.0) -> void:
	var dir := _dir_to_target()
	if def.get("ai", "") == "flyer":
		dir = (dir + dir.orthogonal() * sin(_t * 6.0) * 0.6).normalized()
	velocity = dir * speed * mult
	facing = dir


func _wander() -> void:
	if state_time > 2.2 or _wander_dir == Vector2.ZERO:
		state_time = 0.0
		if randf() < 0.45 or global_position.distance_to(home) > 60.0:
			_wander_dir = (home - global_position).normalized() if global_position.distance_to(home) > 60.0 else Vector2.from_angle(randf() * TAU)
		else:
			_wander_dir = Vector2(0.001, 0)
	if _wander_dir.length() > 0.01:
		velocity = _wander_dir * speed * 0.45
		facing = _wander_dir


func _do_return() -> void:
	var to_home := home - global_position
	if to_home.length() < 8.0:
		hp = max_hp
		hp_changed.emit(hp, max_hp)
		target = null
		_set_state("idle")
		return
	velocity = to_home.normalized() * speed * 1.6
	facing = to_home.normalized()


# --- melee / flyer ------------------------------------------------------------
func _think_melee(_delta: float) -> void:
	match state:
		"windup":
			if state_time >= 0.4:
				if target and _dist_to_target() <= attack_range + body_radius + 12.0:
					target.take_damage(damage)
				_set_state("recover")
		"recover":
			if state_time >= 0.55:
				_set_state("idle")
		_:
			if target == null:
				_wander()
				return
			if _dist_to_target() <= attack_range + body_radius and attack_cooldown <= 0.0:
				facing = _dir_to_target()
				attack_cooldown = 1.1
				_set_state("windup")
				_play_anim("attack")
			else:
				_move_toward_target()


func _think_stationary_melee(_delta: float) -> void:
	if state == "windup":
		if state_time >= float(def.get("attack_duration", 0.6666666865)):
			_set_state("idle")
		return
	if target == null or _dist_to_target() > attack_range or attack_cooldown > 0.0:
		return
	facing = _dir_to_target()
	attack_cooldown = float(def.get("attack_interval", 1.0))
	target.take_damage(damage)
	_set_state("windup")
	_play_anim("attack")


func _think_timed_melee(_delta: float) -> void:
	var attack_interval := float(def.get("attack_interval", 1.1))
	var attack_duration := float(def.get("attack_duration", 0.4))
	match state:
		"windup":
			var hit_time := float(def.get("attack_hit_time", 0.4))
			if not _attack_hit_applied and state_time >= hit_time:
				_attack_hit_applied = true
				if target and _dist_to_target() <= attack_range:
					target.take_damage(damage)
			if state_time >= attack_duration:
				_set_state("recover")
		"recover":
			var recovery_duration := float(def.get("attack_recovery", maxf(0.0, attack_interval - attack_duration)))
			if state_time >= recovery_duration:
				_set_state("idle")
		_:
			if target == null:
				_wander()
				return
			if _dist_to_target() <= attack_range:
				velocity = Vector2.ZERO
				if attack_cooldown <= 0.0:
					facing = _dir_to_target()
					attack_cooldown = attack_interval
					_set_state("windup")
					_play_anim("attack")
				return
			_move_toward_target()


# --- ranged -------------------------------------------------------------------
func _think_ranged(_delta: float) -> void:
	match state:
		"windup":
			if state_time >= 0.5:
				if target:
					var from := global_position + Vector2(0, -visual_height * 0.5)
					var aim := (target.global_position + Vector2(0, -10) - from).normalized()
					Projectile.fire(get_tree(), from, aim, 140.0, float(damage), "enemy", def.get("projectile", "bolt_enemy"))
				_set_state("recover")
		"recover":
			if state_time >= 0.9:
				_set_state("idle")
		_:
			if target == null:
				_wander()
				return
			var d := _dist_to_target()
			if d < attack_range * 0.45:
				velocity = -_dir_to_target() * speed
				facing = _dir_to_target()
			elif d <= attack_range and attack_cooldown <= 0.0:
				facing = _dir_to_target()
				attack_cooldown = 1.8
				_set_state("windup")
				_play_anim("attack")
			elif d > attack_range * 0.85:
				_move_toward_target()


# --- charger ------------------------------------------------------------------
func _think_charger(_delta: float) -> void:
	match state:
		"telegraph":
			facing = _charge_dir
			if state_time >= 0.7:
				_charge_hit = false
				_set_state("charge")
		"charge":
			velocity = _charge_dir * 240.0
			if not _charge_hit and target and _dist_to_target() <= body_radius + 12.0:
				_charge_hit = true
				target.take_damage(damage)
			if state_time >= 0.45:
				_set_state("recover")
		"recover":
			if state_time >= 0.9:
				_set_state("idle")
		_:
			if target == null:
				_wander()
				return
			if _dist_to_target() <= attack_range and attack_cooldown <= 0.0:
				_charge_dir = _dir_to_target()
				attack_cooldown = 3.0
				_set_state("telegraph")
			else:
				_move_toward_target(0.8)


# =============================================================================
# VISUALS
# =============================================================================

func _update_visual() -> void:
	if visual == null:
		return
	if visual is AnimatedSprite2D:
		if state != "windup" and state != "telegraph":
			_play_anim("move" if velocity.length() > 2.0 else "idle")
	else:
		var spr := visual as Sprite2D
		if absf(facing.x) > 0.1:
			spr.flip_h = facing.x < 0.0
		var squash_amount := float(def.get("squash", 0.07))
		var squash := 1.0 + squash_amount * sin(_t * (10.0 if velocity.length() > 2.0 else 4.0))
		if state == "windup" or state == "telegraph":
			squash = 1.0 - 0.15 * minf(state_time * 3.0, 1.0)
		spr.scale = Vector2(_base_visual_scale.x * (2.0 - squash), _base_visual_scale.y * squash)
	var m := Color(1, 1, 1)
	if _flash > 0.0:
		m = Color(3, 3, 3)
	elif state == "windup" or state == "telegraph":
		m = Color(1.4, 0.8, 0.8)
	var tint: Color = def.get("tint", Color.WHITE)
	visual.self_modulate = m * tint


func _play_anim(base: String) -> void:
	var anim := visual as AnimatedSprite2D
	if anim == null or anim.sprite_frames == null:
		return
	var suffix := ""
	if absf(facing.x) > absf(facing.y):
		suffix = "right" if facing.x > 0 else "left"
	else:
		suffix = "down" if facing.y > 0 else "up"
	var full := base + "_" + suffix
	if not anim.sprite_frames.has_animation(full):
		full = base
	if not anim.sprite_frames.has_animation(full):
		return
	if anim.animation != full or (base == "attack" and not anim.is_playing()):
		anim.play(full)


func _draw() -> void:
	if _dead:
		return
	# Shadow
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, body_radius * 0.9, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Charger telegraph line
	if state == "telegraph":
		var end := _charge_dir * 240.0 * 0.45
		draw_line(Vector2(0, -4), end, Color(1, 0.2, 0.15, 0.6), 4.0)
	# Captured field monsters keep a small red HP bar visible even when full.
	if not is_boss:
		var w := 30.0
		var y := -visual_height - 6.0
		draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 5), Color(0.03, 0.025, 0.03), true)
		draw_rect(Rect2(-w / 2, y, w * float(hp) / float(max_hp), 3), Color(0.78, 0.06, 0.07), true)


# =============================================================================
# DAMAGE
# =============================================================================

func is_dead() -> bool:
	return _dead


func _on_hurtbox_damage(amount: int, _knockback: float, from_position: Vector2) -> void:
	var r := Combat.roll(float(amount))
	apply_hit(r["amount"], from_position, r["crit"])


func _on_hurtbox_resolved_damage(amount: int, crit: bool, _knockback: float, from_position: Vector2) -> void:
	var applied := apply_hit(amount, from_position, crit)
	if applied > 0:
		hurtbox.confirm_resolved_damage(applied, crit)


func apply_hit(amount: int, from_pos: Vector2, crit: bool = false, attacker_peer_id: int = 1) -> int:
	if _dead or amount <= 0:
		return 0
	if network_replica:
		LanSession.request_enemy_hit(network_id)
		return 0
	_last_attacker_peer_id = attacker_peer_id
	var applied := mini(maxi(amount, 0), hp)
	hp = maxi(0, hp - amount)
	_flash = 0.1
	hp_changed.emit(hp, max_hp)
	DamageNumber.spawn(get_tree(), global_position + Vector2(0, -visual_height), ("%d!" % amount) if crit else str(amount), Color(1, 0.85, 0.2) if crit else Color.WHITE, crit)
	if not is_boss and not bool(def.get("knockback_immune", false)):
		var away := (global_position - from_pos).normalized()
		_knock = away * (140.0 if crit else 90.0)
	if target == null:
		target = Combat.nearest_in_group(get_tree(), "player", global_position, aggro_range * 2.0)
	if state == "return":
		_set_state("idle")
	if hp <= 0:
		_die()
	return applied


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("monster")
	collision_layer = 0
	collision_mask = 0
	if hurtbox:
		hurtbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("monitoring", false)
	if name_label:
		name_label.visible = false
	queue_redraw()
	_grant_rewards(_last_attacker_peer_id)
	GameState.register_kill(def_id, is_boss)
	GameEvent.enemy_killed.emit(def_id, global_position, is_boss)
	monster_died.emit(self)
	if visual is AnimatedSprite2D and (visual as AnimatedSprite2D).sprite_frames.has_animation("death"):
		(visual as AnimatedSprite2D).play("death")
		await get_tree().create_timer(float(def.get("death_duration", 0.9))).timeout
	else:
		var tw := create_tween()
		tw.tween_property(visual, "scale", visual.scale * Vector2(1.4, 0.2), 0.25)
		tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.3)
		await tw.finished
	queue_free()


func apply_network_snapshot(pos: Vector2, snapshot_facing: Vector2, snapshot_state: String, snapshot_hp: int, snapshot_max_hp: int, zone_id: String) -> void:
	if not network_replica or _dead:
		return
	network_target_position = pos
	if snapshot_facing.length_squared() > 0.01:
		facing = snapshot_facing.normalized()
	state = snapshot_state
	max_hp = maxi(snapshot_max_hp, 1)
	hp = clampi(snapshot_hp, 0, max_hp)
	network_zone_id = zone_id
	visible = network_zone_id == GameState.current_zone
	hp_changed.emit(hp, max_hp)
	queue_redraw()


func apply_network_death() -> void:
	if not network_replica or _dead:
		return
	_dead = true
	remove_from_group("monster")
	collision_layer = 0
	collision_mask = 0
	if hurtbox:
		hurtbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("monitoring", false)
	if name_label:
		name_label.visible = false
	queue_redraw()
	if visual is AnimatedSprite2D and (visual as AnimatedSprite2D).sprite_frames.has_animation("death"):
		(visual as AnimatedSprite2D).play("death")
		await get_tree().create_timer(float(def.get("death_duration", 0.9))).timeout
	else:
		var tw := create_tween()
		tw.tween_property(visual, "scale", visual.scale * Vector2(1.4, 0.2), 0.25)
		tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.3)
		await tw.finished
	queue_free()


func _grant_rewards(killer_peer_id: int = 1) -> void:
	var pos := global_position
	if xp_reward > 0:
		if LanSession.is_host() and killer_peer_id != 1:
			LanSession.grant_peer_xp(killer_peer_id, xp_reward)
		else:
			GameState.add_xp(xp_reward)
			DamageNumber.spawn(get_tree(), pos + Vector2(0, -visual_height - 10), "+%d XP" % xp_reward, Color(0.75, 0.55, 1.0))
	# Gold
	var bonus: Dictionary = GameState.compute_base_stats()
	var g: Vector2i = def.get("gold", Vector2i(0, 0))
	var gold := int(randi_range(g.x, g.y) * (1.0 + float(bonus.get("gold_pct", 0.0))) * (2.0 if elite else 1.0))
	if gold > 0:
		if LanSession.is_host():
			LanSession.spawn_authoritative_gold(pos, gold)
		else:
			ItemSpawner.spawn_gold(get_tree(), pos, gold, pos)
	# Items: each entry rolls independently, weight = percent chance
	var loot: Array = def.get("loot", [])
	var luck := 2.0 if elite else 1.0
	for entry in loot:
		var chance := float(entry[1]) * luck
		if randf() * 100.0 < chance:
			var quantity := randi_range(int(entry[2]), int(entry[3]))
			if LanSession.is_host():
				LanSession.spawn_authoritative_item(pos, String(entry[0]), quantity)
			else:
				ItemSpawner.spawn_item(get_tree(), pos, entry[0], quantity, pos)
