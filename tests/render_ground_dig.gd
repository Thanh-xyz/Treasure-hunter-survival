extends Node
## Captures the automatic ground-dig loop for visual comparison.

const ACTIVE_PATH := "/tmp/emberfield-ground-dig-active.png"
const DONE_PATH := "/tmp/emberfield-ground-dig-done.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await SceneTransitionService.go_to("greenwood")
	await get_tree().create_timer(0.4).timeout
	var spots := get_tree().get_nodes_in_group("dig_spot")
	if spots.is_empty():
		push_error("No dig spots found in Greenwood")
		get_tree().quit(1)
		return
	var spot := spots[0] as DigSpot
	GameState.set_mounted(false)
	main.player.set_auto_farm(false)
	main.player.global_position = spot.global_position
	spot._player = main.player
	await get_tree().create_timer(1.25).timeout
	_save(ACTIVE_PATH)
	print("[RENDER] Active dig hits=", spot._hits, " depleted=", spot._depleted)
	await get_tree().create_timer(2.0).timeout
	_save(DONE_PATH)
	print("[RENDER] Done dig hits=", spot._hits, " depleted=", spot._depleted)
	print("[RENDER] Saved ground dig captures")
	get_tree().quit()


func _save(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save %s: %s" % [path, error_string(err)])
