class_name GameMenu
extends Control
## Full-screen tabbed menu (portrait): Hero, Pet, Mount, Quest, Map, Village,
## System. Each tab is rebuilt from GameState/QuestService when shown or when
## the underlying data changes. The world keeps simulating behind the overlay.

signal closed

const TABS := ["hero", "pet", "mount", "quest", "map", "village", "system"]
const TAB_TITLES := {
	"hero": "Character", "pet": "Pets", "mount": "Mounts", "quest": "Quests",
	"map": "World Map", "village": "Homestead", "system": "System",
}
# Quest screen art comes from the original Ember UI kit (ArtCatalog IDs, ART_BIBLE.md §6).
const QUEST_ICON_SCALE := 3   # 16 px icons drawn at 48 px

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
	GameState.stats_dirty.connect(_mark_dirty)
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


# --- Character ----------------------------------------------------------------
## The single Kindler (owner decision 2026-11-08): no classes, no level. Shows the live stat sheet.
func _build_heroes() -> void:
	var v := _card()
	var row := _row(v)
	row.add_child(_icon(hero_portrait(), 80, Color.WHITE))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UiTheme.label("Kindler", 26, UiTheme.C_GOLD))
	info.add_child(UiTheme.label("Power comes from equipment, socket stones, pets and mounts.", 18, UiTheme.C_MUTED))
	var player := GameState.get_player()
	var stats: CharacterStats = player.get("stats") if player != null else null
	if stats != null:
		info.add_child(UiTheme.label("HP %d  ATK %d  DEF %d  SPD %d" % [stats.max_health, stats.attack_damage, stats.defense, int(stats.move_speed)], 18))
	var inv := GameState.get_inventory()
	if inv != null:
		var gem_stats := inv.get_gem_stats()
		var parts: Array[String] = []
		for stat: String in ["crit_chance", "crit_damage", "life_steal", "dodge", "regeneration", "reflection"]:
			if float(gem_stats.get(stat, 0.0)) > 0.0:
				parts.append("%s %.1f" % [stat.replace("_", " "), float(gem_stats[stat])])
		if not parts.is_empty():
			info.add_child(UiTheme.label(", ".join(parts), 18, Color(0.75, 0.85, 1)))


# --- Pets ---------------------------------------------------------------------
## Pets (sheet 03): stat-only, 4 qualities, diamond levels, 8 stones, hatched from eggs.
func _build_pets() -> void:
	_content.add_child(_wrapped(UiTheme.label("Pets add stats only. One active pet. Duplicates turn into diamonds.", 20, UiTheme.C_MUTED)))
	_content.add_child(UiTheme.label("Diamonds: %d" % GameState.get_diamonds(), 20, UiTheme.C_GOLD))
	# Eggs: price, stock and the hatch odds (sheet 03 §4: the UI must show the rates)
	for egg_id: String in CompanionCatalog.egg_ids():
		var e := CompanionCatalog.egg(egg_id)
		var v := _card()
		v.add_child(UiTheme.label("%s  (%s)  - you have %d" % [e.get("name", egg_id), e.get("region", ""), _count(egg_id)], 24, UiTheme.C_GOLD))
		var odds := CompanionCatalog.egg_odds(egg_id)
		var sp_parts: Array[String] = []
		for row: Dictionary in odds["species"]:
			sp_parts.append("%s %.0f%%" % [CompanionCatalog.species(row["id"]).get("name", row["id"]), float(row["percent"])])
		var q_parts: Array[String] = []
		for row: Dictionary in odds["quality"]:
			q_parts.append("%s %.0f%%" % [String(row["id"]).capitalize(), float(row["percent"])])
		v.add_child(_wrapped(UiTheme.label(", ".join(sp_parts), 17, UiTheme.C_MUTED)))
		v.add_child(_wrapped(UiTheme.label(", ".join(q_parts), 17, UiTheme.C_MUTED)))
		var actions := _row(v)
		actions.add_child(UiTheme.button("Buy (%s)" % GameState.format_cost(e.get("price", {})),
			func() -> void: _act(GameState.buy_egg(egg_id), "Not enough gold / diamonds or bag full")))
		if _count(egg_id) > 0:
			actions.add_child(UiTheme.button("Hatch", _hatch.bind(egg_id)))
	# Collection: every species, owned qualities first
	for species_id: String in CompanionCatalog.species_ids():
		var sp := CompanionCatalog.species(species_id)
		var owned_any := false
		for q: String in CompanionCatalog.qualities():
			var key := CompanionCatalog.pet_key(species_id, q)
			if GameState.pets.has(key):
				owned_any = true
				_pet_card(key)
		if not owned_any:
			var v := _card()
			var row := _row(v)
			row.add_child(_icon(_actor_icon(str(sp.get("art", ""))), 64, Color(0.3, 0.3, 0.3)))
			row.add_child(UiTheme.label("%s - not owned (%s)" % [sp.get("name", species_id), sp.get("focus", "")], 20, UiTheme.C_MUTED))


