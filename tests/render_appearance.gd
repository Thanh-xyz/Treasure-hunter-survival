extends Node
## Owner request 2026-11-09 renders: gear rails on both sides, outfits per armor, portrait menu,
## gear slot panel, and an outfit line-up.

const PATHS := {
	"hud": "/tmp/emberfield-appearance-hud.png",
	"menu": "/tmp/emberfield-appearance-portrait-menu.png",
	"panel": "/tmp/emberfield-appearance-gear-panel.png",
	"lineup": "/tmp/emberfield-appearance-lineup.png",
}


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.8).timeout
	var player = GameState.get_player()
	var inv: InventoryData = player.inventory
	for id: String in ["ironbark_helm", "wayfarer_boots", "ironbark_pack", "emberforged_blade"]:
		inv.add_item(ItemDatabase.get_item(id), 1)
		inv.equip_item(_find(inv, id))
	var armor := ItemDatabase.get_item_copy("ironbark_plate")
	armor.rarity = ItemData.ItemRarity.LEGENDARY
	inv.add_item(armor, 1)
	inv.equip_item(_find(inv, "ironbark_plate"))
	GameState.unlock_mount("dust_pony")
	await get_tree().create_timer(0.5).timeout
	_save(PATHS["hud"])
	main.mobile_hud._toggle_portrait_menu()
	await get_tree().create_timer(0.2).timeout
	_save(PATHS["menu"])
	main.mobile_hud._toggle_portrait_menu()
	inv.add_item(ItemDatabase.get_item("ember_harness"), 1)
	inv.add_item(ItemDatabase.get_item("wayfarer_coat"), 1)
	main.mobile_hud._on_gear_slot("armor")
	await get_tree().create_timer(0.2).timeout
	_save(PATHS["panel"])
	main.mobile_hud.get_node("GearSlotPanel").queue_free()
	# Outfit line-up: one copy of the character per outfit, side by side
	var root := CanvasLayer.new()
	root.layer = 100
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.35, 0.25)
	bg.size = Vector2(720, 300)
	bg.position = Vector2(0, 1250)
	root.add_child(bg)
	var x := 40.0
	for outfit in PlayerAppearance.outfits():
		var s := AnimatedSprite2D.new()
		s.sprite_frames = PlayerAppearance.frames(outfit)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(3, 3)
		s.position = Vector2(x, 1320 if int(x) % 100 < 50 else 1400)
		s.play("idle_down")
		root.add_child(s)
		x += 52.0
	await get_tree().create_timer(0.3).timeout
	_save(PATHS["lineup"])
	get_tree().quit()


func _find(inv: InventoryData, id: String) -> int:
	for i in range(inv.inventory_slots.size()):
		var it: ItemData = inv.inventory_slots[i].get("item")
		if it != null and it.id == id:
			return i
	return -1


func _save(path: String) -> void:
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("[RENDER] Saved %s (%s)" % [path, error_string(err)])
