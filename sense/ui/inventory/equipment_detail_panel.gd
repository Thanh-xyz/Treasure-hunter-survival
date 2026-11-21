class_name EquipmentDetailPanel
extends Control

signal closed

# Original Ember UI kit icons at 2× (32 px) so they scale by an integer (ART_BIBLE.md).
const STAT_ICON_SIZE := 32
var ICON_GOLD: Texture2D = ArtCatalog.texture("ui.icon.gold", 2)
var ICON_HEALTH: Texture2D = ArtCatalog.texture("ui.icon.health", 2)
var ICON_DAMAGE: Texture2D = ArtCatalog.texture("ui.icon.damage", 2)
var ICON_SPEED: Texture2D = ArtCatalog.texture("ui.icon.speed", 2)

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
	_modal.anchor_top = 0.55
	_modal.anchor_right = 0.5
	_modal.anchor_bottom = 0.55
	_modal.offset_left = -264.0
	_modal.offset_top = -273.0
	_modal.offset_right = 264.0
	_modal.offset_bottom = 273.0
	_modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_modal.add_theme_stylebox_override("panel", ArtCatalog.stylebox("ui.panel.default"))
	add_child(_modal)

	var ember_rule := ColorRect.new()
	ember_rule.position = Vector2(28, 13)
	ember_rule.size = Vector2(64, 4)
	ember_rule.color = ArtPalette.color("y")
	ember_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(ember_rule)

	_item_field = Panel.new()
	_item_field.name = "ItemField"
	_item_field.position = Vector2(28, 30)
	_item_field.size = Vector2(84, 84)
	_modal.add_child(_item_field)

	_item_icon = TextureRect.new()
	_item_icon.name = "ItemIcon"
	_item_icon.position = Vector2(10, 10)
	_item_icon.size = Vector2(64, 64)
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_field.add_child(_item_icon)

	_name_label = _label("", 32, UiTheme.C_TEXT)
	_name_label.name = "ItemName"
	_name_label.position = Vector2(128, 30)
	_name_label.size = Vector2(298, 50)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_modal.add_child(_name_label)

	_level_label = _label("", 24, UiTheme.C_GOLD)
	_level_label.name = "Level"
	_level_label.position = Vector2(128, 82)
	_level_label.size = Vector2(298, 32)
	_modal.add_child(_level_label)

	var stats_label := _label("Thuộc tính", 22, UiTheme.C_MUTED)
	stats_label.position = Vector2(28, 128)
	_modal.add_child(stats_label)

	_stats = VBoxContainer.new()
	_stats.name = "Stats"
	_stats.position = Vector2(28, 160)
	_stats.size = Vector2(472, 176)
	_stats.add_theme_constant_override("separation", 5)
	_modal.add_child(_stats)

	_description = _label("", 23, UiTheme.C_TEXT)
	_description.name = "Description"
	_description.position = Vector2(28, 356)
	_description.size = Vector2(472, 68)
	_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.max_lines_visible = 2
	_description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_modal.add_child(_description)

	_remove_button = _action_button("Tháo", Vector2(28, 432), Vector2(126, 88))
	_remove_button.name = "RemoveButton"
	_remove_button.add_theme_stylebox_override("normal", ArtCatalog.stylebox("ui.button.secondary"))
	_remove_button.add_theme_stylebox_override("hover", ArtCatalog.stylebox("ui.button.secondary.hover"))
	_remove_button.add_theme_stylebox_override("pressed", ArtCatalog.stylebox("ui.button.secondary.pressed"))
	_remove_button.pressed.connect(_on_remove_pressed)
	_modal.add_child(_remove_button)

	_upgrade_button = _action_button("Nâng cấp", Vector2(166, 432), Vector2(196, 88))
	_upgrade_button.name = "UpgradeButton"
	_upgrade_button.icon = ICON_GOLD
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_modal.add_child(_upgrade_button)

	_sell_button = _action_button("Bán", Vector2(374, 432), Vector2(126, 88))
	_sell_button.name = "SellButton"
	_sell_button.disabled = true
	_sell_button.add_theme_stylebox_override("disabled", UiTheme.box(ArtPalette.color("o"), UiTheme.C_TRIM, 2))
	_sell_button.add_theme_color_override("font_disabled_color", UiTheme.C_MUTED)
	_sell_button.tooltip_text = "Chưa hỗ trợ bán trực tiếp trang bị đang mặc."
	_modal.add_child(_sell_button)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.position = Vector2(428, 20)
	close_button.size = Vector2(88, 88)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 40)
	close_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close_button.add_theme_stylebox_override("hover", ArtCatalog.stylebox("ui.panel.dark"))
	close_button.add_theme_stylebox_override("pressed", ArtCatalog.stylebox("ui.panel.dark"))
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
	_name_label.tooltip_text = item.name
	_level_label.text = "Cấp %d (Tối đa %d)" % [item.enhancement_level, item.max_upgrade_level]
	_description.text = item.description
	_description.tooltip_text = item.description
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
		_stats.remove_child(child)
		child.queue_free()
	var health := item.get_scaled_health_bonus()
	var attack := item.get_scaled_attack_bonus()
	var speed := item.get_scaled_speed_bonus()
	var defense := item.get_scaled_defense_bonus()
	if health != 0:
		_add_stat_row(ICON_HEALTH, "Máu", _signed_number(health, 0))
	if attack != 0:
		_add_stat_row(ICON_DAMAGE, "Tấn công", _signed_number(attack, 0))
	if speed != 0.0:
		_add_stat_row(ICON_SPEED, "Tốc độ", _signed_number(speed, 0))
	if defense != 0:
		_add_stat_row(null, "Phòng thủ", _signed_number(defense, 0))
	if _stats.get_child_count() == 0:
		var empty := _label("Không có thuộc tính cộng thêm", 24, UiTheme.C_MUTED)
		empty.name = "EmptyStats"
		_stats.add_child(empty)


func _add_stat_row(icon: Texture2D, title: String, value: String) -> void:
	var strip := PanelContainer.new()
	strip.custom_minimum_size.y = 40
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = ArtPalette.color("o")
	style.border_color = ArtPalette.color("A")
	style.border_width_left = 4
	style.content_margin_left = 12
	style.content_margin_right = 14
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	strip.add_theme_stylebox_override("panel", style)
	_stats.add_child(strip)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	strip.add_child(row)

	var glyph := TextureRect.new()
	glyph.texture = icon
	glyph.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)

	var title_label := _label(title, 24, UiTheme.C_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)

	var value_label := _label(value, 28, UiTheme.C_GOLD)
	value_label.name = "Value"
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)


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


func _item_field_style(rarity: int) -> StyleBoxFlat:
	var style := UiTheme.box(InventorySlotUI.get_rarity_field_color(rarity), Color8(31, 29, 34), 4)
	style.set_corner_radius_all(2)
	return style
