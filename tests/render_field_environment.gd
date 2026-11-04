extends Node
## Captures the refined field props, live HUD values and source-style monster plate.

const OUTPUT_PATH := "/tmp/emberfield-field-environment.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await SceneTransitionService.go_to("greenwood")
	await get_tree().create_timer(0.5).timeout
	var field := SceneTransitionService.get_active_map_node()
	if field == null:
		push_error("Greenwood did not load")
		get_tree().quit(1)
		return
	main.player.set_auto_farm(false)
	main.player.global_position = field.spawn_point + Vector2(0, -150)
	var mosqui := Monster.create("slime")
	mosqui.position = main.player.global_position + Vector2(55, -20)
	field.add_child(mosqui)
	var snailu := Monster.create("shroom")
	snailu.position = main.player.global_position + Vector2(-58, 58)
	field.add_child(snailu)
	var astromophy := Monster.create("boar")
	astromophy.position = main.player.global_position + Vector2(65, 76)
	field.add_child(astromophy)
	var stump_holder := Node2D.new()
	stump_holder.position = main.player.global_position + Vector2(-62, -10)
	stump_holder.add_child(WorldProps.make_sprite("stump", 1.5))
	field.add_child(stump_holder)
	await get_tree().create_timer(0.5).timeout
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save field environment capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("[RENDER] Saved ", OUTPUT_PATH)
	get_tree().quit()
