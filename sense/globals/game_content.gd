class_name GameContent
extends RefCounted
## GameContent — static, data-driven content definitions (class constants,
## usable from static functions too; not an autoload).
##
## Every gameplay system reads its numbers from here so balance can be tuned in
## one place. Unverified balance values remain placeholders until runtime capture.
##
## Sections: PLAYER, PETS, MOUNTS, MONSTERS, ZONES, BUILDINGS, QUESTS

# =============================================================================
# PLAYER — the single character (owner decision 2026-11-08: no hero classes,
# no player level or XP). Equipment adds HP/ATK/move speed, socket stones add DEF
# and combat stats, pets and mounts add their passives.
# =============================================================================
const PLAYER_BASE := {"hp": 150, "atk": 12, "def": 0, "spd": 120.0}

# Pets and mounts live in data/companions (CompanionCatalog, plan phase C).

# =============================================================================
# MONSTERS — data for Monster.gd. visual "skeleton" reuses the existing sheet.
# ai: melee | ranged | charger | flyer | stationary_melee
# =============================================================================
const MONSTERS := {
	"slime": {
		"name": "Meadow Slime", "visual": "atlas", "asset_id": "actor.monster.ninja.slime",
		"ai": "flyer", "hp": 30, "dmg": 6, "spd": 38.0, "level": 1,
		"range": 16.0, "aggro": 110.0, "scale": 2.0, "gold": Vector2i(1, 4),
		"loot": [["herb_segment", 30, 1, 2], ["health_potion", 6, 1, 1]],
	},
	"bat": {
		"name": "Dusk Bat", "visual": "atlas", "asset_id": "actor.monster.ninja.blue_bat",
		"ai": "flyer", "hp": 22, "dmg": 5, "spd": 70.0, "level": 2,
		"range": 14.0, "aggro": 140.0, "scale": 2.0, "gold": Vector2i(1, 5),
		"loot": [["spirit_essence", 10, 1, 1], ["herb_segment", 15, 1, 1]],
	},
	"shroom": {
		"name": "Bramble Snake", "visual": "atlas", "asset_id": "actor.monster.ninja.snake",
		"ai": "melee", "hp": 34, "dmg": 7, "spd": 30.0, "level": 3,
		"range": 16.0, "aggro": 150.0, "scale": 2.0, "gold": Vector2i(2, 6),
		"loot": [["venom_gland", 18, 1, 1], ["herb_segment", 25, 1, 2]],
		"on_hit": {"status": "poison", "chance": 0.15, "duration": 3.0, "magnitude": 2},
	},
	"boar": {
		"name": "Bristle Boar", "elite_name": "Alpha Bristle Boar", "visual": "atlas", "asset_id": "actor.monster.ninja.wild_boar",
		"ai": "charger", "hp": 60, "dmg": 12, "spd": 34.0, "level": 4,
		"range": 90.0, "aggro": 140.0, "scale": 2.0, "gold": Vector2i(3, 8),
		"loot": [["ironbark_plate", 3, 1, 1], ["iron_ore", 20, 1, 2]],
	},
	# Stationary guard (save v6 replaces the retired "turtle" row). Art: Ninja Adventure (CC0).
	"mossback": {
		"name": "Mosscap Guardian", "elite_name": "Ancient Mosscap", "visual": "atlas", "asset_id": "actor.monster.ninja.mushroom",
		"ai": "stationary_melee", "hp": 90, "dmg": 14, "spd": 0.0, "level": 1,
		"range": 60.0, "aggro": 160.0, "scale": 2.0, "gold": Vector2i(3, 6),
		"loot": [["herb_segment", 25, 1, 2]],
		"attack_interval": 1.2, "attack_duration": 0.5, "death_duration": 0.6, "knockback_immune": true,
	},
	"skeleton_grunt": {
		"name": "Bone Grunt", "visual": "atlas", "asset_id": "actor.monster.ninja.skull",
		"ai": "melee", "hp": 110, "dmg": 16, "spd": 46.0, "level": 17, "elite_name": "Cinder Bone Knight",
		"range": 24.0, "aggro": 150.0, "scale": 2.0, "gold": Vector2i(4, 12),
		"loot": [["bone", 60, 1, 3], ["fire_shard", 12, 1, 1], ["ashwood_blade", 3, 1, 1], ["stone_guard_1", 4, 1, 1]],
	},
	"skeleton_archer": {
		"name": "Bone Archer", "visual": "atlas", "asset_id": "actor.monster.ninja.skull_blue",
		"ai": "ranged", "hp": 85, "dmg": 15, "spd": 40.0, "level": 19,
		"on_hit": {"status": "burn", "chance": 0.2, "duration": 3.0, "magnitude": 2},
		"range": 140.0, "aggro": 170.0, "scale": 2.0, "gold": Vector2i(4, 12),
		"projectile": "bolt_frost",
		"loot": [["bone", 50, 1, 2], ["frost_shard", 14, 1, 1], ["ember_dirk", 3, 1, 1], ["stone_critical_1", 4, 1, 1]],
	},
	"frost_slime": {
		"name": "Frost Wisp", "visual": "atlas", "asset_id": "actor.monster.ninja.flam2",
		"ai": "melee", "hp": 170, "dmg": 18, "spd": 44.0, "level": 32,
		"on_hit": {"status": "slow", "chance": 0.4, "duration": 2.0, "magnitude": 30},
		"range": 16.0, "aggro": 120.0, "scale": 2.0, "gold": Vector2i(4, 10),
		"loot": [["frost_shard", 25, 1, 2], ["stone_ice_1", 3, 1, 1]],
	},
	"magma_slime": {
		"name": "Magma Flame", "visual": "atlas", "asset_id": "actor.monster.ninja.flam",
		"ai": "melee", "hp": 130, "dmg": 15, "spd": 40.0, "level": 18,
		"on_hit": {"status": "burn", "chance": 0.35, "duration": 3.0, "magnitude": 3},
		"range": 16.0, "aggro": 120.0, "scale": 2.0, "gold": Vector2i(6, 14),
		"loot": [["fire_shard", 25, 1, 2], ["inferno_shard", 5, 1, 1]],
	},
	# Ash: Ash Hound (sheet 05 §4.2). Art: tinted CC0 hyena placeholder (NEEDS_ASSET: no hound).
	"ash_hound": {
		"name": "Ash Hound", "elite_name": "Infernal Hound", "visual": "atlas", "asset_id": "actor.animal.ninja.hyena",
		"tint": Color(0.62, 0.55, 0.52), "art_status": "NEEDS_ASSET",
		"ai": "charger", "hp": 90, "dmg": 18, "spd": 70.0, "level": 20,
		"range": 110.0, "aggro": 170.0, "scale": 2.0, "gold": Vector2i(6, 14),
		"loot": [["fire_shard", 20, 1, 2], ["bone", 30, 1, 2]],
		"on_hit": {"status": "burn", "chance": 0.25, "duration": 2.0, "magnitude": 2},
	},
	# Snow (sheet 05 §4.3). Placeholders are CC0 Ninja sprites, flagged NEEDS_ASSET where the
	# species does not match.
	"snow_wolf": {
		"name": "Whitefang Wolf", "elite_name": "Frostfang Alpha", "visual": "atlas", "asset_id": "actor.animal.ninja.dog_white",
		"tint": Color(0.9, 0.95, 1.1), "art_status": "NEEDS_ASSET",
		"ai": "melee", "hp": 150, "dmg": 22, "spd": 85.0, "level": 33,
		"range": 18.0, "aggro": 190.0, "scale": 2.0, "gold": Vector2i(8, 16),
		"loot": [["frost_shard", 25, 1, 2], ["monster_bone", 15, 1, 1]],
		"on_hit": {"status": "slow", "chance": 0.2, "duration": 2.0, "magnitude": 20},
	},
	"snow_bear": {
		"name": "Glacier Bear", "elite_name": "Ancient Glacier Bear", "visual": "atlas", "asset_id": "actor.monster.ninja.panda",
		"art_status": "NEEDS_ASSET",
		"ai": "melee", "hp": 380, "dmg": 30, "spd": 30.0, "level": 36,
		"range": 22.0, "aggro": 150.0, "scale": 2.5, "gold": Vector2i(12, 24),
		"loot": [["frost_shard", 30, 1, 3], ["blizzard_shard", 8, 1, 1]],
		"on_hit": {"status": "freeze", "chance": 0.25, "duration": 1.0, "magnitude": 70},
		"slam": {"radius": 46.0, "warn": 1.0, "mult": 1.6, "cooldown": 5.0, "trigger_range": 44.0},
	},
	"ice_shaman": {
		"name": "Frost Shaman", "visual": "atlas", "asset_id": "actor.monster.ninja.spirit",
		"tint": Color(0.75, 0.9, 1.2),
		"ai": "ranged", "hp": 140, "dmg": 17, "spd": 38.0, "level": 34,
		"range": 150.0, "aggro": 180.0, "scale": 2.0, "gold": Vector2i(10, 20),
		"projectile": "bolt_frost",
		"loot": [["frost_shard", 25, 1, 2], ["spirit_essence", 15, 1, 1]],
		"on_hit": {"status": "slow", "chance": 0.5, "duration": 2.0, "magnitude": 35},
		"support": {"radius": 90.0, "interval": 5.0, "damage_taken_mult": 0.8, "duration": 3.0},
	},
	# ------------------------------------------------------------ mini-bosses (sheet 05 §7)
	# Random field mini-bosses: scaled, tinted CC0 sprites until dedicated art exists.
	"mini_boss_slime_monarch": {
		"name": "Slime Monarch", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.slime",
		"tint": Color(1.2, 1.1, 0.6),
		"ai": "melee", "hp": 900, "dmg": 18, "spd": 30.0, "level": 12,
		"range": 26.0, "aggro": 200.0, "scale": 4.0, "gold": Vector2i(60, 120), "bonus_table": "mini_boss_meadow",
		"loot": [["stone_guard_1", 100, 2, 3], ["egg_forest", 20, 1, 1]],
		"slam": {"radius": 48.0, "warn": 0.9, "mult": 1.4, "cooldown": 4.5, "trigger_range": 46.0},
		"summon": {"id": "slime", "count": 3, "at_hp": 0.5}, "knockback_immune": true,
	},
	"mini_boss_rootfang": {
		"name": "Rootfang", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.reptile2",
		"art_status": "NEEDS_ASSET",
		"ai": "charger", "hp": 1100, "dmg": 22, "spd": 40.0, "level": 14,
		"range": 130.0, "aggro": 220.0, "scale": 3.5, "gold": Vector2i(70, 130), "bonus_table": "mini_boss_meadow",
		"loot": [["stone_regeneration_1", 100, 1, 2], ["egg_forest", 20, 1, 1]],
		"on_hit": {"status": "slow", "chance": 0.4, "duration": 2.0, "magnitude": 30},
		"slam": {"radius": 40.0, "warn": 1.0, "mult": 1.2, "cooldown": 6.0, "trigger_range": 40.0}, "knockback_immune": true,
	},
	"mini_boss_cinder_warlord": {
		"name": "Cinder Warlord", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.skull",
		"tint": Color(1.3, 0.7, 0.5),
		"ai": "melee", "hp": 1800, "dmg": 28, "spd": 38.0, "level": 27,
		"range": 26.0, "aggro": 220.0, "scale": 3.5, "gold": Vector2i(120, 220), "bonus_table": "mini_boss_ash",
		"loot": [["stone_fire_2", 100, 1, 2], ["egg_ash", 20, 1, 1]],
		"on_hit": {"status": "burn", "chance": 0.5, "duration": 3.0, "magnitude": 5},
		"slam": {"radius": 52.0, "warn": 1.0, "mult": 1.5, "cooldown": 5.0, "trigger_range": 48.0},
		"summon": {"id": "skeleton_grunt", "count": 2, "at_hp": 0.5}, "knockback_immune": true,
	},
	"mini_boss_ash_tyrant": {
		"name": "Ash Tyrant", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.beast",
		"art_status": "NEEDS_ASSET",
		"ai": "charger", "hp": 1600, "dmg": 32, "spd": 50.0, "level": 29,
		"range": 140.0, "aggro": 230.0, "scale": 3.5, "gold": Vector2i(120, 220), "bonus_table": "mini_boss_ash",
		"loot": [["stone_critical_2", 100, 1, 2], ["egg_ash", 20, 1, 1]],
		"on_hit": {"status": "burn", "chance": 0.6, "duration": 3.0, "magnitude": 6},
		"slam": {"radius": 44.0, "warn": 0.9, "mult": 1.3, "cooldown": 5.5, "trigger_range": 42.0}, "knockback_immune": true,
	},
	"mini_boss_frosthorn": {
		"name": "Frosthorn", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.beast2",
		"tint": Color(0.8, 0.95, 1.3), "art_status": "NEEDS_ASSET",
		"ai": "charger", "hp": 2600, "dmg": 38, "spd": 48.0, "level": 38,
		"range": 140.0, "aggro": 230.0, "scale": 3.5, "gold": Vector2i(180, 300), "bonus_table": "mini_boss_snow",
		"loot": [["stone_ice_2", 100, 1, 2], ["egg_snow", 20, 1, 1]],
		"on_hit": {"status": "slow", "chance": 0.6, "duration": 2.5, "magnitude": 45}, "knockback_immune": true,
	},
	"mini_boss_glacial_colossus": {
		"name": "Glacial Colossus", "mini_boss": true, "visual": "atlas", "asset_id": "actor.monster.ninja.panda",
		"tint": Color(0.8, 0.9, 1.25), "art_status": "NEEDS_ASSET",
		"ai": "ranged", "hp": 4000, "dmg": 40, "spd": 24.0, "level": 44,
		"range": 160.0, "aggro": 220.0, "scale": 4.5, "gold": Vector2i(220, 360), "bonus_table": "mini_boss_snow",
		"projectile": "bolt_frost",
		"loot": [["stone_guard_3", 100, 1, 1], ["egg_snow", 25, 1, 1]],
		"on_hit": {"status": "freeze", "chance": 0.3, "duration": 1.2, "magnitude": 80},
		"slam": {"radius": 60.0, "warn": 1.2, "mult": 1.5, "cooldown": 6.0, "trigger_range": 55.0}, "knockback_immune": true,
	},
	# --------------------------------------------------------------- bosses
	# Boss rewards come from data/bosses/bosses.json reward tables (BossRewards), not "loot".
	# World / summoned bosses (plan phase E): behaviour in data/bosses/bosses.json.
	"infernal_dragon": {
		"name": "Infernal Dragon", "visual": "dragon", "asset_id": "actor.boss.ninja.dragon_green", "hue_shift": -85.0,
		"ai": "boss_flyer", "hp": 4000, "dmg": 30, "spd": 40.0, "level": 30,
		"range": 40.0, "aggro": 320.0, "scale": 2.0, "gold": Vector2i(250, 400), "boss": true,
	},
	"frost_leviathan": {
		"name": "Frost Leviathan", "visual": "dragon", "asset_id": "actor.boss.ninja.dragon_blue",
		"ai": "boss_flyer", "hp": 6500, "dmg": 40, "spd": 38.0, "level": 45,
		"range": 40.0, "aggro": 320.0, "scale": 2.0, "gold": Vector2i(350, 550), "boss": true,
	},
	"verdant_treant": {
		"name": "Verdant Treant", "visual": "atlas", "asset_id": "actor.boss.ninja.giant_bamboo",
		"ai": "boss", "hp": 2500, "dmg": 22, "spd": 26.0, "level": 15,
		"range": 40.0, "aggro": 300.0, "scale": 2.0, "gold": Vector2i(150, 260), "boss": true,
	},
	"ash_devourer": {
		"name": "Ash Devourer", "visual": "atlas", "asset_id": "actor.boss.ninja.squid_red",
		"ai": "boss", "hp": 4500, "dmg": 32, "spd": 30.0, "level": 30,
		"range": 44.0, "aggro": 300.0, "scale": 2.0, "gold": Vector2i(250, 420), "boss": true,
	},
	"frost_abyss_king": {
		"name": "Frost Abyss King", "visual": "atlas", "asset_id": "actor.boss.ninja.giant_blue_samurai",
		"ai": "boss", "hp": 7000, "dmg": 42, "spd": 36.0, "level": 45,
		"range": 40.0, "aggro": 300.0, "scale": 3.0, "gold": Vector2i(350, 600), "boss": true,
	},
	"ancient_dragon": {
		"name": "Ancient Dragon", "visual": "dragon", "asset_id": "actor.boss.ninja.dragon_green",
		"ai": "boss_flyer", "hp": 9000, "dmg": 45, "spd": 40.0, "level": 45,
		"range": 40.0, "aggro": 320.0, "scale": 2.0, "gold": Vector2i(500, 800), "boss": true,
	},
	"ember_overlord": {
		"name": "Ember Overlord", "visual": "atlas", "asset_id": "actor.boss.ninja.tengu_red",
		"ai": "boss", "hp": 12000, "dmg": 50, "spd": 34.0, "level": 48,
		"range": 44.0, "aggro": 320.0, "scale": 2.0, "gold": Vector2i(600, 1000), "boss": true,
	},
	"slime_king": {
		"name": "Mire King", "visual": "atlas", "asset_id": "actor.boss.ninja.giant_slime",
		"ai": "boss_slime", "hp": 1200, "dmg": 18, "spd": 32.0, "level": 5,
		"range": 30.0, "aggro": 220.0, "scale": 2.0, "gold": Vector2i(80, 140), "boss": true,
	},
	"crypt_warden": {
		"name": "Crypt Warden", "visual": "atlas", "asset_id": "actor.boss.ninja.giant_spirit",
		"ai": "boss_skeleton", "hp": 650, "dmg": 16, "spd": 42.0, "level": 5,
		"range": 34.0, "aggro": 300.0, "scale": 2.0, "gold": Vector2i(60, 120), "boss": true,
	},
	"bone_colossus": {
		"name": "Cinder Colossus", "visual": "atlas", "asset_id": "actor.boss.ninja.demon_cyclop",
		"ai": "boss_skeleton", "hp": 1600, "dmg": 24, "spd": 40.0, "level": 10,
		"range": 40.0, "aggro": 260.0, "scale": 2.0, "gold": Vector2i(150, 260), "boss": true,
	},
}

