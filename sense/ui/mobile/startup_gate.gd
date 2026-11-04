class_name StartupGate
extends Control
## Clean-room boot gate inspired by the captured portrait flow. Local and the
## direct-IP LAN foundation are real; networked combat remains explicitly scoped out.

signal local_selected
signal mode_selected(mode: String)

var _local_button: Button
var _host_button: Button
var _join_button: Button
var _address_input: LineEdit
var _status_label: Label
var _addresses_label: Label
var _has_profile := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_build_background()
	_build_content()
	LanSession.status_changed.connect(_on_lan_status)
	LanSession.session_ready.connect(_on_lan_ready)


func configure(has_profile: bool) -> void:
	_has_profile = has_profile
	if _local_button != null:
		_local_button.text = "Tiếp tục Local" if _has_profile else "Bắt đầu Local"


func open() -> void:
	visible = true
	get_tree().paused = true


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.055, 0.085, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Blocky silhouettes add depth without copying the source artwork.
	var bands := [
		[0.0, 0.20, 1.0, 0.12, Color(0.08, 0.10, 0.15, 1.0)],
		[0.0, 0.42, 1.0, 0.18, Color(0.055, 0.075, 0.11, 1.0)],
		[0.0, 0.74, 1.0, 0.26, Color(0.025, 0.035, 0.055, 1.0)],
	]
	for data in bands:
		var band := ColorRect.new()
		band.color = data[4]
		band.anchor_left = data[0]
		band.anchor_top = data[1]
		band.anchor_right = data[2]
		band.anchor_bottom = data[1] + data[3]
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(band)

	for i in range(18):
		var ember := ColorRect.new()
		ember.color = UiTheme.C_GOLD.darkened(0.22)
		ember.position = Vector2(24 + ((i * 83) % 650), 90 + ((i * 137) % 1280))
		ember.size = Vector2(4 + (i % 3) * 2, 4 + ((i + 1) % 3) * 2)
		ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(ember)


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := UiTheme.label("TREASURE\nHUNTER", 148, Color(0.92, 0.92, 0.88))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -42)
	root.add_child(title)

	var subtitle := UiTheme.label("SURVIVAL - LOCAL BUILD", 30, UiTheme.C_GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 70)
	root.add_child(spacer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 680)
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.25, 0.23, 0.27, 0.98), Color(0.67, 0.66, 0.63), 4))
	root.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 24)
	panel_margin.add_theme_constant_override("margin_right", 24)
	panel_margin.add_theme_constant_override("margin_top", 24)
	panel_margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(panel_margin)

	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 18)
	panel_margin.add_child(choices)

	var heading := UiTheme.label("CHỌN MÁY CHỦ CỦA BẠN", 34, UiTheme.C_GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choices.add_child(heading)

	choices.add_child(_separator())
	_local_button = UiTheme.button("Tiếp tục Local" if _has_profile else "Bắt đầu Local", _choose_local, Vector2(0, 94))
	_local_button.add_theme_font_size_override("font_size", 32)
	_local_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var first_row := HBoxContainer.new()
	first_row.add_theme_constant_override("separation", 12)
	first_row.add_child(_local_button)
	_host_button = UiTheme.button("Host Wi-Fi", _choose_host, Vector2(0, 94))
	_host_button.add_theme_font_size_override("font_size", 32)
	_host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	first_row.add_child(_host_button)
	choices.add_child(first_row)

	var second_row := HBoxContainer.new()
	second_row.add_theme_constant_override("separation", 12)
	_address_input = LineEdit.new()
	_address_input.placeholder_text = "IP máy chủ"
	_address_input.text = "127.0.0.1"
	_address_input.max_length = 128
	_address_input.custom_minimum_size = Vector2(0, 88)
	_address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address_input.add_theme_font_size_override("font_size", 30)
	second_row.add_child(_address_input)
	_join_button = UiTheme.button("Join Wi-Fi", _choose_join, Vector2(0, 88))
	_join_button.add_theme_font_size_override("font_size", 30)
	_join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	second_row.add_child(_join_button)
	choices.add_child(second_row)

	_status_label = UiTheme.label("LAN: host quản lý zone, quái, HP và hồi sinh", 22, UiTheme.C_MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choices.add_child(_status_label)
	_addresses_label = UiTheme.label("UDP %d • IP: %s" % [LanSession.PORT, LanSession.local_addresses_text()], 20, Color(0.62, 0.72, 0.82))
	_addresses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_addresses_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choices.add_child(_addresses_label)

	var footer := UiTheme.label("Dữ liệu được lưu trên thiết bị", 20, Color(0.48, 0.52, 0.58))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)


func _separator() -> HSeparator:
	var line := HSeparator.new()
	line.add_theme_color_override("separator", Color(0.12, 0.11, 0.13))
	line.add_theme_constant_override("separation", 3)
	return line


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
		_join_button.text = "Đang kết nối..." if connecting else "Join Wi-Fi"
	if _address_input:
		_address_input.editable = not connecting
