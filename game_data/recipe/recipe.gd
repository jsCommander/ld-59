class_name Recipe
extends Resource

@export var output: ProductData
@export var ingredients: Array[RecipeIngredient] = []
@export var produce_time: float = 5.0


func get_cost() -> Dictionary:
	var cost: Dictionary = {}
	for ingredient: RecipeIngredient in ingredients:
		cost[ingredient.product.id] = ingredient.count
	return cost
