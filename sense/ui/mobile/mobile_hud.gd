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
# Original Ember UI kit art (ArtCatalog IDs, ART_BIBLE.md). Icons are 16 px drawn at 3× (48 px).
const HUD_ICON_SCALE := 3
const HUD_ICON_SIZE := 48.0
const RAIL_ICON_TINT := Color.WHITE
const GUIDE_NAME := "Orla"
var MINIMIZE_ICON: Texture2D = ArtCatalog.texture("ui.icon.minimize", HUD_ICON_SCALE)
var MENU_ICON: Texture2D = ArtCatalog.texture("ui.icon.menu", HUD_ICON_SCALE)
var WEAPON_ICON: Texture2D = ArtCatalog.texture("ui.icon.attack", HUD_ICON_SCALE)
var POWER_ICON: Texture2D = ArtCatalog.texture("ui.icon.power", HUD_ICON_SCALE)
var HEALTH_ICON: Texture2D = ArtCatalog.texture("ui.icon.health", HUD_ICON_SCALE)
var DAMAGE_ICON: Texture2D = ArtCatalog.texture("ui.icon.damage", HUD_ICON_SCALE)
var SPEED_ICON: Texture2D = ArtCatalog.texture("ui.icon.speed", HUD_ICON_SCALE)
var GOLD_ICON: Texture2D = ArtCatalog.texture("ui.icon.gold", HUD_ICON_SCALE)
var MAP_ICON: Texture2D = ArtCatalog.texture("ui.icon.map", HUD_ICON_SCALE)
var QUEST_DIG_ICON: Texture2D = ArtCatalog.texture("ui.icon.dig", HUD_ICON_SCALE)
var QUEST_GUIDE: Texture2D = ArtCatalog.texture("npc.warden_captain.portrait", 4)
var BAG_ICON: Texture2D = ArtCatalog.texture("ui.icon.bag", HUD_ICON_SCALE)
var PET_ICON: Texture2D = ArtCatalog.texture("ui.icon.pet", HUD_ICON_SCALE)
var SKILL_ICON: Texture2D = ArtCatalog.texture("ui.icon.skill", HUD_ICON_SCALE)

var legacy_hud: CanvasLayer = null
var player: Node = null

var game_menu: GameMenu
var joystick: VirtualJoystick
var attack_btn: ActionButton
var auto_farm_btn: ActionButton
var gear_btn: ActionButton
var _gear_slots: Dictionary = {}       ## slot id -> HudGearSlot
var _portrait_menu: PanelContainer = null
var potion_btn: ActionButton
var mount_btn: ActionButton
var interact_btn: ActionButton
var _hotbar_slots: Array[ActionButton] = []
var _hotbar_fill: ColorRect
var _hotbar_frame: Panel

var _hp_bar: ProgressBar
var _hp_label: Label
var _en_bar: ProgressBar
var _name_label: Label
var _attack_label: Label
var _speed_label: Label
var _world_time_label: Label
var _world_coord_label: Label
var _world_gold_label: Label
var _portrait: TextureRect
var _boss_timer_label: Label
var _boss_panel: PanelContainer
var _boss_bar: ProgressBar
var _boss_label: Label
var _toast_box: VBoxContainer
var _death_panel: Control
var _death_button: Button
var _quest_tracker: Control
var _quest_title_label: Label
var _quest_progress_label: Label
var _quest_icon: TextureRect
var _tracked_quest_id: String = ""
var _tracked_quest_ready: bool = false
var _quest_available: bool = false
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
	GameState.stats_dirty.connect(_refresh_card)
	GameState.pet_changed.connect(func(_p: String) -> void: _refresh_gear_slots())
	GameState.mount_changed.connect(func(_m: String, _r: bool) -> void: _refresh_gear_slots())
	GameState.collection_changed.connect(_refresh_gear_slots)
	GameEvent.appearance_changed.connect(func(_o: String) -> void: _portrait.texture = GameMenu.hero_portrait())
	GameState.mount_changed.connect(func(_m: String, _r: bool) -> void: _refresh_controls())
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
	inv.equipment_changed.connect(func(_s: String) -> void: _refresh_gear_slots())
	_portrait.texture = GameMenu.hero_portrait()
	_refresh_gear_slots()
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
	if c.name == "InventoryPanel" or c is GemPanel:
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
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_style := StyleBoxEmpty.new()
	frame.add_theme_stylebox_override("normal", frame_style)
	frame.add_theme_stylebox_override("hover", frame_style)
	frame.add_theme_stylebox_override("pressed", frame_style)
	frame.pressed.connect(_toggle_portrait_menu)
	add_child(frame)
	var portrait_background := _kit_panel("ui.panel.dark")
	portrait_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_background.offset_left = 7
	portrait_background.offset_top = 7
	portrait_background.offset_right = -7
	portrait_background.offset_bottom = -7
	portrait_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait_background)
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
	var portrait_border := _kit_panel("ui.frame.portrait")
	portrait_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(portrait_border)

	var stats := _panel(Rect2(8, 150, 180, 204))
	stats.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	stats.add_child(col)
	var level_row := _hud_value_row(col, POWER_ICON)
	_name_label = UiTheme.label("2,0", 20, UiTheme.C_GOLD)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_row.add_child(_name_label)
	var hp_row := _hud_value_row(col, HEALTH_ICON)
	var hp_value := Control.new()
	hp_value.custom_minimum_size = Vector2(0, 49)
	hp_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_value)
	_hp_bar = UiTheme.bar(Color(0.72, 0.06, 0.05), 25)
	_hp_bar.position = Vector2(0, 12)
	_hp_bar.size = Vector2(110, 25)
	hp_value.add_child(_hp_bar)
	_hp_label = UiTheme.label("100/100", 18)
	_hp_label.position = Vector2(0, 7)
	_hp_label.size = Vector2(110, 34)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_value.add_child(_hp_label)
	var energy_row := _hud_value_row(col, DAMAGE_ICON)
	_attack_label = UiTheme.label("10,0", 20, UiTheme.C_TEXT)
	_attack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_row.add_child(_attack_label)
	var speed_row := _hud_value_row(col, SPEED_ICON)
	_speed_label = UiTheme.label("2,00", 20, UiTheme.C_TEXT)
	_speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_row.add_child(_speed_label)


