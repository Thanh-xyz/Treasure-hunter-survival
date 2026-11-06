class_name GameMenu
extends Control
## Full-screen tabbed menu (portrait): Hero, Pet, Mount, Quest, Map, Village,
## System. Each tab is rebuilt from GameState/QuestService when shown or when
## the underlying data changes. The world keeps simulating behind the overlay.

signal closed

const TABS := ["hero", "pet", "mount", "quest", "map", "village", "system"]
const TAB_TITLES := {
	"hero": "Heroes", "pet": "Pets", "mount": "Mounts", "quest": "Quests",
	"map": "World Map", "village": "Homestead", "system": "System",
}
const QUEST_PANEL_NORMAL := preload("res://assets/treasure_hunter/ui/reference/quest_panel_normal.png")
const QUEST_PANEL_CLAIM := preload("res://assets/treasure_hunter/ui/reference/quest_panel_claim.png")
const QUEST_LIST_PANEL := preload("res://assets/treasure_hunter/ui/reference/quest_list_panel.png")
const QUEST_SECTION_LABEL := preload("res://assets/treasure_hunter/ui/reference/quest_section_label.png")
const QUEST_TAB_ACTIVE := preload("res://assets/treasure_hunter/ui/reference/quest_tab_active.png")
const QUEST_TAB_INACTIVE := preload("res://assets/treasure_hunter/ui/reference/quest_tab_inactive.png")
const QUEST_ICON_MAIN := preload("res://assets/treasure_hunter/ui/reference/quest_icon_main.png")
const QUEST_ICON_DAILY := preload("res://assets/treasure_hunter/ui/reference/quest_icon_daily.png")
const QUEST_ICON_LOGIN := preload("res://assets/treasure_hunter/ui/reference/icon_login.png")
const QUEST_ICON_ACHIEVEMENT := preload("res://assets/treasure_hunter/ui/reference/quest_icon_achievement.png")
const QUEST_BUTTON_BACK := preload("res://assets/treasure_hunter/ui/reference/button_back.png")

var current_tab: String = "hero"
var _content: VBoxContainer
var _title: Label
var _gold_label: Label
var _tab_buttons: Dictionary = {}
var _dirty: bool = false
var _generic_header: HBoxContainer
var _generic_tabs: GridContainer
var _quest_category: String = "main"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	if get_parent() is Control:
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 0.0
		offset_top = 0.0
		offset_right = 0.0
		offset_bottom = 0.0
	else:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_top = 60
	panel.offset_bottom = -60
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	_generic_header = HBoxContainer.new()
	root.add_child(_generic_header)
	_title = UiTheme.label("Menu", 34, UiTheme.C_GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_generic_header.add_child(_title)
	_gold_label = UiTheme.label("", 24, UiTheme.C_GOLD)
	_generic_header.add_child(_gold_label)
	_generic_header.add_child(UiTheme.button("  X  ", close, Vector2(64, 56)))

	_generic_tabs = GridContainer.new()
	_generic_tabs.columns = 4
	_generic_tabs.add_theme_constant_override("h_separation", 6)
	_generic_tabs.add_theme_constant_override("v_separation", 6)
	root.add_child(_generic_tabs)
	for id in TABS:
		var b := UiTheme.button(TAB_TITLES[id], open_tab.bind(id), Vector2(0, 50))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		_generic_tabs.add_child(b)
		_tab_buttons[id] = b

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	GameState.collection_changed.connect(_mark_dirty)
	GameState.buildings_changed.connect(_mark_dirty)
	GameState.xp_changed.connect(func(_a: int, _b: int, _c: int) -> void: _mark_dirty())
	QuestService.quests_changed.connect(_mark_dirty)


func open(tab: String = "") -> void:
	if tab != "":
		current_tab = tab
	visible = true
	_rebuild()


func close() -> void:
	# Settings and collection changes are local profile data; closing the menu is
	# a natural persistence boundary on mobile.
	SaveService.save_game()
	visible = false
	closed.emit()


func open_tab(tab: String) -> void:
	current_tab = tab
	_rebuild()


func _mark_dirty() -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if visible and _dirty:
		_dirty = false
		_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# =============================================================================
# BUILD
# =============================================================================

func _rebuild() -> void:
	var quest_mode := current_tab == "quest"
	_generic_header.visible = not quest_mode
	_generic_tabs.visible = not quest_mode
	_title.text = TAB_TITLES.get(current_tab, "Menu")
	_gold_label.text = "Gold %d  " % GameState.get_gold()
	for id in _tab_buttons:
		(_tab_buttons[id] as Button).modulate = Color(1, 0.9, 0.5) if id == current_tab else Color(1, 1, 1)
	for c in _content.get_children():
		c.queue_free()
	match current_tab:
		"hero":
			_build_heroes()
		"pet":
			_build_pets()
		"mount":
			_build_mounts()
		"quest":
			_build_quests()
		"map":
			_build_map()
		"village":
			_build_village()
		"system":
			_build_system()


func _card() -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.C_PANEL_LIGHT, UiTheme.C_TRIM.darkened(0.3), 2))
	_content.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	return v


