class_name StartupGate
extends Control
## Treasure Hunter startup/auth presentation over the existing local/LAN modes.

signal local_selected
signal mode_selected(mode: String)

const LOADING_BACKGROUND := preload("res://assets/treasure_hunter/ui/reference/loading_background_halloween.png")
const LOGIN_BACKGROUND := preload("res://assets/treasure_hunter/ui/reference/login_background_server.png")
const TITLE_LOGO := preload("res://assets/treasure_hunter/ui/reference/logo_title.png")
const AGE_NOTICE := preload("res://assets/treasure_hunter/ui/reference/notice_age_18.png")
const LOGIN_PANEL := preload("res://assets/treasure_hunter/ui/reference/login_panel.png")
const LOGIN_TAB_ACTIVE := preload("res://assets/treasure_hunter/ui/reference/login_tab_active.png")
const LOGIN_TAB_INACTIVE := preload("res://assets/treasure_hunter/ui/reference/login_tab_inactive.png")
const LOGIN_LINE := preload("res://assets/treasure_hunter/ui/reference/login_line.png")
const BUTTON_BLUE := preload("res://assets/treasure_hunter/ui/reference/button_blue.png")
const BUTTON_ORANGE := preload("res://assets/treasure_hunter/ui/reference/button_orange.png")

const REFERENCE_SIZE := Vector2(720, 1600)
const INPUT_COLOR := Color(0.105, 0.105, 0.105, 1.0)

var _loading_layer: Control
var _auth_layer: Control
var _reference_root: Control
var _network_panel: Control
var _login_tab_background: NinePatchRect
var _register_tab_background: NinePatchRect
var _username_input: LineEdit
var _password_input: LineEdit
var _primary_button: Button
var _hint_label: Label
var _hint_line: TextureRect
var _local_button: Button
var _host_button: Button
var _join_button: Button
var _address_input: LineEdit
var _status_label: Label
var _addresses_label: Label
var _has_profile := false
var _is_login := false
var _opened_once := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = REFERENCE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_reference_root = Control.new()
	_reference_root.name = "ReferenceLayout"
	_reference_root.size = REFERENCE_SIZE
	add_child(_reference_root)
	resized.connect(_sync_reference_scale)
	_sync_reference_scale.call_deferred()
	_build_loading_layer()
	_build_auth_layer()
	LanSession.status_changed.connect(_on_lan_status)
	LanSession.session_ready.connect(_on_lan_ready)


func _sync_reference_scale() -> void:
	if _reference_root == null:
		return
	_reference_root.scale = Vector2(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y)


func configure(has_profile: bool) -> void:
	_has_profile = has_profile
	if _local_button != null:
		_local_button.tooltip_text = "Tiếp tục Local" if _has_profile else "Bắt đầu Local"


func open() -> void:
	visible = true
	get_tree().paused = true
	if _opened_once:
		_show_auth()
		return
	_opened_once = true
	_show_loading()
	_finish_loading.call_deferred()


func _finish_loading() -> void:
	await get_tree().create_timer(1.2, true, false, true).timeout
	if is_inside_tree() and visible:
		_show_auth()


func _show_loading() -> void:
	_loading_layer.visible = true
	_auth_layer.visible = false


func _show_auth() -> void:
	_loading_layer.visible = false
	_auth_layer.visible = true


func _build_loading_layer() -> void:
	_loading_layer = _full_layer("Loading")
	_reference_root.add_child(_loading_layer)
	_add_cover_texture(_loading_layer, LOADING_BACKGROUND)
	_add_texture(_loading_layer, TITLE_LOGO, Rect2(76, 140, 568, 298))

	var progress_background := ColorRect.new()
	progress_background.color = Color(0.035, 0.035, 0.035, 1.0)
	progress_background.position = Vector2(122, 1389)
	progress_background.size = Vector2(476, 17)
	_loading_layer.add_child(progress_background)

	var progress_fill := ColorRect.new()
	progress_fill.color = Color(0.91, 0.91, 0.88, 1.0)
	progress_fill.position = Vector2(3, 3)
	progress_fill.size = Vector2(322, 11)
	progress_background.add_child(progress_fill)

	_add_label(_loading_layer, "Phase 3/3", Rect2(304, 1414, 160, 34), 20, Color.WHITE)
	_add_label(_loading_layer, "Loading scene assets... (68%)", Rect2(218, 1447, 330, 34), 19, Color(0.88, 0.86, 0.84))