func _hud_value_row(parent: VBoxContainer, icon_texture: Texture2D) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 49)
	panel.add_theme_stylebox_override("panel", _row_style())
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	row.add_child(_divider(Vector2(12, 48)))
	return row


func _build_left_panel() -> void:
	_quest_tracker = Control.new()
	_quest_tracker.position = Vector2(488, 490)
	_quest_tracker.size = Vector2(232, 292)
	_quest_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker.visible = false
	add_child(_quest_tracker)

	_boss_timer_label = UiTheme.label("", 14, Color(1, 0.64, 0.3))
	_boss_timer_label.size = Vector2(232, 24)
	_boss_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_boss_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_timer_label.position = Vector2(488, 464)
	_boss_timer_label.visible = false
	add_child(_boss_timer_label)

	var popup := _kit_panel("ui.panel.dark")
	popup.position = Vector2(0, 12)
	popup.size = Vector2(176, 70)
	popup.z_index = 0
	_quest_tracker.add_child(popup)

	_quest_icon = TextureRect.new()
	_quest_icon.texture = QUEST_DIG_ICON
	_quest_icon.position = Vector2(9, 23)
	_quest_icon.size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	_quest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_quest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_quest_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_quest_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_icon.z_index = 2
	_quest_tracker.add_child(_quest_icon)

	_quest_title_label = UiTheme.label("", 22, UiTheme.C_TEXT)
	_quest_title_label.position = Vector2(66, 18)
	_quest_title_label.size = Vector2(106, 30)
	_quest_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quest_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_quest_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_title_label.z_index = 2
	_quest_tracker.add_child(_quest_title_label)

	_quest_progress_label = UiTheme.label("", 22, UiTheme.C_TEXT)
	_quest_progress_label.position = Vector2(9, 50)
	_quest_progress_label.size = Vector2(82, 30)
	_quest_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quest_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_progress_label.z_index = 2
	_quest_tracker.add_child(_quest_progress_label)

	var guide := TextureRect.new()
	guide.texture = QUEST_GUIDE
	guide.position = Vector2(104, 151)
	guide.size = Vector2(128, 112)
	guide.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guide.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	guide.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.z_index = 1
	_quest_tracker.add_child(guide)

	var guide_name := UiTheme.label(GUIDE_NAME, 21, UiTheme.C_GOLD)
	guide_name.position = Vector2(132, 263)
	guide_name.size = Vector2(98, 27)
	guide_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	guide_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_name.z_index = 2
	_quest_tracker.add_child(guide_name)

	var open_button := Button.new()
	open_button.position = Vector2(0, 12)
	open_button.size = Vector2(176, 70)
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.tooltip_text = "Quest"
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		open_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	open_button.pressed.connect(_on_tracked_quest_pressed)
	_quest_tracker.add_child(open_button)


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
	var system_button := _reference_icon_button(MENU_ICON, "Menu", func() -> void: _on_menu_button("system"))
	system_button.position = Vector2(622, 18)

	var resources := _panel(Rect2(532, 150, 180, 154))
	resources.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 1)
	resources.add_child(rv)
	_world_time_label = _world_info_row(rv, null, "[Local] 00:00:00", UiTheme.C_TEXT)
	_world_coord_label = _world_info_row(rv, MAP_ICON, "0,00", UiTheme.C_TEXT)
	_world_gold_label = _world_info_row(rv, GOLD_ICON, "0", UiTheme.C_GOLD)
	_refresh_world_info()

	# Side rails: 8 gear squares (owner request 2026-11-09). Left: helmet, armor, boots, back.
	# Right: weapon, pet, mount, special skill. Hero / village / bag / auto modes moved to the
	# menu and to the portrait popup.
	var rails := [["helmet", "Helmet", 0, 0], ["armor", "Armor", 0, 1], ["boots", "Boots", 0, 2], ["back", "Back", 0, 3],
		["weapon", "Weapon", 1, 0], ["pet", "Pet", 1, 1], ["mount", "Mount", 1, 2], ["special", "Skill", 1, 3]]
	for r: Array in rails:
		var slot := HudGearSlot.new().setup(str(r[0]), str(r[1]))
		slot.position = Vector2(12 if int(r[2]) == 0 else 618, 958 + int(r[3]) * 102)
		slot.pressed.connect(_on_gear_slot.bind(str(r[0])))
		add_child(slot)
		_gear_slots[str(r[0])] = slot
		_foldable_controls.append(slot)

	attack_btn = _action_btn("character_attack", Vector2(548, 1180), 52.0, "")
	attack_btn.icon = WEAPON_ICON
	_foldable_controls.append(attack_btn)