func _row(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	return h


func _icon(tex: Texture2D, size_px: int = 72, tint: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(size_px, size_px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.self_modulate = tint
	return tr


static func hero_portrait() -> Texture2D:
	return PixelArt.make_guest_portrait()


func _act(ok: bool, fail_msg: String) -> void:
	if not ok:
		GameEvent.toast.emit(fail_msg, UiTheme.C_BAD)
	_rebuild()


# --- Heroes -------------------------------------------------------------------
func _build_heroes() -> void:
	_content.add_child(UiTheme.label("Lv.%d  —  stats grow with level and stars" % GameState.level, 20, UiTheme.C_MUTED))
	for id in GameContent.HEROES:
		var h: Dictionary = GameContent.HEROES[id]
		var v := _card()
		var row := _row(v)
		row.add_child(_icon(hero_portrait(), 80, h["tint"]))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var owned := GameState.is_hero_owned(id)
		var stars: int = GameState.heroes.get(id, {}).get("stars", 0)
		var star_txt := ""
		for i in range(GameContent.HERO_MAX_STARS):
			star_txt += "*" if i < stars else "-"
		info.add_child(UiTheme.label("%s  [%s]  %s" % [h["name"], h["title"], star_txt if owned else ""], 26, UiTheme.C_GOLD))
		info.add_child(UiTheme.label(h["desc"], 18, UiTheme.C_MUTED))
		var b: Dictionary = h["base"]
		info.add_child(UiTheme.label("HP %d  ATK %d  DEF %d  SPD %d" % [b["hp"], b["atk"], b["def"], int(b["spd"])], 18))
		var skill_names: Array[String] = []
		for sk in h["skills"]:
			var sd: Dictionary = GameContent.HERO_SKILLS[sk]
			skill_names.append("%s(Lv%d)" % [sd["name"], sd["unlock_level"]])
		info.add_child(UiTheme.label("Skills: " + ", ".join(skill_names), 18, Color(0.75, 0.85, 1)))
		var actions := _row(v)
		if not owned:
			var u: Dictionary = h["unlock"]
			actions.add_child(UiTheme.button("Recruit (%d gold, Lv.%d)" % [u["gold"], u["level"]],
				func() -> void: _act(GameState.unlock_hero(id), "Need more gold or level")))
		else:
			if GameState.hero_id == id:
				actions.add_child(UiTheme.label("  IN PARTY", 22, UiTheme.C_GOOD))
			else:
				actions.add_child(UiTheme.button("Select", func() -> void: _act(GameState.select_hero(id), "")))
			var cost := GameState.hero_star_cost(id)
			if cost > 0:
				actions.add_child(UiTheme.button("Star up (%d shards, have %d)" % [cost, _count("hero_shard")],
					func() -> void: _act(GameState.upgrade_hero_star(id), "Not enough Hero Shards")))


# --- Pets ---------------------------------------------------------------------
func _build_pets() -> void:
	_content.add_child(UiTheme.label("Pets evolve at Lv.5 and Lv.10. Feed them Pet Treats.", 20, UiTheme.C_MUTED))
	for id in GameContent.PETS:
		var p: Dictionary = GameContent.PETS[id]
		var v := _card()
		var row := _row(v)
		var owned := GameState.pets.has(id)
		var lv: int = GameState.pets.get(id, {}).get("level", 1)
		var stage := GameState.pet_stage(id) if owned else 0
		row.add_child(_icon(PixelArt.get_texture(p["sprite"]), 72, GameContent.PET_STAGE_TINT[stage]))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var stage_names := ["", " II", " III"]
		info.add_child(UiTheme.label("%s%s  %s" % [p["name"], stage_names[stage], ("Lv.%d" % lv) if owned else ""], 26, UiTheme.C_GOLD))
		info.add_child(UiTheme.label("[%s] %s" % [p["role"], p["desc"]], 18, UiTheme.C_MUTED))
		var passive: Dictionary = p.get("passive", {})
		var parts: Array[String] = []
		for k in passive:
			parts.append("%s +%s" % [k, str(passive[k])])
		info.add_child(UiTheme.label("Passive: " + ", ".join(parts), 18, Color(0.75, 0.85, 1)))
		var actions := _row(v)
		if not owned:
			actions.add_child(UiTheme.button("Adopt (%d gold)" % int(p["unlock"]["gold"]),
				func() -> void: _act(GameState.unlock_pet(id), "Not enough gold")))
		else:
			if GameState.active_pet == id:
				actions.add_child(UiTheme.button("Unequip", _equip_pet.bind("")))
			else:
				actions.add_child(UiTheme.button("Equip", _equip_pet.bind(String(id))))
			if lv < GameContent.PET_MAX_LEVEL:
				var cost := GameContent.pet_level_cost(lv)
				actions.add_child(UiTheme.button("Feed (%d treats, %d gold)" % [cost["pet_treat"], cost["gold"]],
					func() -> void: _act(GameState.level_up_pet(id), "Need Pet Treats / gold (have %d treats)" % _count("pet_treat"))))


# --- Mounts -------------------------------------------------------------------
func _build_mounts() -> void:
	_content.add_child(UiTheme.label("Speed mounts dismount when you attack. Attack/Defense mounts can fight.", 20, UiTheme.C_MUTED))
	for id in GameContent.MOUNTS:
		var m: Dictionary = GameContent.MOUNTS[id]
		var v := _card()
		var row := _row(v)
		var owned := GameState.mounts.has(id)
		var palette: String = GameState.mount_skin_palette(id) if owned else String(m["sprite"])
		row.add_child(_icon(PixelArt.get_texture(m["sprite"], palette), 80))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UiTheme.label("%s  [%s]" % [m["name"], String(m["category"]).to_upper()], 26, UiTheme.C_GOLD))
		var bonus_parts: Array[String] = ["Speed x%.2f" % float(m["speed_mult"])]
		var bonus: Dictionary = m["bonus"]
		for k in bonus:
			bonus_parts.append("%s +%d" % [k, int(bonus[k])])
		info.add_child(UiTheme.label(", ".join(bonus_parts), 18, Color(0.75, 0.85, 1)))
		var actions := _row(v)
		if not owned:
			var u: Dictionary = m["unlock"]
			actions.add_child(UiTheme.button("Claim (%d gold, Lv.%d)" % [u["gold"], u["level"]],
				func() -> void: _act(GameState.unlock_mount(id), "Need more gold or level")))
		else:
			if GameState.active_mount == id:
				actions.add_child(UiTheme.button("Dismount" if GameState.mounted else "Ride", _toggle_ride))
			else:
				actions.add_child(UiTheme.button("Select", _select_mount.bind(String(id))))
			var skins: Array = m["skins"]
			if skins.size() > 1:
				var skin_row := _row(v)
				skin_row.add_child(UiTheme.label("Skins:", 20))
				for i in range(skins.size()):
					var skin_list: Array = GameState.mounts[id]["skins"]
					var owned_skin: bool = skin_list.has(i)
					var label := ("Skin %d" % (i + 1)) if owned_skin else ("Skin %d (%dg)" % [i + 1, int(m["skin_cost"])])
					var skin_index := i
					var on_skin := func() -> void: _act(GameState.buy_or_select_skin(id, skin_index), "Not enough gold")
					var skin_btn := UiTheme.button(label, on_skin, Vector2(0, 48))
					skin_btn.icon = PixelArt.get_texture(m["sprite"], skins[i])
					skin_btn.expand_icon = false
					skin_row.add_child(skin_btn)


# --- Quests -------------------------------------------------------------------
func _build_quests() -> void:
	_build_quest_tabs()
	var heading := "NHIỆM VỤ CHÍNH" if _quest_category == "main" else "NHIỆM VỤ HẰNG NGÀY"
	_content.add_child(_quest_heading(heading))
	if _quest_category == "main":
		_build_main_quest_page()
	else:
		_build_daily_quest_page()


func _build_quest_tabs() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_content.add_child(row)
	row.add_child(_quest_back_button())
	row.add_child(_quest_tab_button(QUEST_ICON_MAIN, "main", true))
	row.add_child(_quest_tab_button(QUEST_ICON_DAILY, "daily", true))
	row.add_child(_quest_tab_button(QUEST_ICON_LOGIN, "login", false))
	row.add_child(_quest_tab_button(QUEST_ICON_ACHIEVEMENT, "achievement", false))


func _quest_back_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Back"
	var style := _quest_texture_style(QUEST_BUTTON_BACK, 12)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(close)
	return button


func _quest_tab_button(icon: Texture2D, category: String, enabled: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(140, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.icon = icon
	button.expand_icon = false
	button.disabled = not enabled
	var active := category == _quest_category
	var normal_style := _quest_texture_style(QUEST_TAB_ACTIVE if active else QUEST_TAB_INACTIVE, 13)
	var pressed_style := _quest_texture_style(QUEST_TAB_ACTIVE, 13)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", pressed_style if enabled else normal_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("hover_pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", normal_style)
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	button.add_theme_color_override("icon_disabled_color", Color(0.55, 0.55, 0.55, 0.7))
	if enabled:
		button.pressed.connect(_set_quest_category.bind(category))
	return button


func _set_quest_category(category: String) -> void:
	if category != "main" and category != "daily":
		return
	_quest_category = category
	_rebuild()


func _quest_heading(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 62)
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.10, 0.09, 0.12, 0.98), Color(0.05, 0.05, 0.06), 3, 10))
	var label := UiTheme.label(text, 30, Color(0.82, 0.80, 0.76))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _build_main_quest_page() -> void:
	var main := QuestService.get_main_quest()
	if main.is_empty():
		_content.add_child(UiTheme.label("Đã hoàn thành toàn bộ nhiệm vụ chính.", 24, UiTheme.C_GOOD))
		_build_completed_quest_list()
		return
	var main_row := {
		"id": main["id"],
		"name": main["name"],
		"desc": main["desc"],
		"progress": QuestService.main_progress,
		"count": int(main["obj"]["count"]),
		"ready": QuestService.main_ready,
		"claimed": false,
	}
	_content.add_child(_quest_card(main_row, main, true))

	var next_quests: Array = []
	for i in range(QuestService.main_index + 1, min(QuestService.main_index + 3, GameContent.MAIN_QUESTS.size())):
		next_quests.append(GameContent.MAIN_QUESTS[i])
	if not next_quests.is_empty():
		_content.add_child(_quest_section("Nhiệm vụ tiếp theo"))
		var list := _quest_list()
		_content.add_child(list["panel"])
		for quest in next_quests:
			list["content"].add_child(_quest_card({
				"id": quest["id"], "name": quest["name"], "desc": quest["desc"],
				"progress": 0, "count": int(quest["obj"]["count"]),
				"ready": false, "claimed": false,
			}, quest, false))

	_build_completed_quest_list()


func _build_completed_quest_list() -> void:
	if QuestService.main_index <= 0:
		return
	_content.add_child(_quest_section("Nhiệm vụ đã hoàn thành"))
	var completed_list := _quest_list()
	_content.add_child(completed_list["panel"])
	var completed_count: int = min(QuestService.main_index, GameContent.MAIN_QUESTS.size())
	var first_completed: int = max(0, completed_count - 2)
	for i in range(first_completed, completed_count):
		var quest: Dictionary = GameContent.MAIN_QUESTS[i]
		completed_list["content"].add_child(_quest_card({
			"id": quest["id"], "name": quest["name"], "desc": quest["desc"],
			"progress": int(quest["obj"]["count"]), "count": int(quest["obj"]["count"]),
			"ready": false, "claimed": true,
		}, quest, false))


func _build_daily_quest_page() -> void:
	var rows := QuestService.get_tracker_rows().filter(func(row: Dictionary) -> bool: return bool(row["daily"]))
	if rows.is_empty():
		_content.add_child(UiTheme.label("Không có nhiệm vụ hằng ngày.", 24, UiTheme.C_MUTED))
		return
	for row_data in rows:
		var quest := QuestService.get_quest_def(row_data["id"])
		_content.add_child(_quest_card(row_data, quest, true))


func _quest_section(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 72)
	var style := _quest_texture_style(QUEST_SECTION_LABEL, 0, Color(0.0588, 0.0588, 0.0588))
	panel.add_theme_stylebox_override("panel", style)
	var label := UiTheme.label(text, 28, UiTheme.C_GOLD)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", UiTheme.C_GOLD)
	panel.add_child(label)
	return panel


func _quest_list() -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _quest_texture_style(QUEST_LIST_PANEL, 20, Color(1, 1, 1, 0.784)))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return {"panel": panel, "content": content}


