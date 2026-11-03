class_name ResourceNode
extends StaticBody2D
## Gatherable tree / rock. Hit it with basic attacks (or skills) to receive
## resources directly into the inventory. Depletes and respawns.

const RESPAWN_TIME := 35.0

var item_id: String = "wood"
var hits_left: int = 5
var max_hits: int = 5
var sprite_key: String = "tree_3"
var sprite_scale: float = 0.45
var body_radius: float = 10.0

var _sprite: Sprite2D
var _hurtbox: HurtboxComponent
var _shake: float = 0.0
var _depleted: bool = false


static func create(p_item: String, p_sprite: String, p_scale: float, p_hits: int) -> ResourceNode:
	var n := ResourceNode.new()
	n.item_id = p_item
	n.sprite_key = p_sprite
	n.sprite_scale = p_scale
	n.max_hits = p_hits
	n.hits_left = p_hits
	return n


func _ready() -> void:
	add_to_group("resource_node")
	collision_layer = CollisionLayers.Layer.WORLD
	collision_mask = 0
	_sprite = WorldProps.make_sprite(sprite_key, sprite_scale)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	_hurtbox = HurtboxComponent.new()
	_hurtbox.invincibility_time = 0.25
	_hurtbox.collision_layer = CollisionLayers.Layer.ENEMY_HURTBOX
	_hurtbox.collision_mask = 0
	var hs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	hs.shape = circle
	hs.position = Vector2(0, -10)
	_hurtbox.add_child(hs)
	add_child(_hurtbox)
	_hurtbox.damage_received.connect(func(_a: int, _k: float, _f: Vector2) -> void: gather_hit())


func gather_hit() -> void:
	if _depleted:
		return
	hits_left -= 1
	_shake = 0.2
	var amount := 1 + (1 if randf() < 0.25 else 0)
	var item: ItemData = ItemDatabase.get_item(item_id)
	var inv := GameState.get_inventory()
	if item and inv:
		inv.add_item(item, amount)
		DamageNumber.spawn(get_tree(), global_position + Vector2(0, -24), "+%d %s" % [amount, item.name], Color(0.95, 0.85, 0.55))
	GameEvent.resource_gathered.emit(item_id, amount)
	if hits_left <= 0:
		_deplete()


func _deplete() -> void:
	_depleted = true
	_sprite.modulate = Color(0.5, 0.5, 0.5, 0.35)
	_hurtbox.set_deferred("monitorable", false)
	await get_tree().create_timer(RESPAWN_TIME).timeout
	if not is_inside_tree():
		return
	hits_left = max_hits
	_depleted = false
	_sprite.modulate = Color.WHITE
	_hurtbox.set_deferred("monitorable", true)


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake -= delta
		_sprite.rotation = sin(_shake * 60.0) * 0.06
	else:
		_sprite.rotation = 0.0