func _build_auth_layer() -> void:
	_auth_layer = _full_layer("Authentication")
	_auth_layer.visible = false
	_reference_root.add_child(_auth_layer)
	_add_cover_texture(_auth_layer, LOGIN_BACKGROUND)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.07, 0.20)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_auth_layer.add_child(shade)

	_add_texture(_auth_layer, AGE_NOTICE, Rect2(386, 22, 146, 64))
	_add_nine_patch(_auth_layer, LOGIN_PANEL, Rect2(22, 348, 676, 940), 8)
	_add_panel_fill(_auth_layer, Rect2(22, 348, 676, 940), 8, Color(0.105, 0.11, 0.16, 0.96))
	_add_texture(_auth_layer, TITLE_LOGO, Rect2(82, 232, 556, 292))
	_add_nine_patch(_auth_layer, LOGIN_PANEL, Rect2(108, 515, 504, 650), 8)
	_add_panel_fill(_auth_layer, Rect2(108, 515, 504, 650), 8, Color(0.29, 0.27, 0.31, 1.0))

	_login_tab_background = _add_nine_patch(_auth_layer, LOGIN_TAB_INACTIVE, Rect2(132, 542, 223, 58), 8)
	_register_tab_background = _add_nine_patch(_auth_layer, LOGIN_TAB_ACTIVE, Rect2(365, 542, 223, 58), 8)
	_add_flat_button(_auth_layer, "Đăng nhập", Rect2(132, 542, 223, 58), _show_login, 29)
	_add_flat_button(_auth_layer, "Đăng ký", Rect2(365, 542, 223, 58), _show_register, 29)

	_add_label(_auth_layer, "Asia26", Rect2(240, 614, 240, 42), 30, UiTheme.C_GOLD)

	_username_input = _add_input(_auth_layer, Rect2(151, 659, 416, 54), "tên tài khoản")
	_password_input = _add_input(_auth_layer, Rect2(151, 729, 334, 54), "Mật Khẩu")
	_password_input.secret = true
	_add_textured_button(_auth_layer, BUTTON_ORANGE, "Hiện", Rect2(505, 729, 63, 54), _toggle_password, 24)

	_primary_button = _add_textured_button(_auth_layer, BUTTON_BLUE, "Đăng ký", Rect2(252, 867, 216, 59), _choose_local, 30)
	_hint_label = _add_label(
		_auth_layer,
		"Hãy nhớ tên người dùng và mật khẩu\ncủa bạn.",
		Rect2(130, 944, 460, 72),
		25,
		UiTheme.C_GOLD
	)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_line = _add_texture(_auth_layer, LOGIN_LINE, Rect2(204, 982, 312, 5))
	_hint_line.visible = false

	_local_button = _add_textured_button(
		_auth_layer,
		BUTTON_ORANGE,
		"Đăng nhập nhanh",
		Rect2(252, 1057, 216, 59),
		_choose_local,
		25
	)
	_local_button.tooltip_text = "Tiếp tục Local" if _has_profile else "Bắt đầu Local"

	_add_flat_panel(_auth_layer, Rect2(372, 1301, 288, 78), Color(0.12, 0.12, 0.16, 0.96), Color(0.25, 0.25, 0.29))
	_add_flat_button(_auth_layer, "Xem thêm", Rect2(372, 1301, 288, 78), _toggle_network_panel, 27)
	_add_label(_auth_layer, "4.3.6-1387", Rect2(270, 1442, 180, 30), 17, Color(0.62, 0.61, 0.67))

	_build_network_panel()
	_refresh_auth_tabs()


