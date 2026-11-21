extends Node
## Renders the equipped-item detail modal and verifies its authoritative actions.

const DETAIL_SCENE := preload("res://sense/ui/inventory/EquipmentDetailPanel.tscn")
const INVENTORY_SCENE := preload("res://sense/ui/inventory/inventory_panel.tscn")

var _failed := false
var _output_dir := OS.get_environment("GEAR_PREVIEW_OUTPUT") if OS.has_environment("GEAR_PREVIEW_OUTPUT") else "/tmp"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var background := ColorRect.new()
	background.color = Color8(45, 58, 45)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var inventory := InventoryData.new()
	inventory.gold = 1000
	var weapon := ItemDatabase.get_item_copy("emberforged_blade")
	_check(weapon != null, "Missing emberforged_blade fixture")
	if weapon == null:
		_finish()
		return
	weapon.enhancement_level = 1
	_check(inventory.add_item(weapon, 1) == 0, "Could not add equipment fixture")
	_check(inventory.equip_item(0), "Could not equip equipment fixture")
	await _verify_inventory_tap_routing(background, inventory)

	var panel := DETAIL_SCENE.instantiate() as EquipmentDetailPanel
	background.add_child(panel)
	panel.setup(inventory, "weapon")
	for _frame in range(3):
		await get_tree().process_frame

	var modal := panel.get_node("Modal") as Panel
	var field := panel.get_node("Modal/ItemField") as Panel
	var upgrade := panel.get_node("Modal/UpgradeButton") as Button
	var remove := panel.get_node("Modal/RemoveButton") as Button
	var sell := panel.get_node("Modal/SellButton") as Button
	var level := panel.get_node("Modal/Level") as Label
	var name_label := panel.get_node("Modal/ItemName") as Label
	var close := panel.get_node("Modal/CloseButton") as Button

	_check(modal.size == Vector2(528, 546), "Detail modal geometry drifted: %s" % modal.size)
	_check(name_label.text == weapon.name, "Detail modal showed the wrong item name")
	_check(level.text == "Cấp 1 (Tối đa 10)", "Detail modal showed the wrong level contract")
	_check(not upgrade.disabled, "Upgradeable equipment action was disabled")
	_check(not remove.disabled, "Remove action was disabled")
	_check(sell.disabled, "Unimplemented equipped sale was exposed")
	_check(upgrade.text.begins_with(str(weapon.get_upgrade_cost())), "Upgrade action ignored authoritative cost")

	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_output_dir.path_join("equipment-detail.png"))
	_check(err == OK, "Could not save equipment detail capture: %s" % error_string(err))
	if err == OK:
		var capture_scale := Vector2(image.get_width(), image.get_height()) / get_viewport().get_visible_rect().size
		var sample_point := (field.get_global_transform_with_canvas() * Vector2(8, 8)) * capture_scale
		var actual := image.get_pixelv(Vector2i(sample_point.round()))
		_check(_color_matches(actual, InventorySlotUI.get_rarity_field_color(weapon.rarity)), "Detail rarity field color drifted: %s" % actual)

	_check(close.size.x >= 88.0 and close.size.y >= 88.0, "Close target is smaller than 44 px at preview scale")
	_check(not close.get_global_rect().intersects(name_label.get_global_rect()), "Close target intersects item name")
	close.pressed.emit()
	_check(not panel.visible, "Close button did not hide the detail panel")
	panel.setup(inventory, "weapon")
	var first_cost := weapon.get_upgrade_cost()
	upgrade.pressed.emit()
	await get_tree().process_frame
	var upgraded := inventory.get_equipped("weapon")
	_check(upgraded != null and upgraded.enhancement_level == 2, "Upgrade button did not use the authoritative command")
	_check(inventory.gold == 1000 - first_cost, "Upgrade button spent the wrong Gold amount")
	_check(level.text == "Cấp 2 (Tối đa 10)", "Detail modal did not refresh the final equipment state")

	inventory.gold = 0
	await get_tree().process_frame
	_check(upgrade.disabled, "Insufficient-Gold state left Upgrade enabled")
	var level_before := upgraded.enhancement_level
	upgrade.pressed.emit()
	await get_tree().process_frame
	_check(inventory.get_equipped("weapon").enhancement_level == level_before, "Disabled Upgrade mutated equipment")

	_check(inventory.unequip_item("weapon"), "Could not clear upgrade fixture")
	var reference_item := ItemDatabase.get_item_copy("ashwood_blade")
	_check(reference_item != null, "Could not create locked equipment")
	if reference_item != null:
		reference_item.can_upgrade = false
		reference_item.max_upgrade_level = 1
	if reference_item != null:
		_check(inventory.add_item(reference_item, 1) == 0, "Could not add locked reference equipment")
		var reference_index := _find_inventory_item(inventory, reference_item.id)
		_check(reference_index >= 0 and inventory.equip_item(reference_index), "Could not equip locked reference equipment")
		inventory.gold = 1000
		panel.setup(inventory, "weapon")
		await get_tree().process_frame
		_check(upgrade.disabled, "Non-upgradeable equipment exposed the Upgrade action")
		_check(upgrade.text.begins_with("Không thể"), "Locked equipment displayed a fake cost")
		var closed_count := [0]
		panel.closed.connect(func() -> void: closed_count[0] += 1)
		remove.pressed.emit()
		await get_tree().process_frame
		_check(inventory.get_equipped("weapon") == null, "Remove action did not use the authoritative unequip command")
		_check(not panel.visible, "Detail modal stayed open after removing its item")
		_check(closed_count[0] == 1, "Remove action emitted the modal closed signal more than once")
		panel.close_panel()
		_check(closed_count[0] == 1, "Closing an already hidden modal emitted another closed signal")

	await _verify_stat_layout(panel, weapon)
	_finish()


