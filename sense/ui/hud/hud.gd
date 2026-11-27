extends CanvasLayer

@onready var health_bar: PixelBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var stamina_bar: PixelBar = $MarginContainer/VBoxContainer/StaminaContainer/StaminaBar

# Status effect icons
@onready var icon_speed: Control = $StatusIconsContainer/IconsFlow/SpeedIcon
@onready var icon_heal: Control = $StatusIconsContainer/IconsFlow/HealIcon
@onready var icon_shield: Control = $StatusIconsContainer/IconsFlow/ShieldIcon
@onready var icon_poison: Control = $StatusIconsContainer/IconsFlow/PoisonIcon
@onready var icon_burn: Control = $StatusIconsContainer/IconsFlow/BurnIcon
@onready var icon_freeze: Control = $StatusIconsContainer/IconsFlow/FreezeIcon

# World Minimap (SubViewport-based)
@onready var minimap_camera: Camera2D = $MinimapContainer/MarginContainer/SubViewportContainer/SubViewport/MinimapCamera
@onready var minimap_viewport: SubViewport = $MinimapContainer/MarginContainer/SubViewportContainer/SubViewport
@onready var world_minimap_container: SubViewportContainer = $MinimapContainer/MarginContainer/SubViewportContainer

# Dungeon Minimap (room-layout based)
@onready var dungeon_minimap: DungeonMinimap = $MinimapContainer/MarginContainer/DungeonMinimap

# Information feed (under minimap)
@onready var feed_container: PanelContainer = $FeedContainer
@onready var feed_rows: Array[HBoxContainer] = [
	$FeedContainer/MarginContainer/FeedList/FeedRow1,
	$FeedContainer/MarginContainer/FeedList/FeedRow2,
	$FeedContainer/MarginContainer/FeedList/FeedRow3
]

var stats: CharacterStats
var player: Node2D # Reference to player for minimap

# Hotbar (skill + item quick-use bar at bottom-center) — scene instance
@onready var hotbar: Hotbar = $HotbarAnchor/Hotbar

const FEED_MAX_ROWS := 3
const FEED_MERGE_WINDOW := 0.8
const FEED_ENTRY_DURATION := 2.5

var _feed_entries: Array[Dictionary] = []
var _skill_component: SkillComponent
var _buff_component: BuffComponent


func _ready() -> void:
	# Ẩn tất cả icon khi bắt đầu
	# hide_all_status_icons()
	# enable_all_status_icons()
	show_shield_icon(true)
	if feed_container:
		feed_container.visible = false


func setup(character_stats: CharacterStats) -> void:
	if stats and stats != character_stats:
		if stats.health_changed.is_connected(_on_health_changed):
			stats.health_changed.disconnect(_on_health_changed)
		if stats.stamina_changed.is_connected(_on_stamina_changed):
			stats.stamina_changed.disconnect(_on_stamina_changed)
	stats = character_stats
	if stats == null:
		_on_health_changed(0, 1)
		_on_stamina_changed(0.0, 1.0)
		return

	if not stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.connect(_on_health_changed)
	if not stats.stamina_changed.is_connected(_on_stamina_changed):
		stats.stamina_changed.connect(_on_stamina_changed)

	_on_health_changed(stats.current_health, stats.max_health)
	_on_stamina_changed(stats.current_stamina, stats.max_stamina)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.set_values(current, maximum)


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.set_values(current, maximum)


# === STATUS ICON FUNCTIONS ===

func hide_all_status_icons() -> void:
	icon_speed.visible = false
	icon_heal.visible = false
	icon_shield.visible = false
	icon_poison.visible = false
	icon_burn.visible = false
	icon_freeze.visible = false


func enable_all_status_icons() -> void:
	icon_speed.visible = true
	icon_heal.visible = true
	icon_shield.visible = true
	icon_poison.visible = true
	icon_burn.visible = true
	icon_freeze.visible = true


func show_speed_icon(value: bool = true) -> void:
	icon_speed.visible = value


func show_heal_icon(value: bool = true) -> void:
	icon_heal.visible = value


func show_shield_icon(value: bool = true) -> void:
	icon_shield.visible = value


func show_poison_icon(value: bool = true) -> void:
	icon_poison.visible = value


