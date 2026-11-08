class_name DigSpot
extends Area2D
## Non-blocking field plot. Standing still on it automatically digs once,
## grants a weighted local reward, then leaves the plot depleted until respawn.
## Tile type, durability, respawn range and loot table come from
## res://data/world/dig_tiles.json via DigTileCatalog (plan phase A).

const PLOT_SIZE := Vector2(38.0, 38.0)
const START_DELAY := 0.45
const DIG_INTERVAL := 0.7

var tile_id: String = ""
var hits_required: int = 3
var dig_interval: float = DIG_INTERVAL
var respawn_time: float = 60.0
## Optional explicit pool (tests); empty means the tile's loot table is used.
var reward_pool: Array = []
var _fill_color := Color("93a171")

var _rng := RandomNumberGenerator.new()
var _player: Node2D = null
var _hits: int = 0
var _dig_timer: float = START_DELAY
var _respawn_left: float = 0.0
var _impact_time: float = 0.0
var _depleted: bool = false
var _variant: int = 0


static func create(seed_value: int, tile: String = "") -> DigSpot:
	var spot := DigSpot.new()
	spot._rng.seed = seed_value
	spot._variant = abs(seed_value) % 3
	spot.configure_tile(tile if tile != "" else DigTileCatalog.starter_tile())
	return spot


func configure_tile(id: String) -> void:
	var tile := DigTileCatalog.get_tile(id)
	if tile.is_empty():
		push_warning("DigSpot: unknown tile '%s'" % id)
		return
	tile_id = id
	hits_required = maxi(int(tile.get("hits", 3)), 1)
	respawn_time = DigTileCatalog.roll_respawn(id, _rng)
	_fill_color = Color(String(tile.get("color", "93a171")))


func _ready() -> void:
	add_to_group("dig_spot")
	z_index = -4
	collision_layer = 0
	collision_mask = CollisionLayers.Layer.PLAYER
	monitoring = true
	monitorable = false
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = PLOT_SIZE - Vector2(4, 4)
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _impact_time > 0.0:
		_impact_time = maxf(_impact_time - delta, 0.0)
		queue_redraw()
	if _depleted:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_restore()
		return
	if not _can_dig_now():
		_dig_timer = maxf(_dig_timer, START_DELAY)
		return
	_dig_timer -= delta
	if _dig_timer <= 0.0:
		_dig_timer = dig_interval
		_dig_once()


func _can_dig_now() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _player.has_method("can_auto_dig"):
		return bool(_player.can_auto_dig())
	return not (_player.has_method("is_dead") and _player.is_dead())


func _dig_once() -> void:
	if _depleted or not _can_dig_now():
		return
	if _player.has_method("play_auto_dig_swing") and not bool(_player.play_auto_dig_swing(global_position)):
		return
	_hits += 1
	_impact_time = 0.22
	queue_redraw()
	if _hits >= hits_required:
		_finish_dig()


func _finish_dig() -> void:
	_depleted = true
	_respawn_left = respawn_time
	monitoring = false
	var reward := _roll_reward()
	var item_id: String = reward.get("item_id", "stone")
	var quantity: int = reward.get("quantity", 1)
	_award_reward(_player, item_id, quantity)
	GameEvent.ground_dug.emit(item_id, quantity)
	RingFX.spawn(get_tree(), global_position, 18.0, Color(0.95, 0.78, 0.3), 0.3)
	queue_redraw()


## {"item_id", "quantity"}; the explicit pool wins over the tile's loot table.
func _roll_reward() -> Dictionary:
	if not reward_pool.is_empty():
		var entry := LootTableData.pick(reward_pool, _rng)
		if not entry.is_empty():
			return {"item_id": entry["item_id"], "quantity": _rng.randi_range(int(entry.get("min", 1)), int(entry.get("max", 1)))}
	var table_id := String(DigTileCatalog.get_tile(tile_id).get("loot", ""))
	var rolled := LootTableData.roll(table_id, _rng)
	return rolled if not rolled.is_empty() else {"item_id": "stone", "quantity": 1}