func _quest_card(row_data: Dictionary, quest: Dictionary, interactive: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 176)
	var texture: Texture2D = QUEST_PANEL_CLAIM if bool(row_data["ready"]) else QUEST_PANEL_NORMAL
	panel.add_theme_stylebox_override("panel", _quest_texture_style(texture, 20))
	panel.modulate = Color(1, 1, 1, 0.58) if bool(row_data["claimed"]) else Color.WHITE
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var title := UiTheme.label(String(row_data["name"]), 27, UiTheme.C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var desc := UiTheme.label(String(row_data["desc"]), 19, Color(0.82, 0.80, 0.78))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc)
	var progress := UiTheme.bar(Color(0.08, 0.48, 0.65), 15)
	progress.max_value = max(1, int(row_data["count"]))
	progress.value = int(row_data["progress"])
	progress.add_theme_stylebox_override("background", UiTheme.box(Color(0.03, 0.03, 0.03), Color(0.02, 0.02, 0.02), 2))
	content.add_child(progress)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	content.add_child(footer)
	var reward := UiTheme.label(_reward_text(quest.get("reward", {})), 19, UiTheme.C_GOLD)
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(reward)
	footer.add_child(UiTheme.label("%d/%d" % [row_data["progress"], row_data["count"]], 23, UiTheme.C_GOLD))
	if interactive and bool(row_data["ready"]) and not bool(row_data["claimed"]):
		var quest_id: String = row_data["id"]
		footer.add_child(UiTheme.button("Nhận", func() -> void: _act(QuestService.claim(quest_id), ""), Vector2(92, 44)))
	return panel