func _pet_card(key: String) -> void:
	var parsed := CompanionCatalog.parse_pet_key(key)
	var sp := CompanionCatalog.species(parsed["species"])
	var lv := GameState.pet_level(key)
	var v := _card()
	var row := _row(v)
	row.add_child(_icon(_actor_icon(str(sp.get("art", ""))), 72))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UiTheme.label("%s  Lv.%d/%d" % [CompanionCatalog.pet_name(key), lv, CompanionCatalog.pet_max_level()], 24, CompanionCatalog.quality_color(parsed["quality"])))
	info.add_child(UiTheme.label(_stat_text(CompanionCatalog.pet_stats(key, lv)), 18, Color(0.75, 0.85, 1)))
	var art_status := str(sp.get("art_status", ""))
	if not art_status.is_empty():
		info.add_child(UiTheme.label("Art: placeholder", 14, UiTheme.C_MUTED))
	var actions := _row(v)
	if GameState.active_pet == key:
		actions.add_child(UiTheme.button("Unequip", _equip_pet.bind("")))
	else:
		actions.add_child(UiTheme.button("Equip", _equip_pet.bind(key)))
	var cost := CompanionCatalog.pet_level_cost(lv)
	if cost > 0:
		actions.add_child(UiTheme.button("Level up (%d diamonds)" % cost, _confirm_spend.bind(
			"Spend %d diamonds to raise %s to Lv.%d?" % [cost, CompanionCatalog.pet_name(key), lv + 1],
			func() -> bool: return GameState.level_up_pet(key), "Not enough diamonds")))
	actions.add_child(UiTheme.button("Stones", _open_companion_stones.bind("pet", key)))


