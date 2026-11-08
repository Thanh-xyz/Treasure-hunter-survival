extends PanelContainer
class_name GemPanel

## Socket stone panel (brainstorm sheet 07 §4, plan phase B). Opened from InventoryPanel for an
## equipped item: 8 sockets, the stones in the bag, and 6 → 1 fusion. Every change goes through
## InventoryData (socket_gem / unsocket_gem / fuse_gems), which are single transactions.
## Editing is locked while a monster is close (sheet 07 §4.5: no swapping during combat).
##
## Scene tree (GemPanel.tscn):
##   GemPanel ─ RootVBox ─ TitleRow (TitleLabel, CloseBtn), StatsLabel, SlotsTitleLabel,
##              SlotsContainer, AvailableTitleLabel, ScrollContainer/AvailableGrid, NoStonesLabel

signal gem_socketed(equip_slot: String, gem_index: int)
signal gem_unsocketed(equip_slot: String, gem_index: int)
signal gems_fused(stone_id: String)
signal panel_closed

const COMBAT_LOCK_RADIUS := 160.0
const SOCKET_COLUMNS := 4

var inventory: InventoryData
var equip_slot: String = ""
var equipment_item: ItemData = null
## Optional node used for the combat lock (the local player). Null = never locked.
var owner_node: Node2D = null

@onready var title_label: Label = $RootVBox/TitleRow/TitleLabel
@onready var close_btn: Button = $RootVBox/TitleRow/CloseBtn
@onready var stats_label: Label = $RootVBox/StatsLabel
@onready var slots_title_label: Label = $RootVBox/SlotsTitleLabel
@onready var slots_container: VBoxContainer = $RootVBox/SlotsContainer
@onready var available_title_label: Label = $RootVBox/AvailableTitleLabel
@onready var available_grid: GridContainer = $RootVBox/ScrollContainer/AvailableGrid
@onready var no_stones_label: Label = $RootVBox/NoStonesLabel


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)


func setup(inv: InventoryData, slot: String, holder_owner: Node2D = null) -> void:
	inventory = inv
	equip_slot = slot
	owner_node = holder_owner
	if inventory and not inventory.inventory_changed.is_connected(_refresh):
		inventory.inventory_changed.connect(_refresh)
	_refresh()


func is_combat_locked() -> bool:
	if owner_node == null or not is_instance_valid(owner_node) or not owner_node.is_inside_tree():
		return false
	return Combat.nearest_in_group(owner_node.get_tree(), "monster", owner_node.global_position, COMBAT_LOCK_RADIUS) != null


func _refresh() -> void:
	equipment_item = inventory.get_equipped(equip_slot) if inventory else null
	if equipment_item == null:
		visible = false
		return
	visible = true
	title_label.text = "Stones: %s" % equipment_item.name
	title_label.add_theme_color_override("font_color", equipment_item.get_rarity_color())
	_update_stats()
	_draw_sockets()
	_draw_bag_stones()


func _update_stats() -> void:
	var parts: Array[String] = []
	for stone_id: String in equipment_item.get_gem_sockets():
		if not stone_id.is_empty():
			parts.append(GemCatalog.describe(stone_id))
	stats_label.text = ", ".join(parts) if not parts.is_empty() else "No stones socketed"
	if is_combat_locked():
		stats_label.text += "\nIn combat: stones are locked"


func _draw_sockets() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	var sockets := equipment_item.get_gem_sockets()
	slots_title_label.text = "Sockets (%d/%d):" % [equipment_item.count_socketed_gems(), sockets.size()]
	var grid := GridContainer.new()
	grid.columns = SOCKET_COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	slots_container.add_child(grid)
	for i in range(sockets.size()):
		grid.add_child(_socket_cell(i, sockets[i]))