func _quest_texture_style(texture: Texture2D, margin: float, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	style.modulate_color = tint
	return style


func _reward_text(r: Dictionary) -> String:
	var parts: Array[String] = []
	if r.has("xp"):
		parts.append("%d XP" % int(r["xp"]))
	if r.has("gold"):
		parts.append("%d gold" % int(r["gold"]))
	var items: Dictionary = r.get("items", {})
	for id in items:
		var it: ItemData = ItemDatabase.get_item(id)
		parts.append("%d %s" % [int(items[id]), it.name if it else id])
	return ", ".join(parts)


# --- World map ----------------------------------------------------------------
func _build_map() -> void:
	_content.add_child(UiTheme.label("Current: %s" % GameContent.ZONES.get(GameState.current_zone, {}).get("name", GameState.current_zone), 22, UiTheme.C_MUTED))
	for id in GameContent.ZONE_ORDER:
		var z: Dictionary = GameContent.ZONES[id]
		var v := _card()
		var row := _row(v)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UiTheme.label(z["name"], 26, UiTheme.C_GOLD))
		var extra := "Safe zone" if z.get("safe", false) else "Recommended Lv.%d" % int(z["level"])
		if z.has("world_boss"):
			extra += "  -  World boss: %s" % GameContent.MONSTERS[z["world_boss"]]["name"]
		info.add_child(UiTheme.label(extra, 18, UiTheme.C_MUTED))
		var locked := GameState.level < int(z["level"]) - 2
		if id == GameState.current_zone:
			row.add_child(UiTheme.label("HERE ", 22, UiTheme.C_GOOD))
		elif locked:
			row.add_child(UiTheme.label("Lv.%d " % (int(z["level"]) - 2), 22, UiTheme.C_BAD))
		else:
			row.add_child(UiTheme.button("Travel", _travel.bind(String(id)), Vector2(120, 52)))


