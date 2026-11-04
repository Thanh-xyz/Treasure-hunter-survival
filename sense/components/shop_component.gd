extends Node
class_name ShopComponent

## Reusable component for handling shop purchases
## Manages gold transactions and item purchases for any NPC shop
## Usage: Add as child to shop NPC, connect buy_requested signal from UI

signal purchase_successful(item: Dictionary, remaining_gold: int)
signal purchase_failed(reason: String, item: Dictionary)

## Process a purchase request from the shop UI
func process_purchase(item: Dictionary) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("ShopComponent: Player not found!")
		purchase_failed.emit("Player not found", item)
		return false
	
	if not player.inventory:
		push_error("ShopComponent: Player has no inventory!")
		purchase_failed.emit("Player has no inventory", item)
		return false
	
	var inventory: InventoryData = player.inventory
	var item_id: String = item.get("id", "")
	
	# Get item data from ItemDatabase
	var item_data: ItemData = ItemDatabase.get_item(item_id)
	if item_data == null:
		push_error("ShopComponent: Item '%s' not found in ItemDatabase!" % item_id)
		purchase_failed.emit("Item not found", item)
		return false
	var item_name := item_data.name
	var price := item_data.buy_price
	if price <= 0:
		purchase_failed.emit("Item not for sale", item)
		return false

	# Price and capacity are committed together from authoritative item data.
	if inventory.gold < price:
		print("Not enough gold! Need %d, have %d" % [price, inventory.gold])
		purchase_failed.emit("Not enough gold", item)
		return false
	
	var additions: Array[Dictionary] = [{"item": item_data, "quantity": 1}]
	if not inventory.transact([], additions, -price):
		print("Inventory full! Cannot add item.")
		purchase_failed.emit("Inventory full", item)
		return false
	
	print("✓ Purchased %s for %d gold! Remaining: %d gold" % [item_name, price, inventory.gold])
	purchase_successful.emit(item, inventory.gold)
	return true

## Get player's current gold amount
func get_player_gold() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		return player.inventory.gold
	return 0
