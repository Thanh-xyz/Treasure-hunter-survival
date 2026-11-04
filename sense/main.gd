extends Node2D
## Main scene - Entry point and orchestrator
##
## Responsibilities:
##   - Register all zones with SceneTransitionService (from GameContent.ZONES)
##   - Load the local profile (SaveService) or start a new game
##   - Setup legacy HUD + portrait MobileHUD
##   - Clean up loose loot when changing zones
##
## Legacy boot-time self tests now live in res://tests/ (run headless).

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var mobile_hud: MobileHUD
var startup_gate: StartupGate
var _lan_zone_transitioning := false
var _lan_client_active := false


func _ready() -> void:
	LanSession.bind(self, player)
	LanSession.session_ready.connect(_on_lan_ready)
	LanSession.host_zone_requested.connect(_on_host_zone_requested)
	LanSession.session_ended.connect(_on_lan_session_ended)
	# Initialize camera service with player
	CameraService.use_player_camera(player)

	# Initialize scene transition service
	SceneTransitionService.initialize(self, player)
	for zone_id in GameContent.ZONES:
		SceneTransitionService.register_map(zone_id, GameContent.ZONES[zone_id]["scene"])
	SceneTransitionService.transition_started.connect(_on_transition_started)
	SceneTransitionService.transition_completed.connect(func(_m: String) -> void: SaveService.save_game())

	# Profile: continue or start fresh
	SaveService.enabled = false
	var loaded := SaveService.has_save() and SaveService.load_game()
	if not loaded:
		GameState.reset_profile()
		QuestService.reset()
		player.give_starter_items()
		player.refresh_profile_stats()
		player.stats.reset()
		GameState.collection_changed.emit()
	SaveService.enabled = true

	# HUD before the first map so zone/quest events are displayed
	_setup_hud()
	mobile_hud = MobileHUD.new()
	mobile_hud.name = "MobileHUD"
	hud.add_child(mobile_hud)
	mobile_hud.bind_player(player, hud)

	# Load initial map (last safe zone from the save, never mid-dungeon)
	var start_zone := "town"
	if loaded and GameContent.ZONES.has(GameState.current_zone) and GameState.current_zone != "dungeon":
		start_zone = GameState.current_zone
	SceneTransitionService.load_initial_map(start_zone)

	# Keep the world paused behind an honest local/LAN mode gate. Only local play
	# is enabled until the Wi-Fi milestone has a real lobby and transport layer.
	startup_gate = StartupGate.new()
	startup_gate.name = "StartupGate"
	hud.add_child(startup_gate)
	startup_gate.configure(loaded)
	startup_gate.mode_selected.connect(_on_mode_selected)
	startup_gate.open()

	# Connect pause event
	GameEvent.request_ui_pause.connect(_on_request_ui_pause)


func _setup_hud() -> void:
	if hud == null:
		return

	if player.has_method("get") and player.get("stats") != null:
		hud.setup(player.stats)

	hud.setup_minimap(player, self)


func _on_request_ui_pause(is_open: bool) -> void:
	get_tree().paused = is_open


func _on_mode_selected(mode: String) -> void:
	if mode == "host":
		mobile_hud.show_toast("Host Wi-Fi UDP %d" % LanSession.PORT, UiTheme.C_GOOD)
	elif mode == "client":
		mobile_hud.show_toast("Đã kết nối Host Wi-Fi", UiTheme.C_GOOD)


func _on_lan_ready(role: String, host_zone: String) -> void:
	if role == "client" and GameContent.ZONES.has(host_zone):
		_lan_client_active = true
		# Establish a guaranteed offline restore point before client-only zone and
		# combat simulation starts, including for a brand-new profile.
		SaveService.save_game()
		SaveService.enabled = false
		_on_host_zone_requested.call_deferred(host_zone)


func _on_host_zone_requested(zone_id: String) -> void:
	if LanSession.mode != LanSession.Mode.CLIENT or not GameContent.ZONES.has(zone_id) or _lan_zone_transitioning:
		return
	if zone_id == SceneTransitionService.get_active_map():
		return
	_lan_zone_transitioning = true
	await SceneTransitionService.go_to(zone_id)
	_lan_zone_transitioning = false


func _on_lan_session_ended(reason: String) -> void:
	if startup_gate == null:
		return
	if _lan_client_active:
		_lan_client_active = false
		var earned_rewards := LanSession.take_earned_rewards()
		SaveService.enabled = true
		SaveService.load_game()
		LanSession.restore_earned_rewards(earned_rewards)
		SaveService.save_game()
	mobile_hud.show_toast(reason, UiTheme.C_BAD)
	startup_gate.open()


## Loot left on the ground belongs to the old zone: auto-collect it.
func _on_transition_started(_from: String, _to: String) -> void:
	for child in get_children():
		if child is GameItem:
			var item := child as GameItem
			if item.network_replica:
				continue
			if item._is_collected:
				continue
			if item.pickup_mode == GameItem.PickupMode.INTERACT:
				item.queue_free()
			else:
				item._collect(player)