# --- Village ------------------------------------------------------------------
func _build_village() -> void:
	_content.add_child(UiTheme.label("Wood %d   Stone %d   — producers fill up for %dh" % [_count("wood"), _count("stone"), int(GameContent.BUILDING_STORAGE_HOURS)], 20, UiTheme.C_MUTED))
	_content.add_child(UiTheme.button("Collect all", _collect_all))
	for i in range(GameState.plots.size()):
		var p: Dictionary = GameState.plots[i]
		var v := _card()
		if p.is_empty():
			v.add_child(UiTheme.label("Plot %d — empty" % (i + 1), 24, UiTheme.C_GOLD))
			var grid := GridContainer.new()
			grid.columns = 2
			v.add_child(grid)
			for bid in GameContent.BUILDINGS:
				if GameState.building_level(bid) > 0:
					continue
				var b: Dictionary = GameContent.BUILDINGS[bid]
				var cost: Dictionary = b["cost"][1]
				var plot_index := i
				var btn := UiTheme.button("%s\n%s" % [b["name"], GameState.format_cost(cost)],
					_build_on_plot.bind(plot_index, String(bid)), Vector2(0, 70))
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.add_theme_font_size_override("font_size", 18)
				grid.add_child(btn)
		else:
			var b: Dictionary = GameContent.BUILDINGS[p["id"]]
			var lv: int = int(p["level"])
			v.add_child(UiTheme.label("Plot %d — %s Lv.%d" % [i + 1, b["name"], lv], 24, UiTheme.C_GOLD))
			v.add_child(UiTheme.label(b["desc"], 18, UiTheme.C_MUTED))
			var actions := _row(v)
			var plot_index := i
			if b.has("produces"):
				var pending := GameState.building_pending(i)
				actions.add_child(UiTheme.label("Stored: %d" % pending, 20))
				actions.add_child(UiTheme.button("Collect", _collect_plot.bind(plot_index)))
			if lv < GameContent.BUILDING_MAX_LEVEL:
				var cost := GameState.build_cost(i, p["id"])
				actions.add_child(UiTheme.button("Upgrade (%s)" % GameState.format_cost(cost),
					_build_on_plot.bind(plot_index, String(p["id"]))))
			else:
				actions.add_child(UiTheme.label("MAX", 20, UiTheme.C_GOOD))
	_content.add_child(UiTheme.button("Travel to Homestead", _travel.bind("homestead")))


