class_name EquipmentDetailPanel
extends Control

signal closed

const BUTTON_BLUE := preload("res://assets/treasure_hunter/ui/reference/button_blue.png")
const ICON_GOLD := preload("res://assets/treasure_hunter/ui/reference/icon_gold.png")
const ICON_HEALTH := preload("res://assets/treasure_hunter/ui/reference/icon_health.png")
const ICON_DAMAGE := preload("res://assets/treasure_hunter/ui/reference/icon_damage.png")
const ICON_SPEED := preload("res://assets/treasure_hunter/ui/reference/icon_speed.png")

var inventory_data: InventoryData
var slot_type := ""

var _modal: Panel
var _name_label: Label
var _level_label: Label
var _item_field: Panel
var _item_icon: TextureRect
var _stats: VBoxContainer
var _description: Label
var _remove_button: Button
var _upgrade_button: Button
var _sell_button: Button


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	visible = false


func _exit_tree() -> void:
	_disconnect_inventory()


func setup(data: InventoryData, target_slot_type: String) -> void:
	_disconnect_inventory()
	inventory_data = data
	slot_type = target_slot_type
	_connect_inventory()
	visible = true
	_refresh()
	move_to_front()


func close_panel() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_modal = Panel.new()
	_modal.name = "Modal"
	_modal.anchor_left = 0.5
	_modal.anchor_top = 0.69
	_modal.anchor_right = 0.5
	_modal.anchor_bottom = 0.69
	_modal.offset_left = -240.0
	_modal.offset_top = -235.0
	_modal.offset_right = 240.0
	_modal.offset_bottom = 235.0
	_modal.add_theme_stylebox_override("panel", _panel_style())
	add_child(_modal)

	_name_label = _label("Item Name", 32, UiTheme.C_TEXT)
	_name_label.name = "ItemName"
	_name_label.position = Vector2(24, 18)
	_name_label.size = Vector2(432, 42)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal.add_child(_name_label)

	_level_label = _label("Level 1 (Max 10)", 23, UiTheme.C_TEXT)
	_level_label.name = "Level"
	_level_label.position = Vector2(24, 58)
	_level_label.size = Vector2(432, 34)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal.add_child(_level_label)

	var separator := ColorRect.new()
	separator.name = "HeaderSeparator"
	separator.position = Vector2(24, 100)
	separator.size = Vector2(432, 2)
	separator.color = Color(0.12, 0.11, 0.14, 0.85)
	_modal.add_child(separator)

	_item_field = Panel.new()
	_item_field.name = "ItemField"
	_item_field.position = Vector2(52, 126)
	_item_field.size = Vector2(104, 104)
	_modal.add_child(_item_field)

	_item_icon = TextureRect.new()
	_item_icon.name = "ItemIcon"
	_item_icon.position = Vector2(8, 8)
	_item_icon.size = Vector2(88, 88)
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_item_field.add_child(_item_icon)

	_stats = VBoxContainer.new()
	_stats.name = "Stats"
	_stats.position = Vector2(184, 122)
	_stats.size = Vector2(244, 132)
	_stats.add_theme_constant_override("separation", 5)
	_modal.add_child(_stats)

	_description = _label("", 23, UiTheme.C_TEXT)
	_description.name = "Description"
	_description.position = Vector2(34, 268)
	_description.size = Vector2(412, 62)
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal.add_child(_description)

	_remove_button = _action_button("Tháo", Vector2(30, 360), Vector2(126, 70))
	_remove_button.name = "RemoveButton"
	_apply_flat_button_styles(_remove_button, Color8(96, 97, 101), Color8(144, 145, 148))
	_remove_button.pressed.connect(_on_remove_pressed)
	_modal.add_child(_remove_button)

	_upgrade_button = _action_button("Nâng cấp", Vector2(174, 360), Vector2(132, 70))
	_upgrade_button.name = "UpgradeButton"
	_upgrade_button.icon = ICON_GOLD
	_apply_texture_button_styles(_upgrade_button)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_modal.add_child(_upgrade_button)

	_sell_button = _action_button("Bán", Vector2(324, 360), Vector2(126, 70))
	_sell_button.name = "SellButton"
	_sell_button.disabled = true
	_sell_button.tooltip_text = "Chưa hỗ trợ bán trực tiếp trang bị đang mặc."
	_apply_flat_button_styles(_sell_button, Color8(179, 44, 58), Color8(235, 75, 86))
	_modal.add_child(_sell_button)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.position = Vector2(424, 10)
	close_button.size = Vector2(42, 42)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.pressed.connect(close_panel)
	_modal.add_child(close_button)


