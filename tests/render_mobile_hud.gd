extends Node
## Captures live and dead local HUD states for visual-diff work.

const OUTPUT_PATH := "/tmp/emberfield-mobile-hud.png"
const DEAD_OUTPUT_PATH := "/tmp/emberfield-mobile-hud-dead.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.8).timeout
	if not _save_capture(OUTPUT_PATH):
		get_tree().quit(1)
		return
	main.mobile_hud._on_player_died()
	await get_tree().process_frame
	if not _save_capture(DEAD_OUTPUT_PATH):
		get_tree().quit(1)
		return
	get_tree().quit()


func _save_capture(output_path: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Could not save HUD capture: %s" % error_string(err))
		return false
	print("[RENDER] Saved ", output_path)
	return true
