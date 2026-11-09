extends Node
## Plan phase E renders: world bosses with telegraphs and the phase boss bar, the summoned
## bosses lined up, and the World Map tab (schedule + boss cards).

const PATHS := {
	"infernal": "/tmp/emberfield-boss-infernal.png",
	"leviathan": "/tmp/emberfield-boss-leviathan.png",
	"summoned": "/tmp/emberfield-boss-summoned.png",
	"map_tab": "/tmp/emberfield-boss-map-tab.png",
}


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main := preload("res://sense/Main.tscn").instantiate()
	add_child(main)
	for _i in range(5):
		await get_tree().process_frame
	main.startup_gate._choose_local()
	await get_tree().create_timer(0.6).timeout
	await _world("cinderwaste", "infernal_dragon", "line", PATHS["infernal"])
	await _world("frostvale", "frost_leviathan", "rain", PATHS["leviathan"])
	await _summoned()
	var inv := GameState.get_inventory()
	inv.add_item(ItemDatabase.get_item("card_meadow_guardian"), 1)
	inv.add_item(ItemDatabase.get_item("fragment_ash"), 15)
	inv.add_item(ItemDatabase.get_item("fragment_snow"), 4)
	main.mobile_hud.open_menu("map")
	await get_tree().create_timer(0.3).timeout
	_save(PATHS["map_tab"])
	get_tree().quit()


func _world(zone_id: String, boss_id: String, ability: String, path: String) -> void:
	SceneTransitionService.go_to(zone_id)
	await get_tree().create_timer(1.2).timeout
	for m in get_tree().get_nodes_in_group("monster"):
		m.queue_free()
	var player := GameState.get_player() as Node2D
	var boss := Monster.create(boss_id) as Boss
	_find_map(get_tree().root).add_child(boss)
	boss.global_position = player.global_position + Vector2(0, -150)
	boss.home = boss.global_position
	await get_tree().physics_frame
	boss.target = player
	boss.apply_hit(int(boss.max_hp * 0.4), Vector2.ZERO)
	boss.set_physics_process(false)
	match ability:
		"line": boss._special_line()
		"rain": boss._special_rain()
	await get_tree().create_timer(0.45).timeout
	get_tree().paused = false
	_save(path)
	boss.queue_free()
	for t in Combat.world_root(get_tree()).get_children():
		if t is Telegraph:
			t.queue_free()


func _summoned() -> void:
	var player := GameState.get_player() as Node2D
	var map := _find_map(get_tree().root)
	var x := -120.0
	for id: String in ["verdant_treant", "ash_devourer", "frost_abyss_king", "ember_overlord"]:
		var b := Monster.create(id)
		map.add_child(b)
		b.global_position = player.global_position + Vector2(x, -110 if int(x) % 160 == 0 else -40)
		b.set_physics_process(false)
		x += 80.0
	var dragon := Monster.create("ancient_dragon")
	map.add_child(dragon)
	dragon.global_position = player.global_position + Vector2(0, 120)
	dragon.set_physics_process(false)
	await get_tree().create_timer(0.4).timeout
	_save(PATHS["summoned"])
	for m in get_tree().get_nodes_in_group("monster"):
		m.queue_free()


func _save(path: String) -> void:
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("[RENDER] Saved %s (%s)" % [path, error_string(err)])


func _find_map(node: Node) -> FieldMap:
	if node is FieldMap:
		return node
	for child in node.get_children():
		var found := _find_map(child)
		if found != null:
			return found
	return null