func show_burn_icon(value: bool = true) -> void:
	icon_burn.visible = value


func show_freeze_icon(value: bool = true) -> void:
	icon_freeze.visible = value


## Connect BuffComponent signals to HUD status icons
## Called by Player after creating BuffComponent
func connect_buff_component(buff_comp: BuffComponent) -> void:
	if is_instance_valid(_buff_component) and _buff_component != buff_comp:
		if _buff_component.buff_applied.is_connected(_on_buff_applied):
			_buff_component.buff_applied.disconnect(_on_buff_applied)
		if _buff_component.buff_expired.is_connected(_on_buff_expired):
			_buff_component.buff_expired.disconnect(_on_buff_expired)
	_buff_component = buff_comp
	if _buff_component:
		if not _buff_component.buff_applied.is_connected(_on_buff_applied):
			_buff_component.buff_applied.connect(_on_buff_applied)
		if not _buff_component.buff_expired.is_connected(_on_buff_expired):
			_buff_component.buff_expired.connect(_on_buff_expired)
	_refresh_buff_icons()


## Connect SkillComponent signals to HUD skill display
## Called by Player after creating SkillComponent
func connect_skill_component(skill_comp: SkillComponent) -> void:
	if is_instance_valid(_skill_component) and _skill_component != skill_comp:
		if _skill_component.skills_changed.is_connected(_on_skills_changed):
			_skill_component.skills_changed.disconnect(_on_skills_changed)
		if _skill_component.skill_cooldown_updated.is_connected(_on_skill_cooldown_updated):
			_skill_component.skill_cooldown_updated.disconnect(_on_skill_cooldown_updated)
	_skill_component = skill_comp
	if _skill_component:
		if not _skill_component.skills_changed.is_connected(_on_skills_changed):
			_skill_component.skills_changed.connect(_on_skills_changed)
		if not _skill_component.skill_cooldown_updated.is_connected(_on_skill_cooldown_updated):
			_skill_component.skill_cooldown_updated.connect(_on_skill_cooldown_updated)


func _on_buff_applied(buff_data: Dictionary) -> void:
	_refresh_buff_icons()
	var source_id: String = buff_data.get("source_item_id", "")
	if "defense" in source_id and not "speed" in source_id and not "vitality" in source_id and not "health" in source_id:
		if feed_container:
			feed_container.visible = false # TODO: Add duration overlay (Label with countdown) on each icon


func _on_buff_expired(_buff_id: String) -> void:
	_refresh_buff_icons()


func _refresh_buff_icons() -> void:
	var speed := false
	var heal := false
	var shield := false
	if is_instance_valid(_buff_component):
		for buff: Dictionary in _buff_component.active_buffs:
			var source_id: String = buff.get("source_item_id", "")
			# Keep the existing source-ID mapping and priority.
			if "speed" in source_id:
				speed = true
			elif "vitality" in source_id or "health" in source_id:
				heal = true
			elif "defense" in source_id:
				shield = true
	show_speed_icon(speed)
	show_heal_icon(heal)
	show_shield_icon(shield)


func _on_skills_changed() -> void:
	if hotbar:
		hotbar._refresh_skill_slots()


func _on_skill_cooldown_updated(skill_id: String, remaining: float) -> void:
	if hotbar:
		hotbar._on_skill_cooldown_updated(skill_id, remaining)


func set_status_icon(icon_name: String, value: bool) -> void:
	match icon_name:
		"speed":
			show_speed_icon(value)
		"heal":
			show_heal_icon(value)
		"shield":
			show_shield_icon(value)
		"poison":
			show_poison_icon(value)
		"burn":
			show_burn_icon(value)
		"freeze":
			show_freeze_icon(value)


# === HOTBAR ===

## Setup hotbar with inventory + skill component (called by Player)
func setup_hotbar(inventory: InventoryData, skill_comp: SkillComponent) -> void:
	if hotbar:
		hotbar.setup(inventory, skill_comp)


## Get hotbar reference (for connecting signals in Player)
func get_hotbar() -> Hotbar:
	return hotbar


# === INFO FEED ===

