extends Node
## SceneTransitionService - Handles all scene transitions with fade effect
##
## Usage:
##   1. Call initialize() from main scene with root and player reference
##   2. Register maps with register_map()
##   3. Use go_to() to transition between maps
##
## Each map scene should have a "PlayerSpawn" (Marker2D) node for spawn position,
## or implement get_spawn_position() method.

signal transition_started(from_map: String, to_map: String)
signal transition_completed(active_map: String)

# Constants for backward compatibility
const MAP_TOWN := "town"
const MAP_DUNGEON := "dungeon"
const NON_CACHED_MAPS := {
	MAP_DUNGEON: true
}

const FADE_DURATION := 0.25

# Internal state
var _map_registry: Dictionary = {} # map_id → scene_path
var _loaded_maps: Dictionary = {} # map_id → Node2D instance (cache)
var _active_map_id: String = ""
var _active_map_node: Node2D = null
var _is_transitioning: bool = false

# References (set via initialize())
var _root: Node2D = null
var _player: Node2D = null
var _fade_rect: ColorRect = null
var _fade_layer: CanvasLayer = null


#region Public API

## Initialize the service with root scene and player reference
func initialize(root: Node2D, player: Node2D) -> void:
	_root = root
	_player = player
	_setup_fade_layer()


## Register a map with its scene path
func register_map(map_id: String, scene_path: String) -> void:
	_map_registry[map_id] = scene_path


## Check if map_id is registered
func is_valid_map(map_id: String) -> bool:
	return _map_registry.has(map_id)


## Get current active map id
func get_active_map() -> String:
	return _active_map_id


## Get current active map node
func get_active_map_node() -> Node2D:
	return _active_map_node


## Transition to a registered map
func go_to(map_id: String) -> void:
	if not is_valid_map(map_id):
		push_warning("SceneTransitionService: Unknown map_id '%s'" % map_id)
		return
	if _is_transitioning or map_id == _active_map_id:
		return
	if _root == null or _player == null:
		push_error("SceneTransitionService: Not initialized. Call initialize() first.")
		return
	
	await _change_map_with_fade(map_id)


## Shortcut: go to town (backward compatible)
func go_to_town() -> void:
	go_to(MAP_TOWN)


## Shortcut: go to dungeon (backward compatible)
func go_to_dungeon() -> void:
	go_to(MAP_DUNGEON)


## Load initial map without fade (use in _ready)
func load_initial_map(map_id: String) -> void:
	if not is_valid_map(map_id):
		push_warning("SceneTransitionService: Unknown map_id '%s'" % map_id)
		return
	_load_map(map_id)

#endregion


#region Internal Logic

func _change_map_with_fade(target_map: String) -> void:
	_is_transitioning = true
	transition_started.emit(_active_map_id, target_map)
	
	await _fade_to(1.0)
	var loaded := _load_map(target_map)
	await _fade_to(0.0)
	
	if loaded:
		transition_completed.emit(_active_map_id)
	_is_transitioning = false


## Prepare a usable destination before detaching the current run; failure is atomic.
func _load_map(map_id: String) -> bool:
	if not is_instance_valid(_root) or not is_instance_valid(_player) or not is_valid_map(map_id):
		return false
	var cached_map: Variant = _loaded_maps.get(map_id)
	var map_node: Node2D = cached_map as Node2D if is_instance_valid(cached_map) else null
	if not is_instance_valid(map_node) or map_node.is_queued_for_deletion():
		var scene_path := String(_map_registry[map_id])
		if not ResourceLoader.exists(scene_path):
			push_warning("SceneTransitionService: Missing destination '%s'" % scene_path)
			return false
		var scene := load(scene_path) as PackedScene
		if scene == null or not scene.can_instantiate():
			push_warning("SceneTransitionService: Invalid destination scene '%s'" % scene_path)
			return false
		var instance := scene.instantiate()
		if not instance is Node2D:
			instance.free()
			push_warning("SceneTransitionService: Destination must be Node2D '%s'" % scene_path)
			return false
		map_node = instance as Node2D
		map_node.name = map_id.capitalize().replace(" ", "")
	if map_node.get_parent() != null and map_node.get_parent() != _root:
		push_warning("SceneTransitionService: Destination belongs to another root")
		return false

	var previous_map_id := _active_map_id
	var previous_map_node := _active_map_node
	if is_instance_valid(previous_map_node) and previous_map_node != map_node:
		if previous_map_node.get_parent() == _root:
			_root.remove_child(previous_map_node)
		if not _should_cache_map(previous_map_id):
			_loaded_maps.erase(previous_map_id)
			previous_map_node.queue_free()

	_loaded_maps[map_id] = map_node
	if map_node.get_parent() != _root:
		_root.add_child(map_node)
	_root.move_child(map_node, 0)
	_spawn_player_in_map(map_node)
	_active_map_id = map_id
	_active_map_node = map_node
	return true


func _should_cache_map(map_id: String) -> bool:
	return not NON_CACHED_MAPS.has(map_id)


func _spawn_player_in_map(map_node: Node2D) -> void:
	# Convention 1: Look for "PlayerSpawn" node
	var spawn = map_node.get_node_or_null("PlayerSpawn")
	if spawn != null:
		_player.global_position = spawn.global_position
		return
	
	# Convention 2: Map has get_spawn_position() method
	if map_node.has_method("get_spawn_position"):
		var spawn_pos: Variant = map_node.call("get_spawn_position")
		if spawn_pos is Vector2:
			_player.global_position = spawn_pos
			return
	
	# Convention 3: Look for legacy spawn names
	var legacy_names = ["DungeonSpawn", "TownSpawn", "Spawn"]
	for spawn_name in legacy_names:
		spawn = map_node.get_node_or_null(spawn_name)
		if spawn != null:
			_player.global_position = spawn.global_position
			return


func _setup_fade_layer() -> void:
	if _fade_layer != null:
		return # Already setup
	
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 100
	_root.add_child(_fade_layer)
	
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func _fade_to(alpha: float) -> void:
	if _fade_rect == null:
		return
	var tween := get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished

#endregion
