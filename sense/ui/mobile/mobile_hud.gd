class_name MobileHUD
extends Control
## Portrait mobile HUD layered on top of the legacy HUD CanvasLayer.
##
## Regions (720x1600 logical), measured from a direct 4.3.6 device capture:
##   top-left    square portrait and four-row stat stack
##   top-right   map/system buttons and three-row world/resource stack
##   side rails  four square navigation buttons on each side
##   right       quest tracker and world-boss timer
##   top         boss bar (when a boss is engaged)
##   lower field fixed compass joystick
##   bottom      eight contiguous action slots
##   overlays    toasts, death panel, GameMenu

const BTN_ICONS := {
	"bag": "bag", "hero": "helmet_horned", "pet": "heart", "mount": "boot_green",
	"quest": "scroll", "map": "gem_green", "village": "wood", "system": "gamepad",
}
const HUD_PANEL := preload("res://assets/treasure_hunter/ui/reference/panel_stats.png")
const MENU_BUTTON := preload("res://assets/treasure_hunter/ui/reference/button_menu.png")
const MINIMIZE_ICON := preload("res://assets/treasure_hunter/ui/reference/icon_minimize.png")
const WEAPON_ICON := preload("res://assets/treasure_hunter/ui/reference/icon_weapon.png")

var legacy_hud: CanvasLayer = null
var player: Node = null

var game_menu: GameMenu
var joystick: VirtualJoystick
var attack_btn: ActionButton
var auto_farm_btn: ActionButton
var skill_btns: Array[ActionButton] = []
var gear_btn: ActionButton
var potion_btn: ActionButton
var mount_btn: ActionButton
var interact_btn: ActionButton
var _hotbar_slots: Array[ActionButton] = []
var _hotbar_fill: ColorRect
var _hotbar_frame: NinePatchRect

var _hp_bar: ProgressBar
var _hp_label: Label
var _en_bar: ProgressBar
var _xp_bar: ProgressBar
var _name_label: Label
var _attack_label: Label
var _speed_label: Label
var _world_time_label: Label
var _world_coord_label: Label
var _world_gold_label: Label
var _portrait: TextureRect
var _zone_label: Label
var _quest_box: VBoxContainer
var _boss_timer_label: Label
var _boss_panel: PanelContainer
var _boss_bar: ProgressBar
var _boss_label: Label
var _toast_box: VBoxContainer
var _death_panel: Control
var _death_button: Button
var _quest_tracker: Control
var _fold_button: Button
var _hud_collapsed: bool = false
var _death_timer: float = 0.0
var _controls: Array[Control] = []
var _foldable_controls: Array[Control] = []
var _quest_btn_badge_t: float = 0.0
var _world_info_t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	_hud_collapsed = bool(GameState.settings.get("compact_hud", false))
	# This node is parented directly to a CanvasLayer, so use an explicit logical
	# viewport rect rather than full-rect anchors with no Control parent.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_player_card()
	_build_left_panel()
	_build_boss_bar()
	_build_menu_rail()
	_build_controls()
	_build_toasts()
	_build_death_panel()
	game_menu = GameMenu.new()
	add_child(game_menu)

	GameEvent.toast.connect(show_toast)
	GameEvent.open_menu.connect(func(id: String) -> void: open_menu(id))
	GameEvent.player_died.connect(_on_player_died)
	GameEvent.player_respawned.connect(func() -> void: _death_panel.visible = false)
	GameEvent.boss_state_changed.connect(_on_boss_state)
	GameEvent.world_boss_timer.connect(_on_world_boss_timer)
	GameEvent.zone_entered.connect(_on_zone_entered)
	GameState.xp_changed.connect(func(_l: int, _x: int, _n: int) -> void: _refresh_card())
	GameState.hero_changed.connect(func(_h: String) -> void: _refresh_card())
	GameState.mount_changed.connect(func(_m: String, _r: bool) -> void: _refresh_controls())
	GameState.leveled_up.connect(func(_l: int) -> void: _refresh_controls())
	QuestService.quests_changed.connect(_refresh_quests)
	QuestService.quest_completed.connect(func(_id: String, qname: String) -> void: show_toast("Reward claimed: %s" % qname, UiTheme.C_GOLD))