# --- System -------------------------------------------------------------------
func _build_system() -> void:
	var v := _card()
	v.add_child(UiTheme.label("SETTINGS", 30, UiTheme.C_GOLD))
	v.add_child(UiTheme.label("Profile: Lv.%d, %d kills, bosses: %s" % [GameState.level, GameState.kills_total, str(GameState.boss_kills)], 18, UiTheme.C_MUTED))
	v.add_child(UiTheme.label("Session: %s" % LanSession.role_text(), 18, UiTheme.C_MUTED))
	if LanSession.is_active():
		v.add_child(UiTheme.button("Disconnect Wi-Fi", func() -> void:
			close()
			LanSession.stop(true)
		))
	v.add_child(UiTheme.button("Save game", _save))
	var fps_row := _row(v)
	fps_row.add_child(UiTheme.label("Frame rate", 20))
	var fps_picker := OptionButton.new()
	fps_picker.custom_minimum_size = Vector2(220, 50)
	for cap in [30, 60, 120]:
		fps_picker.add_item("%d FPS" % cap, cap)
	var current_fps := int(GameState.settings.get("max_fps", 60))
	for i in range(fps_picker.item_count):
		if fps_picker.get_item_id(i) == current_fps:
			fps_picker.select(i)
			break
	fps_picker.item_selected.connect(func(index: int) -> void:
		var cap := fps_picker.get_item_id(index)
		GameState.settings["max_fps"] = cap
		Engine.max_fps = cap
	)
	fps_row.add_child(fps_picker)
	var opacity_row := _row(v)
	opacity_row.add_child(UiTheme.label("Controls opacity", 20))
	var slider := HSlider.new()
	slider.min_value = 0.2
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(GameState.settings.get("joystick_opacity", 0.7))
	slider.custom_minimum_size = Vector2(260, 40)
	slider.value_changed.connect(func(val: float) -> void: GameState.settings["joystick_opacity"] = val)
	opacity_row.add_child(slider)
	var dn := CheckButton.new()
	dn.text = "Damage numbers"
	dn.button_pressed = bool(GameState.settings.get("damage_numbers", true))
	dn.toggled.connect(func(on: bool) -> void: GameState.settings["damage_numbers"] = on)
	v.add_child(dn)
	var compact := CheckButton.new()
	compact.text = "Compact HUD"
	compact.button_pressed = bool(GameState.settings.get("compact_hud", false))
	compact.toggled.connect(func(on: bool) -> void: GameState.settings["compact_hud"] = on)
	v.add_child(compact)
	var danger := _card()
	danger.add_child(UiTheme.label("Danger zone", 22, UiTheme.C_BAD))
	danger.add_child(UiTheme.button("Start a new game (deletes save)", _new_game))


