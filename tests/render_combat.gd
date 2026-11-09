extends Node
## Plan phase D renders: Cinderwaste with its roster, an elite, a mini-boss mid slam warning,
## and the player burning. Run with a display (xvfb) and review the PNG.

const OUTPUT_PATH := "/tmp/emberfield-combat-cinderwaste.png"
const SNOW_PATH := "/tmp/emberfield-combat-frostvale.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.6).timeout
	await _stage("cinderwaste", "mini_boss_cinder_warlord", ["ash_hound", "magma_slime", "skeleton_archer"], "burn", OUTPUT_PATH)
	await _stage("frostvale", "mini_boss_glacial_colossus", ["snow_wolf", "snow_bear", "ice_shaman"], "slow", SNOW_PATH)
	get_tree().quit()


func _stage(zone_id: String, boss_id: String, roster: Array, status: String, path: String) -> void:
	SceneTransitionService.go_to(zone_id)
	await get_tree().create_timer(1.2).timeout
	var player := GameState.get_player() as Node2D
	var map := _find_map(get_tree().root)
	for m in get_tree().get_nodes_in_group("monster"):
		m.queue_free()
	var boss := map.spawn_mini_boss(boss_id)
	if boss == null:
		boss = map._mini_boss
	boss.global_position = player.global_position + Vector2(0, -120)
	boss.home = boss.global_position
	var x := -90.0
	for id: String in roster:
		var m := Monster.create(id, id == roster[0])
		m.global_position = player.global_position + Vector2(x, 70)
		map.add_child(m)
		x += 90.0
	await get_tree().create_timer(0.3).timeout
	boss.target = null
	boss.set_physics_process(false)
	boss.state = "slam_warn"
	boss.state_time = 0.55
	boss.queue_redraw()
	player.apply_status(status, 30.0, 40.0 if status == "slow" else 3.0)
	for m in get_tree().get_nodes_in_group("monster"):
		(m as Node).set_physics_process(false)
	await get_tree().create_timer(0.3).timeout
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("[RENDER] Saved %s (%s)" % [path, error_string(err)])


func _find_map(node: Node) -> FieldMap:
	if node is FieldMap:
		return node
	for child in node.get_children():
		var found := _find_map(child)
		if found != null:
			return found
	return null
