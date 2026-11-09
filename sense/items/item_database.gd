extends Node

## Sample items database - preloaded item definitions
## Use this to get item data by ID

var items: Dictionary = {}

## Path to the item icons sprite sheet
const ICON_SHEET_PATH := "res://assets/items/item_icons.png"


func _ready() -> void:
	_init_icon_atlas()
	_create_all_items()


## Initialize the icon atlas with sprite sheet
func _init_icon_atlas() -> void:
	var sheet := load(ICON_SHEET_PATH) as Texture2D
	if sheet:
		# Adjust icon_size based on your sprite sheet (16x16, 24x24, 32x32, etc.)
		# This sprite sheet uses 32x32 icons with 16 columns
		ItemIconAtlas.init(sheet, Vector2i(32, 32), 16)
		print("[ItemDatabase] Icon atlas initialized: %dx%d icons (32x32 each)" % [ItemIconAtlas.columns, ItemIconAtlas.rows])
		print("[ItemDatabase] Sprite sheet: %dx%d pixels" % [sheet.get_width(), sheet.get_height()])
	else:
		push_warning("[ItemDatabase] Could not load icon sheet: %s" % ICON_SHEET_PATH)


func _create_all_items() -> void:
	_create_equipment()
	_create_consumables()
	_create_materials()
	_create_segments()
	_create_gems()
	_create_eggs()
	_create_boss_cards()
	_create_timed_buffs()
	_create_survival_items()


## Equipment comes from data/equipment/templates.json; stats are computed by EquipmentBalance.
## The pre-2026-11-08 equipment (swords, armours, shields, rings…) was retired with save v6.
func _create_equipment() -> void:
	for template_id: String in EquipmentCatalog.ids():
		var t := EquipmentCatalog.get_template(template_id)
		var slot := str(t["slot"])
		var item_type: int = ItemData.ItemType.WEAPON
		for type: int in ItemData.SLOT_BY_TYPE:
			if ItemData.SLOT_BY_TYPE[type] == slot:
				item_type = type
		var rarity := maxi(EquipmentBalance.rarity_enum(str(t["rarity"])), 0)
		var item := ItemHelper.create_item({
			"id": template_id,
			"name": str(t.get("name", template_id)),
			"description": str(t.get("description", "")),
			"type": item_type,
			"rarity": rarity,
			"price": int(t.get("price", 60 + 40 * rarity)),
			"max_upgrade_level": EquipmentBalance.max_level(),
			"use_atlas": false,
		})
		item.equipment_line = str(t["line"])
		item.icon_asset_id = str(t.get("icon", ""))
		items[template_id] = item


func _create_consumables() -> void:
	items["health_potion"] = ItemHelper.create_item({
		"id": "health_potion", "name": "Health Potion",
		"description": "A red potion that restores health.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 20,
		"price": 25, "sell_price": 10, "heal": 50,
		"icon_name": "potion_red"
	})
	items["large_health_potion"] = ItemHelper.create_item({
		"id": "large_health_potion", "name": "Large Health Potion",
		"description": "A large red potion that greatly restores health.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 10,
		"price": 75, "sell_price": 30, "heal": 100,
		"icon_name": "potion_red"
	})
	items["stamina_potion"] = ItemHelper.create_item({
		"id": "stamina_potion", "name": "Stamina Potion",
		"description": "A blue potion that restores stamina.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 20,
		"price": 20, "sell_price": 8, "stamina": 50.0,
		"icon_row": 9, "icon_col": 1
	})


func _create_materials() -> void:
	items["iron_ore"] = ItemHelper.create_item({
		"id": "iron_ore", "name": "Iron Ore",
		"description": "Raw iron ore. Can be smelted into iron ingots.",
		"stackable": true, "price": 10,
		"icon_name": "iron_ore"
	})
	items["gold_ore"] = ItemHelper.create_item({
		"id": "gold_ore", "name": "Gold Ore",
		"description": "Precious gold ore. Valuable but soft.",
		"stackable": true, "price": 50,
		"icon_name": "gold_ore"
	})
	items["monster_bone"] = ItemHelper.create_item({
		"id": "monster_bone", "name": "Monster Bone",
		"description": "A bone from a defeated monster. Used in crafting.",
		"stackable": true, "price": 15,
		"icon_name": "bone"
	})
	items["bone"] = ItemHelper.create_item({
		"id": "bone", "name": "Bone",
		"description": "A skeletal bone. Common drop from skeleton enemies.",
		"stackable": true, "price": 5,
		"icon_name": "bone"
	})
	items["gold_coin"] = ItemHelper.create_item({
		"id": "gold_coin", "name": "Gold Coin",
		"description": "A shiny gold coin.",
		"stackable": true, "max_stack": 9999,
		"price": 1, "sell_price": 1,
		"icon_name": "gold_coin"
	})


