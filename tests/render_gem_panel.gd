extends Node
## Renders the socket stone panel (plan phase B) for an equipped weapon with stones socketed
## and stones in the bag, so its layout can be reviewed.

const OUTPUT_PATH := "/tmp/emberfield-gem-panel.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var background := ColorRect.new()
	background.color = Color8(31, 28, 34)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var inv := InventoryData.new()
	inv.add_item(ItemDatabase.get_item("emberforged_blade"), 1)
	inv.equip_item(0)
	for stone_id: String in ["stone_critical_2", "stone_guard_3", "stone_fire_1"]:
		inv.add_item(ItemDatabase.get_item(stone_id), 1)
		inv.socket_gem("weapon", inv.get_equipped("weapon").get_gem_sockets().find(""), 0)
	inv.add_item(ItemDatabase.get_item("stone_guard_1"), 7)
	inv.add_item(ItemDatabase.get_item("stone_lifesteal_4"), 1)

	var panel: GemPanel = preload("res://sense/ui/gems/GemPanel.tscn").instantiate()
	panel.position = Vector2(20, 40)
	background.add_child(panel)
	panel.setup(inv, "weapon")

	for i in range(4):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	print("[RENDER] Saved %s (%s)" % [OUTPUT_PATH, error_string(err)])
	get_tree().quit(0 if err == OK else 1)
