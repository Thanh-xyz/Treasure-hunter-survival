class_name FieldMap
extends Node2D
## Procedurally laid-out open field zone (deterministic per zone seed).
##
## Builds: grass ground, border, decorative + gatherable trees and
## rocks, monster camps with respawn, a world-boss altar with a timer, and a
## town gate. Configured from GameContent.ZONES[zone_id].

const TILE := 16
const CAMP_RESPAWN := 10.0
const MAGNET_INTERVAL := 0.15

@export var zone_id: String = "greenwood"

var cfg: Dictionary = {}
var map_size_px: Vector2 = Vector2.ZERO
var spawn_point: Vector2 = Vector2.ZERO
var altar_point: Vector2 = Vector2.ZERO

var _rng := RandomNumberGenerator.new()          ## seeded: same layout on every LAN peer
var _spawn_rng := RandomNumberGenerator.new()    ## unseeded: elite / mini-boss rolls on the authority
var _mini_boss_scheduler := SpawnRules.MiniBossScheduler.new()
var _mini_boss: Monster = null
var _camps: Array[Dictionary] = []   ## {id, pos, monster, timer}
var _boss: Monster = null
var _boss_timer: float = 0.0
var _boss_emit_t: float = 0.0
var _magnet_t: float = 0.0
var _occupied: Array[Vector2] = []
var _built: bool = false


func _ready() -> void:
	y_sort_enabled = true
	cfg = GameContent.ZONES.get(zone_id, GameContent.ZONES["greenwood"])
	var size: Vector2i = cfg.get("size", Vector2i(60, 90))
	map_size_px = Vector2(size) * TILE
	# Keep enough world below the entrance for the camera to center the player.
	# Spawning against the southern limit pinned the avatar behind the hotbar.
	spawn_point = Vector2(map_size_px.x * 0.5, maxf(map_size_px.y - 540.0, 520.0))
	altar_point = Vector2(map_size_px.x * 0.5, 120.0)
	_rng.seed = int(cfg.get("seed", 1))
	_build_ground(size)
	_build_bounds()
	_build_border_trees()
	_build_altar()
	_build_gate()
	_build_dig_spots()
	_scatter_world()
	_build_camps()
	_boss_timer = float(cfg.get("boss_interval", 180.0)) * 0.5
	_built = true
	_on_entered()


func _enter_tree() -> void:
	if _built:
		_on_entered.call_deferred()


func _exit_tree() -> void:
	var player := GameState.get_player()
	if player:
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = -10000000
			cam.limit_top = -10000000
			cam.limit_right = 10000000
			cam.limit_bottom = 10000000


func _on_entered() -> void:
	GameState.current_zone = zone_id
	GameEvent.zone_entered.emit(zone_id)
	var player := GameState.get_player()
	if player:
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = int(map_size_px.x)
			cam.limit_bottom = int(map_size_px.y)


func get_spawn_position() -> Vector2:
	return spawn_point


# =============================================================================
# BUILD
# =============================================================================

func _build_ground(size: Vector2i) -> void:
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = WorldProps.make_ground_tileset()
	ground.z_index = -10
	ground.modulate = cfg.get("ground_tint", Color.WHITE)
	add_child(ground)
	for y in range(size.y):
		for x in range(size.x):
			var atlas := Vector2i(_rng.randi_range(0, 7), _rng.randi_range(0, 6))
			if _rng.randf() < 0.12:
				atlas = Vector2i(_rng.randi_range(8, 15), _rng.randi_range(0, 6))
			ground.set_cell(Vector2i(x, y), 0, atlas)


func _build_bounds() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Bounds"
	walls.collision_layer = CollisionLayers.Layer.WORLD
	add_child(walls)
	var t := 32.0
	var rects := [
		Rect2(-t, -t, map_size_px.x + 2 * t, t),
		Rect2(-t, map_size_px.y, map_size_px.x + 2 * t, t),
		Rect2(-t, 0, t, map_size_px.y),
		Rect2(map_size_px.x, 0, t, map_size_px.y),
	]
	for r: Rect2 in rects:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size * 0.5
		walls.add_child(cs)