func _create_segments() -> void:
	items["fire_shard"] = ItemHelper.create_item({
		"id": "fire_shard", "name": "Fire Shard",
		"description": "A warm crystalline fragment.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 15, "sell_price": 5,
		"icon_name": "fire_shard"
	})
	items["frost_shard"] = ItemHelper.create_item({
		"id": "frost_shard", "name": "Frost Shard",
		"description": "A cold crystalline fragment.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 15, "sell_price": 5,
		"icon_name": "frost_shard"
	})
	items["power_fragment"] = ItemHelper.create_item({
		"id": "power_fragment", "name": "Power Fragment",
		"description": "Pulses with raw energy.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 20, "sell_price": 7,
		"icon_name": "power_fragment"
	})
	items["spirit_essence"] = ItemHelper.create_item({
		"id": "spirit_essence", "name": "Spirit Essence",
		"description": "A wisp of spectral energy.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "price": 30, "sell_price": 10,
		"icon_name": "spirit_essence"
	})
	items["venom_gland"] = ItemHelper.create_item({
		"id": "venom_gland", "name": "Venom Gland",
		"description": "Drips with potent toxin.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "price": 25, "sell_price": 8,
		"icon_name": "venom_gland"
	})
	items["herb_segment"] = ItemHelper.create_item({
		"id": "herb_segment", "name": "Herb Segment",
		"description": "A fragrant healing herb.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 10, "sell_price": 3,
		"icon_name": "herb_segment"
	})
	items["inferno_shard"] = ItemHelper.create_item({
		"id": "inferno_shard", "name": "Inferno Shard",
		"description": "Blazing hot crystal.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 50, "sell_price": 18,
		"icon_name": "inferno_shard"
	})
	items["blizzard_shard"] = ItemHelper.create_item({
		"id": "blizzard_shard", "name": "Blizzard Shard",
		"description": "Freezing cold crystal.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 50, "sell_price": 18,
		"icon_name": "blizzard_shard"
	})
	items["greater_power_fragment"] = ItemHelper.create_item({
		"id": "greater_power_fragment", "name": "Greater Power Fragment",
		"description": "Surges with intense energy.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 60, "sell_price": 22,
		"icon_name": "greater_power_fragment"
	})
	items["hellfire_shard"] = ItemHelper.create_item({
		"id": "hellfire_shard", "name": "Hellfire Shard",
		"description": "Burns with infernal flame.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.EPIC,
		"stackable": true, "price": 120, "sell_price": 45,
		"icon_name": "hellfire_shard"
	})


## Socket stones (data/gems): 11 types × 4 tiers. Icons are placeholders until the
## Ninja Adventure item icons are assigned (plan phase F, NEEDS_ASSET).
func _create_gems() -> void:
	for stone_id: String in GemCatalog.all_item_ids():
		var p := GemCatalog.parse(stone_id)
		var tier := GemCatalog.tier_def(int(p["tier"]))
		items[stone_id] = ItemHelper.create_item({
			"id": stone_id, "name": GemCatalog.display_name(stone_id),
			"description": "%s %s" % [GemCatalog.type_def(p["type"]).get("description", ""), GemCatalog.describe(stone_id)],
			"type": ItemData.ItemType.GEM,
			"rarity": maxi(EquipmentBalance.rarity_enum(str(tier.get("rarity", "common"))), 0),
			"stackable": true, "max_stack": 99,
			"price": int(tier.get("sell_price", 10)) * 2, "sell_price": int(tier.get("sell_price", 10)),
			"icon_name": "diamond",
		})


## Pet eggs (data/companions/pets.json). Hatched from the Pet menu. Icon placeholder until pet
## item art is assigned (plan phase F, NEEDS_ASSET).
func _create_eggs() -> void:
	for egg_id: String in CompanionCatalog.egg_ids():
		var e := CompanionCatalog.egg(egg_id)
		items[egg_id] = ItemHelper.create_item({
			"id": egg_id, "name": str(e.get("name", egg_id)),
			"description": "Hatch it in the Pet menu (%s)." % e.get("region", ""),
			"stackable": true, "max_stack": 99, "price": 0, "sell_price": 0,
			"rarity": ItemData.ItemRarity.UNCOMMON,
			"icon_name": "heart",
		})


