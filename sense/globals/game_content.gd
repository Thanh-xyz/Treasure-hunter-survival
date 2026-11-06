class_name GameContent
extends RefCounted
## GameContent — static, data-driven content definitions (class constants,
## usable from static functions too; not an autoload).
##
## Every gameplay system reads its numbers from here so balance can be tuned in
## one place. Unverified balance values remain placeholders until runtime capture.
##
## Sections: HEROES, HERO_SKILLS, PETS, MOUNTS, MONSTERS, ZONES, BUILDINGS, QUESTS

# =============================================================================
# HEROES — collectible playable classes (stars upgrade with hero_shard)
# =============================================================================
const HEROES := {
	"warden": {
		"name": "Warden",
		"title": "Warden",
		"desc": "Sturdy frontliner. Melee strikes and crowd control.",
		"tint": Color(1, 1, 1),
		"base": {"hp": 120, "atk": 10, "def": 2, "spd": 120.0},
		"growth": {"hp": 14, "atk": 2, "def": 1},
		"attack_style": "melee",
		"skills": ["cleave_spin", "shield_charge", "war_cry"],
		"unlock": {"gold": 0, "level": 1},
	},
	"ranger": {
		"name": "Ranger",
		"title": "Ranger",
		"desc": "Fires a bolt with every strike. Fast and agile.",
		"tint": Color(0.7, 1.0, 0.7),
		"base": {"hp": 95, "atk": 12, "def": 1, "spd": 135.0},
		"growth": {"hp": 10, "atk": 3, "def": 0},
		"attack_style": "bolt",
		"skills": ["bolt_fan", "dash_strike", "arrow_rain"],
		"unlock": {"gold": 1200, "level": 5},
	},
	"mystic": {
		"name": "Mystic",
		"title": "Mystic",
		"desc": "Every strike releases a small nova. Powerful area spells.",
		"tint": Color(0.85, 0.7, 1.0),
		"base": {"hp": 90, "atk": 14, "def": 1, "spd": 118.0},
		"growth": {"hp": 9, "atk": 3, "def": 0},
		"attack_style": "nova",
		"skills": ["meteor", "frost_ring", "mend"],
		"unlock": {"gold": 2500, "level": 8},
	},
}

const HERO_MAX_STARS := 5
const HERO_STAR_BONUS := 0.08          ## +8% hp/atk/def per extra star
const HERO_STAR_COST := [0, 5, 10, 20, 35]  ## hero_shard cost to reach star i+1

# =============================================================================
# HERO SKILLS — executed by HeroSkillRunner. unlock_level gates usage.
# =============================================================================
const HERO_SKILLS := {
	"cleave_spin": {"name": "Cleave", "type": "spin", "cd": 4.0, "cost": 20.0, "mult": 1.6, "radius": 44.0, "unlock_level": 1},
	"shield_charge": {"name": "Charge", "type": "dash", "cd": 7.0, "cost": 25.0, "mult": 1.4, "distance": 90.0, "unlock_level": 3},
	"war_cry": {"name": "War Cry", "type": "buff", "cd": 18.0, "cost": 30.0, "atk_mult": 1.4, "duration": 8.0, "unlock_level": 6},
	"bolt_fan": {"name": "Volley", "type": "fan", "cd": 3.5, "cost": 18.0, "mult": 1.0, "count": 5, "spread": 0.9, "unlock_level": 1},
	"dash_strike": {"name": "Dash", "type": "dash", "cd": 5.0, "cost": 18.0, "mult": 1.2, "distance": 110.0, "unlock_level": 3},
	"arrow_rain": {"name": "Rain", "type": "rain", "cd": 12.0, "cost": 35.0, "mult": 0.9, "radius": 40.0, "hits": 5, "unlock_level": 6},
	"meteor": {"name": "Meteor", "type": "meteor", "cd": 6.0, "cost": 28.0, "mult": 2.6, "radius": 46.0, "delay": 0.7, "unlock_level": 1},
	"frost_ring": {"name": "Frost", "type": "ring", "cd": 8.0, "cost": 25.0, "mult": 1.3, "count": 12, "unlock_level": 3},
	"mend": {"name": "Mend", "type": "heal", "cd": 15.0, "cost": 30.0, "heal_pct": 0.35, "unlock_level": 6},
}

