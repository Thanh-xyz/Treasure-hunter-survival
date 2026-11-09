class_name LanRemoteAvatar
extends Node2D
## Presentation-only avatar for another LAN peer.

const NAME_FONT := preload("res://assets/Font/Pixellari.ttf")

var peer_id: int = 0
var display_name: String = "Guest"
var zone_id: String = ""
var target_position: Vector2 = Vector2.ZERO
var target_facing: Vector2 = Vector2.DOWN
var current_health: int = 100
var max_health: int = 100
var dead: bool = false

var _sprite: AnimatedSprite2D
var _last_position: Vector2
var _health_bar: ProgressBar


func setup(id: int, peer_name: String) -> void:
	peer_id = id
	display_name = peer_name.left(24)
	name = "LanPeer_%d" % peer_id


func _ready() -> void:
	z_index = 2
	if LanSession.is_host():
		add_to_group("player")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = PixelArt.make_guest_frames()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.22, 1.35)
	_sprite.position = Vector2(0, 4)
	_sprite.play("idle_down")
	add_child(_sprite)

	var label := Label.new()
	label.text = display_name
	label.add_theme_font_override("font", NAME_FONT)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -30)
	label.size = Vector2(120, 22)
	label.scale = Vector2(0.6, 0.6)
	add_child(label)

	_health_bar = ProgressBar.new()
	_health_bar.show_percentage = false
	_health_bar.position = Vector2(-18, -18)
	_health_bar.size = Vector2(36, 5)
	_health_bar.add_theme_stylebox_override("background", UiTheme.box(Color(0.025, 0.025, 0.03), Color(0.02, 0.02, 0.02), 1))
	_health_bar.add_theme_stylebox_override("fill", UiTheme.box(Color(0.08, 0.65, 0.16), Color(0.08, 0.65, 0.16), 0))
	add_child(_health_bar)
	apply_vitals(current_health, max_health, dead)
	_last_position = position


func apply_snapshot(pos: Vector2, facing: Vector2, snapshot_zone: String) -> void:
	target_position = pos
	if facing.length_squared() > 0.01:
		target_facing = facing.normalized()
	zone_id = snapshot_zone
	visible = zone_id == GameState.current_zone


func _process(delta: float) -> void:
	visible = zone_id == GameState.current_zone
	if not visible:
		return
	position = position.lerp(target_position, minf(delta * 12.0, 1.0))
	var moving := position.distance_squared_to(_last_position) > 0.04
	_last_position = position
	_play_motion(moving)


func apply_vitals(hp: int, maximum: int, is_dead_state: bool) -> void:
	max_health = maxi(maximum, 1)
	current_health = clampi(hp, 0, max_health)
	dead = is_dead_state or current_health <= 0
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = current_health
		_health_bar.visible = not dead
	if _sprite:
		_sprite.rotation = PI * 0.5 if dead else 0.0
		_sprite.modulate.a = 0.65 if dead else 1.0


func take_damage(amount: int) -> void:
	if LanSession.is_host() and not dead:
		LanSession.damage_peer(peer_id, amount)


func apply_status(kind: String, duration: float, magnitude: float) -> void:
	if LanSession.is_host() and not dead:
		LanSession.apply_peer_status(peer_id, kind, duration, magnitude)


func is_dead() -> bool:
	return dead


func _play_motion(moving: bool) -> void:
	if _sprite == null:
		return
	if dead:
		return
	var direction := "down"
	if absf(target_facing.x) > absf(target_facing.y):
		direction = "right" if target_facing.x > 0.0 else "left"
	else:
		direction = "down" if target_facing.y > 0.0 else "up"
	var animation := ("move_" if moving else "idle_") + direction
	if _sprite.animation != animation:
		_sprite.play(animation)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2(0, 9), 8.0, Color(0, 0, 0, 0.24))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