# --- Mounts -------------------------------------------------------------------
## Mounts (sheet 04): diamond levels, 8 stones (socketing can evolve the form), shared stomp.
func _build_mounts() -> void:
	_content.add_child(_wrapped(UiTheme.label("Every mount can fight: attacks play the stomp. Socketing a stone may evolve the mount.", 20, UiTheme.C_MUTED)))
	_content.add_child(UiTheme.label("Diamonds: %d" % GameState.get_diamonds(), 20, UiTheme.C_GOLD))
	for id: String in CompanionCatalog.mount_ids():
		var m := CompanionCatalog.mount(id)
		var owned := GameState.mounts.has(id)
		var v := _card()
		var row := _row(v)
		var look := MountVisual.describe(id, GameState.mount_skin(id) if owned else {}, GameState.mount_form(id))
		row.add_child(_icon(_actor_icon(str(look["art"])), 80, look["modulate"] if owned else Color(0.35, 0.35, 0.35)))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var title := "%s  [%s]" % [m.get("name", id), String(m.get("category", "")).to_upper()]
		if owned:
			title += "  Lv.%d  %s" % [GameState.mount_level(id), CompanionCatalog.form_name(GameState.mount_form(id))]
		info.add_child(UiTheme.label(title, 24, UiTheme.C_GOLD))
		var lv := maxi(GameState.mount_level(id), 1)
		var stats_text := "Speed x%.2f" % CompanionCatalog.mount_speed_mult(id, GameState.mount_form(id))
		var extra := _stat_text(CompanionCatalog.mount_stats(id, lv, GameState.mount_form(id)))
		info.add_child(UiTheme.label(stats_text + ("  " + extra if not extra.is_empty() else ""), 18, Color(0.75, 0.85, 1)))
		if not str(m.get("art_status", "")).is_empty():
			info.add_child(UiTheme.label("Art: placeholder", 14, UiTheme.C_MUTED))
		var actions := _row(v)
		if not owned:
			actions.add_child(UiTheme.button("Claim (%s)" % GameState.format_cost(m.get("unlock", {})),
				func() -> void: _act(GameState.unlock_mount(id), "Not enough gold / diamonds")))
			continue
		if GameState.active_mount == id:
			actions.add_child(UiTheme.button("Dismount" if GameState.mounted else "Ride", _toggle_ride))
		else:
			actions.add_child(UiTheme.button("Select", _select_mount.bind(id)))
		var cost := CompanionCatalog.mount_level_cost(GameState.mount_level(id))
		if cost > 0:
			actions.add_child(UiTheme.button("Train (%d diamonds)" % cost, _confirm_spend.bind(
				"Spend %d diamonds to train %s to Lv.%d?" % [cost, m.get("name", id), GameState.mount_level(id) + 1],
				func() -> bool: return GameState.level_up_mount(id), "Not enough diamonds")))
		actions.add_child(UiTheme.button("Stones", _open_companion_stones.bind("mount", id)))
		var skins: Array = m.get("skins", [])
		if skins.size() > 1:
			var skin_row := HFlowContainer.new()
			skin_row.add_theme_constant_override("h_separation", 8)
			skin_row.add_theme_constant_override("v_separation", 6)
			v.add_child(skin_row)
			skin_row.add_child(UiTheme.label("Skins:", 20))
			for i in range(skins.size()):
				var skin: Dictionary = skins[i]
				var owned_skin := false
				for s_i: Variant in GameState.mounts[id]["skins"]:
					owned_skin = owned_skin or int(s_i) == i
				var label := str(skin.get("name", "Skin %d" % (i + 1)))
				if not owned_skin:
					label += " (%dg)" % int(skin.get("cost", 0))
				var skin_index := i
				var skin_btn := UiTheme.button(label, func() -> void: _act(GameState.buy_or_select_skin(id, skin_index), "Not enough gold"), Vector2(0, 48))
				skin_row.add_child(skin_btn)