## Push one row into the HUD information feed (below minimap).
## - icon: optional entry icon
## - title: label text (item/system info)
## - quantity: positive amount shown as +N
## - merge_key: when provided, duplicate entries merge in a short time window
func push_info_feed_entry(icon: Texture2D, title: String, quantity: int, merge_key: String = "") -> void:
	var safe_title := title.strip_edges()
	if safe_title.is_empty():
		safe_title = "Unknown"

	var safe_quantity: int = max(quantity, 1)
	var now_s := Time.get_ticks_msec() / 1000.0

	# Merge with a recent duplicate entry to reduce spam.
	if not merge_key.is_empty():
		for i in range(_feed_entries.size()):
			var entry: Dictionary = _feed_entries[i]
			if entry.get("merge_key", "") == merge_key and now_s - entry.get("last_update", 0.0) <= FEED_MERGE_WINDOW:
				entry["quantity"] = int(entry.get("quantity", 0)) + safe_quantity
				entry["title"] = safe_title
				entry["icon"] = icon if icon != null else entry.get("icon", null)
				entry["last_update"] = now_s
				entry["expires_at"] = now_s + FEED_ENTRY_DURATION
				_feed_entries[i] = entry
				_render_info_feed()
				return

	var new_entry := {
		"title": safe_title,
		"quantity": safe_quantity,
		"icon": icon,
		"merge_key": merge_key,
		"last_update": now_s,
		"expires_at": now_s + FEED_ENTRY_DURATION
	}
	_feed_entries.push_front(new_entry)
	if _feed_entries.size() > FEED_MAX_ROWS:
		_feed_entries.resize(FEED_MAX_ROWS)

	_render_info_feed()


func _render_info_feed() -> void:
	if feed_container:
		feed_container.visible = _feed_entries.size() > 0

	for row_index in range(feed_rows.size()):
		var row := feed_rows[row_index]
		var icon_rect := row.get_node_or_null("Icon") as TextureRect
		var title_label := row.get_node_or_null("Title") as Label
		var qty_label := row.get_node_or_null("Qty") as Label

		if row_index < _feed_entries.size():
			var entry: Dictionary = _feed_entries[row_index]
			row.visible = true
			if title_label:
				title_label.text = str(entry.get("title", "Unknown"))
			if qty_label:
				qty_label.text = "+%d" % int(entry.get("quantity", 1))
			if icon_rect:
				icon_rect.texture = entry.get("icon", icon_rect.texture)
		else:
			row.visible = false


func _prune_expired_feed_entries() -> void:
	if _feed_entries.is_empty():
		return

	var now_s := Time.get_ticks_msec() / 1000.0
	var filtered: Array[Dictionary] = []
	for entry in _feed_entries:
		if now_s <= float(entry.get("expires_at", 0.0)):
			filtered.append(entry)

	if filtered.size() != _feed_entries.size():
		_feed_entries = filtered
		_render_info_feed()


# === MINIMAP FUNCTIONS ===

func setup_minimap(player_node: Node2D, world: Node2D) -> void:
	player = player_node
	
	# Share the same world_2d so minimap sees the game world
	# This avoids duplicating nodes which causes infinite loops
	if world != null and minimap_viewport != null:
		minimap_viewport.world_2d = world.get_world_2d()


## Switch to world minimap mode (for open-world maps like town)
func show_world_minimap() -> void:
	if world_minimap_container:
		world_minimap_container.visible = true
	if dungeon_minimap:
		dungeon_minimap.hide_minimap()
		dungeon_minimap.clear_dungeon()


## Switch to dungeon minimap mode (for room-based dungeons)
func show_dungeon_minimap() -> void:
	if world_minimap_container:
		world_minimap_container.visible = false
	if dungeon_minimap:
		dungeon_minimap.show_minimap()


## Update dungeon minimap with room data
func update_dungeon_minimap(rooms: Dictionary, current_room: Vector2i) -> void:
	if dungeon_minimap:
		dungeon_minimap.update_dungeon(rooms, current_room)


## Update only current room position on dungeon minimap
func update_dungeon_current_room(pos: Vector2i) -> void:
	if dungeon_minimap:
		dungeon_minimap.update_current_room(pos)


func _process(_delta: float) -> void:
	_prune_expired_feed_entries()

	# Update minimap camera to follow player
	if player != null and minimap_camera != null:
		minimap_camera.global_position = player.global_position