func _build_border_trees() -> void:
	var step := 26.0
	var x := 0.0
	while x <= map_size_px.x:
		_add_decor_tree(Vector2(x + _rng.randf_range(-6, 6), 10.0 + _rng.randf_range(0, 8)))
		_add_decor_tree(Vector2(x + _rng.randf_range(-6, 6), map_size_px.y + 6.0))
		x += step
	var y := 0.0
	while y <= map_size_px.y:
		_add_decor_tree(Vector2(4.0 + _rng.randf_range(0, 8), y))
		_add_decor_tree(Vector2(map_size_px.x - 4.0 - _rng.randf_range(0, 8), y))
		y += step


func _add_decor_tree(pos: Vector2) -> void:
	var key: String = ["tree_1", "tree_2", "tree_3"][_rng.randi_range(0, 2)]
	var tree := WorldProps.make_obstacle(key, _rng.randf_range(0.42, 0.55), Vector2(10, 6))
	tree.position = pos
	add_child(tree)


func _build_altar() -> void:
	var circle := WorldProps.make_sprite("stone_circle", 1.0)
	circle.position = altar_point + Vector2(0, 0)
	circle.z_index = -5
	add_child(circle)
	var altar := Node2D.new()
	altar.position = altar_point + Vector2(0, -2)
	var spr := Sprite2D.new()
	spr.texture = PixelArt.get_texture("altar")
	spr.position = Vector2(0, -5)
	altar.add_child(spr)
	add_child(altar)
	_occupied.append(altar_point)
	_add_interaction(altar_point, 40.0, "summon world boss", _on_altar_interact)
	# Statues flanking the altar
	for side: int in [-1, 1]:
		var st := WorldProps.make_obstacle("statue", 0.6, Vector2(16, 8))
		st.position = altar_point + Vector2(64 * side, 10)
		add_child(st)


func _build_gate() -> void:
	var gate_point := spawn_point + Vector2(0, 260)
	for side: int in [-1, 1]:
		var p := WorldProps.make_obstacle("pillar", 0.6, Vector2(14, 8))
		p.position = gate_point + Vector2(40 * side, 0)
		add_child(p)
	var signpost := WorldProps.make_obstacle("signpost", 0.8, Vector2.ZERO)
	signpost.position = gate_point + Vector2(-56, -30)
	add_child(signpost)
	_occupied.append(spawn_point)
	_occupied.append(gate_point)
	_add_interaction(gate_point + Vector2(0, 30), 26.0, "return to town", func() -> void: SceneTransitionService.go_to("town"))


func _build_dig_spots() -> void:
	# Source-like starter plots stay outside the monster bands so the first
	# "Đào đất" objective can be learned safely after entering the field.
	for offset in [Vector2(-76, -40), Vector2(-38, -40), Vector2(-76, -78), Vector2(58, -58)]:
		_add_dig_spot(spawn_point + offset, DigTileCatalog.starter_tile())
	var remaining := int(cfg.get("dig_spots", 36))
	while remaining > 0:
		var anchor := _free_spot(54.0, 40.0)
		if anchor.x < 0:
			break
		var cluster_size := mini(_rng.randi_range(1, 4), remaining)
		var offsets := [Vector2.ZERO, Vector2(38, 0), Vector2(0, 38), Vector2(38, 38)]
		for i in range(cluster_size):
			_add_dig_spot(anchor + offsets[i])
		remaining -= cluster_size


func _add_dig_spot(pos: Vector2, tile_id: String = "") -> void:
	if tile_id == "":
		tile_id = DigTileCatalog.pick_tile(DigTileCatalog.region_for_field(zone_id), _rng)
	var spot := DigSpot.create(int(_rng.randi()), tile_id)
	spot.position = pos
	add_child(spot)
	_occupied.append(pos)


func _add_interaction(pos: Vector2, radius: float, action: String, callback: Callable) -> void:
	var area_scene := preload("res://sense/components/interaction_scene.tscn")
	var area: InteractionArea = area_scene.instantiate()
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	area.add_child(cs)
	area.position = pos
	add_child(area)
	area.action_name = action
	area.interact = callback


