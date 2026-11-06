extends Node2D
## Captures the runtime Snailu catalog at a fixed idle frame.

const OUTPUT_PATH := "/tmp/emberfield-snailu.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	RenderingServer.set_default_clear_color(Color("18362f"))
	var animation := AnimatedSprite2D.new()
	animation.sprite_frames = MonsterVisualCatalog.get_frames("actor.monster.snailu.atlas")
	animation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animation.position = Vector2(180, 400)
	animation.animation = "idle"
	animation.frame = 0
	animation.frame_progress = 0.0
	add_child(animation)
	animation.stop()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save Snailu capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("[RENDER] Saved ", OUTPUT_PATH)
	get_tree().quit()