const ELITE_HP_MULT := 2.6
const ELITE_DMG_MULT := 1.5
# Elite chance and caps: data/monsters/spawn_rules.json (SpawnRules).
# Ground-dig tiles and loot: data/world/dig_tiles.json + loot_tables.json (DigTileCatalog, LootTableData).

# =============================================================================
# ZONES — open fields generated by FieldMap
# =============================================================================
const ZONES := {
	"town": {"name": "Hearthmoor Town", "level": 1, "scene": "res://sense/maps/town/town.tscn", "safe": true},
	"homestead": {"name": "Homestead", "level": 1, "scene": "res://sense/maps/homestead/homestead.tscn", "safe": true},
	"greenwood": {
		"name": "Greenwood Meadow", "level": 1, "scene": "res://sense/maps/field/greenwood.tscn",
		"size": Vector2i(60, 90), "ground_tint": Color(1, 1, 1), "seed": 1101,
		"spawns": [["slime", 9], ["bat", 5], ["shroom", 4], ["boar", 3], ["mossback", 1]],
		"region": "meadow", "mini_bosses": ["mini_boss_slime_monarch", "mini_boss_rootfang"],
		"trees": 34, "rocks": 18, "lumber": 9, "dig_spots": 64,
	},
	"cinderwaste": {
		"name": "Cinderwaste", "level": 15, "scene": "res://sense/maps/field/cinderwaste.tscn",
		"size": Vector2i(62, 92), "ground_tint": Color(0.78, 0.7, 0.64), "seed": 3303,
		"spawns": [["magma_slime", 6], ["skeleton_grunt", 6], ["skeleton_archer", 5], ["ash_hound", 4]],
		"region": "ash", "mini_bosses": ["mini_boss_cinder_warlord", "mini_boss_ash_tyrant"],
		"trees": 18, "rocks": 32, "lumber": 6, "dig_spots": 66,
	},
	"frostvale": {
		"name": "Frostvale Ruins", "level": 30, "scene": "res://sense/maps/field/frostvale.tscn",
		"size": Vector2i(64, 96), "ground_tint": Color(0.82, 0.9, 1.15), "seed": 2202,
		"spawns": [["frost_slime", 7], ["snow_wolf", 6], ["snow_bear", 3], ["ice_shaman", 4]],
		"region": "snow", "mini_bosses": ["mini_boss_frosthorn", "mini_boss_glacial_colossus"],
		"trees": 30, "rocks": 26, "lumber": 8, "dig_spots": 70,
		"area_boss": "bone_colossus",
	},
	"dungeon": {"name": "Crypt Depths", "level": 4, "scene": "res://sense/maps/dungeon/dungeon_map.tscn"},
}
const ZONE_ORDER := ["town", "homestead", "greenwood", "cinderwaste", "frostvale", "dungeon"]

