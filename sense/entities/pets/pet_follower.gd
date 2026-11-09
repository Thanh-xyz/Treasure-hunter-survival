class_name PetFollower
extends Node2D
## Companion pet that follows its owner (brainstorm sheet 03, plan phase C).
##
## Pets are stat-only: they never attack, heal or take part in combat. Their stats are applied by
## GameState.compute_base_stats(). Art comes from MonsterVisualCatalog (CC0 Ninja Adventure);
## quality is shown by a coloured ground ring, never by changing the species.
##
## Lives as a child of Main (not of a map) so it travels with the player between zones.

const WORLD_SCALE := 2.0

var pet_key: String = ""
var quality: String = "common"
var owner_player: Node2D = null

var _sprite: AnimatedSprite2D
var _t: float = 0.0
var _last_pos: Vector2
var _has_facings := false


func setup(key: String, player: Node2D) -> void:
	pet_key = key
	owner_player = player
	quality = str(CompanionCatalog.parse_pet_key(key).get("quality", "common"))


func _ready() -> void:
	z_index = 0
	var species_id := str(CompanionCatalog.parse_pet_key(pet_key).get("species", ""))
	var art := str(CompanionCatalog.species(species_id).get("art", ""))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = MonsterVisualCatalog.get_frames(art)
	_sprite.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_size: Vector2i = MonsterVisualCatalog.get_definition(art).get("frame_size", Vector2i(16, 16))
	_sprite.position = Vector2(0, -frame_size.y * WORLD_SCALE * 0.5)
	add_child(_sprite)
	_has_facings = _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("move_down")
	_play("idle", Vector2.DOWN)
	if owner_player:
		global_position = owner_player.global_position + Vector2(-14, 14)
	_last_pos = global_position


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
	_t += delta
	_follow(delta)
	var moved := global_position - _last_pos
	_play("move" if moved.length() > 0.2 else "idle", moved)
	_last_pos = global_position
	queue_redraw()


func _follow(delta: float) -> void:
	var side := 1.0
	var ld: Variant = owner_player.get("last_dir")
	if ld == null or (ld is Vector2 and ld.x >= 0.0):
		side = -1.0
	var gap := 40.0 if GameState.mounted else 22.0
	var desired := owner_player.global_position + Vector2(gap * side, 14.0)
	var dist := global_position.distance_to(desired)
	if dist > 260.0:
		global_position = desired
	elif dist > 4.0:
		global_position = global_position.move_toward(desired, maxf(60.0, dist * 4.0) * delta)


## Grid sheets have one animation per facing; side-view strips flip horizontally.
func _play(action: String, moved: Vector2) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim_name := action
	if _has_facings:
		var facing := "down"
		if moved.length() > 0.05:
			if absf(moved.x) > absf(moved.y):
				facing = "right" if moved.x > 0.0 else "left"
			else:
				facing = "down" if moved.y > 0.0 else "up"
		elif _sprite.animation.contains("_"):
			facing = _sprite.animation.get_slice("_", 1)
		anim_name = "%s_%s" % [action, facing]
	elif absf(moved.x) > 0.05:
		_sprite.flip_h = moved.x < 0.0
	if not _sprite.sprite_frames.has_animation(anim_name):
		anim_name = "idle" if _sprite.sprite_frames.has_animation("idle") else anim_name
	if _sprite.animation != anim_name or not _sprite.is_playing():
		_sprite.play(anim_name)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.25))
	if quality != "common":
		var c := CompanionCatalog.quality_color(quality)
		c.a = 0.55 + 0.2 * sin(_t * 3.0)
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, c, 1.5)