func _nav_button(id: String, caption: String) -> Button:
	return _icon_button(BTN_ICONS[id], caption, func() -> void: _on_menu_button(id))


func _world_info_row(parent: VBoxContainer, icon_texture: Texture2D, initial_text: String, color: Color) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 49)
	panel.add_theme_stylebox_override("panel", _row_style())
	parent.add_child(panel)
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.position = Vector2(4, 0)
		icon.size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var line := _divider(Vector2(12, 45))
		line.position = Vector2(52, 2)
		row.add_child(line)
	var value := UiTheme.label(initial_text, 18, color)
	value.position = Vector2(69, 0) if icon_texture != null else Vector2(7, 0)
	value.size = Vector2(108, 49) if icon_texture != null else Vector2(166, 49)
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

	var frame := _kit_panel("ui.frame.action")
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
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


func _reference_icon_button(texture: Texture2D, caption: String, callback: Callable, tint: Color = Color.WHITE) -> Button:
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

	var frame := _kit_panel("ui.frame.action")
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(frame)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = tint
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 12
	icon.offset_top = 12
	icon.offset_right = -12
	icon.offset_bottom = -12
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	b.pressed.connect(callback)
	add_child(b)
	_controls.append(b)
	return b


func _build_controls() -> void:
	joystick = VirtualJoystick.new()
	# Unity's default 1080x1920 layout maps the fixed-stick center to (360, 1123)
	# in the 720x1516 game surface; the remaining 84 pixels are Android navigation.
	joystick.position = Vector2(241, 958)
	joystick.size = Vector2(238, 300)
	add_child(joystick)

	var hotbar_top := get_viewport_rect().size.y - 200.0
	_hotbar_fill = ColorRect.new()
	_hotbar_fill.color = Color(0.025, 0.025, 0.03, 0.96)
	_hotbar_fill.position = Vector2(10, hotbar_top + 10.0)
	_hotbar_fill.size = Vector2(700, 96)
	_hotbar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hotbar_fill)
	_controls.append(_hotbar_fill)

	_hotbar_frame = _kit_panel("ui.frame.hotbar")
	_hotbar_frame.position = Vector2(0, hotbar_top)
	_hotbar_frame.size = Vector2(720, 116)
	add_child(_hotbar_frame)
	_controls.append(_hotbar_frame)

	var centers := [66.0, 150.0, 234.0, 318.0, 402.0, 486.0, 570.0, 654.0]
	for i in range(8):
		var slot := _action_btn("hotbar_%d" % (i + 1), Vector2(centers[i], hotbar_top + 58.0), 37.0, "")
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
	_death_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_death_button.add_theme_stylebox_override("normal", _revive_button_style(Color.WHITE))
	_death_button.add_theme_stylebox_override("hover", _revive_button_style(Color8(245, 245, 245)))
	_death_button.add_theme_stylebox_override("pressed", _revive_button_style(Color8(200, 200, 200)))
	_death_button.add_theme_stylebox_override("hover_pressed", _revive_button_style(Color8(200, 200, 200)))
	_death_button.add_theme_stylebox_override("disabled", _revive_button_style(Color8(200, 200, 200, 128)))
	_death_button.add_theme_font_size_override("font_size", 34)
	_death_button.add_theme_color_override("font_color", UiTheme.C_GOLD)
	_death_button.add_theme_color_override("font_hover_color", UiTheme.C_GOLD)
	_death_button.add_theme_color_override("font_pressed_color", UiTheme.C_GOLD)
	_death_button.add_theme_color_override("font_hover_pressed_color", UiTheme.C_GOLD)
	_death_button.add_theme_color_override("font_disabled_color", UiTheme.C_GOLD)
	_death_panel.add_child(_death_button)


