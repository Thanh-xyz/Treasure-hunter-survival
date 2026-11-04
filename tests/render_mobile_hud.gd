extends Node
## Captures the live local HUD for visual-diff work.

const OUTPUT_PATH := "/tmp/emberfield-mobile-hud.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.8).timeout
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save HUD capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("[RENDER] Saved ", OUTPUT_PATH)
	get_tree().quit()