func _award_reward(player: Node2D, item_id: String, quantity: int) -> void:
	if player == null or not player.has_method("get_inventory"):
		return
	var inventory: InventoryData = player.get_inventory()
	if inventory != null and LootTableData.is_currency(item_id):
		var gold := quantity if item_id == "gold" else 0
		var diamonds := quantity if item_id == "diamonds" else 0
		if inventory.transact([], [], gold, diamonds):
			var label := "+%d %s" % [quantity, "Gold" if gold > 0 else "Diamond"]
			DamageNumber.spawn(get_tree(), global_position + Vector2(0, -22), label, Color(1.0, 0.86, 0.35))
		return
	var item: ItemData = ItemDatabase.get_item(item_id)
	if inventory == null or item == null:
		return
	var remaining := inventory.add_item(item, quantity)
	var collected := quantity - remaining
	if collected > 0:
		GameEvent.resource_gathered.emit(item_id, collected)
		DamageNumber.spawn(get_tree(), global_position + Vector2(0, -22), "+%d %s" % [collected, item.name], Color(1.0, 0.86, 0.35))
	if remaining > 0:
		ItemSpawner.spawn_item(get_tree(), global_position + Vector2(0, -8), item_id, remaining, global_position, GameItem.PickupMode.PROXIMITY)
		GameEvent.toast.emit("Túi đầy", Color(1.0, 0.55, 0.45))


func _restore() -> void:
	_depleted = false
	_hits = 0
	_dig_timer = START_DELAY
	respawn_time = DigTileCatalog.roll_respawn(tile_id, _rng) if tile_id != "" else respawn_time
	monitoring = true
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player = body
		_dig_timer = START_DELAY


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_dig_timer = START_DELAY


func _draw() -> void:
	var fill: Color = _fill_color.darkened(0.06 * _variant)
	if _depleted:
		fill = Color("403a32")
	draw_colored_polygon(_plot_polygon(0.0), Color("29251f"))
	draw_colored_polygon(_plot_polygon(1.0), fill)
	draw_polyline(_closed_polygon(_plot_polygon(1.0)), Color(0.72, 0.72, 0.52, 0.65), 1.0)
	for p in [Vector2(-13, -10), Vector2(11, -11), Vector2(-10, 11), Vector2(14, 8)]:
		draw_rect(Rect2(p, Vector2(2, 2)), Color(0.2, 0.17, 0.12, 0.45), true)
	if _hits > 0 or _depleted:
		_draw_cracks(_crack_stage())
	if _impact_time > 0.0:
		var alpha := _impact_time / 0.22
		for angle in range(0, 360, 45):
			var direction := Vector2.from_angle(deg_to_rad(float(angle)))
			draw_line(direction * 5.0, direction * (8.0 + 4.0 * alpha), Color(1.0, 0.9, 0.55, alpha), 1.5)


func _plot_polygon(inset: float) -> PackedVector2Array:
	var half := PLOT_SIZE * 0.5 - Vector2(inset, inset)
	var notch := 3.0
	return PackedVector2Array([
		Vector2(-half.x + notch, -half.y), Vector2(half.x - notch, -half.y),
		Vector2(half.x - notch, -half.y + 1), Vector2(half.x, -half.y + 1),
		Vector2(half.x, half.y - notch), Vector2(half.x - 1, half.y - notch),
		Vector2(half.x - 1, half.y), Vector2(-half.x + notch, half.y),
		Vector2(-half.x + notch, half.y - 1), Vector2(-half.x, half.y - 1),
		Vector2(-half.x, -half.y + notch), Vector2(-half.x + 1, -half.y + notch),
		Vector2(-half.x + 1, -half.y),
	])


func _closed_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed


func _draw_cracks(stage: int) -> void:
	var c := Color(0.16, 0.13, 0.1, 0.9)
	draw_line(Vector2(-1, -1), Vector2(-7, -7), c, 1.5)
	draw_line(Vector2(-1, -1), Vector2(5, -5), c, 1.5)
	if stage >= 2:
		draw_line(Vector2(-1, -1), Vector2(2, 8), c, 1.5)
		draw_line(Vector2(2, 8), Vector2(9, 11), c, 1.5)
	if stage >= 3:
		draw_line(Vector2(-7, -7), Vector2(-13, -4), c, 1.5)
		draw_line(Vector2(5, -5), Vector2(12, -10), c, 1.5)


## Crack drawing has 3 stages whatever the tile's durability.
func _crack_stage() -> int:
	if _depleted:
		return 3
	return clampi(ceili(3.0 * float(_hits) / float(hits_required)), 1, 3)