func _wrapped(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 1
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _stat_text(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for k: String in stats:
		var value := float(stats[k])
		if k == "gold_pct":
			parts.append("gold +%d%%" % roundi(value * 100.0))
		else:
			parts.append("%s +%s" % [k.replace("_", " "), ("%d" % roundi(value)) if absf(value) >= 10.0 else ("%.1f" % value)])
	return ", ".join(parts)


## First frame of an actor sheet, for list icons.
func _actor_icon(asset_id: String) -> Texture2D:
	var frames := MonsterVisualCatalog.get_frames(asset_id)
	if frames == null:
		return null
	for name: String in ["idle_down", "idle"]:
		if frames.has_animation(name) and frames.get_frame_count(name) > 0:
			return frames.get_frame_texture(name, 0)
	return null


func _hatch(egg_id: String) -> void:
	var result := GameState.hatch_egg(egg_id)
	if result.is_empty():
		GameEvent.toast.emit("Could not hatch the egg", UiTheme.C_BAD)
	elif bool(result["duplicate"]):
		GameEvent.toast.emit("Duplicate %s: +%d diamonds" % [CompanionCatalog.pet_name(result["key"]), int(result["diamonds"])], UiTheme.C_GOLD)
	else:
		GameEvent.toast.emit("New pet: %s!" % CompanionCatalog.pet_name(result["key"]), UiTheme.C_GOOD)
	_rebuild()


## Every diamond spend asks first (sheet 03 §5 Pet Upgrade).
func _confirm_spend(message: String, action: Callable, fail_msg: String) -> void:
	ConfirmDialog.show_confirm(message, func() -> void: _act(bool(action.call()), fail_msg))


func _open_companion_stones(kind: String, id: String) -> void:
	var existing := get_node_or_null("GemPanel")
	if existing:
		existing.queue_free()
	var panel: GemPanel = preload("res://sense/ui/gems/GemPanel.tscn").instantiate()
	panel.name = "GemPanel"
	add_child(panel)
	panel.setup_companion(GameState.get_inventory(), kind, id, GameState.get_player() as Node2D)
	panel.position = Vector2(40, 260)
	panel.panel_closed.connect(_rebuild)


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
	row.add_child(_quest_tab_button(ArtCatalog.texture("ui.icon.quest_main", QUEST_ICON_SCALE), "main", true))
	row.add_child(_quest_tab_button(ArtCatalog.texture("ui.icon.quest_daily", QUEST_ICON_SCALE), "daily", true))
	row.add_child(_quest_tab_button(ArtCatalog.texture("ui.icon.login", QUEST_ICON_SCALE), "login", false))
	row.add_child(_quest_tab_button(ArtCatalog.texture("ui.icon.quest_achievement", QUEST_ICON_SCALE), "achievement", false))


func _quest_back_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Back"
	button.icon = ArtCatalog.texture("ui.icon.back", QUEST_ICON_SCALE)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_stylebox_override("normal", _kit_style("ui.button.secondary"))
	button.add_theme_stylebox_override("hover", _kit_style("ui.button.secondary.hover"))
	button.add_theme_stylebox_override("pressed", _kit_style("ui.button.secondary.pressed"))
	button.add_theme_stylebox_override("hover_pressed", _kit_style("ui.button.secondary.pressed"))
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
	var normal_style := _kit_style("ui.tab.active" if active else "ui.tab.inactive")
	var pressed_style := _kit_style("ui.tab.active")
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
	var style := _kit_style("ui.panel.dark")
	panel.add_theme_stylebox_override("panel", style)
	var label := UiTheme.label(text, 28, UiTheme.C_GOLD)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", UiTheme.C_GOLD)
	panel.add_child(label)
	return panel


func _quest_list() -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _kit_style("ui.panel.dark"))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return {"panel": panel, "content": content}


func _quest_card(row_data: Dictionary, quest: Dictionary, interactive: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 176)
	var style_id := "ui.panel.highlight" if bool(row_data["ready"]) else "ui.panel.default"
	panel.add_theme_stylebox_override("panel", _kit_style(style_id))
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
	var reward := UiTheme.label(_reward_text(quest), 19, UiTheme.C_GOLD)
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(reward)
	footer.add_child(UiTheme.label("%d/%d" % [row_data["progress"], row_data["count"]], 23, UiTheme.C_GOLD))
	if interactive and bool(row_data["ready"]) and not bool(row_data["claimed"]):
		var quest_id: String = row_data["id"]
		footer.add_child(UiTheme.button("Nhận", func() -> void: _act(QuestService.claim(quest_id), ""), Vector2(92, 44)))
	return panel


## A per-control copy of a kit style with the quest screen's content padding.
func _kit_style(id: String) -> StyleBox:
	var style := ArtCatalog.stylebox(id).duplicate() as StyleBox
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


func _reward_text(quest: Dictionary) -> String:
	var preview := str(quest.get("reward_preview", ""))
	if not preview.is_empty():
		return preview
	var r := quest.get("reward", {}) as Dictionary
	var parts: Array[String] = []
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
	_build_world_boss_card()
	_build_boss_cards()
	for id in GameContent.ZONE_ORDER:
		var z: Dictionary = GameContent.ZONES[id]
		var v := _card()
		var row := _row(v)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UiTheme.label(z["name"], 26, UiTheme.C_GOLD))
		var extra := "Safe zone" if z.get("safe", false) else "Monster level %d" % int(z["level"])
		var bosses: Array[String] = []
		for boss_id: String in BossCatalog.boss_ids():
			var b := BossCatalog.boss(boss_id)
			if str(b.get("zone", "")) == id and str(b.get("type", "")) in ["world", "area"]:
				bosses.append("%s (%s)" % [GameContent.MONSTERS[boss_id]["name"], b["type"]])
		if not bosses.is_empty():
			extra += "  -  " + ", ".join(bosses)
		info.add_child(UiTheme.label(extra, 18, UiTheme.C_MUTED))
		if id == GameState.current_zone:
			row.add_child(UiTheme.label("HERE ", 22, UiTheme.C_GOOD))
		else:
			row.add_child(UiTheme.button("Travel", _travel.bind(String(id)), Vector2(120, 52)))