## Called by Main once the player exists
func bind_player(p: Node, hud: CanvasLayer) -> void:
	player = p
	legacy_hud = hud
	_adapt_legacy_hud()
	var stats: CharacterStats = p.get("stats")
	stats.health_changed.connect(_on_hp_changed)
	stats.stamina_changed.connect(_on_stamina_changed)
	_on_hp_changed(stats.current_health, stats.max_health)
	_on_stamina_changed(stats.current_stamina, stats.max_stamina)
	var inv: InventoryData = p.get_inventory()
	inv.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(inv.gold)
	var runner: HeroSkillRunner = p.get("hero_skills")
	if runner:
		runner.cooldowns_changed.connect(_refresh_controls)
	_refresh_card()
	_refresh_controls()
	_refresh_quests()


func _on_hp_changed(c: int, m: int) -> void:
	_hp_bar.max_value = m
	_hp_bar.value = c
	_hp_label.text = "%d/%d" % [c, m]


func _on_stamina_changed(c: float, m: float) -> void:
	if _en_bar:
		_en_bar.max_value = m
		_en_bar.value = c


func _on_gold_changed(g: int) -> void:
	if _world_gold_label:
		_world_gold_label.text = str(g)


# =============================================================================
# LEGACY HUD ADAPTATION
# =============================================================================

func _adapt_legacy_hud() -> void:
	if legacy_hud == null:
		return
	# The captured mobile HUD has no legacy landscape bars, minimap or feed.
	for path in ["MarginContainer", "MinimapContainer", "FeedContainer", "HotbarAnchor"]:
		var n := legacy_hud.get_node_or_null(path) as CanvasItem
		if n:
			n.visible = false
	var icons := legacy_hud.get_node_or_null("StatusIconsContainer") as Control
	if icons:
		icons.position = Vector2(12, 370)
	# Fit legacy popups (designed for 1280x720) into the portrait screen
	legacy_hud.child_entered_tree.connect(_on_legacy_child_added)
	for c in legacy_hud.get_children():
		_on_legacy_child_added(c)


func _on_legacy_child_added(node: Node) -> void:
	if node == self or not node is Control:
		return
	var known := ["MarginContainer", "StatusIconsContainer", "MinimapContainer", "FeedContainer", "HotbarAnchor"]
	if known.has(String(node.name)):
		return
	_fit_legacy_popup.call_deferred(node)


## Scale a full-rect legacy popup so its 1280-wide layout fits the screen
func _fit_legacy_popup(node) -> void:
	if not is_instance_valid(node):
		return
	var c := node as Control
	if c == null:
		return
	var vp := get_viewport_rect().size
	var design_w := 1280.0
	if c.name == "InventoryPanel" or c is AugmentPanel:
		design_w = 760.0
	var s := minf(1.0, vp.x / design_w)
	if s >= 1.0:
		return
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = Vector2.ZERO
	c.size = vp / s
	c.scale = Vector2(s, s)


func _legacy_overlay_open() -> bool:
	if legacy_hud == null:
		return false
	var vp := get_viewport_rect().size
	for c in legacy_hud.get_children():
		if c == self or not c is Control:
			continue
		var ctrl := c as Control
		if not ctrl.visible:
			continue
		if ["MarginContainer", "StatusIconsContainer", "MinimapContainer", "FeedContainer", "HotbarAnchor"].has(String(ctrl.name)):
			continue
		var area := ctrl.size * ctrl.scale
		if area.x * area.y >= vp.x * vp.y * 0.4:
			return true
	return false


# =============================================================================
# BUILD
# =============================================================================

