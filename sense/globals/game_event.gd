extends Node
signal request_ui_pause(is_open: bool)
signal item_crafted(recipe_id: String, tier: int)
signal gem_socketed(equip_slot: String, stone_id: String)
signal gem_unsocketed(equip_slot: String, stone_id: String)
signal gems_fused(source_id: String, result_id: String)
signal pet_hatched(pet_key: String, duplicate: bool, diamonds: int)
signal mount_evolved(mount_id: String, form: int)
signal appearance_changed(outfit: String)
signal equipment_upgraded(slot_type: String, item_id: String, level: int, cost: int)
signal buff_applied(buff_id: String)
signal buff_expired(buff_id: String)
signal skill_used(skill_id: String)
signal shop_opened
signal shop_closed

# --- Survival RPG domain events ---------------------------------------------
signal enemy_killed(monster_id: String, position: Vector2, is_boss: bool)
signal resource_gathered(item_id: String, quantity: int)
signal ground_dug(item_id: String, quantity: int)
signal zone_entered(zone_id: String)
signal building_built(building_id: String, level: int)
signal player_died
signal player_respawned
signal boss_spawned(boss_id: String, boss: Node)
signal boss_state_changed(boss_id: String, hp: int, max_hp: int, phase: int)
signal boss_defeated(boss_id: String)
signal world_boss_timer(zone_id: String, seconds_left: float)
signal toast(text: String, color: Color)
signal open_menu(menu_id: String)

var is_shop_open: bool = false
