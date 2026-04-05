class_name CostFunctionExponential
extends CostFunction


func get_cost(base_cost: int, level: int) -> int:
	return base_cost * int(pow(2, level - 1))