func _panel(rect: Rect2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func _build_player_card() -> void:
	var frame := Button.new()
	frame.position = Vector2(18, 18)
	frame.size = Vector2(98, 98)
	frame.focus_mode = Control.FOCUS_NONE
	frame.add_theme_stylebox_override("normal", UiTheme.box(Color(0.08, 0.08, 0.08, 0.96), UiTheme.C_TRIM, 4))
	frame.add_theme_stylebox_override("hover", UiTheme.box(Color(0.12, 0.12, 0.13, 0.96), UiTheme.C_GOLD, 4))
	frame.add_theme_stylebox_override("pressed", UiTheme.box(Color(0.20, 0.10, 0.04, 0.96), UiTheme.C_GOLD, 4))
	frame.pressed.connect(func() -> void: _on_menu_button("bag"))
	add_child(frame)
	_portrait = TextureRect.new()
	_portrait.texture = GameMenu.hero_portrait()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait.offset_left = 8
	_portrait.offset_top = 8
	_portrait.offset_right = -8
	_portrait.offset_bottom = -8
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_portrait)

	_xp_bar = UiTheme.bar(Color(0.12, 0.62, 0.96), 7)
	_xp_bar.position = Vector2(28, 124)
	_xp_bar.size = Vector2(78, 7)
	add_child(_xp_bar)

	var stats := _panel(Rect2(8, 150, 180, 204))
	stats.add_theme_stylebox_override("panel", UiTheme.box(Color(0.04, 0.08, 0.06, 0.92), UiTheme.C_TRIM, 2))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	stats.add_child(col)
	var level_row := _hud_value_row("hud_helmet")
	_name_label = UiTheme.label("2,0", 20, UiTheme.C_GOLD)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_row.add_child(_name_label)
	col.add_child(level_row)
	var hp_row := Control.new()
	hp_row.custom_minimum_size = Vector2(0, 49)
	var hp_icon := TextureRect.new()
	hp_icon.texture = PixelArt.get_texture("hud_heart")
	hp_icon.position = Vector2(0, 2)
	hp_icon.size = Vector2(44, 44)
	hp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hp_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hp_row.add_child(hp_icon)
	_hp_bar = UiTheme.bar(Color(0.72, 0.06, 0.05), 25)
	_hp_bar.position = Vector2(50, 12)
	_hp_bar.size = Vector2(116, 25)
	hp_row.add_child(_hp_bar)
	_hp_label = UiTheme.label("100/100", 18)
	_hp_label.position = Vector2(50, 7)
	_hp_label.size = Vector2(116, 34)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_row.add_child(_hp_label)
	col.add_child(hp_row)
	var energy_row := _hud_value_row("hud_sword")
	_attack_label = UiTheme.label("10,0", 20, UiTheme.C_TEXT)
	_attack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_row.add_child(_attack_label)
	col.add_child(energy_row)
	var speed_row := _hud_value_row("hud_boot")
	_speed_label = UiTheme.label("2,00", 20, UiTheme.C_TEXT)
	_speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_row.add_child(_speed_label)
	col.add_child(speed_row)


func _hud_value_row(icon_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 49)
	row.add_theme_constant_override("separation", 4)
	var icon := TextureRect.new()
	icon.texture = PixelArt.get_texture(icon_name) if icon_name.begins_with("hud_") else ItemIconAtlas.get_named_icon(icon_name)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	return row


func _build_left_panel() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(488, 472)
	box.size = Vector2(224, 190)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_quest_tracker = box
	_zone_label = UiTheme.label("", 16, UiTheme.C_GOOD)
	box.add_child(_zone_label)
	_boss_timer_label = UiTheme.label("", 14, Color(1, 0.64, 0.3))
	box.add_child(_boss_timer_label)
	var qp := PanelContainer.new()
	qp.add_theme_stylebox_override("panel", UiTheme.box(Color(0.06, 0.045, 0.035, 0.72), Color(UiTheme.C_TRIM, 0.65), 1))
	box.add_child(qp)
	_quest_box = VBoxContainer.new()
	_quest_box.add_theme_constant_override("separation", 2)
	qp.add_child(_quest_box)