func _revive_button_style(tint: Color) -> StyleBoxTexture:
	var style := ArtCatalog.stylebox("ui.button.primary").duplicate() as StyleBoxTexture
	style.modulate_color = tint
	return style


## A non-interactive Panel drawn with a kit 9-slice style.
func _kit_panel(style_id: String) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", ArtCatalog.stylebox(style_id))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## HUD stat/info row background with no content padding.
func _row_style() -> StyleBox:
	var style := ArtCatalog.stylebox("ui.panel.dark").duplicate() as StyleBox
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


## Thin vertical divider between an icon and its value.
func _divider(min_size: Vector2) -> Control:
	var holder := CenterContainer.new()
	holder.custom_minimum_size = min_size
	holder.size = min_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = ArtPalette.color("m")
	bar.custom_minimum_size = Vector2(3, min_size.y - 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bar)
	return holder


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
		_quest_tracker.visible = _quest_available and not blocked and not _hud_collapsed and not dead
	if _boss_timer_label:
		_boss_timer_label.visible = not _boss_timer_label.text.is_empty() and not blocked and not _hud_collapsed and not dead
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
			var mount_frames := MonsterVisualCatalog.get_frames(str(MountVisual.describe(GameState.active_mount, GameState.mount_skin(GameState.active_mount), 0)["art"]))
			if mount_frames != null:
				mount_btn.icon = mount_frames.get_frame_texture(mount_frames.get_animation_names()[0], 0)
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
	var quest := QuestService.get_main_quest()
	_quest_available = not quest.is_empty()
	if not _quest_available:
		_tracked_quest_id = ""
		_tracked_quest_ready = false
		_quest_tracker.visible = false
		return
	_tracked_quest_id = String(quest["id"])
	_tracked_quest_ready = QuestService.main_ready
	_quest_title_label.text = String(quest["name"])
	_quest_progress_label.text = "%d/%d" % [QuestService.main_progress, int(quest["obj"]["count"])]
	_quest_icon.visible = _tracked_quest_id == "q01"
	_quest_title_label.position.x = 66 if _quest_icon.visible else 9


func _on_tracked_quest_pressed() -> void:
	if _tracked_quest_ready:
		QuestService.claim(_tracked_quest_id)
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


func _on_zone_entered(_zone_id: String) -> void:
	_boss_timer_label.text = ""
	_boss_panel.visible = false


func _on_world_boss_timer(zone_id: String, seconds_left: float) -> void:
	if zone_id != GameState.current_zone:
		return
	# FieldMap: negative = boss up with |seconds| left, positive = next arrival here, INF = none
	if is_inf(seconds_left):
		_boss_timer_label.text = ""
	elif seconds_left < 0.0:
		var left := int(-seconds_left)
		_boss_timer_label.text = "World boss! %d:%02d left" % [left / 60, left % 60]
	else:
		var wait := int(seconds_left)
		_boss_timer_label.text = "World boss here in %dh %02dm" % [wait / 3600, (wait % 3600) / 60] if wait >= 3600 else "World boss here in %d:%02d" % [wait / 60, wait % 60]


func _on_boss_state(boss_id: String, hp: int, max_hp: int, phase: int) -> void:
	_boss_panel.visible = hp > 0
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	var bname: String = GameContent.MONSTERS.get(boss_id, {}).get("name", boss_id)
	var phases := BossCatalog.phases(boss_id)
	var pname := str((phases[phase - 1] as Dictionary).get("name", "")) if phase >= 1 and phase <= phases.size() else ""
	_boss_label.text = "%s  [%d/%d %s]  %d/%d" % [bname, phase, maxi(phases.size(), 1), pname, hp, max_hp]


func _on_player_died() -> void:
	_death_timer = 0.0
	_death_panel.visible = true
	_quest_tracker.visible = false
	_boss_timer_label.visible = false


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


