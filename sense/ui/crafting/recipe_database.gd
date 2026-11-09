extends Node

## ╔════════════════════════════════════════════════════════════╗
## ║  RecipeDatabase — Autoload                                ║
## ║  Mirrors the ItemDatabase pattern:                        ║
## ║  - Dictionary of CraftingRecipe keyed by recipe_id        ║
## ║  - get_recipe(id) → CraftingRecipe                        ║
## ║  - get_recipes_by_category(cat) → Array[CraftingRecipe]   ║
## ╚════════════════════════════════════════════════════════════╝

var recipes: Dictionary = {}  # recipe_id: String → CraftingRecipe

const PROVISIONAL_RECIPE_EVIDENCE := (
	"Clean-room Emberfield recipe used for the local vertical slice. Treasure Hunter "
	+ "confirms crafting, ingredients, equipment/potion outputs, and tiers, but this "
	+ "recipe's exact item IDs, quantities, and balance values are not yet mapped."
)


func _ready() -> void:
	_create_recipes()


func get_recipe(recipe_id: String) -> CraftingRecipe:
	return recipes.get(recipe_id)


func get_all_recipes() -> Array:
	return recipes.values()


func get_recipes_by_category(category: CraftingRecipe.RecipeCategory) -> Array:
	var result: Array = []
	for recipe: CraftingRecipe in recipes.values():
		if recipe.category == category:
			result.append(recipe)
	return result


func register_recipe(recipe: CraftingRecipe, report_error: bool = true) -> bool:
	if recipe == null:
		return false
	if recipes.has(recipe.id):
		if report_error:
			push_error("RecipeDatabase: duplicate recipe id '%s'" % recipe.id)
		return false
	var errors := recipe.validate_catalog()
	if not errors.is_empty():
		if report_error:
			push_error("RecipeDatabase: rejected '%s': %s" % [recipe.id, "; ".join(errors)])
		return false
	recipes[recipe.id] = recipe
	return true


func _create_recipes() -> void:
	# === SOCKET STONE RECIPES (tier I; higher tiers come from fusing 6 → 1) ===
	# RecipeCategory.AUGMENT keeps its saved enum value; it now means "socket stone".

	_add_recipe("stone_fire", "Inferno Stone", "Cut a stone that sets targets burning.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "fire_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "stone_fire_1", "result_quantity": 1},
	])

	_add_recipe("stone_ice", "Frost Stone", "Cut a stone that slows targets.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "frost_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "stone_ice_1", "result_quantity": 1},
	])

	_add_recipe("stone_poison", "Venom Stone", "Cut a stone that poisons targets.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "venom_gland", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "stone_poison_1", "result_quantity": 1},
	])

	_add_recipe("stone_lifesteal", "Vampiric Stone", "Cut a stone that drains life on hit.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "spirit_essence", "quantity": 3}, {"item_id": "monster_bone", "quantity": 2}], "result_item_id": "stone_lifesteal_1", "result_quantity": 1},
	])

	_add_recipe("stone_critical", "Precision Stone", "Cut a stone that sharpens critical strikes.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 3}], "result_item_id": "stone_critical_1", "result_quantity": 1},
	])

	_add_recipe("stone_guard", "Guardian Stone", "Cut a stone that hardens the bearer.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "stone", "quantity": 6}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "stone_guard_1", "result_quantity": 1},
	])

	# === CONSUMABLE BUFF RECIPES ===

	_add_recipe("vitality_tonic", "Vitality Tonic", "Temporary max HP boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 1}], "result_item_id": "vitality_tonic_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "vitality_tonic_t2", "result_quantity": 1},
	])

	_add_recipe("speed_elixir", "Speed Elixir", "Temporary movement speed boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "frost_shard", "quantity": 1}], "result_item_id": "speed_elixir_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "blizzard_shard", "quantity": 2}], "result_item_id": "speed_elixir_t2", "result_quantity": 1},
	])

	_add_recipe("defense_brew", "Defense Brew", "Temporary defense boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "iron_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 1}], "result_item_id": "defense_brew_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "gold_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 3}], "result_item_id": "defense_brew_t2", "result_quantity": 1},
	])


## Helper to construct and register a recipe
func _add_recipe(id: String, recipe_name: String, desc: String, category: CraftingRecipe.RecipeCategory, tier_data: Array) -> void:
	var recipe := CraftingRecipe.new()
	recipe.id = id
	recipe.recipe_name = recipe_name
	recipe.description = desc
	recipe.category = category
	recipe.evidence_status = CraftingRecipe.EvidenceStatus.PROVISIONAL
	recipe.evidence_source = PROVISIONAL_RECIPE_EVIDENCE
	recipe.tiers.assign(tier_data)
	register_recipe(recipe)
