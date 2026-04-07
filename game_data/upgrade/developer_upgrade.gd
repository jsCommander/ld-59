class_name DeveloperUpgrade
extends Resource

@export var upgrade_name: String
@export var base_cost: int = 100
@export var cost_function: CostFunction
@export var max_level: int = 0
@export var damage_bonus: float = 0.0


func get_scaled_cost(level: int) -> int:
	if not cost_function:
		return base_cost
	return cost_function.get_cost(base_cost, level)
