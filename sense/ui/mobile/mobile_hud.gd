class_name MobileHUD
extends Control
## Portrait mobile HUD layered on top of the legacy HUD CanvasLayer.
##
## Regions (720x1280 logical):
##   top-left    player card (portrait, level, HP / energy / XP bars, gold)
##   top-right   legacy minimap + loot feed (kept)
##   right rail  menu buttons (Bag, Hero, Pet, Mount, Quest, Map, Home, Menu)
##   left        zone name, quest tracker, world-boss timer
##   top         boss bar (when a boss is engaged)
##   bottom-left floating virtual joystick
##   bottom-right attack + 3 hero skills + gear skill + potion + mount + interact
##   overlays    toasts, death panel, GameMenu

const BTN_ICONS := {
	"bag": "bag", "hero": "helmet_horned", "pet": "heart", "mount": "boot_green",
	"quest": "scroll", "map": "gem_green", "village": "wood", "system": "gamepad",
}

var legacy_hud: CanvasLayer = null
var player: Node = null

var game_menu: GameMenu
var joystick: VirtualJoystick
var attack_btn: ActionButton
var skill_btns: Array[ActionButton] = []
var gear_btn: ActionButton
var potion_btn: ActionButton
var mount_btn: ActionButton
var interact_btn: ActionButton

var _hp_bar: ProgressBar
var _hp_label: Label
var _en_bar: ProgressBar
var _xp_bar: ProgressBar
var _name_label: Label
var _gold_label: Label
var _portrait: TextureRect
var _zone_label: Label
var _quest_box: VBoxContainer
var _boss_timer_label: Label
var _boss_panel: PanelContainer
var _boss_bar: ProgressBar
var _boss_label: Label
var _toast_box: VBoxContainer
var _death_panel: Control
var _death_label: Label
var _death_timer: float = 0.0
var _controls: Array[Control] = []
var _quest_btn_badge_t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	_en_bar.max_value = m
	_en_bar.value = c


func _on_gold_changed(g: int) -> void:
	_gold_label.text = "Gold %d" % g


# =============================================================================
# LEGACY HUD ADAPTATION
# =============================================================================

func _adapt_legacy_hud() -> void:
	if legacy_hud == null:
		return
	# Hide legacy HP/stamina (replaced by player card) and the landscape hotbar
	for path in ["MarginContainer", "HotbarAnchor"]:
		var n := legacy_hud.get_node_or_null(path) as CanvasItem
		if n:
			n.visible = false
	var icons := legacy_hud.get_node_or_null("StatusIconsContainer") as Control
	if icons:
		icons.position = Vector2(12, 150)
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
	var card := _panel(Rect2(10, 10, 340, 132))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box(Color(0.1, 0.08, 0.1), UiTheme.C_GOLD, 3))
	frame.custom_minimum_size = Vector2(92, 104)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.texture = GameMenu.hero_portrait()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_name_label = UiTheme.label("Lv.1 Ironwarden", 22, UiTheme.C_GOLD)
	col.add_child(_name_label)
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(0, 22)
	col.add_child(hp_stack)
	_hp_bar = UiTheme.bar(Color(0.85, 0.2, 0.2), 22)
	_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_stack.add_child(_hp_bar)
	_hp_label = UiTheme.label("100/100", 16)
	_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_stack.add_child(_hp_label)
	_en_bar = UiTheme.bar(Color(0.3, 0.6, 1.0), 12)
	col.add_child(_en_bar)
	_xp_bar = UiTheme.bar(Color(0.7, 0.45, 1.0), 8)
	col.add_child(_xp_bar)
	_gold_label = UiTheme.label("Gold 0", 18, UiTheme.C_GOLD)
	col.add_child(_gold_label)


func _build_left_panel() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(10, 196)
	box.size = Vector2(360, 300)
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_zone_label = UiTheme.label("", 22, Color(0.9, 1, 0.9))
	box.add_child(_zone_label)
	_boss_timer_label = UiTheme.label("", 18, Color(1, 0.6, 0.5))
	box.add_child(_boss_timer_label)
	var qp := PanelContainer.new()
	qp.add_theme_stylebox_override("panel", UiTheme.box(Color(0.1, 0.07, 0.06, 0.72), Color(0.85, 0.66, 0.3, 0.6), 2))
	box.add_child(qp)
	_quest_box = VBoxContainer.new()
	_quest_box.add_theme_constant_override("separation", 2)
	qp.add_child(_quest_box)


func _build_boss_bar() -> void:
	_boss_panel = _panel(Rect2(60, 150, 500, 50))
	_boss_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_boss_panel.add_child(v)
	_boss_label = UiTheme.label("Boss", 18, Color(1, 0.6, 0.5))
	v.add_child(_boss_label)
	_boss_bar = UiTheme.bar(Color(0.75, 0.15, 0.2), 14)
	v.add_child(_boss_bar)


