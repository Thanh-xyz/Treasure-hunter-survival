class_name StartupGate
extends Control
## Cinderwild title screen: short loading state, then Play (offline) or LAN (host/join).
## Original layout and art (ART_BIBLE.md); the offline/LAN logic is unchanged.

signal local_selected
signal mode_selected(mode: String)

const DESIGN_SIZE := Vector2(720, 1600)
const LOADING_SECONDS := 1.2

var _design_root: Control
var _loading_layer: Control
var _menu_layer: Control
var _network_panel: Control
var _menu_main: Control
var _progress_fill: ColorRect
var _local_button: Button
var _host_button: Button
var _join_button: Button
var _address_input: LineEdit
var _status_label: Label
var _addresses_label: Label
var _has_profile := false
var _opened_once := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_design_root = Control.new()
	_design_root.name = "DesignLayout"
	_design_root.size = DESIGN_SIZE
	add_child(_design_root)
	resized.connect(_sync_design_scale)
	_sync_design_scale.call_deferred()
	_add_backdrop()
	_build_loading_layer()
	_build_menu_layer()
	LanSession.status_changed.connect(_on_lan_status)
	LanSession.session_ready.connect(_on_lan_ready)


func _sync_design_scale() -> void:
	if _design_root != null:
		_design_root.scale = Vector2(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)


func configure(has_profile: bool) -> void:
	_has_profile = has_profile
	if _local_button != null:
		_local_button.text = "Tiếp tục" if _has_profile else "Bắt đầu"


func open() -> void:
	visible = true
	get_tree().paused = true
	if _opened_once:
		_show_menu()
		return
	_opened_once = true
	_show_loading()
	_finish_loading.call_deferred()


func _finish_loading() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_progress_fill, "size:x", _progress_fill.get_meta("full_width"), LOADING_SECONDS)
	await tween.finished
	if is_inside_tree() and visible:
		_show_menu()


func _show_loading() -> void:
	_loading_layer.visible = true
	_menu_layer.visible = false


func _show_menu() -> void:
	_loading_layer.visible = false
	_menu_layer.visible = true


# --- layout ------------------------------------------------------------------

func _add_backdrop() -> void:
	var bg := TextureRect.new()
	bg.texture = ArtCatalog.texture("ui.title.background")
	bg.size = DESIGN_SIZE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(bg)
	var logo := ArtCatalog.texture("ui.title.logo")
	var logo_rect := TextureRect.new()
	logo_rect.texture = logo
	logo_rect.position = Vector2((DESIGN_SIZE.x - logo.get_width()) * 0.5, 200)
	logo_rect.size = Vector2(logo.get_width(), logo.get_height())
	logo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(logo_rect)
	_add_label(_design_root, "Nhóm lại ngọn lửa nơi biên giới tro tàn", Rect2(40, 330, 640, 40), 24, UiTheme.C_GOLD)


func _build_loading_layer() -> void:
	_loading_layer = _layer("Loading")
	var frame := _add_panel(_loading_layer, Rect2(150, 1360, 420, 36), "ui.panel.dark")
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_fill = ColorRect.new()
	_progress_fill.color = ArtPalette.color("E")
	_progress_fill.position = Vector2(9, 9)
	_progress_fill.size = Vector2(0, 18)
	_progress_fill.set_meta("full_width", 402.0)
	frame.add_child(_progress_fill)
	_add_label(_loading_layer, "Đang nhóm lửa...", Rect2(150, 1404, 420, 36), 22, UiTheme.C_MUTED)


