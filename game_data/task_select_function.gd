class_name TaskSelectFunction extends Resource


func select(dev_data: DeveloperData, tasks: Array[TaskData]) -> TaskData:
	var best_task: TaskData = null
	var best_score: float = -1.0
	for task: TaskData in tasks:
		var score: float = Balance.get_task_mult(dev_data, task.task_type)
		if score > best_score:
			best_score = score
			best_task = task
	return best_task