# =============================================================================
# BUILDINGS — homestead plots. Producers accumulate output over real time.
# =============================================================================
const BUILDINGS := {
	"lumber_mill": {
		"name": "Lumber Mill", "desc": "Produces wood over time.",
		"produces": "wood", "per_hour": [0, 30, 60, 110],
		"cost": [{}, {"gold": 150, "wood": 0, "stone": 5}, {"gold": 400, "wood": 30, "stone": 20}, {"gold": 900, "wood": 80, "stone": 50}],
		"prop": "barrel",
	},
	"stone_quarry": {
		"name": "Stone Quarry", "desc": "Produces stone over time.",
		"produces": "stone", "per_hour": [0, 25, 50, 90],
		"cost": [{}, {"gold": 150, "wood": 10, "stone": 0}, {"gold": 400, "wood": 40, "stone": 15}, {"gold": 900, "wood": 90, "stone": 40}],
		"prop": "rock",
	},
	"herb_garden": {
		"name": "Herb Garden", "desc": "Grows herbs.",
		"produces": "herb_segment", "per_hour": [0, 20, 40, 70],
		"cost": [{}, {"gold": 200, "wood": 15, "stone": 5}, {"gold": 500, "wood": 40, "stone": 25}, {"gold": 1100, "wood": 90, "stone": 60}],
		"prop": "bush",
	},
	"training_hall": {
		"name": "Training Hall", "desc": "Permanent +ATK per level.",
		"stat": {"atk": [0, 3, 7, 12]},
		"cost": [{}, {"gold": 300, "wood": 25, "stone": 25}, {"gold": 800, "wood": 60, "stone": 60}, {"gold": 1800, "wood": 120, "stone": 120}],
		"prop": "statue",
	},
	"watchtower": {
		"name": "Watchtower", "desc": "Permanent +DEF and +HP per level.",
		"stat": {"def": [0, 2, 5, 9], "hp": [0, 20, 50, 90]},
		"cost": [{}, {"gold": 300, "wood": 30, "stone": 20}, {"gold": 800, "wood": 70, "stone": 50}, {"gold": 1800, "wood": 140, "stone": 110}],
		"prop": "pillar",
	},
	"stable": {
		"name": "Stable", "desc": "+10% mount speed per level.",
		"stat": {"mount_pct": [0, 0.1, 0.2, 0.3]},
		"cost": [{}, {"gold": 250, "wood": 40, "stone": 10}, {"gold": 700, "wood": 80, "stone": 40}, {"gold": 1500, "wood": 150, "stone": 90}],
		"prop": "crate",
	},
}
const BUILDING_MAX_LEVEL := 3
const BUILDING_STORAGE_HOURS := 8.0