func _build_menu_layer() -> void:
	_menu_layer = _layer("Menu")
	_menu_layer.visible = false
	_menu_main = Control.new()
	_menu_main.name = "MainMenu"
	_menu_main.size = DESIGN_SIZE
	_menu_main.mouse_filter = Control.MOUSE_FILTER_PASS
	_menu_layer.add_child(_menu_main)
	_add_panel(_menu_main, Rect2(120, 880, 480, 360), "ui.panel.default")
	_local_button = _add_button(_menu_main, "Tiếp tục" if _has_profile else "Bắt đầu", Rect2(156, 920, 408, 88), _choose_local, 34, "primary")
	_add_button(_menu_main, "Chơi LAN", Rect2(156, 1028, 408, 88), _toggle_network_panel, 30, "secondary")
	var hint := _add_label(_menu_main, "Chơi offline, tiến trình lưu trên máy này.\nLAN: tối đa 4 người cùng mạng Wi-Fi.", Rect2(150, 1130, 420, 90), 19, UiTheme.C_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	_add_label(_menu_layer, "Cinderwild%s · bản phát triển" % ((" " + version) if not version.is_empty() else ""), Rect2(120, 1520, 480, 30), 17, UiTheme.C_MUTED)
	_build_network_panel()


func _build_network_panel() -> void:
	_network_panel = Control.new()
	_network_panel.name = "LanOptions"
	_network_panel.position = Vector2(70, 840)
	_network_panel.size = Vector2(580, 440)
	_network_panel.visible = false
	_menu_layer.add_child(_network_panel)
	_add_panel(_network_panel, Rect2(Vector2.ZERO, _network_panel.size), "ui.panel.default")
	_add_label(_network_panel, "CHƠI LAN (WI-FI)", Rect2(30, 24, 520, 44), 28, UiTheme.C_GOLD)
	_address_input = _add_input(_network_panel, Rect2(36, 90, 330, 76), "IP máy chủ")
	_address_input.text = "127.0.0.1"
	_address_input.max_length = 128
	_join_button = _add_button(_network_panel, "Vào", Rect2(380, 90, 164, 76), _choose_join, 26, "secondary")
	_host_button = _add_button(_network_panel, "Làm máy chủ", Rect2(36, 186, 330, 76), _choose_host, 26, "primary")
	_add_button(_network_panel, "Đóng", Rect2(380, 186, 164, 76), _toggle_network_panel, 26, "secondary")
	_status_label = _add_label(_network_panel, "Máy chủ quản lý quái, máu và hồi sinh.", Rect2(36, 286, 508, 60), 19, UiTheme.C_MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_addresses_label = _add_label(
		_network_panel,
		"UDP %d • IP: %s" % [LanSession.PORT, LanSession.local_addresses_text()],
		Rect2(36, 356, 508, 50),
		17,
		ArtPalette.color("i")
	)
	_addresses_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_addresses_label.clip_text = true
	_addresses_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.size = DESIGN_SIZE
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_design_root.add_child(layer)
	return layer


func _add_panel(parent: Control, rect: Rect2, style_id: String) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", ArtCatalog.stylebox(style_id))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _add_label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := UiTheme.label(text, font_size, color)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _add_input(parent: Control, rect: Rect2, placeholder: String) -> LineEdit:
	var input := LineEdit.new()
	input.position = rect.position
	input.size = rect.size
	input.placeholder_text = placeholder
	input.add_theme_font_size_override("font_size", 27)
	input.add_theme_color_override("font_placeholder_color", UiTheme.C_STEEL)
	input.add_theme_color_override("font_color", UiTheme.C_TEXT)
	input.add_theme_stylebox_override("normal", ArtCatalog.stylebox("ui.panel.dark"))
	input.add_theme_stylebox_override("focus", ArtCatalog.stylebox("ui.tab.active"))
	parent.add_child(input)
	return input


## kind: "primary" (theme default) or "secondary" (frost blue).
func _add_button(parent: Control, text: String, rect: Rect2, callback: Callable, font_size: int, kind: String) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	if kind == "secondary":
		button.add_theme_stylebox_override("normal", ArtCatalog.stylebox("ui.button.secondary"))
		button.add_theme_stylebox_override("hover", ArtCatalog.stylebox("ui.button.secondary.hover"))
		button.add_theme_stylebox_override("pressed", ArtCatalog.stylebox("ui.button.secondary.pressed"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


# --- actions (unchanged behaviour) ---------------------------------------------

func _toggle_network_panel() -> void:
	_network_panel.visible = not _network_panel.visible
	_menu_main.visible = not _network_panel.visible


func _choose_local() -> void:
	LanSession.stop(false)
	visible = false
	get_tree().paused = false
	local_selected.emit()
	mode_selected.emit("local")


func _choose_host() -> void:
	_set_connecting(true)
	var err := LanSession.start_host()
	if err != OK:
		_set_connecting(false)


func _choose_join() -> void:
	_set_connecting(true)
	var err := LanSession.join_host(_address_input.text)
	if err != OK:
		_set_connecting(false)


func _on_lan_ready(role: String, _zone_id: String) -> void:
	visible = false
	get_tree().paused = false
	_set_connecting(false)
	mode_selected.emit(role)


func _on_lan_status(text: String, is_error: bool) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", UiTheme.C_BAD if is_error else UiTheme.C_GOOD)
	if is_error:
		_set_connecting(false)


func _set_connecting(connecting: bool) -> void:
	if _local_button:
		_local_button.disabled = connecting
	if _host_button:
		_host_button.disabled = connecting
	if _join_button:
		_join_button.disabled = connecting
		_join_button.text = "Đang kết nối..." if connecting else "Vào"
	if _address_input:
		_address_input.editable = not connecting