func _build_network_panel() -> void:
	_network_panel = Control.new()
	_network_panel.name = "LanOptions"
	_network_panel.position = Vector2(82, 1118)
	_network_panel.size = Vector2(556, 318)
	_network_panel.visible = false
	_auth_layer.add_child(_network_panel)
	_add_nine_patch(_network_panel, LOGIN_PANEL, Rect2(0, 0, 556, 318), 8)

	var title := _add_label(_network_panel, "KẾT NỐI LOCAL / WI-FI", Rect2(30, 20, 496, 38), 25, UiTheme.C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_address_input = _add_input(_network_panel, Rect2(30, 72, 318, 58), "IP máy chủ")
	_address_input.text = "127.0.0.1"
	_address_input.max_length = 128
	_join_button = _add_textured_button(_network_panel, BUTTON_BLUE, "Join", Rect2(360, 72, 166, 58), _choose_join, 24)
	_host_button = _add_textured_button(_network_panel, BUTTON_ORANGE, "Host Wi-Fi", Rect2(30, 145, 236, 58), _choose_host, 23)
	_add_textured_button(_network_panel, BUTTON_ORANGE, "Đóng", Rect2(290, 145, 236, 58), _toggle_network_panel, 23)

	_status_label = _add_label(
		_network_panel,
		"LAN: host quản lý zone, quái, HP và hồi sinh",
		Rect2(30, 216, 496, 34),
		18,
		UiTheme.C_MUTED
	)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_addresses_label = _add_label(
		_network_panel,
		"UDP %d • IP: %s" % [LanSession.PORT, LanSession.local_addresses_text()],
		Rect2(30, 260, 496, 34),
		17,
		Color(0.62, 0.72, 0.82)
	)
	_addresses_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_addresses_label.clip_text = true
	_addresses_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _full_layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.position = Vector2.ZERO
	layer.size = REFERENCE_SIZE
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	return layer


func _add_cover_texture(parent: Control, texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _add_texture(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _add_nine_patch(parent: Control, texture: Texture2D, rect: Rect2, margin: int) -> NinePatchRect:
	var node := NinePatchRect.new()
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		node.set_patch_margin(side, margin)
	parent.add_child(node)
	return node


func _add_flat_panel(parent: Control, rect: Rect2, background: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4)
	style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _add_panel_fill(parent: Control, rect: Rect2, margin: int, color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.color = color
	fill.position = rect.position + Vector2(margin, margin)
	fill.size = rect.size - Vector2(margin * 2, margin * 2)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)
	return fill


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
	input.add_theme_color_override("font_placeholder_color", Color(0.72, 0.71, 0.72))
	input.add_theme_color_override("font_color", UiTheme.C_TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = INPUT_COLOR
	style.border_color = Color(0.02, 0.02, 0.02)
	style.set_border_width_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.anti_aliasing = false
	input.add_theme_stylebox_override("normal", style)
	input.add_theme_stylebox_override("focus", style)
	parent.add_child(input)
	return input


func _add_textured_button(
	parent: Control,
	texture: Texture2D,
	text: String,
	rect: Rect2,
	callback: Callable,
	font_size: int
) -> Button:
	_add_nine_patch(parent, texture, rect, 8)
	return _add_flat_button(parent, text, rect, callback, font_size)


func _add_flat_button(
	parent: Control,
	text: String,
	rect: Rect2,
	callback: Callable,
	font_size: int
) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", UiTheme.C_TEXT)
	button.add_theme_color_override("font_hover_color", UiTheme.C_GOLD)
	button.add_theme_color_override("font_pressed_color", UiTheme.C_GOLD)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_register() -> void:
	_is_login = false
	_refresh_auth_tabs()


func _show_login() -> void:
	_is_login = true
	_refresh_auth_tabs()


func _refresh_auth_tabs() -> void:
	if _login_tab_background == null:
		return
	_login_tab_background.texture = LOGIN_TAB_ACTIVE if _is_login else LOGIN_TAB_INACTIVE
	_register_tab_background.texture = LOGIN_TAB_INACTIVE if _is_login else LOGIN_TAB_ACTIVE
	_primary_button.text = "Đăng nhập" if _is_login else "Đăng ký"
	_hint_label.text = "Quên mật khẩu" if _is_login else "Hãy nhớ tên người dùng và mật khẩu\ncủa bạn."
	_hint_line.visible = _is_login


func _toggle_password() -> void:
	_password_input.secret = not _password_input.secret


func _toggle_network_panel() -> void:
	_network_panel.visible = not _network_panel.visible


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
		_join_button.text = "Đang kết nối..." if connecting else "Join"
	if _address_input:
		_address_input.editable = not connecting