# =============================================================================
# PETS — follow, fight, give passives, level up with pet_treat, evolve at 5/10
# =============================================================================
const PETS := {
	"ember_fox": {
		"name": "Ember Fox", "sprite": "pet_fox", "role": "attack",
		"desc": "Pounces on nearby enemies.",
		"attack": {"damage": 6, "cooldown": 1.2, "range": 110.0},
		"passive": {"atk": 2},
		"unlock": {"gold": 0},
	},
	"moss_turtle": {
		"name": "Moss Turtle", "sprite": "pet_turtle", "role": "defense",
		"desc": "Slowly heals its owner and hardens skin.",
		"heal": {"amount": 3, "interval": 4.0},
		"passive": {"def": 2, "hp": 15},
		"unlock": {"gold": 600},
	},
	"dusk_owl": {
		"name": "Dusk Owl", "sprite": "pet_owl", "role": "support",
		"desc": "Fires feathers at distant targets.",
		"attack": {"damage": 4, "cooldown": 0.9, "range": 150.0, "ranged": true},
		"passive": {"spd": 8.0},
		"unlock": {"gold": 900},
	},
	"lucky_cat": {
		"name": "Lucky Cat", "sprite": "pet_cat", "role": "utility",
		"desc": "Attracts loot and extra gold.",
		"passive": {"gold_pct": 0.25, "magnet": 60.0},
		"unlock": {"gold": 1500},
	},
}
const PET_MAX_LEVEL := 15
const PET_EVOLVE_LEVELS := [5, 10]       ## stage 2 at lvl 5, stage 3 at lvl 10
const PET_STAGE_SCALE := [1.0, 1.35, 1.7]
const PET_STAGE_TINT := [Color(1, 1, 1), Color(1.15, 1.05, 0.85), Color(1.3, 1.1, 1.4)]

static func pet_level_cost(level: int) -> Dictionary:
	return {"pet_treat": 2 + level, "gold": 40 * level}

# =============================================================================
# MOUNTS — categories speed / attack / defense, skins are palette swaps
# =============================================================================
const MOUNTS := {
	"dust_pony": {
		"name": "Dust Pony", "category": "speed", "sprite": "mount_pony",
		"speed_mult": 1.6, "bonus": {},
		"skins": ["mount_pony", "mount_pony_snow", "mount_pony_night"],
		"skin_cost": 300,
		"unlock": {"gold": 0, "level": 3},
	},
	"tusk_boar": {
		"name": "Tusk Boar", "category": "attack", "sprite": "mount_boar",
		"speed_mult": 1.35, "bonus": {"atk": 6},
		"skins": ["mount_boar"], "skin_cost": 0,
		"unlock": {"gold": 1000, "level": 6},
	},
	"shell_tortoise": {
		"name": "Shell Tortoise", "category": "defense", "sprite": "mount_tortoise",
		"speed_mult": 1.2, "bonus": {"def": 6, "hp": 40},
		"skins": ["mount_tortoise"], "skin_cost": 0,
		"unlock": {"gold": 1000, "level": 6},
	},
	"gale_stag": {
		"name": "Gale Stag", "category": "speed", "sprite": "mount_stag",
		"speed_mult": 1.9, "bonus": {},
		"skins": ["mount_stag"], "skin_cost": 0,
		"unlock": {"gold": 3000, "level": 10},
	},
}