func _free_spot(min_dist: float, margin: float = 48.0) -> Vector2:
	for attempt in range(30):
		var p := Vector2(_rng.randf_range(margin, map_size_px.x - margin), _rng.randf_range(margin + 60.0, map_size_px.y - margin - 40.0))
		if p.distance_to(spawn_point) < 185.0 or p.distance_to(altar_point) < 160.0:
			continue
		var ok := true
		for o in _occupied:
			if o.distance_to(p) < min_dist:
				ok = false
				break
		if ok:
			_occupied.append(p)
			return p
	return Vector2(-1, -1)


func _scatter_world() -> void:
	for i in range(int(cfg.get("trees", 50))):
		var p := _free_spot(96.0)
		if p.x >= 0:
			_add_decor_tree(p)
	for i in range(int(cfg.get("lumber", 10))):
		var p := _free_spot(88.0)
		if p.x >= 0:
			var n := ResourceNode.create("wood", "tree_3", 0.42, 5)
			n.position = p
			add_child(n)
	for i in range(int(cfg.get("rocks", 15))):
		var p := _free_spot(26.0)
		if p.x >= 0:
			var key := "rock_big" if _rng.randf() < 0.5 else "rock_1"
			var n := ResourceNode.create("stone", key, 0.55 if key == "rock_big" else 0.9, 6)
			n.position = p
			add_child(n)
	# Decor without collision
	for i in range(140):
		var p := _free_spot(26.0, 20.0)
		if p.x < 0:
			continue
		var key: String = ["bush_1", "bush_2", "bush_3", "bush_4", "bush_5", "tuft_1", "tuft_2", "tuft_3", "tuft_4", "pebble", "stump"][_rng.randi_range(0, 10)]
		var decor_scale := 0.5 if key.begins_with("bush") else (1.5 if key == "stump" else 1.0)
		var spr := WorldProps.make_sprite(key, decor_scale)
		var holder := Node2D.new()
		holder.position = p
		holder.add_child(spr)
		if key.begins_with("tuft") or key == "pebble":
			holder.z_index = -6
		add_child(holder)
	# A few loot chests
	for i in range(3):
		var p := _free_spot(40.0)
		if p.x >= 0:
			var chest: GameItem = preload("res://sense/items/game_item.tscn").instantiate()
			chest.position = p
			chest.setup_chest(["health_potion", "herb_segment", "stone_guard_1"], 60)
			add_child(chest)


func _build_camps() -> void:
	var spawns: Array = cfg.get("spawns", [])
	var kinds := spawns.size()
	for k in range(kinds):
		var entry: Array = spawns[k]
		for i in range(int(entry[1])):
			var band := (float(k) + _rng.randf()) / float(maxi(kinds, 1))
			var pos := Vector2.ZERO
			for attempt in range(20):
				pos = Vector2(_rng.randf_range(60, map_size_px.x - 60), lerpf(map_size_px.y - 260.0, 260.0, band))
				if absf(pos.x - map_size_px.x * 0.5) > 30.0 and pos.distance_to(spawn_point) > 180.0:
					break
			_camps.append({"id": entry[0], "pos": pos, "monster": null, "timer": 0.0})
	if LanSession.mode == LanSession.Mode.CLIENT:
		return
	for camp in _camps:
		_spawn_camp(camp)


func _elites_alive() -> int:
	var count := 0
	for camp: Dictionary in _camps:
		var m: Variant = camp.get("monster")
		if m != null and is_instance_valid(m) and (m as Monster).elite:
			count += 1
	return count


func _spawn_camp(camp: Dictionary) -> void:
	var elite := SpawnRules.roll_elite(_spawn_rng, _elites_alive())
	var m := Monster.create(camp["id"], elite)
	m.network_zone_id = zone_id
	m.position = camp["pos"] + Vector2(randf_range(-16, 16), randf_range(-16, 16))
	add_child(m)
	camp["monster"] = m
	if elite:
		RingFX.spawn(get_tree(), m.global_position, 34.0, Color(1.0, 0.82, 0.25), 0.6)
		GameEvent.toast.emit("An elite %s prowls nearby" % GameContent.MONSTERS[camp["id"]].get("elite_name", GameContent.MONSTERS[camp["id"]]["name"]), Color(1.0, 0.82, 0.25))
	camp["timer"] = CAMP_RESPAWN


# =============================================================================
# RUNTIME
# =============================================================================