## Boss Summon Cards and fragments (data/bosses/bosses.json). Used from the World Map tab.
## Icons are placeholders until card art is assigned (plan phase F, NEEDS_ASSET).
func _create_boss_cards() -> void:
	var rarity_by_name := {"rare": ItemData.ItemRarity.RARE, "epic": ItemData.ItemRarity.EPIC, "legendary": ItemData.ItemRarity.LEGENDARY}
	for card_id: String in BossCatalog.cards():
		var c: Dictionary = BossCatalog.card(card_id)
		items[card_id] = ItemHelper.create_item({
			"id": card_id, "name": str(c.get("name", card_id)),
			"description": "Summons %s. Consumed only when the boss appears." % GameContent.MONSTERS.get(str(c.get("boss", "")), {}).get("name", c.get("boss", "")),
			"stackable": true, "max_stack": 20, "price": 0, "sell_price": 0,
			"rarity": rarity_by_name.get(str(c.get("rarity", "rare")), ItemData.ItemRarity.RARE),
			"icon_name": "power_fragment",
		})
	for fragment_id: String in BossCatalog.fragments():
		items[fragment_id] = ItemHelper.create_item({
			"id": fragment_id, "name": str(BossCatalog.fragments()[fragment_id].get("name", fragment_id)),
			"description": "Combine fragments into a Boss Summon Card.",
			"stackable": true, "max_stack": 999, "price": 0, "sell_price": 0,
			"rarity": ItemData.ItemRarity.UNCOMMON,
			"icon_name": "power_fragment",
		})


func _create_timed_buffs() -> void:
	items["vitality_tonic_t1"] = ItemHelper.create_item({
		"id": "vitality_tonic_t1", "name": "Vitality Tonic I",
		"description": "Temporarily increases max HP by 20 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "health": 20,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "vitality_tonic"
	})
	items["vitality_tonic_t2"] = ItemHelper.create_item({
		"id": "vitality_tonic_t2", "name": "Vitality Tonic II",
		"description": "Temporarily increases max HP by 50 for 90 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "health": 50,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 90.0,
		"icon_name": "vitality_tonic"
	})
	items["speed_elixir_t1"] = ItemHelper.create_item({
		"id": "speed_elixir_t1", "name": "Speed Elixir I",
		"description": "Temporarily increases move speed by 20 for 45 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "speed": 20.0,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 45.0,
		"icon_name": "speed_elixir"
	})
	items["speed_elixir_t2"] = ItemHelper.create_item({
		"id": "speed_elixir_t2", "name": "Speed Elixir II",
		"description": "Temporarily increases move speed by 40 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "speed": 40.0,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "speed_elixir"
	})
	items["defense_brew_t1"] = ItemHelper.create_item({
		"id": "defense_brew_t1", "name": "Defense Brew I",
		"description": "Temporarily increases defense by 8 for 45 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "defense": 8,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 45.0,
		"icon_name": "defense_brew"
	})
	items["defense_brew_t2"] = ItemHelper.create_item({
		"id": "defense_brew_t2", "name": "Defense Brew II",
		"description": "Temporarily increases defense by 15 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "defense": 15,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "defense_brew"
	})


## Survival RPG resources and progression materials
func _create_survival_items() -> void:
	items["wood"] = ItemHelper.create_item({
		"id": "wood", "name": "Wood",
		"description": "Sturdy timber. Used to build and upgrade homestead buildings.",
		"stackable": true, "max_stack": 999, "price": 4,
		"icon_name": "wood"
	})
	items["stone"] = ItemHelper.create_item({
		"id": "stone", "name": "Stone",
		"description": "Quarried stone. Used to build and upgrade homestead buildings.",
		"stackable": true, "max_stack": 999, "price": 4,
		"icon_name": "iron_ore"
	})
	items["boss_core"] = ItemHelper.create_item({
		"id": "boss_core", "name": "Boss Core",
		"description": "The pulsing heart of a defeated boss. Sells for a fortune.",
		"stackable": true, "max_stack": 99, "price": 400,
		"rarity": ItemData.ItemRarity.EPIC,
		"icon_name": "skull"
	})


## Get item data by ID
func get_item(item_id: String) -> ItemData:
	if items.has(item_id):
		return items[item_id]
	return null


## Get a duplicate of item data (for instances)
func get_item_copy(item_id: String) -> ItemData:
	var item := get_item(item_id)
	if item != null:
		return item.duplicate()
	return null
