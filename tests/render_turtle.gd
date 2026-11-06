extends Node2D
## Captures the integrated Turtle atlas in its idle gameplay presentation.

const OUTPUT_PATH := "/tmp/emberfield-turtle.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	RenderingServer.set_default_clear_color(Color("18362f"))
	var turtle := Monster.create("turtle")
	turtle.position = Vector2(360, 820)
	add_child(turtle)
	await get_tree().process_frame
	turtle.set_physics_process(false)
	await get_tree().create_timer(0.25).timeout
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save Turtle capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("[RENDER] Saved ", OUTPUT_PATH)
	get_tree().quit()
