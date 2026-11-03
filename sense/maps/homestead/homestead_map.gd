class_name HomesteadMap
extends Node2D
## Player homestead: 6 building plots (GameState.plots). Walk up to a plot and
## interact to open the Village menu; buildings render as props with a level
## badge and a "ready to collect" marker.

const TILE := 16
const SIZE := Vector2i(30, 40)
const FONT := preload("res://assets/Font/Pixellari.ttf")

var map_size_px: Vector2
var spawn_point: Vector2
var _plot_nodes: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()
var _refresh_t: float = 0.0


func _ready() -> void:
	y_sort_enabled = true
	_rng.seed = 7070
	map_size_px = Vector2(SIZE) * TILE
	spawn_point = Vector2(map_size_px.x * 0.5, map_size_px.y - 60)
	var ground := TileMapLayer.new()
	ground.tile_set = WorldProps.make_ground_tileset()
	ground.z_index = -10
	add_child(ground)
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(_rng.randi_range(0, 7), _rng.randi_range(0, 6)))
	for y in range(SIZE.y - 8, SIZE.y):
		for dx in range(-1, 2):
			ground.set_cell(Vector2i(SIZE.x / 2 + dx, y), 1, Vector2i(0, 0))
	_build_bounds()
	_build_fence_trees()
	_build_plots()
	var gate := Node2D.new()
	gate.position = spawn_point + Vector2(0, 30)
	add_child(gate)
	_add_interaction(gate.position, 24.0, "return to town", func() -> void: SceneTransitionService.go_to("town"))
	GameState.buildings_changed.connect(_refresh_plots)
	_refresh_plots()


func _enter_tree() -> void:
	GameState.current_zone = "homestead"
	call_deferred("_emit_zone")


func _emit_zone() -> void:
	GameEvent.zone_entered.emit("homestead")


func get_spawn_position() -> Vector2:
	return spawn_point


func _build_bounds() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = CollisionLayers.Layer.WORLD
	add_child(walls)
	var t := 32.0
	for r: Rect2 in [
		Rect2(-t, -t, map_size_px.x + 2 * t, t), Rect2(-t, map_size_px.y, map_size_px.x + 2 * t, t),
		Rect2(-t, 0, t, map_size_px.y), Rect2(map_size_px.x, 0, t, map_size_px.y)]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size * 0.5
		walls.add_child(cs)


func _build_fence_trees() -> void:
	var x := 0.0
	while x <= map_size_px.x:
		for y: float in [8.0, map_size_px.y + 4.0]:
			var tr := WorldProps.make_obstacle("tree_%d" % _rng.randi_range(1, 3), 0.45, Vector2(10, 6))
			tr.position = Vector2(x, y)
			add_child(tr)
		x += 28.0
	var y2 := 0.0
	while y2 <= map_size_px.y:
		for xx: float in [4.0, map_size_px.x - 4.0]:
			var tr := WorldProps.make_obstacle("tree_%d" % _rng.randi_range(1, 3), 0.45, Vector2(10, 6))
			tr.position = Vector2(xx, y2)
			add_child(tr)
		y2 += 28.0


func _plot_position(i: int) -> Vector2:
	var col := i % 2
	var row := i / 2
	return Vector2(map_size_px.x * (0.3 + 0.4 * col), 130.0 + row * 140.0)


func _build_plots() -> void:
	for i in range(GameState.PLOT_COUNT):
		var holder := Node2D.new()
		holder.position = _plot_position(i)
		add_child(holder)
		_plot_nodes.append(holder)
		_add_interaction(holder.position, 30.0, "manage plot %d" % (i + 1), func() -> void: GameEvent.open_menu.emit("village"))


func _add_interaction(pos: Vector2, radius: float, action: String, callback: Callable) -> void:
	var area: InteractionArea = preload("res://sense/components/interaction_scene.tscn").instantiate()
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	area.add_child(cs)
	area.position = pos
	add_child(area)
	area.action_name = action
	area.interact = callback


func _refresh_plots() -> void:
	for i in range(_plot_nodes.size()):
		var holder := _plot_nodes[i]
		for c in holder.get_children():
			c.queue_free()
		var p: Dictionary = GameState.plots[i]
		if p.is_empty():
			var outline := Sprite2D.new()
			outline.texture = PixelArt.get_texture("plot")
			outline.scale = Vector2(3, 3)
			outline.position = Vector2(0, -12)
			outline.z_index = -5
			holder.add_child(outline)
			holder.add_child(_make_label("Empty plot", Color(0.9, 0.85, 0.6), Vector2(-40, -44)))
			continue
		var bdef: Dictionary = GameContent.BUILDINGS[p["id"]]
		var prop: String = bdef.get("prop", "crate")
		var key := prop
		match prop:
			"rock":
				key = "rock_big"
			"bush":
				key = "bush_1"
		var lv: int = int(p["level"])
		var body := WorldProps.make_obstacle(key, 0.6 + 0.15 * lv, Vector2(20, 8))
		holder.add_child(body)
		holder.add_child(_make_label("%s Lv.%d" % [bdef["name"], lv], Color(1, 0.95, 0.8), Vector2(-40, -70)))
		var pending := GameState.building_pending(i)
		if pending > 0:
			holder.add_child(_make_label("Ready: %d" % pending, Color(0.5, 1, 0.5), Vector2(-40, -82)))


func _make_label(text: String, color: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(200, 20)
	l.scale = Vector2(0.4, 0.4)
	l.position = pos
	l.z_index = 40
	return l


func _process(delta: float) -> void:
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = 5.0
		_refresh_plots()