func _socket_cell(index: int, stone_id: String) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(146, 64)
	btn.add_theme_font_size_override("font_size", 18)
	btn.clip_text = true
	if stone_id.is_empty():
		btn.text = "Empty"
		btn.disabled = true
	else:
		var stone := ItemDatabase.get_item(stone_id)
		btn.text = _short_name(stone_id)
		btn.tooltip_text = "%s\nTap to remove" % GemCatalog.describe(stone_id)
		if stone:
			btn.add_theme_color_override("font_color", GemCatalog.tier_color(stone_id))
		btn.disabled = is_combat_locked()
		btn.pressed.connect(_on_socket_pressed.bind(index))
	return btn


func _draw_bag_stones() -> void:
	for child in available_grid.get_children():
		child.queue_free()
	var first_empty := equipment_item.get_gem_sockets().find("")
	var locked := is_combat_locked()
	var seen := {}
	for i in range(inventory.inventory_slots.size()):
		var item: ItemData = inventory.inventory_slots[i].get("item")
		if item == null or not item.is_gem() or seen.has(item.id):
			continue
		seen[item.id] = true
		var count := inventory.get_item_count(item.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var socket_btn := Button.new()
		socket_btn.text = "%s  x%d" % [GemCatalog.display_name(item.id), count]
		socket_btn.tooltip_text = GemCatalog.describe(item.id)
		socket_btn.icon = item.get_icon()
		socket_btn.expand_icon = true
		socket_btn.custom_minimum_size = Vector2(420, 56)
		socket_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		socket_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		socket_btn.add_theme_font_size_override("font_size", 20)
		socket_btn.add_theme_color_override("font_color", GemCatalog.tier_color(item.id))
		socket_btn.disabled = locked or first_empty < 0
		socket_btn.pressed.connect(_on_bag_stone_pressed.bind(i, first_empty))
		row.add_child(socket_btn)
		var fuse_btn := Button.new()
		fuse_btn.text = "Fuse %d to 1" % GemCatalog.fuse_cost()
		fuse_btn.custom_minimum_size = Vector2(150, 56)
		fuse_btn.add_theme_font_size_override("font_size", 20)
		fuse_btn.disabled = GemCatalog.fuse_result(item.id).is_empty() or count < GemCatalog.fuse_cost()
		fuse_btn.pressed.connect(_on_fuse_pressed.bind(item.id))
		row.add_child(fuse_btn)
		available_grid.add_child(row)
	no_stones_label.visible = seen.is_empty()


## "Inferno Stone II" -> "Inferno II": fits the socket cells on a phone screen.
func _short_name(stone_id: String) -> String:
	return GemCatalog.display_name(stone_id).replace(" Stone", "")


func _on_socket_pressed(index: int) -> void:
	if inventory == null or is_combat_locked():
		return
	var stone_id: String = equipment_item.get_gem_sockets()[index]
	if inventory.unsocket_gem(equip_slot, index):
		gem_unsocketed.emit(equip_slot, index)
		GameEvent.gem_unsocketed.emit(equip_slot, stone_id)
	else:
		NotificationManager.show_warning("Bag is full")


func _on_bag_stone_pressed(inventory_index: int, gem_index: int) -> void:
	if inventory == null or gem_index < 0 or is_combat_locked():
		return
	var stone: ItemData = inventory.get_item_at(inventory_index).get("item")
	if inventory.socket_gem(equip_slot, gem_index, inventory_index):
		gem_socketed.emit(equip_slot, gem_index)
		GameEvent.gem_socketed.emit(equip_slot, stone.id if stone else "")


func _on_fuse_pressed(stone_id: String) -> void:
	if inventory == null:
		return
	if inventory.fuse_gems(stone_id):
		gems_fused.emit(stone_id)
		GameEvent.gems_fused.emit(stone_id, GemCatalog.fuse_result(stone_id))
	else:
		NotificationManager.show_warning("Cannot fuse right now")


func _on_close_pressed() -> void:
	panel_closed.emit()
	queue_free()
