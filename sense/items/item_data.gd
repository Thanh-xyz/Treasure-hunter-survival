class_name ItemData
extends Resource

## Item data resource - defines all properties of an item
##
## ╔═══════════════════════════════════════════════════════════════╗
## ║                    ITEM TYPE DIAGRAM                          ║
## ╠═══════════════════════════════════════════════════════════════╣
## ║  HELMET / ARMOR / BOOTS / WEAPON / BACK → the 5 equipment     ║
## ║    slots. Stats come from data/equipment (EquipmentBalance).  ║
## ║  SHIELD / ACCESSORY → retired (save v6); kept for enum values ║
## ║  CONSUMABLE → Used from inventory, applies effect             ║
## ║  MATERIAL   → Crafting materials, cannot be used directly     ║
## ║  QUEST      → Quest items, cannot be dropped or sold          ║
## ║  SEGMENT    → Magical crafting drops, stackable max 99        ║
## ║  AUGMENT    → Timed buff consumables (brews, tonics)          ║
## ║  GEM        → Socket stones, 8 sockets per equipment piece    ║
## ╚═══════════════════════════════════════════════════════════════╝

enum ItemType {
	WEAPON,
	ARMOR,
	HELMET,
	BOOTS,
	SHIELD,
	ACCESSORY,
	CONSUMABLE,
	MATERIAL,
	QUEST,
	SEGMENT,   ## Magical crafting drops, stackable max 99
	AUGMENT,   ## Crafted buff items, non-stackable, slotted into equipment
	BACK,      ## Back equipment (cloak, pack, quiver). Appended to keep saved enum values stable
	GEM        ## Socket stone (data/gems). Appended to keep saved enum values stable
}

enum AugmentType {
	NONE,            ## Not an augment item
	STAT_BOOST,      ## Pure stat increase (ATK, DEF, HP, SPD)
	PASSIVE_EFFECT,  ## Retired in save v7 (socket stones replace slotted augments)
	ACTIVE_SKILL,    ## Retired in save v7
	TIMED_BUFF       ## Consumable-style — used from inventory for temporary buff
}

enum PassiveEffect {
	NONE,
	LIFE_STEAL,     ## Heal % of damage dealt
	CRIT_CHANCE,    ## Percentage-point bonus to critical chance
	THORNS,         ## Reflect % damage back to attacker on hit received
	BURN_ON_HIT,    ## Apply burn DoT on hit
	FREEZE_ON_HIT,  ## Apply slow on hit
	POISON_ON_HIT,  ## Apply poison DoT on hit
	CRIT_DAMAGE,    ## Percentage bonus to the critical multiplier (stones, save v7)
	DODGE,          ## Percent chance to avoid an incoming hit
	ACCURACY,       ## Percentage points removed from a target's dodge (PvP)
	REGENERATION    ## HP restored per second
}

enum ItemRarity {
	COMMON,      # White/Gray
	UNCOMMON,    # Green
	RARE,        # Blue
	EPIC,        # Purple
	LEGENDARY    # Orange/Gold
}

@export_category("Basic Info")
@export var id: String = ""
@export var name: String = "Item"
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: ItemRarity = ItemRarity.COMMON

@export_category("Icon from Atlas")
## Use icon from sprite sheet atlas instead of individual texture
@export var use_atlas_icon: bool = false
## Icon name from ItemIconAtlas.ICONS (e.g., "sword_iron", "potion_health")
@export var atlas_icon_name: String = ""
## Or specify row/column directly in sprite sheet
@export var atlas_row: int = 0
@export var atlas_col: int = 0

@export_category("Stacking")
@export var stackable: bool = true
@export var max_stack: int = 99

@export_category("Value")
@export var buy_price: int = 0
@export var sell_price: int = 0

@export_category("Equipment Stats")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var speed_bonus: float = 0.0

@export_category("Equipment Enhancement")
@export var can_upgrade: bool = false
@export var upgrade_base_cost: int = 0
@export var upgrade_cost_rate: float = 1.0
@export var max_upgrade_level: int = 1

## Displayed equipment level. Catalog templates remain at level 1; upgraded
## equipment is stored on duplicated item instances.
@export_storage var enhancement_level: int = 1

@export_category("Equipment Line")
## Balance line from data/equipment/balance.json (tank, damage, balanced, sword, axe, dagger).
## When set, HP/ATK/move-speed come from EquipmentBalance by slot, line, rarity and level.
@export var equipment_line: String = ""
## ArtCatalog asset ID for the icon (original art); empty uses the atlas or `icon`.
@export var icon_asset_id: String = ""

@export_category("Consumable Effects")
@export var heal_amount: int = 0
@export var stamina_restore: float = 0.0
@export var effect_duration: float = 0.0

@export_category("Augment Properties")
@export var augment_type: AugmentType = AugmentType.NONE
@export var passive_effect: PassiveEffect = PassiveEffect.NONE
@export var passive_value: float = 0.0          ## e.g. 5.0 = 5% life steal, 10.0 = 10% crit
@export var active_skill_id: String = ""        ## Links to SkillData.id (e.g. "whirlwind")
@export var buff_duration: float = 0.0          ## > 0 means timed consumable buff; 0 = permanent augment

## Socket stones in this equipment instance: GemCatalog.slots_per_holder() entries, "" = empty.
## Only populated on duplicated equipment instances, never on ItemDatabase templates.
var gems: Array[String] = []


## Legacy items without an equipment line scale every bonus by this rate per level.
const LEGACY_STAT_GROWTH_RATE := 1.1