func _build_boss_bar() -> void:
	_boss_panel = _panel(Rect2(110, 374, 500, 48))
	_boss_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_boss_panel.add_child(v)
	_boss_label = UiTheme.label("Boss", 16, Color(1, 0.5, 0.35))
	v.add_child(_boss_label)
	_boss_bar = UiTheme.bar(Color(0.75, 0.15, 0.2), 14)
	v.add_child(_boss_bar)


func _build_menu_rail() -> void:
	_fold_button = _reference_icon_button(MINIMIZE_ICON, "Hide controls", _toggle_hud_chrome)
	_fold_button.position = Vector2(540, 18)
	var system_button := _reference_image_button(MENU_BUTTON, "Menu", func() -> void: _on_menu_button("system"))
	system_button.position = Vector2(622, 18)

	var resources := _panel(Rect2(532, 150, 180, 154))
	resources.add_theme_stylebox_override("panel", UiTheme.box(Color(0.04, 0.08, 0.06, 0.92), UiTheme.C_TRIM, 2))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 1)
	resources.add_child(rv)
	_world_time_label = _world_info_row(rv, "", "[Local] 00:00:00", UiTheme.C_TEXT)
	_world_coord_label = _world_info_row(rv, "hud_world", "0,00", UiTheme.C_TEXT)
	_world_gold_label = _world_info_row(rv, "hud_coin", "0", UiTheme.C_GOLD)
	_refresh_world_info()

	var left_ids := ["hero", "pet", "mount", "village"]
	for i in range(4):
		var left := _nav_button(left_ids[i], left_ids[i].capitalize())
		left.position = Vector2(12, 958 + i * 102)
		left.size = Vector2(90, 90)
		_foldable_controls.append(left)

	# Direct 4.3.6 capture places combat on the right rail. The starter hotbar
	# below remains empty instead of carrying an invented ATK slot.
	attack_btn = _action_btn("character_attack", Vector2(663, 1003), 45.0, "")
	attack_btn.icon = WEAPON_ICON
	_foldable_controls.append(attack_btn)

	var inventory_button := _nav_button("bag", "Inventory")
	inventory_button.position = Vector2(618, 1060)
	inventory_button.size = Vector2(90, 90)
	_foldable_controls.append(inventory_button)

	var pet_button := _nav_button("pet", "Pets")
	pet_button.position = Vector2(618, 1162)
	pet_button.size = Vector2(90, 90)
	_foldable_controls.append(pet_button)

	auto_farm_btn = _action_btn("", Vector2(663, 1309), 45.0, "")
	auto_farm_btn.radar_icon = true
	auto_farm_btn.tapped.connect(_toggle_auto_farm)
	_foldable_controls.append(auto_farm_btn)


func _nav_button(id: String, caption: String) -> Button:
	return _icon_button(BTN_ICONS[id], caption, func() -> void: _on_menu_button(id))


func _world_info_row(parent: VBoxContainer, icon_name: String, initial_text: String, color: Color) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 49)
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.035, 0.055, 0.04, 0.88), Color(UiTheme.C_TRIM, 0.8), 1))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	if icon_name != "":
		var icon := TextureRect.new()
		icon.texture = PixelArt.get_texture(icon_name) if icon_name.begins_with("hud_") else ItemIconAtlas.get_named_icon(icon_name)
		icon.custom_minimum_size = Vector2(46, 46)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
	var value := UiTheme.label(initial_text, 18, color)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	return value


