class_name GearSlotPanel
extends PanelContainer
## Opened from a HUD equipment slot: what is worn there, items in the bag that fit, and the
## actions (wear, take off, socket stones). Every change goes through InventoryData.

signal closed

var inventory: InventoryData
var slot_type: String = ""
var _body: VBoxContainer


func setup(inv: InventoryData, slot: String) -> void:
	inventory = inv
	slot_type = slot
	custom_minimum_size = Vector2(560, 0)
	add_theme_stylebox_override("panel", UiTheme.box(UiTheme.C_PANEL, UiTheme.C_TRIM, 3))
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	add_child(_body)
	if not inventory.inventory_changed.is_connected(_rebuild):
		inventory.inventory_changed.connect(_rebuild)
		inventory.equipment_changed.connect(func(_s: String) -> void: _rebuild())
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	for c in _body.get_children():
		c.queue_free()
	var head := HBoxContainer.new()
	_body.add_child(head)
	var title := UiTheme.label(slot_type.capitalize(), 26, UiTheme.C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiTheme.button("X", _close, Vector2(56, 48)))
	var worn := inventory.get_equipped(slot_type)
	if worn != null:
		_body.add_child(_item_row(worn, -1))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		_body.add_child(actions)
		actions.add_child(UiTheme.button("Take off", _take_off, Vector2(0, 52)))
		actions.add_child(UiTheme.button("Stones %d/%d" % [worn.count_socketed_gems(), worn.get_gem_slot_count()], _open_stones, Vector2(0, 52)))
	else:
		_body.add_child(UiTheme.label("Nothing worn here.", 20, UiTheme.C_MUTED))
	_body.add_child(UiTheme.label("In your bag:", 20, UiTheme.C_TEXT))
	var any := false
	for i in range(inventory.inventory_slots.size()):
		var item: ItemData = inventory.inventory_slots[i].get("item")
		if item != null and item.get_equipment_slot() == slot_type:
			any = true
			_body.add_child(_item_row(item, i))
	if not any:
		_body.add_child(UiTheme.label("No %s in the bag." % slot_type, 18, UiTheme.C_MUTED))


func _item_row(item: ItemData, bag_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.texture = item.get_icon()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UiTheme.label("%s  Lv.%d" % [item.name, item.enhancement_level], 20, item.get_rarity_color()))
	var stats := item.get_line_stats()
	info.add_child(UiTheme.label("HP +%d  ATK +%d  SPD +%d" % [int(stats.get("hp", 0)), int(stats.get("attack", 0)), int(stats.get("move_speed", 0))], 16, UiTheme.C_MUTED))
	if bag_index >= 0:
		row.add_child(UiTheme.button("Wear", _wear.bind(bag_index), Vector2(110, 52)))
	return row


func _take_off() -> void:
	if not inventory.unequip_item(slot_type):
		GameEvent.toast.emit("Bag is full", UiTheme.C_BAD)


func _wear(bag_index: int) -> void:
	if not inventory.equip_item(bag_index):
		GameEvent.toast.emit("Cannot wear that now", UiTheme.C_BAD)


func _open_stones() -> void:
	var gem_panel: GemPanel = preload("res://sense/ui/gems/GemPanel.tscn").instantiate()
	get_parent().add_child(gem_panel)
	gem_panel.position = Vector2(40, 300)
	gem_panel.setup(inventory, slot_type, GameState.get_player() as Node2D)
	_close()


func _close() -> void:
	closed.emit()
	queue_free()
