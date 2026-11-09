extends Node
## Plan phase C renders: rider on an evolved mount with a pet, mid-stomp, plus the Pet and
## Mount menu tabs. Run with a display (xvfb) and review the PNGs.

const RIDE_PATH := "/tmp/emberfield-companions-ride.png"
const STOMP_PATH := "/tmp/emberfield-companions-stomp.png"
const PET_MENU_PATH := "/tmp/emberfield-companions-pet-menu.png"
const MOUNT_MENU_PATH := "/tmp/emberfield-companions-mount-menu.png"
const MOUNT_STONES_PATH := "/tmp/emberfield-companions-mount-stones.png"


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.8).timeout
	var inv := GameState.get_inventory()
	inv.diamonds = 500
	inv.gold = 5000
	GameState.pets["dusk_owl:epic"] = GameState._new_pet_record()
	GameState.pets["ember_drake:legendary"] = GameState._new_pet_record()
	GameState.pets["ember_drake:legendary"]["level"] = 6
	GameState.equip_pet("ember_drake:legendary")
	GameState.unlock_mount("dust_pony")
	GameState.unlock_mount("ember_lion")
	GameState.mounts["ember_lion"]["form"] = 2
	GameState.mounts["ember_lion"]["level"] = 4
	GameState.select_mount("ember_lion")
	GameState.set_mounted(true)
	await get_tree().create_timer(0.8).timeout
	_save(RIDE_PATH)
	var player := GameState.get_player()
	player.play_mounted_stomp()
	await get_tree().create_timer(0.16).timeout
	_save(STOMP_PATH)
	await get_tree().create_timer(0.6).timeout
	main.mobile_hud.open_menu("pet")
	await get_tree().create_timer(0.3).timeout
	_save(PET_MENU_PATH)
	main.mobile_hud.open_menu("mount")
	await get_tree().create_timer(0.3).timeout
	_save(MOUNT_MENU_PATH)
	inv.add_item(ItemDatabase.get_item("stone_fire_2"), 3)
	inv.add_item(ItemDatabase.get_item("stone_guard_1"), 6)
	GameState.socket_companion_gem("mount", "ember_lion", 0, inv.inventory_slots.find(inv.inventory_slots.filter(func(sl: Dictionary) -> bool: return sl.item != null and sl.item.id == "stone_fire_2")[0]))
	main.mobile_hud.game_menu._open_companion_stones("mount", "ember_lion")
	await get_tree().create_timer(0.3).timeout
	_save(MOUNT_STONES_PATH)
	get_tree().quit()


func _save(path: String) -> void:
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("[RENDER] Saved %s (%s)" % [path, error_string(err)])