# =============================================================================
# QUESTS — main chain (sequential) + daily repeatables
# objective types: dig, kill, boss, have_item, gather, visit, craft, build, own_pet,
#                  own_mount, pet_level, mount_ride, socketed_gems, equipped_count,
#                  equipment_level, equipped_rarity
# =============================================================================
const MAIN_QUESTS := [
	{"id": "q01", "name": "Nhóm lửa đầu tiên", "desc": "Đứng yên trên một ô đất mềm để đào thử.",
		"obj": {"type": "dig", "target": "any", "count": 1}, "reward": {"gold": 100}},
	# Original Hearthmoor tutorial (save v6 maps the retired q305–q311 rows onto t01–t06).
	{"id": "t01", "name": "Đất còn hơi ấm", "desc": "Đào 10 ô đất quanh Hearthmoor. Orla nói than hồng hay nằm ngay dưới lớp cỏ.",
		"obj": {"type": "dig", "target": "any", "count": 10},
		"reward_table": "starter_weapon", "reward_preview": "1 vũ khí khởi đầu"},
	{"id": "t02", "name": "Nấm rêu chắn lối", "desc": "Hạ một con Mosscap đang chắn lối ra đồng cỏ.",
		"obj": {"type": "kill", "target": "mossback", "count": 1},
		"reward_table": "mossback_bounty", "reward_preview": "30 vàng, 1 kim cương"},
	{"id": "t03", "name": "Khoác giáp lên đường", "desc": "Mặc ít nhất 3 món trang bị trước khi rời làng.",
		"obj": {"type": "equipped_count", "target": "any", "count": 3},
		"reward_table": "diamond_1", "reward_preview": "1 kim cương"},
	{"id": "t04", "name": "Rèn cho bén", "desc": "Nâng một món trang bị lên cấp 2 ở lò rèn.",
		"obj": {"type": "equipment_level", "target": 2, "count": 1},
		"reward_table": "gold_200", "reward_preview": "200 vàng"},
	{"id": "t05", "name": "Rắn trong bụi gai", "desc": "Dọn 3 con Bramble Snake ở rìa đồng cỏ.",
		"obj": {"type": "kill", "target": "shroom", "count": 3},
		"reward_table": "diamond_1", "reward_preview": "1 kim cương"},
	{"id": "t06", "name": "Màu của độ hiếm", "desc": "Viền khung cho biết độ hiếm. Mặc một món từ Uncommon trở lên.",
		"obj": {"type": "equipped_rarity", "target": ItemData.ItemRarity.UNCOMMON, "count": 1},
		"reward_table": "diamond_1", "reward_preview": "1 kim cương"},
	{"id": "t07", "name": "Bàn tay thợ rèn", "desc": "Chế tạo một món bất kỳ ở bàn chế tạo.",
		"obj": {"type": "craft", "target": "any", "count": 1},
		"reward_table": "smith_kit", "reward_preview": "50 vàng, 2 bình máu"},
	{"id": "q02", "name": "Slime Cleanup", "desc": "Defeat Meadow Slimes.",
		"obj": {"type": "kill", "target": "slime", "count": 8}, "reward": {"gold": 80, "items": {"health_potion": 3}}},
	{"id": "q03", "name": "Timber!", "desc": "Chop trees for wood. Hit a tree to gather.",
		"obj": {"type": "gather", "target": "wood", "count": 10}, "reward": {"gold": 60, "items": {"stone": 5}}},
	{"id": "q04", "name": "A Loyal Friend", "desc": "Equip a pet from the Pet menu.",
		"obj": {"type": "own_pet", "target": "any", "count": 1}, "reward": {"items": {"egg_forest": 1}}},
	{"id": "q05", "name": "Bats in the Dusk", "desc": "Defeat Dusk Bats.",
		"obj": {"type": "kill", "target": "bat", "count": 6}, "reward": {"gold": 100}},
	{"id": "q06", "name": "Saddle Up", "desc": "Claim a mount from the Mount menu.",
		"obj": {"type": "own_mount", "target": "any", "count": 1}, "reward": {"gold": 120}},
	{"id": "q07", "name": "Homestead", "desc": "Build a Lumber Mill at your Homestead.",
		"obj": {"type": "build", "target": "lumber_mill", "count": 1}, "reward": {"gold": 150, "items": {"wood": 20}}},
	{"id": "q08", "name": "Charging Beasts", "desc": "Defeat Bristle Boars. Dodge their charge!",
		"obj": {"type": "kill", "target": "boar", "count": 5}, "reward": {"gold": 160, "items": {"ember_visor": 1}}},
	{"id": "q09", "name": "Pet Training", "desc": "Raise any pet to level 3.",
		"obj": {"type": "pet_level", "target": "any", "count": 3}, "reward": {"diamonds": 10}},
	{"id": "q10", "name": "The Mire King", "desc": "The world boss rises at the altar. Defeat it!",
		"obj": {"type": "boss", "target": "slime_king", "count": 1}, "reward": {"gold": 400, "items": {"stone_guard_1": 3}}},
	{"id": "q11", "name": "Into the Crypt", "desc": "Clear the Crypt Depths dungeon (use the town portal).",
		"obj": {"type": "kill", "target": "skeleton_grunt", "count": 10}, "reward": {"gold": 300}},
	{"id": "q12", "name": "Into the Ash", "desc": "Cross into Cinderwaste, the ash ring around Greenwood.",
		"obj": {"type": "visit", "target": "cinderwaste", "count": 1}, "reward": {"gold": 300}},
	{"id": "q13", "name": "Bone Archers", "desc": "Defeat Bone Archers.",
		"obj": {"type": "kill", "target": "skeleton_archer", "count": 10}, "reward": {"gold": 400, "items": {"stone_critical_1": 3}}},
	{"id": "q14", "name": "Stone Setter", "desc": "Socket 3 stones into your equipment.",
		"obj": {"type": "socketed_gems", "target": "any", "count": 3}, "reward": {"gold": 500}},
	{"id": "q15", "name": "The Colossus", "desc": "Defeat the Cinder Colossus.",
		"obj": {"type": "boss", "target": "bone_colossus", "count": 1}, "reward": {"gold": 1500, "items": {"stone_critical_2": 2}}},
]

const DAILY_QUESTS := [
	{"id": "d_hunt", "name": "Daily Hunt", "desc": "Defeat any 30 monsters.",
		"obj": {"type": "kill", "target": "any", "count": 30}, "reward": {"gold": 200, "diamonds": 2}},
	{"id": "d_gather", "name": "Daily Gather", "desc": "Gather 25 wood or stone.",
		"obj": {"type": "gather", "target": "any", "count": 25}, "reward": {"gold": 150}},
	{"id": "d_boss", "name": "Daily Boss", "desc": "Defeat any boss.",
		"obj": {"type": "boss", "target": "any", "count": 1}, "reward": {"gold": 300, "items": {"stone_guard_1": 2}}},
]

static func get_main_quest_index(quest_id: String) -> int:
	for i in range(MAIN_QUESTS.size()):
		if MAIN_QUESTS[i]["id"] == quest_id:
			return i
	return -1