# =============================================================================
# GEAR RAILS AND PORTRAIT MENU (owner request 2026-11-09)
# =============================================================================

func _refresh_gear_slots() -> void:
	if player == null or _gear_slots.is_empty():
		return
	var inv: InventoryData = player.get_inventory()
	for slot_type: String in InventoryData.EQUIPMENT_SLOTS:
		var slot: HudGearSlot = _gear_slots.get(slot_type)
		var item := inv.get_equipped(slot_type) if inv else null
		if slot == null:
			continue
		if item != null:
			slot.show_item(item.get_icon(), item.get_rarity_color(), "Lv.%d" % item.enhancement_level)
		else:
			slot.show_empty(slot_type.capitalize())
	var pet_slot: HudGearSlot = _gear_slots.get("pet")
	if pet_slot:
		if GameState.active_pet != "":
			var p := CompanionCatalog.parse_pet_key(GameState.active_pet)
			pet_slot.show_item(_first_frame(str(CompanionCatalog.species(p["species"]).get("art", ""))), CompanionCatalog.quality_color(p["quality"]), "Lv.%d" % GameState.pet_level(GameState.active_pet))
		else:
			pet_slot.show_empty("Pet")
	var mount_slot: HudGearSlot = _gear_slots.get("mount")
	if mount_slot:
		if GameState.active_mount != "":
			var look := MountVisual.describe(GameState.active_mount, GameState.mount_skin(GameState.active_mount), GameState.mount_form(GameState.active_mount))
			mount_slot.show_item(_first_frame(str(look["art"])), Color(1.0, 0.85, 0.35) if GameState.mounted else Color(0.6, 0.6, 0.65), "Off" if GameState.mounted else "Ride", look["modulate"])
		else:
			mount_slot.show_empty("Mount")
	var special: HudGearSlot = _gear_slots.get("special")
	if special:
		special.show_empty("Skill", true)


func _first_frame(asset_id: String) -> Texture2D:
	var frames := MonsterVisualCatalog.get_frames(asset_id)
	if frames == null:
		return null
	for n: String in ["idle_down", "idle", "move"]:
		if frames.has_animation(n) and frames.get_frame_count(n) > 0:
			return frames.get_frame_texture(n, 0)
	return null


func _on_gear_slot(slot_id: String) -> void:
	match slot_id:
		"pet":
			open_menu("pet")
		"mount":
			if GameState.active_mount == "":
				open_menu("mount")
			else:
				GameState.set_mounted(not GameState.mounted)
		"special":
			show_toast("Special skills unlock in a later update.", UiTheme.C_MUTED)
		_:
			var existing := get_node_or_null("GearSlotPanel")
			if existing:
				existing.queue_free()
			var panel := GearSlotPanel.new()
			panel.name = "GearSlotPanel"
			add_child(panel)
			panel.setup(player.get_inventory(), slot_id)
			panel.position = Vector2(80, 420)


## Tapping the portrait: bag, auto attack, auto dig (owner request 2026-11-09).
func _toggle_portrait_menu() -> void:
	if _portrait_menu != null and is_instance_valid(_portrait_menu):
		_portrait_menu.queue_free()
		_portrait_menu = null
		return
	_portrait_menu = PanelContainer.new()
	_portrait_menu.name = "PortraitMenu"
	_portrait_menu.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.C_PANEL, UiTheme.C_TRIM, 3))
	_portrait_menu.position = Vector2(126, 18)
	add_child(_portrait_menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_portrait_menu.add_child(v)
	var auto_attack := bool(player.get("auto_farm_enabled")) if player else false
	var auto_dig := bool(player.get("auto_dig_enabled")) if player else false
	v.add_child(UiTheme.button("Bag", _portrait_action.bind("bag"), Vector2(260, 56)))
	v.add_child(UiTheme.button("Auto attack: %s" % ("ON" if auto_attack else "off"), _portrait_action.bind("attack"), Vector2(260, 56)))
	v.add_child(UiTheme.button("Auto dig: %s" % ("ON" if auto_dig else "off"), _portrait_action.bind("dig"), Vector2(260, 56)))


func _portrait_action(action: String) -> void:
	match action:
		"bag":
			_on_menu_button("bag")
		"attack":
			if player and player.has_method("set_auto_farm"):
				player.set_auto_farm(not bool(player.get("auto_farm_enabled")))
		"dig":
			if player and player.has_method("set_auto_dig"):
				player.set_auto_dig(not bool(player.get("auto_dig_enabled")))
	if _portrait_menu != null and is_instance_valid(_portrait_menu):
		_portrait_menu.queue_free()
		_portrait_menu = null