func _verify_stat_layout(panel: EquipmentDetailPanel, source_item: ItemData) -> void:
	var fixture := source_item.duplicate() as ItemData
	fixture.equipment_line = ""
	fixture.health_bonus = 627
	fixture.attack_bonus = 112
	fixture.speed_bonus = 43.0
	fixture.defense_bonus = 11
	var fixture_inventory := InventoryData.new()
	fixture_inventory.gold = 1000
	_check(fixture_inventory.add_item(fixture, 1) == 0, "Could not add four-stat fixture")
	_check(fixture_inventory.equip_item(0), "Could not equip four-stat fixture")
	panel.setup(fixture_inventory, "weapon")
	panel._refresh()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var modal := panel.get_node("Modal") as Control
	var stats := modal.get_node("Stats") as Control
	var description := modal.get_node("Description") as Control
	var stats_bounds := Rect2(modal.global_position + Vector2(28, 160), Vector2(472, 176))
	_check(stats.get_child_count() == 4, "Repeated refresh did not yield exactly four rows")
	var bottom := stats_bounds.position.y
	for child in stats.get_children():
		var row := child as Control
		var rect := row.get_global_rect()
		_check(stats_bounds.encloses(rect), "Stat row exceeded the fixed layout bounds")
		_check(rect.position.y >= bottom, "Stat rows overlapped")
		bottom = rect.end.y
	_check(bottom < description.global_position.y, "Stats overlap description")
	var image := get_viewport().get_texture().get_image()
	_check(image.save_png(_output_dir.path_join("equipment-detail-four-stats.png")) == OK, "Could not save four-stat render")

	fixture.health_bonus = 0
	fixture.attack_bonus = 0
	fixture.speed_bonus = 0.0
	fixture.defense_bonus = 0
	panel._refresh()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var empty := stats.get_node_or_null("EmptyStats") as Label
	_check(stats.get_child_count() == 1 and empty != null, "No stats did not show one empty-state label")
	if empty != null:
		_check(stats_bounds.encloses(empty.get_global_rect()), "Empty-state label exceeded the stats area")
	image = get_viewport().get_texture().get_image()
	_check(image.save_png(_output_dir.path_join("equipment-detail-no-stats.png")) == OK, "Could not save empty-state render")


func _verify_inventory_tap_routing(parent: Control, inventory: InventoryData) -> void:
	var inventory_panel := INVENTORY_SCENE.instantiate() as InventoryPanel
	parent.add_child(inventory_panel)
	inventory_panel.setup(inventory)
	await get_tree().process_frame
	var weapon_slot := inventory_panel.equipment_slots.get("weapon") as InventorySlotUI
	_check(weapon_slot != null, "Inventory panel did not create the weapon slot")
	if weapon_slot != null:
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = false
		weapon_slot.gui_input.emit(tap)
		await get_tree().process_frame
		_check(inventory_panel.equipment_detail_panel.visible, "Equipment-slot tap did not open the detail modal")
	inventory_panel.queue_free()
	await get_tree().process_frame


func _find_inventory_item(inventory: InventoryData, item_id: String) -> int:
	for index in inventory.inventory_slots.size():
		var item := inventory.get_item_at(index).item as ItemData
		if item != null and item.id == item_id:
			return index
	return -1


func _color_matches(actual: Color, expected: Color) -> bool:
	return (
		abs(roundi(actual.r * 255.0) - roundi(expected.r * 255.0)) <= 1
		and abs(roundi(actual.g * 255.0) - roundi(expected.g * 255.0)) <= 1
		and abs(roundi(actual.b * 255.0) - roundi(expected.b * 255.0)) <= 1
	)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		get_tree().quit(1)
		return
	print("[RENDER] Verified equipment detail layout and authoritative actions. Screenshots in ", _output_dir)
	get_tree().quit()