# =============================================================================
# MONSTERS — data for Monster.gd. visual "skeleton" reuses the existing sheet.
# ai: melee | ranged | charger | flyer | stationary_melee
# =============================================================================
const MONSTERS := {
	"slime": {
		"name": "Mosqui", "visual": "pixel", "sprite": "mosquito", "palette": "mosquito",
		"texture": "res://assets/treasure_hunter/monsters/mosqui.png", "squash": 0.025,
		"ai": "flyer", "hp": 30, "dmg": 6, "spd": 38.0, "xp": 8, "level": 1,
		"range": 16.0, "aggro": 110.0, "scale": 0.75, "gold": Vector2i(1, 4),
		"loot": [["herb_segment", 30, 1, 2], ["pet_treat", 12, 1, 1], ["health_potion", 6, 1, 1]],
	},
	"bat": {
		"name": "Dusk Bat", "visual": "pixel", "sprite": "bat", "palette": "bat",
		"ai": "flyer", "hp": 22, "dmg": 5, "spd": 70.0, "xp": 9, "level": 2,
		"range": 14.0, "aggro": 140.0, "scale": 1.0, "gold": Vector2i(1, 5),
		"loot": [["spirit_essence", 10, 1, 1], ["pet_treat", 10, 1, 1]],
	},
	"shroom": {
		"name": "Snailu", "visual": "pixel", "sprite": "snail", "palette": "snail",
		"texture": "res://assets/treasure_hunter/monsters/snailu.png", "squash": 0.025,
		"ai": "melee", "hp": 34, "dmg": 7, "spd": 30.0, "xp": 12, "level": 3,
		"range": 16.0, "aggro": 150.0, "scale": 0.78, "gold": Vector2i(2, 6),
		"loot": [["venom_gland", 18, 1, 1], ["herb_segment", 25, 1, 2]],
	},
	# Source confirms movement but not the Unity-to-Emberfield speed conversion.
	"snailu": {
		"name": "Snailu", "source_card_id": 34,
		"visual": "atlas", "asset_id": "actor.monster.snailu.atlas",
		"ai": "reference_melee", "hp": 200, "dmg": 30, "spd": 30.0, "xp": 0, "level": 1,
		"range": 70.0, "aggro": 200.0, "scale": 1.0, "collision_radius": 30.0,
		"gold": Vector2i(40, 50), "loot": [],
		"attack_interval": 1.0, "attack_duration": 0.6666666865, "attack_hit_time": 0.4,
		"death_duration": 0.75,
	},
	"boar": {
		"name": "Astromophy", "visual": "pixel", "sprite": "boar", "palette": "boar",
		"texture": "res://assets/treasure_hunter/monsters/astromophy.png", "squash": 0.025,
		"ai": "charger", "hp": 60, "dmg": 12, "spd": 34.0, "xp": 16, "level": 4,
		"range": 90.0, "aggro": 140.0, "scale": 0.78, "gold": Vector2i(3, 8),
		"loot": [["leather_armor", 3, 1, 1], ["pet_treat", 15, 1, 2], ["iron_ore", 20, 1, 2]],
	},
	"turtle": {
		"name": "Turtle", "source_card_id": 33,
		"visual": "atlas", "asset_id": "actor.monster.turtle.default",
		"ai": "stationary_melee", "hp": 100, "dmg": 20, "spd": 0.0, "xp": 0, "level": 1,
		"range": 70.0, "aggro": 200.0, "scale": 1.0, "gold": Vector2i.ZERO, "loot": [],
		"attack_interval": 1.0, "attack_duration": 0.6666666865,
		"death_duration": 0.75, "knockback_immune": true,
	},
	"skeleton_grunt": {
		"name": "Bone Grunt", "visual": "skeleton", "tint": Color(1, 1, 1),
		"ai": "melee", "hp": 70, "dmg": 12, "spd": 46.0, "xp": 20, "level": 6,
		"range": 24.0, "aggro": 150.0, "scale": 0.55, "gold": Vector2i(4, 12),
		"loot": [["bone", 60, 1, 3], ["fire_shard", 12, 1, 1], ["iron_sword", 3, 1, 1], ["hero_shard", 4, 1, 1]],
	},
	"skeleton_archer": {
		"name": "Bone Archer", "visual": "skeleton", "tint": Color(0.65, 0.8, 1.0),
		"ai": "ranged", "hp": 55, "dmg": 11, "spd": 40.0, "xp": 22, "level": 7,
		"range": 140.0, "aggro": 170.0, "scale": 0.5, "gold": Vector2i(4, 12),
		"projectile": "bolt_frost",
		"loot": [["bone", 50, 1, 2], ["frost_shard", 14, 1, 1], ["hunting_bow", 3, 1, 1], ["hero_shard", 4, 1, 1]],
	},
	"frost_slime": {
		"name": "Frost Slime", "visual": "pixel", "sprite": "slime", "palette": "slime_frost",
		"ai": "melee", "hp": 80, "dmg": 13, "spd": 44.0, "xp": 22, "level": 8,
		"range": 16.0, "aggro": 120.0, "scale": 1.3, "gold": Vector2i(4, 10),
		"loot": [["frost_shard", 25, 1, 2], ["pet_treat", 15, 1, 2]],
	},
	"magma_slime": {
		"name": "Magma Slime", "visual": "pixel", "sprite": "slime", "palette": "slime_magma",
		"ai": "melee", "hp": 110, "dmg": 16, "spd": 46.0, "xp": 30, "level": 10,
		"range": 16.0, "aggro": 120.0, "scale": 1.4, "gold": Vector2i(6, 14),
		"loot": [["fire_shard", 25, 1, 2], ["inferno_shard", 5, 1, 1]],
	},
	# --------------------------------------------------------------- bosses
	"slime_king": {
		"name": "Mire King", "visual": "pixel", "sprite": "slime", "palette": "slime_king",
		"ai": "boss_slime", "hp": 900, "dmg": 18, "spd": 32.0, "xp": 300, "level": 5,
		"range": 30.0, "aggro": 220.0, "scale": 3.2, "gold": Vector2i(80, 140), "boss": true,
		"loot": [["hero_shard", 100, 2, 4], ["pet_treat", 100, 3, 6], ["platinum_sword", 25, 1, 1], ["swift_boots", 25, 1, 1], ["boss_core", 100, 1, 1]],
	},
	"crypt_warden": {
		"name": "Crypt Warden", "visual": "skeleton", "tint": Color(0.8, 0.7, 1.0),
		"ai": "boss_skeleton", "hp": 650, "dmg": 16, "spd": 42.0, "xp": 220, "level": 5,
		"range": 34.0, "aggro": 300.0, "scale": 1.0, "gold": Vector2i(60, 120), "boss": true,
		"loot": [["hero_shard", 100, 1, 3], ["steel_sword", 30, 1, 1], ["iron_armor", 25, 1, 1], ["pet_treat", 100, 2, 4]],
	},
	"bone_colossus": {
		"name": "Bone Colossus", "visual": "skeleton", "tint": Color(1.0, 0.75, 0.7),
		"ai": "boss_skeleton", "hp": 1600, "dmg": 24, "spd": 40.0, "xp": 600, "level": 10,
		"range": 40.0, "aggro": 260.0, "scale": 1.4, "gold": Vector2i(150, 260), "boss": true,
		"loot": [["hero_shard", 100, 3, 6], ["fire_blade", 30, 1, 1], ["plate_armor", 25, 1, 1], ["diamond_ring", 20, 1, 1], ["boss_core", 100, 1, 2]],
	},
}

