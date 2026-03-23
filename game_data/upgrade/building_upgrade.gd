class_name BuildingUpgrade
extends Resource

@export var upgrade_name: String
@export var icon: Texture2D
@export var cost: Array[RecipeIngredient] = []
@export var cost_function: CostFunction
@export var max_level: int = 0
@export var speed_bonus: float = 0.0
@export var extra_produce: int = 0


func get_scaled_cost(level: int) -> Array[RecipeIngredient]:
	if not cost_function:
		return cost
	var scaled: Array[RecipeIngredient] = []
	for ingredient: RecipeIngredient in cost:
		var ri: RecipeIngredient = RecipeIngredient.new()
		ri.product = ingredient.product
		ri.count = cost_function.get_cost(ingredient.count, level)
		scaled.append(ri)
	return scaled
