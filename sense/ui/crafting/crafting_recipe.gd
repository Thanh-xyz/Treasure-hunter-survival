class_name CraftingRecipe
extends Resource

## ╔════════════════════════════════════════════════════════════╗
## ║                  CRAFTING RECIPE                           ║
## ╠════════════════════════════════════════════════════════════╣
## ║  Each recipe has 1-3 tiers.                               ║
## ║  Higher tiers use rarer ingredients → stronger output.    ║
## ║                                                           ║
## ║  Recipe "flame_augment":                                  ║
## ║  ┌─────┬──────────────────────────┬───────────────────┐   ║
## ║  │ T1  │ 3× fire_shard + 2× iron │ flame_augment_t1  │   ║
## ║  │ T2  │ 3× inferno + 2× gold    │ flame_augment_t2  │   ║
## ║  │ T3  │ 3× hellfire + 1× m_bone │ flame_augment_t3  │   ║
## ║  └─────┴──────────────────────────┴───────────────────┘   ║
## ╚════════════════════════════════════════════════════════════╝

enum RecipeCategory {
	AUGMENT,         ## Output is an AUGMENT item (permanent or active skill)
	CONSUMABLE_BUFF  ## Output is a timed buff item
}

enum EvidenceStatus {
	CONFIRMED,
	INFERRED,
	PROVISIONAL,
}

@export var id: String = ""
@export var recipe_name: String = ""
@export var description: String = ""
@export var category: RecipeCategory = RecipeCategory.AUGMENT
@export var evidence_status: EvidenceStatus = EvidenceStatus.PROVISIONAL
@export_multiline var evidence_source: String = ""

## Array of tier definitions. Each tier is a Dictionary:
## {
##   "tier": int,                                        # 1, 2, or 3
##   "ingredients": Array[Dictionary],                   # [{"item_id": "fire_shard", "quantity": 3}, ...]
##   "result_item_id": String,                           # ID in ItemDatabase (e.g. "flame_augment_t1")
##   "result_quantity": int                              # Usually 1
## }
@export var tiers: Array[Dictionary] = []


## Validate structural integrity and catalog references without mutating inventory.
func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.strip_edges().is_empty():
		errors.append("recipe id is empty")
	elif id != id.strip_edges():
		errors.append("recipe id is not canonical")
	if recipe_name.strip_edges().is_empty():
		errors.append("recipe name is empty")
	if evidence_source.strip_edges().is_empty():
		errors.append("recipe evidence source is empty")
	if tiers.is_empty():
		errors.append("recipe has no tiers")
		return errors

	var seen_tiers := {}
	for tier_index in range(tiers.size()):
		var tier_data: Dictionary = tiers[tier_index]
		var prefix := "tier[%d]" % tier_index
		var raw_tier: Variant = tier_data.get("tier", null)
		var tier := 0
		if typeof(raw_tier) != TYPE_INT:
			errors.append("%s tier is not an integer" % prefix)
		else:
			tier = raw_tier
			if tier <= 0:
				errors.append("%s has a non-positive tier" % prefix)
			elif seen_tiers.has(tier):
				errors.append("%s duplicates tier %d" % [prefix, tier])
			else:
				seen_tiers[tier] = true

		var ingredients: Variant = tier_data.get("ingredients", [])
		if not ingredients is Array or ingredients.is_empty():
			errors.append("%s has no ingredients" % prefix)
		else:
			var seen_ingredients := {}
			for ingredient_index in range(ingredients.size()):
				var ingredient: Variant = ingredients[ingredient_index]
				var ingredient_prefix := "%s ingredient[%d]" % [prefix, ingredient_index]
				if not ingredient is Dictionary:
					errors.append("%s is not a dictionary" % ingredient_prefix)
					continue
				var raw_item_id: Variant = ingredient.get("item_id", null)
				if typeof(raw_item_id) != TYPE_STRING:
					errors.append("%s has a non-string item id" % ingredient_prefix)
				else:
					var item_id: String = raw_item_id
					if item_id.is_empty():
						errors.append("%s has an empty item id" % ingredient_prefix)
					elif item_id != item_id.strip_edges():
						errors.append("%s item id is not canonical" % ingredient_prefix)
					elif seen_ingredients.has(item_id):
						errors.append("%s duplicates item %s" % [ingredient_prefix, item_id])
					elif ItemDatabase.get_item(item_id) == null:
						errors.append("%s references unknown item %s" % [ingredient_prefix, item_id])
					else:
						seen_ingredients[item_id] = true
				var raw_quantity: Variant = ingredient.get("quantity", null)
				if typeof(raw_quantity) != TYPE_INT:
					errors.append("%s quantity is not an integer" % ingredient_prefix)
				elif raw_quantity <= 0:
					errors.append("%s has a non-positive quantity" % ingredient_prefix)

		var raw_result_item_id: Variant = tier_data.get("result_item_id", null)
		if typeof(raw_result_item_id) != TYPE_STRING:
			errors.append("%s result item id is not a string" % prefix)
		else:
			var result_item_id: String = raw_result_item_id
			if result_item_id.is_empty():
				errors.append("%s has an empty result item id" % prefix)
			elif result_item_id != result_item_id.strip_edges():
				errors.append("%s result item id is not canonical" % prefix)
			elif ItemDatabase.get_item(result_item_id) == null:
				errors.append("%s references unknown result item %s" % [prefix, result_item_id])
		var raw_result_quantity: Variant = tier_data.get("result_quantity", null)
		if typeof(raw_result_quantity) != TYPE_INT:
			errors.append("%s result quantity is not an integer" % prefix)
		elif raw_result_quantity <= 0:
			errors.append("%s has a non-positive result quantity" % prefix)
	return errors


## Check if the player can craft a specific tier
func can_craft(inventory: InventoryData, tier: int) -> bool:
	var tier_data := _get_tier_data(tier)
	if tier_data.is_empty():
		return false
	for ingredient: Dictionary in tier_data.get("ingredients", []):
		var item_id: String = ingredient.get("item_id", "")
		var quantity: int = ingredient.get("quantity", 0)
		if not inventory.has_item(item_id, quantity):
			return false
	return true


## Returns the highest tier the player can currently craft (0 = none)
func get_highest_craftable_tier(inventory: InventoryData) -> int:
	var best := 0
	for tier_data: Dictionary in tiers:
		var t: int = tier_data.get("tier", 0)
		if can_craft(inventory, t):
			best = maxi(best, t)
	return best


## Get ingredient list for a specific tier (for UI display)
func get_ingredients(tier: int) -> Array[Dictionary]:
	var tier_data := _get_tier_data(tier)
	var raw: Array = tier_data.get("ingredients", [])
	var result: Array[Dictionary] = []
	result.assign(raw)
	return result


## Get result item ID for a specific tier
func get_result_item_id(tier: int) -> String:
	var tier_data := _get_tier_data(tier)
	return tier_data.get("result_item_id", "")


## Get result quantity for a specific tier
func get_result_quantity(tier: int) -> int:
	var tier_data := _get_tier_data(tier)
	return tier_data.get("result_quantity", 1)


## Get max tier available for this recipe
func get_max_tier() -> int:
	var max_t := 0
	for t: Dictionary in tiers:
		max_t = maxi(max_t, t.get("tier", 0))
	return max_t


func _get_tier_data(tier: int) -> Dictionary:
	for t: Dictionary in tiers:
		if t.get("tier", 0) == tier:
			return t
	return {}
