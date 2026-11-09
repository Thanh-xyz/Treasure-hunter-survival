class_name InventoryData
extends Resource

## Inventory data manager - handles item storage and equipment
##
## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                      INVENTORY STRUCTURE                              ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║                                                                       ║
## ║  ┌─────────────────────┐    ┌───────────────────────────────────────┐ ║
## ║  │   EQUIPMENT SLOTS   │    │           INVENTORY GRID              │ ║
## ║  │                     │    │                                       │ ║
## ║  │  [Helmet]           │    │  [00][01][02][03][04][05][06][07]     │ ║
## ║  │  [Armor]  [Weapon]  │    │  [08][09][10][11][12][13][14][15]     │ ║
## ║  │  [Boots]  [Shield]  │    │  [16][17][18][19][20][21][22][23]     │ ║
## ║  │  [Acc1]   [Acc2]    │    │  [24][25][26][27][28][29][30][31]     │ ║
## ║  │                     │    │  ...                                  │ ║
## ║  └─────────────────────┘    └───────────────────────────────────────┘ ║
## ║                                                                       ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal inventory_changed
signal equipment_changed(slot_type: String)
signal equipment_upgraded(slot_type: String, item_id: String, level: int, cost: int)
signal gems_changed(equip_slot: String)
signal gold_changed(amount: int)
signal diamonds_changed(amount: int)

const INVENTORY_SIZE: int = 32  # 8 columns x 4 rows
## The five equipment slots (EQUIPMENT_SYSTEM_PROPOSAL.md). Shield and accessories were retired in save v6.
const EQUIPMENT_SLOTS := ["helmet", "armor", "boots", "weapon", "back"]
## Stone stat -> passive effect handled by PassiveEffectProcessor. DEF is a flat stat instead.
const GEM_EFFECTS := {
	"crit_chance": ItemData.PassiveEffect.CRIT_CHANCE,
	"crit_damage": ItemData.PassiveEffect.CRIT_DAMAGE,
	"life_steal": ItemData.PassiveEffect.LIFE_STEAL,
	"dodge": ItemData.PassiveEffect.DODGE,
	"accuracy": ItemData.PassiveEffect.ACCURACY,
	"regeneration": ItemData.PassiveEffect.REGENERATION,
	"reflection": ItemData.PassiveEffect.THORNS,
	"fire_damage": ItemData.PassiveEffect.BURN_ON_HIT,
	"ice_slow": ItemData.PassiveEffect.FREEZE_ON_HIT,
	"poison_damage": ItemData.PassiveEffect.POISON_ON_HIT,
}

# Equipment slots
var equipped_helmet: ItemData = null
var equipped_armor: ItemData = null
var equipped_boots: ItemData = null
var equipped_weapon: ItemData = null
var equipped_back: ItemData = null

# Inventory grid - array of {item: ItemData, quantity: int}
var inventory_slots: Array[Dictionary] = []

# Currency
var _gold: int = 0
var gold: int:
	get:
		return _gold
	set(value):
		_gold = maxi(value, 0)
		gold_changed.emit(_gold)

var _diamonds: int = 0
var diamonds: int:
	get:
		return _diamonds
	set(value):
		_diamonds = maxi(value, 0)
		diamonds_changed.emit(_diamonds)


func _init() -> void:
	# Initialize empty inventory slots
	inventory_slots.clear()
	for i in range(INVENTORY_SIZE):
		inventory_slots.append({"item": null, "quantity": 0})