func _build_menu_rail() -> void:
	var ids := ["bag", "hero", "pet", "mount", "quest", "map", "village", "system"]
	var captions := {"bag": "Bag", "hero": "Hero", "pet": "Pet", "mount": "Mount", "quest": "Quest", "map": "Map", "village": "Home", "system": "Menu"}
	for i in range(ids.size()):
		var id: String = ids[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(74, 74)
		b.size = Vector2(74, 74)
		b.position = Vector2(560 + (i % 2) * 80, 266 + (i / 2) * 82)
		b.icon = ItemIconAtlas.get_named_icon(BTN_ICONS[id])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = captions[id]
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_constant_override("icon_max_width", 36)
		b.pressed.connect(func() -> void: _on_menu_button(id))
		add_child(b)
		_controls.append(b)


func _build_controls() -> void:
	joystick = VirtualJoystick.new()
	joystick.position = Vector2(0, 820)
	joystick.size = Vector2(340, 460)
	add_child(joystick)

	attack_btn = _action_btn("character_attack", Vector2(615, 1150), 68.0, "ATK")
	attack_btn.icon = ItemIconAtlas.get_named_icon("iron_sword")
	var skill_pos := [Vector2(478, 1190), Vector2(494, 1060), Vector2(590, 1000)]
	for i in range(3):
		var sb := _action_btn("hero_skill_%d" % (i + 1), skill_pos[i], 46.0, "")
		skill_btns.append(sb)
	gear_btn = _action_btn("gear_skill", Vector2(684, 1024), 34.0, "Gear")
	potion_btn = _action_btn("quick_potion", Vector2(684, 940), 34.0, "")
	potion_btn.icon = ItemIconAtlas.get_named_icon("potion_red")
	potion_btn.base_color = Color(0.35, 0.12, 0.12)
	mount_btn = _action_btn("toggle_mount", Vector2(600, 900), 34.0, "Ride")
	interact_btn = _action_btn("character_interact", Vector2(392, 1206), 40.0, "Use")
	interact_btn.base_color = Color(0.15, 0.25, 0.18)


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
	_toast_box.position = Vector2(60, 500)
	_toast_box.size = Vector2(600, 200)
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_death_panel() -> void:
	_death_panel = Control.new()
	_death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_panel.visible = false
	add_child(_death_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_panel.add_child(dim)
	var p := PanelContainer.new()
	p.position = Vector2(110, 480)
	p.size = Vector2(500, 260)
	_death_panel.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var t := UiTheme.label("You have fallen!", 36, UiTheme.C_BAD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_death_label = UiTheme.label("", 22)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_death_label)
	v.add_child(UiTheme.button("Revive here", _respawn_here))
	v.add_child(UiTheme.button("Return to town", _respawn_town))


# =============================================================================
# RUNTIME
# =============================================================================

func _process(delta: float) -> void:
	var blocked := game_menu.visible or _death_panel.visible or _legacy_overlay_open()
	joystick.enabled = not blocked
	for c in _controls:
		c.visible = not blocked
	joystick.visible = not blocked
	if _death_panel.visible:
		_death_timer -= delta
		_death_label.text = "Revive available in %d..." % ceili(_death_timer) if _death_timer > 0.0 else "Choose where to revive"
	# Context interact button: highlight when something is in range
	var im := get_node_or_null("/root/InteractionManager")
	var areas: Variant = im.get("active_areas") if im != null else null
	var has_target: bool = areas is Array and not areas.is_empty()
	interact_btn.locked = not has_target
	_quest_btn_badge_t -= delta
	if _quest_btn_badge_t <= 0.0:
		_quest_btn_badge_t = 0.5
		_refresh_controls()


func _refresh_card() -> void:
	var hero: Dictionary = GameContent.HEROES.get(GameState.hero_id, {})
	_name_label.text = "Lv.%d %s" % [GameState.level, hero.get("name", "")]
	_portrait.self_modulate = hero.get("tint", Color.WHITE)
	_xp_bar.max_value = GameState.xp_needed()
	_xp_bar.value = GameState.xp


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
	potion_btn.badge = str(potions)
	potion_btn.locked = potions <= 0
	mount_btn.locked = GameState.active_mount == ""
	mount_btn.caption = "Off" if GameState.mounted else "Ride"
	if GameState.active_mount != "":
		mount_btn.icon = PixelArt.get_texture(GameContent.MOUNTS[GameState.active_mount]["sprite"], GameState.mount_skin_palette(GameState.active_mount))
		mount_btn.caption = "Off" if GameState.mounted else ""


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
		line.add_theme_font_size_override("font_size", 18)
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


func open_menu(id: String) -> void:
	game_menu.open(id)


func show_toast(text: String, color: Color = Color.WHITE) -> void:
	var l := UiTheme.label(text, 26, color)
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
	show_toast(z.get("name", zone_id), Color(0.9, 1, 0.9))


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
	_death_timer = 3.0
	_death_panel.visible = true


func _respawn_here() -> void:
	if _death_timer > 0.0:
		return
	if player and player.has_method("respawn"):
		player.respawn()
		var map := SceneTransitionService.get_active_map_node()
		if map and map.has_method("get_spawn_position"):
			(player as Node2D).global_position = map.get_spawn_position()


func _respawn_town() -> void:
	if _death_timer > 0.0:
		return
	if player and player.has_method("respawn"):
		player.respawn()
		if SceneTransitionService.get_active_map() != "town":
			SceneTransitionService.go_to("town")
