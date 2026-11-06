extends Node
## Renders occupied inventory fields and verifies the capture-derived rarity colors.

const OUTPUT_PATH := "/tmp/emberfield-inventory-rarity.png"
const SLOT_ORIGIN := Vector2(8, 54)
const SLOT_STEP := 86.0
const SAMPLE_OFFSET := Vector2i(20, 20)
const VERIFIED_TIERS := [
	["Common", ItemData.ItemRarity.COMMON, Color8(255, 237, 195)],
	["Rare", ItemData.ItemRarity.RARE, Color8(39, 161, 203)],
	["Epic", ItemData.ItemRarity.EPIC, Color8(169, 100, 223)],
	["Legendary", ItemData.ItemRarity.LEGENDARY, Color8(225, 195, 33)],
]


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var background := ColorRect.new()
	background.color = Color8(31, 28, 34)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var transparent_icon := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	transparent_icon.fill(Color(0, 0, 0, 0))
	var icon_texture := ImageTexture.create_from_image(transparent_icon)

	var verified_slots: Array[Control] = []
	for index in VERIFIED_TIERS.size():
		var tier: Array = VERIFIED_TIERS[index]
		var slot := InventorySlotUI.new()
		slot.position = SLOT_ORIGIN + Vector2(SLOT_STEP * index, 0)
		slot.size = InventorySlotUI.SLOT_SIZE
		var item := ItemData.new()
		item.id = "rarity_render_%s" % String(tier[0]).to_lower()
		item.item_type = ItemData.ItemType.WEAPON
		item.rarity = tier[1]
		item.icon = icon_texture
		item.stackable = false
		slot.set_item(item)
		background.add_child(slot)
		verified_slots.append(slot)

	var uncommon_slot := InventorySlotUI.new()
	uncommon_slot.position = Vector2(8, 154)
	uncommon_slot.size = InventorySlotUI.SLOT_SIZE
	var uncommon_item := ItemData.new()
	uncommon_item.id = "rarity_render_uncommon_fallback"
	uncommon_item.item_type = ItemData.ItemType.WEAPON
	uncommon_item.rarity = ItemData.ItemRarity.UNCOMMON
	uncommon_item.icon = icon_texture
	uncommon_item.stackable = false
	uncommon_slot.set_item(uncommon_item)
	background.add_child(uncommon_slot)

	var empty_slot := InventorySlotUI.new()
	empty_slot.position = Vector2(94, 154)
	empty_slot.size = InventorySlotUI.SLOT_SIZE
	background.add_child(empty_slot)

	var material_slot := InventorySlotUI.new()
	material_slot.position = Vector2(180, 154)
	material_slot.size = InventorySlotUI.SLOT_SIZE
	var material_item := ItemData.new()
	material_item.id = "rarity_render_non_equipment"
	material_item.item_type = ItemData.ItemType.MATERIAL
	material_item.rarity = ItemData.ItemRarity.EPIC
	material_item.icon = icon_texture
	material_item.stackable = false
	material_slot.set_item(material_item)
	background.add_child(material_slot)

	var drop_slot := InventorySlotUI.new()
	drop_slot.position = Vector2(266, 154)
	drop_slot.size = InventorySlotUI.SLOT_SIZE
	var drop_item := ItemData.new()
	drop_item.id = "rarity_render_drop_target"
	drop_item.item_type = ItemData.ItemType.WEAPON
	drop_item.rarity = ItemData.ItemRarity.EPIC
	drop_item.icon = icon_texture
	drop_item.stackable = false
	drop_slot.set_item(drop_item)
	drop_slot.is_drag_target = true
	background.add_child(drop_slot)

	for _frame in range(3):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Could not save rarity capture: %s" % error_string(err))
		get_tree().quit(1)
		return
	var capture_scale := Vector2(image.get_width(), image.get_height()) / get_viewport().get_visible_rect().size
	for index in VERIFIED_TIERS.size():
		var tier: Array = VERIFIED_TIERS[index]
		var sample_point := (
			verified_slots[index].get_global_transform_with_canvas() * Vector2(SAMPLE_OFFSET)
		) * capture_scale
		var actual := image.get_pixelv(Vector2i(sample_point.round()))
		if not _color_matches(actual, tier[2]):
			push_error("Rarity field mismatch for %s: expected %s, got %s" % [tier[0], tier[2], actual])
			get_tree().quit(1)
			return
	var uncommon_color := _sample_slot(image, uncommon_slot, capture_scale)
	if not _color_matches(uncommon_color, Color(0.3, 0.8, 0.3, 1.0)):
		push_error("Emberfield Uncommon fallback color drifted")
		get_tree().quit(1)
		return
	var empty_color := _sample_slot(image, empty_slot, capture_scale)
	if not _color_matches(empty_color, InventorySlotUI.SLOT_BG_EMPTY):
		push_error("Empty inventory slot background drifted")
		get_tree().quit(1)
		return
	var material_color := _sample_slot(image, material_slot, capture_scale)
	if not _color_matches(material_color, InventorySlotUI.SLOT_BG_COLOR):
		push_error("Non-equipment item unexpectedly received a Treasure Hunter rarity field")
		get_tree().quit(1)
		return
	var drop_color := _sample_slot(image, drop_slot, capture_scale)
	if not _color_matches(drop_color, InventorySlotUI.SLOT_BG_DROP_TARGET):
		push_error("Drop-target state no longer overrides the rarity field")
		get_tree().quit(1)
		return

	print("[RENDER] Verified equipment rarity fields and non-equipment fallback; saved ", OUTPUT_PATH)
	get_tree().quit()


func _color_matches(actual: Color, expected: Color) -> bool:
	return (
		abs(roundi(actual.r * 255.0) - roundi(expected.r * 255.0)) <= 1
		and abs(roundi(actual.g * 255.0) - roundi(expected.g * 255.0)) <= 1
		and abs(roundi(actual.b * 255.0) - roundi(expected.b * 255.0)) <= 1
	)


func _sample_slot(image: Image, slot: Control, capture_scale: Vector2) -> Color:
	var sample_point := (
		slot.get_global_transform_with_canvas() * Vector2(SAMPLE_OFFSET)
	) * capture_scale
	return image.get_pixelv(Vector2i(sample_point.round()))