## Add item to inventory, returns remaining quantity that couldn't be added
func add_item(item: ItemData, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return quantity
	
	var remaining := quantity
	
	# If stackable, try to add to existing stacks first
	if item.stackable:
		for slot in inventory_slots:
			if slot.item != null and slot.item.id == item.id:
				var can_add := mini(item.max_stack - slot.quantity, remaining)
				if can_add > 0:
					slot.quantity += can_add
					remaining -= can_add
				if remaining <= 0:
					break
	
	# Add to empty slots
	if remaining > 0:
		for slot in inventory_slots:
			if slot.item == null:
				var add_amount := mini(item.max_stack if item.stackable else 1, remaining)
				slot.item = item
				slot.quantity = add_amount
				remaining -= add_amount
				if remaining <= 0:
					break
	
	if remaining < quantity:
		inventory_changed.emit()
	return remaining


## Apply item removals and additions as one inventory mutation.
## Each entry is {"item": ItemData, "quantity": int}. Nothing changes on failure.
func transact_items(removals: Array[Dictionary], additions: Array[Dictionary]) -> bool:
	return transact(removals, additions, 0)


## Commit item and currency changes together. Signals observe the final combined state.
func transact(removals: Array[Dictionary], additions: Array[Dictionary], gold_delta: int = 0, diamond_delta: int = 0) -> bool:
	var resulting_gold := gold + gold_delta
	var resulting_diamonds := diamonds + diamond_delta
	if resulting_gold < 0 or resulting_diamonds < 0:
		return false
	var simulated := _copy_slots(inventory_slots)
	for entry: Dictionary in removals:
		var item := entry.get("item") as ItemData
		var quantity := int(entry.get("quantity", 0))
		if item == null or quantity <= 0 or not _remove_from_slots(simulated, item.id, quantity):
			return false
	for entry: Dictionary in additions:
		var item := entry.get("item") as ItemData
		var quantity := int(entry.get("quantity", 0))
		if item == null or quantity <= 0 or _add_to_slots(simulated, item, quantity) > 0:
			return false
	inventory_slots = simulated
	# Commit every domain before publishing signals so observers never see a
	# partially applied item/currency transaction.
	if gold_delta != 0:
		_gold = resulting_gold
	if diamond_delta != 0:
		_diamonds = resulting_diamonds
	if gold_delta != 0:
		gold_changed.emit(_gold)
	if diamond_delta != 0:
		diamonds_changed.emit(_diamonds)
	if not removals.is_empty() or not additions.is_empty():
		inventory_changed.emit()
	return true


func _copy_slots(source: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: Dictionary in source:
		result.append({"item": slot.get("item"), "quantity": int(slot.get("quantity", 0))})
	return result


func _remove_from_slots(slots: Array[Dictionary], item_id: String, quantity: int) -> bool:
	var available := 0
	for slot: Dictionary in slots:
		var slot_item := slot.get("item") as ItemData
		if slot_item != null and slot_item.id == item_id:
			available += int(slot.get("quantity", 0))
	if available < quantity:
		return false
	var remaining := quantity
	for slot: Dictionary in slots:
		var slot_item := slot.get("item") as ItemData
		if slot_item == null or slot_item.id != item_id:
			continue
		var remove_amount := mini(int(slot.get("quantity", 0)), remaining)
		slot.quantity = int(slot.get("quantity", 0)) - remove_amount
		remaining -= remove_amount
		if int(slot.quantity) <= 0:
			slot.item = null
			slot.quantity = 0
		if remaining <= 0:
			break
	return true


func _remove_at_from_slots(slots: Array[Dictionary], index: int, quantity: int) -> bool:
	if index < 0 or index >= slots.size() or quantity <= 0:
		return false
	var slot: Dictionary = slots[index]
	if slot.get("item") == null or int(slot.get("quantity", 0)) < quantity:
		return false
	slot.quantity = int(slot.get("quantity", 0)) - quantity
	if int(slot.quantity) <= 0:
		slot.item = null
		slot.quantity = 0
	return true


func _add_to_slots(slots: Array[Dictionary], item: ItemData, quantity: int) -> int:
	var remaining := quantity
	if item.stackable:
		for slot: Dictionary in slots:
			var slot_item := slot.get("item") as ItemData
			if slot_item == null or slot_item.id != item.id:
				continue
			var can_add := mini(item.max_stack - int(slot.get("quantity", 0)), remaining)
			if can_add > 0:
				slot.quantity = int(slot.get("quantity", 0)) + can_add
				remaining -= can_add
			if remaining <= 0:
				return 0
	for slot: Dictionary in slots:
		if slot.get("item") != null:
			continue
		var add_amount := mini(item.max_stack if item.stackable else 1, remaining)
		slot.item = item
		slot.quantity = add_amount
		remaining -= add_amount
		if remaining <= 0:
			break
	return remaining


## Remove item from inventory by index
func remove_item_at(index: int, quantity: int = 1) -> bool:
	if index < 0 or index >= inventory_slots.size() or quantity <= 0:
		return false
	
	var slot := inventory_slots[index]
	if slot.item == null or int(slot.quantity) < quantity:
		return false
	
	slot.quantity -= quantity
	if slot.quantity <= 0:
		slot.item = null
		slot.quantity = 0
	
	inventory_changed.emit()
	return true


## Remove item by ItemData reference
func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null or quantity <= 0:
		return false
	var removals: Array[Dictionary] = [{"item": item, "quantity": quantity}]
	return transact_items(removals, [])


## Sell one item from an exact slot at its authoritative catalog price.
## Returns the credited gold, or 0 when the slot is stale or the item is not sellable.
func sell_item_at(index: int, expected_item_id: String = "") -> int:
	if index < 0 or index >= inventory_slots.size():
		return 0
	var slot: Dictionary = inventory_slots[index]
	var item := slot.get("item") as ItemData
	if item == null or int(slot.get("quantity", 0)) <= 0:
		return 0
	if not expected_item_id.is_empty() and item.id != expected_item_id:
		return 0
	var catalog_item := ItemDatabase.get_item(item.id)
	if catalog_item == null:
		return 0
	var sell_price := catalog_item.sell_price
	if sell_price <= 0:
		return 0
	var simulated := _copy_slots(inventory_slots)
	if not _remove_at_from_slots(simulated, index, 1):
		return 0
	inventory_slots = simulated
	gold = gold + sell_price
	inventory_changed.emit()
	return sell_price


## Get item at index
func get_item_at(index: int) -> Dictionary:
	if index < 0 or index >= inventory_slots.size():
		return {"item": null, "quantity": 0}
	return inventory_slots[index]


## Check if inventory has item
func has_item(item_id: String, quantity: int = 1) -> bool:
	var total := 0
	for slot in inventory_slots:
		if slot.item != null and slot.item.id == item_id:
			total += slot.quantity
	return total >= quantity


## Get total quantity of item
func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in inventory_slots:
		if slot.item != null and slot.item.id == item_id:
			total += slot.quantity
	return total


## Sort inventory: group by item type, then rarity (desc), then name
func sort_inventory() -> void:
	# Collect all non-empty slots
	var items: Array[Dictionary] = []
	for slot in inventory_slots:
		if slot.item != null:
			items.append({"item": slot.item, "quantity": slot.quantity})

	# Sort: item_type ascending, rarity descending, name ascending
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_item: ItemData = a.item
		var b_item: ItemData = b.item
		# Equipment first, then consumables, then materials, then segments, then augments
		var type_order_a := _get_sort_type_order(a_item.item_type)
		var type_order_b := _get_sort_type_order(b_item.item_type)
		if type_order_a != type_order_b:
			return type_order_a < type_order_b
		# Higher rarity first within same type
		if a_item.rarity != b_item.rarity:
			return a_item.rarity > b_item.rarity
		# Alphabetical by name
		return a_item.name.naturalnocasecmp_to(b_item.name) < 0
	)

	# Rebuild inventory: sorted items first, then empty slots
	for i in range(INVENTORY_SIZE):
		if i < items.size():
			inventory_slots[i] = items[i]
		else:
			inventory_slots[i] = {"item": null, "quantity": 0}

	inventory_changed.emit()


## Sort order for item types (lower = earlier)
func _get_sort_type_order(item_type: ItemData.ItemType) -> int:
	match item_type:
		ItemData.ItemType.WEAPON:     return 0
		ItemData.ItemType.ARMOR:      return 1
		ItemData.ItemType.HELMET:     return 2
		ItemData.ItemType.BOOTS:      return 3
		ItemData.ItemType.BACK:       return 4
		ItemData.ItemType.CONSUMABLE: return 6
		ItemData.ItemType.MATERIAL:   return 7
		ItemData.ItemType.QUEST:      return 8
		ItemData.ItemType.SEGMENT:    return 9
		ItemData.ItemType.AUGMENT:    return 10
		ItemData.ItemType.GEM:        return 11
		_: return 99


## Swap two inventory slots
func swap_slots(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= inventory_slots.size():
		return
	if index_b < 0 or index_b >= inventory_slots.size():
		return
	
	var temp := inventory_slots[index_a]
	inventory_slots[index_a] = inventory_slots[index_b]
	inventory_slots[index_b] = temp
	inventory_changed.emit()


## Equip item from inventory slot
func equip_item(inventory_index: int) -> bool:
	var slot := get_item_at(inventory_index)
	if slot.item == null or not slot.item.is_equippable():
		return false
	
	var item: ItemData = slot.item
	var equipped_item: ItemData = null
	var slot_type := ""
	
	slot_type = item.get_equipment_slot()
	if slot_type.is_empty():
		return false
	equipped_item = get_equipped(slot_type)
	_set_equipped(slot_type, item)

	# Remove item from inventory
	inventory_slots[inventory_index].item = null
	inventory_slots[inventory_index].quantity = 0

	# Place previously equipped item at the SAME inventory index so the
	# hotbar slot can show the swapped-in equipment automatically.
	if equipped_item != null:
		inventory_slots[inventory_index].item = equipped_item
		inventory_slots[inventory_index].quantity = 1

	equipment_changed.emit(slot_type)
	inventory_changed.emit()
	return true


## Unequip item from equipment slot
## If target_index is provided, place item directly in that slot
func unequip_item(slot_type: String, target_index: int = -1) -> bool:
	if not EQUIPMENT_SLOTS.has(slot_type):
		return false
	var item := get_equipped(slot_type)
	if item == null:
		return false
	var simulated := _copy_slots(inventory_slots)
	var replacement: ItemData = null
	var placed := false
	if target_index >= 0 and target_index < simulated.size():
		var target_slot: Dictionary = simulated[target_index]
		var target_item := target_slot.get("item") as ItemData
		if target_item == null:
			target_slot.item = item
			target_slot.quantity = 1
			placed = true
		elif target_item.is_equippable() and _item_fits_slot(target_item, slot_type):
			replacement = target_item
			target_slot.item = item
			target_slot.quantity = 1
			placed = true
	if not placed and _add_to_slots(simulated, item, 1) > 0:
		return false
	inventory_slots = simulated
	_set_equipped(slot_type, replacement)
	equipment_changed.emit(slot_type)
	inventory_changed.emit()
	return true


## Helper to set equipped item by slot type
func _set_equipped(slot_type: String, item: ItemData) -> void:
	match slot_type:
		"helmet": equipped_helmet = item
		"armor": equipped_armor = item
		"boots": equipped_boots = item
		"weapon": equipped_weapon = item
		"back": equipped_back = item


## Check if item fits in slot type
func _item_fits_slot(item: ItemData, slot_type: String) -> bool:
	if item == null:
		return true
	return EQUIPMENT_SLOTS.has(slot_type) and item.get_equipment_slot() == slot_type


## Swap equipment between two equipment slots
func swap_equipment(from_slot: String, to_slot: String) -> bool:
	var from_item := get_equipped(from_slot)
	var to_item := get_equipped(to_slot)
	
	# Verify both items fit in swapped slots
	if not _item_fits_slot(from_item, to_slot):
		return false
	if not _item_fits_slot(to_item, from_slot):
		return false
	
	_set_equipped(from_slot, to_item)
	_set_equipped(to_slot, from_item)
	
	equipment_changed.emit(from_slot)
	equipment_changed.emit(to_slot)
	return true


## Get equipped item by slot type
func get_equipped(slot_type: String) -> ItemData:
	match slot_type:
		"helmet": return equipped_helmet
		"armor": return equipped_armor
		"boots": return equipped_boots
		"weapon": return equipped_weapon
		"back": return equipped_back
		_: return null


## Upgrade one equipped item level as a single economy/equipment transaction.
## The caller supplies only a stable slot ID; cost and growth come from ItemData.
func upgrade_equipment(slot_type: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot_type):
		return false
	var equipment := get_equipped(slot_type)
	if equipment == null or not equipment.can_upgrade_further():
		return false
	var cost := equipment.get_upgrade_cost()
	if cost <= 0 or gold < cost:
		return false

	var upgraded := equipment.duplicate() as ItemData
	if upgraded == null:
		return false
	upgraded.gems = equipment.gems.duplicate()
	upgraded.enhancement_level = equipment.enhancement_level + 1

	# Commit the item first so every gold/equipment observer sees final state.
	_set_equipped(slot_type, upgraded)
	gold = gold - cost
	equipment_changed.emit(slot_type)
	equipment_upgraded.emit(slot_type, upgraded.id, upgraded.enhancement_level, cost)
	return true


func count_equipment_at_or_above_level(minimum_level: int) -> int:
	if minimum_level < 1:
		return 0
	var count := 0
	for slot_type: String in EQUIPMENT_SLOTS:
		var item := get_equipped(slot_type)
		if item != null and item.enhancement_level >= minimum_level:
			count += 1
	return count


func count_equipped_items() -> int:
	var count := 0
	for slot_type: String in EQUIPMENT_SLOTS:
		if get_equipped(slot_type) != null:
			count += 1
	return count


func count_equipment_at_or_above_rarity(minimum_rarity: int) -> int:
	if minimum_rarity < ItemData.ItemRarity.COMMON or minimum_rarity > ItemData.ItemRarity.LEGENDARY:
		return 0
	var count := 0
	for slot_type: String in EQUIPMENT_SLOTS:
		var item := get_equipped(slot_type)
		if item != null and int(item.rarity) >= minimum_rarity:
			count += 1
	return count


## Calculate total equipment bonuses. Socket stones add DEF (Guardian Stone); every other
## stone stat is a combat modifier (see get_gem_stats / get_all_gem_passive_effects).
func get_total_attack_bonus() -> int:
	var total := 0
	for item: ItemData in _equipped_items():
		if item != null:
			total += item.get_scaled_attack_bonus()
	return total


func get_total_defense_bonus() -> int:
	var total := 0
	for item: ItemData in _equipped_items():
		if item != null:
			total += item.get_scaled_defense_bonus()
	return total + roundi(float(get_gem_stats().get("defense", 0.0)))


func get_total_health_bonus() -> int:
	var total := 0
	for item: ItemData in _equipped_items():
		if item != null:
			total += item.get_scaled_health_bonus()
	return total


## Equipment move speed is capped by data (max_equipment_move_speed).
func get_total_speed_bonus() -> float:
	var equipment := 0.0
	for item: ItemData in _equipped_items():
		if item != null:
			equipment += item.get_scaled_speed_bonus()
	var cap := EquipmentBalance.max_equipment_move_speed()
	if cap > 0:
		equipment = minf(equipment, float(cap))
	return equipment


## Equipped items in slot order (null for empty slots).
func _equipped_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for slot: String in EQUIPMENT_SLOTS:
		out.append(get_equipped(slot))
	return out


## Use consumable item at index
func use_item(index: int) -> Dictionary:
	var slot := get_item_at(index)
	if slot.item == null or not slot.item.is_consumable():
		return {"success": false}

	var item: ItemData = slot.item

	# Handle timed buff consumables (crafted AUGMENT with TIMED_BUFF type)
	if item.is_timed_buff():
		var buff_result := {
			"success": true,
			"item_id": item.id,
			"consumed_quantity": 1,
			"is_timed_buff": true,
			"buff_item": item,  # Pass full ItemData so BuffComponent can read it
			"heal_amount": 0,
			"stamina_restore": 0.0,
			"effect_duration": item.buff_duration
		}
		remove_item_at(index, 1)
		return buff_result

	# Handle regular consumables (existing logic)
	var result := {
		"success": true,
		"item_id": item.id,
		"consumed_quantity": 1,
		"is_timed_buff": false,
		"heal_amount": item.heal_amount,
		"stamina_restore": item.stamina_restore,
		"effect_duration": item.effect_duration
	}

	remove_item_at(index, 1)
	return result


# =============================================================================
# SOCKET STONES (brainstorm sheet 07 §4, plan phase B)
# =============================================================================

## Socket the stone at inventory_index into equip_slot's socket gem_index (must be empty).
## One transaction: the bag loses the stone and the equipment gains it, or nothing changes.
func socket_gem(equip_slot: String, gem_index: int, inventory_index: int) -> bool:
	var equipment := get_equipped(equip_slot)
	if equipment == null or gem_index < 0 or gem_index >= equipment.get_gem_slot_count():
		return false
	var stone_slot := get_item_at(inventory_index)
	var stone: ItemData = stone_slot.get("item")
	if stone == null or not stone.is_gem():
		return false
	var sockets := equipment.get_gem_sockets()
	if not sockets[gem_index].is_empty():
		return false
	var simulated := _copy_slots(inventory_slots)
	if not _remove_at_from_slots(simulated, inventory_index, 1):
		return false
	sockets[gem_index] = stone.id
	_commit_sockets(equip_slot, equipment, sockets, simulated)
	return true


## Return the stone in socket gem_index to the bag. Fails (nothing lost) when the bag is full.
func unsocket_gem(equip_slot: String, gem_index: int) -> bool:
	var equipment := get_equipped(equip_slot)
	if equipment == null or gem_index < 0 or gem_index >= equipment.get_gem_slot_count():
		return false
	var sockets := equipment.get_gem_sockets()
	var stone: ItemData = ItemDatabase.get_item(sockets[gem_index]) if not sockets[gem_index].is_empty() else null
	if stone == null:
		return false
	var simulated := _copy_slots(inventory_slots)
	if _add_to_slots(simulated, stone, 1) > 0:
		return false
	sockets[gem_index] = ""
	_commit_sockets(equip_slot, equipment, sockets, simulated)
	return true


func _commit_sockets(equip_slot: String, equipment: ItemData, sockets: Array[String], new_slots: Array[Dictionary]) -> void:
	var updated := equipment.duplicate() as ItemData
	updated.enhancement_level = equipment.enhancement_level
	updated.gems = sockets
	inventory_slots = new_slots
	_set_equipped(equip_slot, updated)
	gems_changed.emit(equip_slot)
	equipment_changed.emit(equip_slot)
	inventory_changed.emit()


## Fuse GemCatalog.fuse_cost() stones of one type and tier from the bag into one stone of the
## next tier. No failure chance; nothing is consumed unless the result fits.
func fuse_gems(stone_id: String) -> bool:
	var result_id := GemCatalog.fuse_result(stone_id)
	var source := ItemDatabase.get_item(stone_id)
	var result := ItemDatabase.get_item(result_id) if not result_id.is_empty() else null
	if source == null or result == null:
		return false
	return transact([{"item": source, "quantity": GemCatalog.fuse_cost()}], [{"item": result, "quantity": 1}])


## Stone ids socketed across all equipped items.
func get_equipped_gem_sockets() -> Array:
	var arrays: Array = []
	for item: ItemData in _equipped_items():
		if item != null:
			arrays.append(item.get_gem_sockets())
	return arrays


## Capped stone totals for everything worn, plus optional extra holders (pet, mount).
func get_gem_stats(extra_socket_arrays: Array = []) -> Dictionary:
	var arrays := get_equipped_gem_sockets()
	arrays.append_array(extra_socket_arrays)
	return GemCatalog.total_stats(arrays)


## Stone stats as passive-effect entries {effect, value} for PassiveEffectProcessor.
func get_all_gem_passive_effects(extra_socket_arrays: Array = []) -> Array[Dictionary]:
	var totals := get_gem_stats(extra_socket_arrays)
	var effects: Array[Dictionary] = []
	for stat: String in GEM_EFFECTS:
		var value := float(totals.get(stat, 0.0))
		if value > 0.0:
			effects.append({"effect": GEM_EFFECTS[stat], "value": value})
	return effects