func _refresh() -> void:
	if inventory_data == null or slot_type.is_empty():
		close_panel()
		return
	var item := inventory_data.get_equipped(slot_type)
	if item == null:
		close_panel()
		return

	_name_label.text = item.name
	_level_label.text = "Cấp %d (Tối đa %d)" % [item.enhancement_level, item.max_upgrade_level]
	_description.text = item.description
	_item_icon.texture = item.get_icon()
	_item_field.add_theme_stylebox_override("panel", _item_field_style(item.rarity))
	_rebuild_stats(item)

	var can_upgrade := item.can_upgrade_further()
	var cost := item.get_upgrade_cost() if can_upgrade else 0
	_upgrade_button.text = "%d\nNâng cấp" % cost if can_upgrade else "Không thể\nNâng cấp"
	_upgrade_button.disabled = not can_upgrade or inventory_data.gold < cost
	_upgrade_button.tooltip_text = (
		"Cần %d Vàng." % cost if can_upgrade else "Trang bị này không thể nâng cấp."
	)
	_remove_button.disabled = false
	_remove_button.tooltip_text = "Tháo trang bị vào túi đồ."
	_sell_button.text = "%d\nBán" % item.sell_price if item.sell_price > 0 else "Không thể\nBán"


func _rebuild_stats(item: ItemData) -> void:
	for child in _stats.get_children():
		child.queue_free()
	var rows := 0
	if item.health_bonus != 0:
		_add_stat_row(ICON_HEALTH, _signed_number(item.get_scaled_health_bonus(), 0))
		rows += 1
	if item.attack_bonus != 0:
		_add_stat_row(ICON_DAMAGE, _signed_number(item.get_scaled_attack_bonus(), 0))
		rows += 1
	if item.speed_bonus != 0.0:
		_add_stat_row(ICON_SPEED, _signed_number(item.get_scaled_speed_bonus(), 2))
		rows += 1
	if item.defense_bonus != 0:
		_add_stat_row(null, "DEF %s" % _signed_number(item.get_scaled_defense_bonus(), 0))
		rows += 1
	if rows == 0:
		var empty := _label("Không có thuộc tính cộng thêm", 20, UiTheme.C_MUTED)
		empty.name = "EmptyStats"
		_stats.add_child(empty)


func _add_stat_row(icon: Texture2D, value: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 8)
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon_rect)
	var value_label := _label(value, 24, UiTheme.C_TEXT)
	row.add_child(value_label)
	_stats.add_child(row)


func _signed_number(value: float, decimals: int) -> String:
	if decimals == 0:
		return "%+d" % roundi(value)
	if decimals == 1:
		return "%+.1f" % value
	return "%+.2f" % value


func _on_upgrade_pressed() -> void:
	if inventory_data == null:
		return
	if not inventory_data.upgrade_equipment(slot_type):
		_refresh()


func _on_remove_pressed() -> void:
	if inventory_data == null:
		return
	if not inventory_data.unequip_item(slot_type):
		_remove_button.tooltip_text = "Túi đồ đã đầy."


func _on_equipment_changed(changed_slot_type: String) -> void:
	if visible and changed_slot_type == slot_type:
		_refresh()


func _on_gold_changed(_amount: int) -> void:
	if visible:
		_refresh()


func _connect_inventory() -> void:
	if inventory_data == null:
		return
	if not inventory_data.equipment_changed.is_connected(_on_equipment_changed):
		inventory_data.equipment_changed.connect(_on_equipment_changed)
	if not inventory_data.gold_changed.is_connected(_on_gold_changed):
		inventory_data.gold_changed.connect(_on_gold_changed)


func _disconnect_inventory() -> void:
	if inventory_data == null:
		return
	if inventory_data.equipment_changed.is_connected(_on_equipment_changed):
		inventory_data.equipment_changed.disconnect(_on_equipment_changed)
	if inventory_data.gold_changed.is_connected(_on_gold_changed):
		inventory_data.gold_changed.disconnect(_on_gold_changed)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _action_button(text: String, position: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := UiTheme.box(Color8(75, 70, 80), Color8(143, 143, 146), 5)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 6
	return style


func _item_field_style(rarity: int) -> StyleBoxFlat:
	var style := UiTheme.box(InventorySlotUI.get_rarity_field_color(rarity), Color8(31, 29, 34), 4)
	style.set_corner_radius_all(2)
	return style


func _apply_texture_button_styles(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxTexture.new()
		style.texture = BUTTON_BLUE
		style.texture_margin_left = 14
		style.texture_margin_top = 14
		style.texture_margin_right = 14
		style.texture_margin_bottom = 14
		if state == "hover":
			style.modulate_color = Color(1.08, 1.08, 1.08, 1)
		elif state == "pressed":
			style.modulate_color = Color(0.82, 0.82, 0.82, 1)
		button.add_theme_stylebox_override(state, style)
	var disabled := _flat_button_style(Color8(54, 58, 65), Color8(92, 94, 99))
	button.add_theme_stylebox_override("disabled", disabled)


func _apply_flat_button_styles(button: Button, base: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _flat_button_style(base, border))
	button.add_theme_stylebox_override("hover", _flat_button_style(base.lightened(0.08), border.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _flat_button_style(base.darkened(0.1), border))
	button.add_theme_stylebox_override("disabled", _flat_button_style(base.darkened(0.35), border.darkened(0.35)))


func _flat_button_style(base: Color, border: Color) -> StyleBoxFlat:
	var style := UiTheme.box(base, border, 3)
	style.set_corner_radius_all(1)
	return style