func _process(delta: float) -> void:
	if LanSession.mode == LanSession.Mode.CLIENT:
		return
	for camp in _camps:
		var m: Variant = camp["monster"]
		if m == null or not is_instance_valid(m) or (m as Monster).is_dead():
			camp["timer"] = float(camp["timer"]) - delta
			if float(camp["timer"]) <= 0.0:
				_spawn_camp(camp)
	_process_world_boss(delta)
	_process_mini_boss(delta)
	_magnet_t -= delta
	if _magnet_t <= 0.0:
		_magnet_t = MAGNET_INTERVAL
		_magnet_loot()


## Random field mini-boss (sheet 05 §7): one check per interval, at most one alive per zone,
## never near the safe spawn, announced to the player, respawn cooldown after it dies.
func _process_mini_boss(delta: float) -> void:
	var pool: Array = cfg.get("mini_bosses", [])
	if pool.is_empty():
		return
	if _mini_boss_scheduler.tick(delta, _spawn_rng):
		spawn_mini_boss(str(pool[_spawn_rng.randi_range(0, pool.size() - 1)]))


func spawn_mini_boss(boss_id: String) -> Monster:
	if _mini_boss != null and is_instance_valid(_mini_boss) and not _mini_boss.is_dead():
		return null
	var min_dist := float(SpawnRules.mini_boss_config().get("min_distance_from_safe", 400.0))
	var pos := Vector2.ZERO
	for attempt in range(30):
		pos = Vector2(_spawn_rng.randf_range(80, map_size_px.x - 80), _spawn_rng.randf_range(160, map_size_px.y - 160))
		if pos.distance_to(spawn_point) >= min_dist:
			break
	_mini_boss = Monster.create(boss_id)
	_mini_boss.network_zone_id = zone_id
	_mini_boss.position = pos
	add_child(_mini_boss)
	_mini_boss.monster_died.connect(func(_m: Monster) -> void: _mini_boss_scheduler.on_defeated())
	GameEvent.toast.emit("%s appeared in %s!" % [GameContent.MONSTERS[boss_id]["name"], cfg.get("name", zone_id)], Color(1.0, 0.5, 0.35))
	return _mini_boss


func _process_world_boss(delta: float) -> void:
	var boss_id: String = cfg.get("world_boss", "")
	if boss_id == "":
		return
	var alive := _boss != null and is_instance_valid(_boss) and not _boss.is_dead()
	if not alive:
		_boss_timer -= delta
		if _boss_timer <= 0.0:
			_summon_boss()
	_boss_emit_t -= delta
	if _boss_emit_t <= 0.0:
		_boss_emit_t = 0.5
		GameEvent.world_boss_timer.emit(zone_id, -1.0 if alive else maxf(_boss_timer, 0.0))


func _summon_boss() -> void:
	var boss_id: String = cfg.get("world_boss", "")
	if boss_id == "" or (_boss != null and is_instance_valid(_boss) and not _boss.is_dead()):
		return
	_boss = Monster.create(boss_id)
	_boss.network_zone_id = zone_id
	_boss.position = altar_point + Vector2(0, 40)
	add_child(_boss)
	_boss_timer = float(cfg.get("boss_interval", 180.0))
	RingFX.spawn(get_tree(), altar_point + Vector2(0, 40), 60.0, Color(0.8, 0.3, 1.0), 0.6)
	GameEvent.toast.emit("World boss %s has appeared!" % GameContent.MONSTERS[boss_id]["name"], Color(1, 0.4, 0.3))


func _on_altar_interact() -> void:
	if _boss != null and is_instance_valid(_boss) and not _boss.is_dead():
		GameEvent.toast.emit("The boss is already here!", Color(1, 0.6, 0.4))
		return
	_summon_boss()


func _magnet_loot() -> void:
	var player := GameState.get_player() as Node2D
	if player == null:
		return
	var radius := 30.0 + float(GameState.compute_base_stats().get("magnet", 0.0))
	var root := get_tree().current_scene
	if root == null:
		return
	for child in root.get_children():
		if child is GameItem and not child._is_collected and child.pickup_mode != GameItem.PickupMode.INTERACT:
			if (child as Node2D).global_position.distance_to(player.global_position) <= radius:
				child.magnet_collect(player, 0.2)
