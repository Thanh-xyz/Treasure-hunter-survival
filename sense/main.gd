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


func _ready() -> void:
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
	if not loaded:
		mobile_hud.show_toast("Welcome, Treasure Seeker! Check your quests.", UiTheme.C_GOLD)

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


## Loot left on the ground belongs to the old zone: auto-collect it.
func _on_transition_started(_from: String, _to: String) -> void:
	for child in get_children():
		if child is GameItem:
			var item := child as GameItem
			if item._is_collected:
				continue
			if item.pickup_mode == GameItem.PickupMode.INTERACT:
				item.queue_free()
			else:
				item._collect(player)