func _icon_button(icon_name: String, caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(72, 72)
	b.size = Vector2(72, 72)
	b.text = ""
	b.tooltip_text = caption
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	var background := ColorRect.new()
	background.color = UiTheme.C_PANEL
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(background)

	var frame := NinePatchRect.new()
	frame.texture = HUD_PANEL
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_patch_margin(side, 6)
	b.add_child(frame)

	var icon := TextureRect.new()
	icon.texture = ItemIconAtlas.get_named_icon(icon_name)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 13
	icon.offset_top = 13
	icon.offset_right = -13
	icon.offset_bottom = -13
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	b.pressed.connect(callback)
	add_child(b)
	_controls.append(b)
	return b


func _reference_icon_button(texture: Texture2D, caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(72, 72)
	b.size = Vector2(72, 72)
	b.tooltip_text = caption
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	var background := ColorRect.new()
	background.color = UiTheme.C_PANEL
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(background)

	var frame := NinePatchRect.new()
	frame.texture = HUD_PANEL
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_patch_margin(side, 6)
	b.add_child(frame)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.position = Vector2(14, 13)
	icon.size = Vector2(44, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	b.pressed.connect(callback)
	add_child(b)
	_controls.append(b)
	return b


func _reference_image_button(texture: Texture2D, caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(72, 72)
	b.size = Vector2(72, 72)
	b.icon = texture
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = caption
	b.add_theme_constant_override("icon_max_width", 72)
	b.pressed.connect(callback)
	add_child(b)
	_controls.append(b)
	return b


func _build_controls() -> void:
	joystick = VirtualJoystick.new()
	joystick.position = Vector2(274, 980)
	joystick.size = Vector2(238, 300)
	add_child(joystick)

	var bottom_y := get_viewport_rect().size.y - 134.0
	_hotbar_fill = ColorRect.new()
	_hotbar_fill.color = Color(0.025, 0.025, 0.03, 0.96)
	_hotbar_fill.position = Vector2(10, bottom_y - 48.0)
	_hotbar_fill.size = Vector2(700, 108)
	_hotbar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hotbar_fill)
	_controls.append(_hotbar_fill)

	_hotbar_frame = NinePatchRect.new()
	_hotbar_frame.texture = HUD_PANEL
	_hotbar_frame.position = Vector2(4, bottom_y - 54.0)
	_hotbar_frame.size = Vector2(712, 120)
	_hotbar_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hotbar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_hotbar_frame.set_patch_margin(side, 8)
	add_child(_hotbar_frame)
	_controls.append(_hotbar_frame)

	var centers := [68.0, 152.0, 236.0, 320.0, 404.0, 488.0, 572.0, 656.0]
	for i in range(8):
		var slot := _action_btn("hotbar_%d" % (i + 1), Vector2(centers[i], bottom_y + 5.0), 40.0, "")
		slot.locked = true
		_hotbar_slots.append(slot)


func _action_btn(action: String, center: Vector2, r: float, caption: String) -> ActionButton:
	var b := ActionButton.new()
	b.action = action
	b.radius = r
	b.caption = caption
	b.position = center - Vector2(r, r)
	add_child(b)
	_controls.append(b)
	return b


func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.position = Vector2(70, 690)
	_toast_box.size = Vector2(580, 180)
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_death_panel() -> void:
	_death_panel = Control.new()
	_death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_panel.visible = false
	add_child(_death_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_panel.add_child(dim)
	_death_button = UiTheme.button("Hồi sinh làng", _respawn_town, Vector2(254, 80))
	_death_button.position = Vector2(233, 1192)
	_death_button.size = Vector2(254, 80)
	_death_button.add_theme_font_size_override("font_size", 34)
	_death_button.add_theme_color_override("font_color", UiTheme.C_GOLD)
	_death_panel.add_child(_death_button)


# =============================================================================
# RUNTIME
# =============================================================================

func _process(delta: float) -> void:
	_world_info_t -= delta
	if _world_info_t <= 0.0:
		_world_info_t = 0.5
		_refresh_world_info()
	_hud_collapsed = bool(GameState.settings.get("compact_hud", _hud_collapsed))
	var blocked := game_menu.visible or _legacy_overlay_open()
	var dead := _death_panel.visible
	joystick.enabled = not blocked
	for c in _controls:
		c.visible = not blocked
	if not blocked:
		for c in _foldable_controls:
			c.visible = not _hud_collapsed and not dead
	joystick.visible = not blocked and not _hud_collapsed
	if _quest_tracker:
		_quest_tracker.visible = not blocked and not _hud_collapsed and not dead
	if _death_panel.visible:
		_death_timer -= delta
		_death_button.disabled = _death_timer > 0.0
		_death_button.text = "Hồi sinh (%d)" % ceili(_death_timer) if _death_timer > 0.0 else "Hồi sinh làng"
	# Context interact button: highlight when something is in range
	var im := get_node_or_null("/root/InteractionManager")
	var areas: Variant = im.get("active_areas") if im != null else null
	var has_target: bool = areas is Array and not areas.is_empty()
	if interact_btn:
		interact_btn.locked = not has_target
	_quest_btn_badge_t -= delta
	if _quest_btn_badge_t <= 0.0:
		_quest_btn_badge_t = 0.5
		_refresh_controls()


func _refresh_card() -> void:
	var hero: Dictionary = GameContent.HEROES.get(GameState.hero_id, {})
	_portrait.self_modulate = hero.get("tint", Color.WHITE)
	_xp_bar.max_value = GameState.xp_needed()
	_xp_bar.value = GameState.xp
	if player:
		var stats: CharacterStats = player.get("stats")
		if stats:
			_name_label.text = ("%.1f" % float(stats.defense)).replace(".", ",")
			if _attack_label:
				_attack_label.text = ("%.1f" % float(stats.attack_damage)).replace(".", ",")
			if _speed_label:
				_speed_label.text = ("%.2f" % (stats.move_speed / 60.0)).replace(".", ",")


func _refresh_world_info() -> void:
	if _world_time_label:
		_world_time_label.text = "%s %s" % [LanSession.short_role_text(), Time.get_time_string_from_system()]
	if _world_coord_label and player is Node2D:
		var p := (player as Node2D).global_position / 16.0
		_world_coord_label.text = "%d,%d" % [roundi(p.x), roundi(p.y)]


func _refresh_controls() -> void:
	if player == null:
		return
	var runner: HeroSkillRunner = player.get("hero_skills")
	if runner:
		for i in range(skill_btns.size()):
			var b := skill_btns[i]
			var d := runner.get_skill_def(i)
			b.caption = d.get("name", "")
			b.locked = not runner.is_unlocked(i)
			b.cooldown_ratio = runner.get_cooldown_ratio(i)
			var cd := runner.get_cooldown(i)
			b.cooldown_text = str(ceili(cd)) if cd > 0.0 else ""
			if b.locked:
				b.cooldown_text = "Lv%d" % int(d.get("unlock_level", 1))
	var sc: SkillComponent = player.get("skill_component")
	if gear_btn:
		gear_btn.locked = sc == null or sc.available_skills.is_empty()
		if sc and not sc.available_skills.is_empty():
			var s0: Dictionary = sc.available_skills[0]
			var cd0: float = s0.get("current_cooldown", 0.0)
			gear_btn.cooldown_ratio = cd0 / maxf(float(s0.get("cooldown", 1.0)), 0.01)
			gear_btn.cooldown_text = str(ceili(cd0)) if cd0 > 0.0 else ""
		else:
			gear_btn.cooldown_ratio = 0.0
	var inv: InventoryData = player.get_inventory()
	var potions := inv.get_item_count("health_potion") + inv.get_item_count("large_health_potion") if inv else 0
	if potion_btn:
		potion_btn.badge = str(potions)
		potion_btn.locked = potions <= 0
	if mount_btn:
		mount_btn.locked = GameState.active_mount == ""
		mount_btn.caption = "Off" if GameState.mounted else "Ride"
		if GameState.active_mount != "":
			mount_btn.icon = PixelArt.get_texture(GameContent.MOUNTS[GameState.active_mount]["sprite"], GameState.mount_skin_palette(GameState.active_mount))
			mount_btn.caption = "Off" if GameState.mounted else ""
	if auto_farm_btn:
		var auto_on := bool(player.get("auto_farm_enabled"))
		auto_farm_btn.base_color = Color(0.33, 0.18, 0.05) if auto_on else Color(0.08, 0.08, 0.09)
		auto_farm_btn.queue_redraw()


func _toggle_auto_farm() -> void:
	if player == null or not player.has_method("toggle_auto_farm"):
		return
	player.toggle_auto_farm()
	_refresh_controls()


func _refresh_quests() -> void:
	for c in _quest_box.get_children():
		c.queue_free()
	var rows := QuestService.get_tracker_rows()
	var shown := 0
	for r in rows:
		if r["claimed"]:
			continue
		if r["daily"] and shown >= 2:
			continue
		var line := Button.new()
		line.flat = true
		line.focus_mode = Control.FOCUS_NONE
		line.alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.add_theme_font_size_override("font_size", 15)
		var prefix := "! " if r["ready"] else ""
		line.text = "%s%s  %d/%d" % [prefix, r["name"], r["progress"], r["count"]]
		line.add_theme_color_override("font_color", UiTheme.C_GOOD if r["ready"] else (UiTheme.C_TEXT if not r["daily"] else UiTheme.C_MUTED))
		line.pressed.connect(_on_quest_line.bind(String(r["id"]), bool(r["ready"])))
		_quest_box.add_child(line)
		shown += 1
		if shown >= 3:
			break


func _on_quest_line(qid: String, ready: bool) -> void:
	if ready:
		QuestService.claim(qid)
	else:
		open_menu("quest")


func _on_menu_button(id: String) -> void:
	if id == "bag":
		if player and player.get("inventory_panel"):
			player.inventory_panel.toggle_inventory()
		return
	open_menu(id)


func _toggle_hud_chrome() -> void:
	_hud_collapsed = not _hud_collapsed
	GameState.settings["compact_hud"] = _hud_collapsed
	_fold_button.tooltip_text = "Show controls" if _hud_collapsed else "Hide controls"
	_fold_button.modulate = Color(1.0, 0.72, 0.2) if _hud_collapsed else Color.WHITE


func open_menu(id: String) -> void:
	game_menu.open(id)


func show_toast(text: String, color: Color = Color.WHITE) -> void:
	var l := UiTheme.label(text, 22, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(600, 34)
	_toast_box.add_child(l)
	while _toast_box.get_child_count() > 4:
		var first := _toast_box.get_child(0)
		_toast_box.remove_child(first)
		first.queue_free()
	var tw := l.create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func _on_zone_entered(zone_id: String) -> void:
	var z: Dictionary = GameContent.ZONES.get(zone_id, {})
	_zone_label.text = z.get("name", zone_id)
	_boss_timer_label.text = ""
	_boss_panel.visible = false


func _on_world_boss_timer(zone_id: String, seconds_left: float) -> void:
	if zone_id != GameState.current_zone:
		return
	if seconds_left < 0.0:
		_boss_timer_label.text = "World boss is active!"
	else:
		_boss_timer_label.text = "World boss in %d:%02d (or use the altar)" % [int(seconds_left) / 60, int(seconds_left) % 60]


func _on_boss_state(boss_id: String, hp: int, max_hp: int, phase: int) -> void:
	_boss_panel.visible = hp > 0
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	var bname: String = GameContent.MONSTERS.get(boss_id, {}).get("name", boss_id)
	_boss_label.text = "%s  %s  %d/%d" % [bname, "ENRAGED" if phase >= 2 else "", hp, max_hp]


func _on_player_died() -> void:
	_death_timer = 0.0
	_death_panel.visible = true


func _respawn_here() -> void:
	if _death_timer > 0.0:
		return
	if LanSession.mode == LanSession.Mode.CLIENT:
		LanSession.request_player_respawn()
		return
	if player and player.has_method("respawn"):
		player.respawn()
		var map := SceneTransitionService.get_active_map_node()
		if map and map.has_method("get_spawn_position"):
			(player as Node2D).global_position = map.get_spawn_position()


func _respawn_town() -> void:
	if _death_timer > 0.0:
		return
	if LanSession.mode == LanSession.Mode.CLIENT:
		LanSession.request_player_respawn()
		return
	if player and player.has_method("respawn"):
		player.respawn()
		if SceneTransitionService.get_active_map() != "town":
			SceneTransitionService.go_to("town")