const ELITE_HP_MULT := 2.6
const ELITE_DMG_MULT := 1.5
const ELITE_XP_MULT := 3.0
const ELITE_CHANCE := 0.08

# Ground-dig timings and weights are clean-room provisional values until a full
# first-person source capture measures the live table and cadence.
const DIG_HITS := 3
const DIG_INTERVAL := 0.7
const DIG_RESPAWN_TIME := 24.0
const DIG_LOOT := [
	{"item_id": "stone", "weight": 28, "min": 1, "max": 3},
	{"item_id": "wood", "weight": 20, "min": 1, "max": 2},
	{"item_id": "iron_ore", "weight": 18, "min": 1, "max": 2},
	{"item_id": "herb_segment", "weight": 10, "min": 1, "max": 2},
	{"item_id": "health_potion", "weight": 8, "min": 1, "max": 1},
	{"item_id": "wooden_sword", "weight": 4, "min": 1, "max": 1},
	{"item_id": "leather_cap", "weight": 4, "min": 1, "max": 1},
	{"item_id": "leather_armor", "weight": 4, "min": 1, "max": 1},
	{"item_id": "leather_boots", "weight": 4, "min": 1, "max": 1},
]

# =============================================================================
# ZONES — open fields generated by FieldMap
# =============================================================================
const ZONES := {
	"town": {"name": "Hearthmoor Town", "level": 1, "scene": "res://sense/maps/town/town.tscn", "safe": true},
	"homestead": {"name": "Homestead", "level": 1, "scene": "res://sense/maps/homestead/homestead.tscn", "safe": true},
	"greenwood": {
		"name": "Greenwood Meadow", "level": 1, "scene": "res://sense/maps/field/greenwood.tscn",
		"size": Vector2i(60, 90), "ground_tint": Color(1, 1, 1), "seed": 1101,
		"spawns": [["slime", 9], ["bat", 5], ["shroom", 4], ["boar", 3], ["turtle", 1], ["snailu", 1]],
		"trees": 34, "rocks": 18, "lumber": 9, "dig_spots": 42,
		"world_boss": "slime_king", "boss_interval": 180.0,
	},
	"frostvale": {
		"name": "Frostvale Ruins", "level": 6, "scene": "res://sense/maps/field/frostvale.tscn",
		"size": Vector2i(64, 96), "ground_tint": Color(0.82, 0.9, 1.15), "seed": 2202,
		"spawns": [["frost_slime", 7], ["skeleton_grunt", 6], ["skeleton_archer", 5], ["magma_slime", 3]],
		"trees": 30, "rocks": 26, "lumber": 8, "dig_spots": 46,
		"world_boss": "bone_colossus", "boss_interval": 240.0,
	},
	"dungeon": {"name": "Crypt Depths", "level": 4, "scene": "res://sense/maps/dungeon/dungeon_map.tscn"},
}
const ZONE_ORDER := ["town", "homestead", "greenwood", "frostvale", "dungeon"]

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
		"name": "Herb Garden", "desc": "Grows herbs and pet treats.",
		"produces": "herb_segment", "per_hour": [0, 20, 40, 70],
		"bonus_item": "pet_treat",
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
# objective types: dig, kill, boss, have_item, gather, level, visit, craft, build,
#                  own_pet, own_mount, pet_level, hero_star, mount_ride
# =============================================================================
const MAIN_QUESTS := [
	{"id": "q01", "name": "Đào đất", "desc": "Đứng trên một ô đất để tự động đào.",
		"source_quest_id": 335,
		"obj": {"type": "dig", "target": "any", "count": 1}, "reward": {"gold": 100}},
	{"id": "q305", "name": "Đào đất", "desc": "Di chuyển đến bất kỳ ô nào và đứng yên để đào.",
		"source_quest_id": 305,
		"obj": {"type": "dig", "target": "any", "count": 10},
		"reward_box_id": 149, "reward_preview": "1 trang bị Common"},
	{"id": "q306", "name": "Đánh bại Turtle", "desc": "Đánh bại Rùa.",
		"source_quest_id": 306,
		"obj": {"type": "kill", "target": "turtle", "count": 1},
		"reward_box_id": 98, "reward_preview": "1 Kim cương"},
	{"id": "q307", "name": "Mặc trang bị", "desc": "Trang bị bất kỳ vật phẩm nào",
		"source_quest_id": 307,
		"obj": {"type": "equipped_count", "target": "any", "count": 3},
		"reward_box_id": 98, "reward_preview": "1 Kim cương"},
	{"id": "q308", "name": "Nâng cấp trang bị", "desc": "Nâng cấp bất kỳ trang bị nào lên Cấp 2",
		"source_quest_id": 308,
		"obj": {"type": "equipment_level", "target": 2, "count": 1},
		"reward_box_id": 151, "reward_preview": "200 Vàng"},
	{"id": "q310", "name": "Đánh bại Snailu", "desc": "Đánh bại Snailu",
		"source_quest_id": 310,
		"obj": {"type": "kill", "target": "snailu", "count": 3},
		"reward_box_id": 98, "reward_preview": "1 Kim cương"},
	{"id": "q311", "name": "Mặc trang bị Rare", "desc": "Độ hiếm của vật phẩm được xác định bằng màu sắc",
		"source_quest_id": 311,
		"obj": {"type": "equipped_rarity", "target": ItemData.ItemRarity.RARE, "count": 1},
		"reward_box_id": 98, "reward_preview": "1 Kim cương"},
	{"id": "q02", "name": "Slime Cleanup", "desc": "Defeat Meadow Slimes.",
		"obj": {"type": "kill", "target": "slime", "count": 8}, "reward": {"xp": 60, "gold": 80, "items": {"health_potion": 3}}},
	{"id": "q03", "name": "Timber!", "desc": "Chop trees for wood. Hit a tree to gather.",
		"obj": {"type": "gather", "target": "wood", "count": 10}, "reward": {"xp": 60, "gold": 60, "items": {"stone": 5}}},
	{"id": "q04", "name": "A Loyal Friend", "desc": "Equip a pet from the Pet menu.",
		"obj": {"type": "own_pet", "target": "any", "count": 1}, "reward": {"xp": 50, "items": {"pet_treat": 6}}},
	{"id": "q05", "name": "Bats in the Dusk", "desc": "Defeat Dusk Bats.",
		"obj": {"type": "kill", "target": "bat", "count": 6}, "reward": {"xp": 90, "gold": 100}},
	{"id": "q06", "name": "Saddle Up", "desc": "Reach level 3 and claim a mount.",
		"obj": {"type": "own_mount", "target": "any", "count": 1}, "reward": {"xp": 80, "gold": 120}},
	{"id": "q07", "name": "Homestead", "desc": "Build a Lumber Mill at your Homestead.",
		"obj": {"type": "build", "target": "lumber_mill", "count": 1}, "reward": {"xp": 120, "gold": 150, "items": {"wood": 20}}},
	{"id": "q08", "name": "Charging Beasts", "desc": "Defeat Bristle Boars. Dodge their charge!",
		"obj": {"type": "kill", "target": "boar", "count": 5}, "reward": {"xp": 160, "gold": 160, "items": {"iron_helmet": 1}}},
	{"id": "q09", "name": "Pet Training", "desc": "Raise any pet to level 3.",
		"obj": {"type": "pet_level", "target": "any", "count": 3}, "reward": {"xp": 120, "items": {"pet_treat": 8}}},
	{"id": "q10", "name": "The Mire King", "desc": "The world boss rises at the altar. Defeat it!",
		"obj": {"type": "boss", "target": "slime_king", "count": 1}, "reward": {"xp": 400, "gold": 400, "items": {"hero_shard": 5}}},
	{"id": "q11", "name": "Into the Crypt", "desc": "Clear the Crypt Depths dungeon (use the town portal).",
		"obj": {"type": "kill", "target": "skeleton_grunt", "count": 10}, "reward": {"xp": 400, "gold": 300}},
	{"id": "q12", "name": "Northern Ruins", "desc": "Reach level 6 and travel to Frostvale.",
		"obj": {"type": "visit", "target": "frostvale", "count": 1}, "reward": {"xp": 300, "gold": 300}},
	{"id": "q13", "name": "Bone Archers", "desc": "Defeat Bone Archers.",
		"obj": {"type": "kill", "target": "skeleton_archer", "count": 10}, "reward": {"xp": 500, "gold": 400, "items": {"hero_shard": 5}}},
	{"id": "q14", "name": "Star Power", "desc": "Upgrade any hero to 2 stars.",
		"obj": {"type": "hero_star", "target": "any", "count": 2}, "reward": {"xp": 400, "gold": 500}},
	{"id": "q15", "name": "The Colossus", "desc": "Defeat the Bone Colossus.",
		"obj": {"type": "boss", "target": "bone_colossus", "count": 1}, "reward": {"xp": 1200, "gold": 1500, "items": {"hero_shard": 10}}},
]

const DAILY_QUESTS := [
	{"id": "d_hunt", "name": "Daily Hunt", "desc": "Defeat any 30 monsters.",
		"obj": {"type": "kill", "target": "any", "count": 30}, "reward": {"xp": 150, "gold": 200, "items": {"pet_treat": 4}}},
	{"id": "d_gather", "name": "Daily Gather", "desc": "Gather 25 wood or stone.",
		"obj": {"type": "gather", "target": "any", "count": 25}, "reward": {"xp": 100, "gold": 150}},
	{"id": "d_boss", "name": "Daily Boss", "desc": "Defeat any boss.",
		"obj": {"type": "boss", "target": "any", "count": 1}, "reward": {"xp": 300, "gold": 300, "items": {"hero_shard": 3}}},
]

# =============================================================================
# PROGRESSION
# =============================================================================
const MAX_LEVEL := 40

static func xp_to_next(level: int) -> int:
	return 40 + level * level * 22


static func get_main_quest_index(quest_id: String) -> int:
	for i in range(MAIN_QUESTS.size()):
		if MAIN_QUESTS[i]["id"] == quest_id:
			return i
	return -1