const SLOT_BY_TYPE := {
	ItemType.HELMET: "helmet",
	ItemType.ARMOR: "armor",
	ItemType.BOOTS: "boots",
	ItemType.WEAPON: "weapon",
	ItemType.BACK: "back",
}


## Equipment slot id for an item type ("" if it can't be equipped).
static func slot_for_type(type: int) -> String:
	return SLOT_BY_TYPE.get(type, "")


func get_equipment_slot() -> String:
	return slot_for_type(item_type)


## {"hp", "attack", "move_speed"} at the current level, from the equipment formula.
## Empty for items without an equipment line.
func get_line_stats() -> Dictionary:
	if equipment_line.is_empty() or get_equipment_slot().is_empty():
		return {}
	var rarity_key := EquipmentBalance.rarity_name(rarity)
	if rarity_key.is_empty():
		return {}
	var level := clampi(enhancement_level, 1, maxi(max_upgrade_level, 1))
	return EquipmentBalance.compute(get_equipment_slot(), equipment_line, rarity_key, level)


func get_enhancement_multiplier() -> float:
	var safe_level := clampi(enhancement_level, 1, maxi(max_upgrade_level, 1))
	return pow(LEGACY_STAT_GROWTH_RATE, safe_level - 1)


func get_scaled_attack_bonus() -> int:
	var line := get_line_stats()
	if not line.is_empty():
		return int(line["attack"])
	return roundi(attack_bonus * get_enhancement_multiplier())


## Base equipment never carries DEF (owner decision 2026-11-08); it comes from socketed stones.
func get_scaled_defense_bonus() -> int:
	if not equipment_line.is_empty():
		return 0
	return roundi(defense_bonus * get_enhancement_multiplier())


func get_scaled_health_bonus() -> int:
	var line := get_line_stats()
	if not line.is_empty():
		return int(line["hp"])
	return roundi(health_bonus * get_enhancement_multiplier())


func get_scaled_speed_bonus() -> float:
	var line := get_line_stats()
	if not line.is_empty():
		return float(line["move_speed"])
	return speed_bonus * get_enhancement_multiplier()


func has_valid_upgrade_configuration() -> bool:
	return (
		can_upgrade
		and is_equippable()
		and upgrade_base_cost > 0
		and is_finite(upgrade_cost_rate)
		and upgrade_cost_rate >= 1.0
		and max_upgrade_level > 1
	)


func can_upgrade_further() -> bool:
	return has_valid_upgrade_configuration() and enhancement_level >= 1 and enhancement_level < max_upgrade_level


func get_upgrade_cost() -> int:
	if not can_upgrade_further():
		return 0
	return maxi(1, int(upgrade_base_cost * pow(upgrade_cost_rate, enhancement_level)))


## Get the color associated with item rarity
func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color(0.7, 0.7, 0.7, 1.0)  # Gray
		ItemRarity.UNCOMMON:
			return Color(0.3, 0.8, 0.3, 1.0)  # Green
		ItemRarity.RARE:
			return Color(0.3, 0.5, 1.0, 1.0)  # Blue
		ItemRarity.EPIC:
			return Color(0.7, 0.3, 0.9, 1.0)  # Purple
		ItemRarity.LEGENDARY:
			return Color(1.0, 0.6, 0.1, 1.0)  # Orange
		_:
			return Color.WHITE


## Check if this item can be equipped
func is_equippable() -> bool:
	return SLOT_BY_TYPE.has(item_type)


## Check if this item is consumable
func is_consumable() -> bool:
	return item_type == ItemType.CONSUMABLE or is_timed_buff()


## Every equipment piece has the same number of sockets (sheet 07 §4.1: 8).
func get_gem_slot_count() -> int:
	return GemCatalog.slots_per_holder() if is_equippable() else 0


## Socket array padded to the slot count ("" = empty). Read-only view.
func get_gem_sockets() -> Array[String]:
	var sockets := GemCatalog.empty_sockets() if is_equippable() else ([] as Array[String])
	for i in range(mini(gems.size(), sockets.size())):
		sockets[i] = gems[i]
	return sockets


func count_socketed_gems() -> int:
	var n := 0
	for id: String in gems:
		if not id.is_empty():
			n += 1
	return n


## True if this is a SEGMENT or MATERIAL (valid crafting input)
func is_crafting_material() -> bool:
	return item_type in [ItemType.SEGMENT, ItemType.MATERIAL]


## True for socket stones.
func is_gem() -> bool:
	return item_type == ItemType.GEM


## True if this is a timed buff consumable (crafted via AUGMENT type but used like a consumable)
func is_timed_buff() -> bool:
	return item_type == ItemType.AUGMENT and augment_type == AugmentType.TIMED_BUFF


## Get the icon texture (supports both direct texture and atlas)
func get_icon() -> Texture2D:
	if not icon_asset_id.is_empty():
		return ArtCatalog.texture(icon_asset_id, 2)
	if use_atlas_icon:
		# Debug: Check if atlas is initialized
		if ItemIconAtlas.sprite_sheet == null:
			push_warning("[ItemData] Atlas not initialized when getting icon for: %s" % id)
			return null
		
		# Try named icon first
		if not atlas_icon_name.is_empty():
			var atlas_icon := ItemIconAtlas.get_named_icon(atlas_icon_name)
			if atlas_icon:
				return atlas_icon
			else:
				push_warning("[ItemData] Named icon '%s' not found for item: %s" % [atlas_icon_name, id])
		# Fall back to row/col
		return ItemIconAtlas.get_icon(atlas_row, atlas_col)
	return icon
