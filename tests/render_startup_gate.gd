extends Node
## Captures the local/direct-IP LAN choices for visual comparison.

const OUTPUT_PATH := "/tmp/emberfield-startup-lan.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(8):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save startup LAN capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("[RENDER] Saved ", OUTPUT_PATH)
	get_tree().quit()
