extends Node
## Captures the Treasure Hunter quest menu presentation for visual-diff work.

const MAIN_OUTPUT_PATH := "/tmp/emberfield-quest-menu-main.png"
const CLAIM_OUTPUT_PATH := "/tmp/emberfield-quest-menu-claim.png"
const DAILY_OUTPUT_PATH := "/tmp/emberfield-quest-menu-daily.png"
const COMPLETE_OUTPUT_PATH := "/tmp/emberfield-quest-menu-complete.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	QuestService.reset()
	var surface := Control.new()
	surface.set_anchors_preset(Control.PRESET_TOP_LEFT)
	surface.size = Vector2(720, 1600)
	add_child(surface)
	var menu := GameMenu.new()
	surface.add_child(menu)
	await get_tree().process_frame
	menu.open("quest")
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_capture(MAIN_OUTPUT_PATH):
		get_tree().quit(1)
		return
	var active_quest := QuestService.get_main_quest()
	QuestService.main_progress = int(active_quest["obj"]["count"])
	QuestService.main_ready = true
	menu._rebuild()
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_capture(CLAIM_OUTPUT_PATH):
		get_tree().quit(1)
		return
	menu._set_quest_category("daily")
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_capture(DAILY_OUTPUT_PATH):
		get_tree().quit(1)
		return
	QuestService.main_index = GameContent.MAIN_QUESTS.size()
	QuestService.main_progress = 0
	QuestService.main_ready = false
	menu._set_quest_category("main")
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_capture(COMPLETE_OUTPUT_PATH):
		get_tree().quit(1)
		return
	get_tree().quit()


func _save_capture(output_path: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Could not save quest-menu capture: %s" % error_string(err))
		return false
	print("[RENDER] Saved ", output_path)
	return true
