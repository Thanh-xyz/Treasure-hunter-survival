extends Node
## Captures the loading and authentication states for visual comparison.

const LOADING_OUTPUT_PATH := "/tmp/emberfield-startup-loading.png"
const REGISTER_OUTPUT_PATH := "/tmp/emberfield-startup-register.png"
const LOGIN_OUTPUT_PATH := "/tmp/emberfield-startup-login.png"
const LAN_OUTPUT_PATH := "/tmp/emberfield-startup-lan.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(8):
		await get_tree().process_frame
	if not _save_capture(LOADING_OUTPUT_PATH):
		get_tree().quit(1)
		return
	await get_tree().create_timer(1.3, true, false, true).timeout
	if not _save_capture(REGISTER_OUTPUT_PATH):
		get_tree().quit(1)
		return
	main.startup_gate._show_login()
	await get_tree().process_frame
	if not _save_capture(LOGIN_OUTPUT_PATH):
		get_tree().quit(1)
		return
	main.startup_gate._toggle_network_panel()
	await get_tree().process_frame
	if not _save_capture(LAN_OUTPUT_PATH):
		get_tree().quit(1)
		return
	get_tree().quit()


func _save_capture(output_path: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Could not save startup capture: %s" % error_string(err))
		return false
	print("[RENDER] Saved ", output_path)
	return true