## World boss timetable (sheet 06 §6): what is up now and what comes next, host clock.
func _build_world_boss_card() -> void:
	var v := _card()
	v.add_child(UiTheme.label("WORLD BOSSES", 24, UiTheme.C_GOLD))
	var status := WorldBossSchedule.status_at(Time.get_datetime_dict_from_system())
	if bool(status["active"]):
		var left := int(status["seconds_left"])
		v.add_child(_wrapped(UiTheme.label("Now: %s at %s (%d:%02d left)" % [GameContent.MONSTERS[status["boss_id"]]["name"], GameContent.ZONES[status["zone"]]["name"], left / 60, left % 60], 19, UiTheme.C_GOOD)))
	var wait := int(status["seconds_to_next"])
	v.add_child(_wrapped(UiTheme.label("Next: %s at %s in %dh %02dm" % [GameContent.MONSTERS.get(str(status["next_boss"]), {}).get("name", ""), GameContent.ZONES.get(str(status["next_zone"]), {}).get("name", ""), wait / 3600, (wait % 3600) / 60], 19, UiTheme.C_MUTED)))
	var slots: Array[String] = []
	for slot: Array in WorldBossSchedule.config().get("slots", []):
		slots.append("%02d:00 %s" % [int(slot[0]), GameContent.MONSTERS[str(slot[1])]["name"]])
	v.add_child(_wrapped(UiTheme.label(", ".join(slots), 16, UiTheme.C_MUTED)))


## Boss Summon Cards and fragments (sheet 06 §7).
func _build_boss_cards() -> void:
	var v := _card()
	v.add_child(UiTheme.label("BOSS CARDS", 24, UiTheme.C_GOLD))
	var any := false
	for card_id: String in BossCatalog.cards():
		var c := BossCatalog.card(card_id)
		var have := _count(card_id)
		var frag := str(c.get("fragment", ""))
		var frags := _count(frag) if not frag.is_empty() else 0
		if have <= 0 and frags <= 0:
			continue
		any = true
		var row := _row(v)
		var info := "%s x%d  (%s, %s)" % [c.get("name", card_id), have, GameContent.MONSTERS[str(c["boss"])]["name"], "/".join(c.get("regions", []))]
		if not frag.is_empty():
			info += "  fragments %d/%d" % [frags, int(c.get("fragments_needed", 0))]
		row.add_child(_wrapped(UiTheme.label(info, 18)))
		if have > 0:
			row.add_child(UiTheme.button("Summon", _use_card.bind(card_id), Vector2(120, 48)))
		if not frag.is_empty() and frags >= int(c.get("fragments_needed", 0)):
			row.add_child(UiTheme.button("Combine", func() -> void: _act(GameState.combine_card_fragments(frag), "Bag full"), Vector2(120, 48)))
	if not any:
		v.add_child(_wrapped(UiTheme.label("No cards yet. Fragments drop from bosses and rare digs.", 18, UiTheme.C_MUTED)))


func _use_card(card_id: String) -> void:
	var reason := GameState.use_boss_card(card_id)
	if reason.is_empty():
		close()
	else:
		GameEvent.toast.emit(reason, UiTheme.C_BAD)
		_rebuild()


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
	v.add_child(UiTheme.label("Profile: %d kills, bosses: %s" % [GameState.kills_total, str(GameState.boss_kills)], 18, UiTheme.C_MUTED))
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