func _count(item_id: String) -> int:
	var inv := GameState.get_inventory()
	return inv.get_item_count(item_id) if inv else 0


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _equip_pet(id: String) -> void:
	GameState.equip_pet(id)
	_rebuild()


func _toggle_ride() -> void:
	GameState.set_mounted(not GameState.mounted)
	_rebuild()


func _select_mount(id: String) -> void:
	GameState.select_mount(id)
	_rebuild()


func _travel(zone_id: String) -> void:
	close()
	SceneTransitionService.go_to(zone_id)


func _collect_all() -> void:
	var total := 0
	for i in range(GameState.plots.size()):
		total += GameState.collect_building(i)
	if total > 0:
		GameEvent.toast.emit("Collected %d resources" % total, UiTheme.C_GOOD)
	else:
		GameEvent.toast.emit("Nothing to collect yet", UiTheme.C_MUTED)
	_rebuild()


func _collect_plot(plot_index: int) -> void:
	GameState.collect_building(plot_index)
	_rebuild()


func _save() -> void:
	if SaveService.save_game():
		GameEvent.toast.emit("Game saved", UiTheme.C_GOOD)
	else:
		GameEvent.toast.emit("Save failed", UiTheme.C_BAD)


func _new_game() -> void:
	SaveService.delete_save()
	SaveService.enabled = false  # Main re-enables after the fresh profile is ready
	get_tree().paused = false
	get_tree().reload_current_scene()


func _build_on_plot(plot_index: int, building_id: String) -> void:
	_act(GameState.build_or_upgrade(plot_index, building_id), "Not enough resources")
