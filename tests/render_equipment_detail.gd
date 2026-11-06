extends Node
## Renders the equipped-item detail modal and verifies its authoritative actions.

const OUTPUT_PATH := "/tmp/emberfield-equipment-detail.png"
const DETAIL_SCENE := preload("res://sense/ui/inventory/EquipmentDetailPanel.tscn")
const INVENTORY_SCENE := preload("res://sense/ui/inventory/inventory_panel.tscn")

var _failed := false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var background := ColorRect.new()
	background.color = Color8(45, 58, 45)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var inventory := InventoryData.new()
	inventory.gold = 1000
	var weapon := ItemDatabase.get_item("fire_blade").duplicate() as ItemData
	_check(weapon != null, "Missing fire_blade fixture")
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

	_check(modal.size == Vector2(480, 470), "Detail modal geometry drifted: %s" % modal.size)
	_check(name_label.text == weapon.name, "Detail modal showed the wrong item name")
	_check(level.text == "Cấp 1 (Tối đa 10)", "Detail modal showed the wrong level contract")
	_check(not upgrade.disabled, "Upgradeable equipment action was disabled")
	_check(not remove.disabled, "Remove action was disabled")
	_check(sell.disabled, "Unimplemented equipped sale was exposed")
	_check(upgrade.text.begins_with(str(weapon.get_upgrade_cost())), "Upgrade action ignored authoritative cost")

	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	_check(err == OK, "Could not save equipment detail capture: %s" % error_string(err))
	if err == OK:
		var capture_scale := Vector2(image.get_width(), image.get_height()) / get_viewport().get_visible_rect().size
		var sample_point := (field.get_global_transform_with_canvas() * Vector2(8, 8)) * capture_scale
		var actual := image.get_pixelv(Vector2i(sample_point.round()))
		_check(_color_matches(actual, InventorySlotUI.get_rarity_field_color(weapon.rarity)), "Detail rarity field color drifted: %s" % actual)

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
	var reference_item := ReferenceEquipmentCatalog.materialize(28, {"health": 0.0, "damage": 5.0, "speed": 0.0})
	_check(reference_item != null, "Could not materialize locked reference equipment")
	if reference_item != null:
		_check(inventory.add_item(reference_item, 1) == 0, "Could not add locked reference equipment")
		var reference_index := _find_inventory_item(inventory, reference_item.id)
		_check(reference_index >= 0 and inventory.equip_item(reference_index), "Could not equip locked reference equipment")
		inventory.gold = 1000
		panel.setup(inventory, "weapon")
		await get_tree().process_frame
		_check(upgrade.disabled, "Reference equipment exposed the provisional Upgrade action")
		_check(upgrade.text.begins_with("Không thể"), "Locked reference equipment displayed a fake cost")
		var closed_count := [0]
		panel.closed.connect(func() -> void: closed_count[0] += 1)
		remove.pressed.emit()
		await get_tree().process_frame
		_check(inventory.get_equipped("weapon") == null, "Remove action did not use the authoritative unequip command")
		_check(not panel.visible, "Detail modal stayed open after removing its item")
		_check(closed_count[0] == 1, "Remove action emitted the modal closed signal more than once")
		panel.close_panel()
		_check(closed_count[0] == 1, "Closing an already hidden modal emitted another closed signal")

	_finish()


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
	print("[RENDER] Verified equipment detail layout and authoritative actions; saved ", OUTPUT_PATH)
	get_tree().quit()
