class_name PetFollower
extends Node2D
## Companion pet that follows its owner, fights, heals and evolves.
##
## Lives as a child of Main (not of a map) so it travels with the player
## between zones. Stats scale with pet level; visuals change per evolution
## stage (GameContent.PET_STAGE_SCALE / PET_STAGE_TINT).

var pet_id: String = ""
var def: Dictionary = {}
var owner_player: Node2D = null
var level: int = 1
var stage: int = 0

var _sprite: Sprite2D
var _cd: float = 0.0
var _heal_t: float = 0.0
var _t: float = 0.0
var _pounce_target: Node2D = null
var _pounce_t: float = -1.0
var _pounce_from: Vector2
var _last_pos: Vector2


func setup(id: String, player: Node2D) -> void:
	pet_id = id
	def = GameContent.PETS.get(id, {})
	owner_player = player
	level = int(GameState.pets.get(id, {}).get("level", 1))
	stage = GameState.pet_stage(id)


func _ready() -> void:
	z_index = 0
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.get_texture(def.get("sprite", "pet_fox"))
	var s: float = GameContent.PET_STAGE_SCALE[stage]
	_sprite.scale = Vector2(s, s)
	_sprite.modulate = GameContent.PET_STAGE_TINT[stage]
	_sprite.position = Vector2(0, -_sprite.texture.get_height() * s * 0.5)
	add_child(_sprite)
	if owner_player:
		global_position = owner_player.global_position + Vector2(-14, 14)
	_last_pos = global_position
	GameState.collection_changed.connect(_on_collection_changed)


func _on_collection_changed() -> void:
	level = int(GameState.pets.get(pet_id, {}).get("level", level))


func _power_mult() -> float:
	return (1.0 + 0.2 * float(level - 1)) * (1.0 + 0.5 * float(stage))


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
	_t += delta
	if _pounce_t >= 0.0:
		_process_pounce(delta)
	else:
		_follow(delta)
		_try_attack(delta)
	_try_heal(delta)
	# Visual: hop + face movement
	var moved := global_position - _last_pos
	if absf(moved.x) > 0.05:
		_sprite.flip_h = moved.x < 0.0
	var hop := absf(sin(_t * 10.0)) * 2.0 if moved.length() > 0.2 else 0.0
	var s: float = GameContent.PET_STAGE_SCALE[stage]
	_sprite.position.y = -_sprite.texture.get_height() * s * 0.5 - hop
	_last_pos = global_position
	queue_redraw()


func _follow(delta: float) -> void:
	var side := 1.0
	var ld: Variant = owner_player.get("last_dir")
	if ld == null or (ld is Vector2 and ld.x >= 0.0):
		side = -1.0
	var desired := owner_player.global_position + Vector2(18.0 * side, 14.0)
	var dist := global_position.distance_to(desired)
	if dist > 260.0:
		global_position = desired
	elif dist > 4.0:
		global_position = global_position.move_toward(desired, maxf(60.0, dist * 4.0) * delta)


func _try_attack(delta: float) -> void:
	if not def.has("attack"):
		return
	_cd -= delta
	if _cd > 0.0:
		return
	var atk: Dictionary = def["attack"]
	var target := Combat.nearest_monster(get_tree(), owner_player.global_position, float(atk["range"]))
	if target == null:
		return
	_cd = float(atk["cooldown"])
	var dmg := float(atk["damage"]) * _power_mult()
	if atk.get("ranged", false):
		var from := global_position + Vector2(0, -8)
		Projectile.fire(get_tree(), from, (target.global_position + Vector2(0, -6) - from), 200.0, dmg, "player", "bolt_arcane")
	else:
		_pounce_target = target
		_pounce_from = global_position
		_pounce_t = 0.0


func _process_pounce(delta: float) -> void:
	_pounce_t += delta
	if _pounce_target == null or not Combat.is_alive_target(_pounce_target):
		_pounce_t = -1.0
		return
	var k := clampf(_pounce_t / 0.18, 0.0, 1.0)
	if _pounce_t <= 0.18:
		global_position = _pounce_from.lerp(_pounce_target.global_position, k)
	elif _pounce_t <= 0.2:
		var dmg := float(def["attack"]["damage"]) * _power_mult()
		var r := Combat.roll(dmg)
		_pounce_target.apply_hit(r["amount"], global_position, r["crit"])
		_pounce_t = 0.21
	elif _pounce_t > 0.35:
		_pounce_t = -1.0


func _try_heal(delta: float) -> void:
	if not def.has("heal"):
		return
	_heal_t += delta
	var h: Dictionary = def["heal"]
	if _heal_t < float(h["interval"]):
		return
	_heal_t = 0.0
	if owner_player.has_method("heal"):
		var amount := int(round(float(h["amount"]) * _power_mult()))
		owner_player.heal(amount)
		DamageNumber.spawn(get_tree(), owner_player.global_position + Vector2(0, -20), "+%d" % amount, Color(0.4, 1, 0.5))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0 * GameContent.PET_STAGE_SCALE[stage], Color(0, 0, 0, 0.25))
