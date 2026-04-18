class_name TaskSelectFunctionCompensating extends TaskSelectFunction


func select(_dev_data: DeveloperData, tasks: Array[TaskData]) -> TaskData:
	var counts: Dictionary[Constants.TaskType, int] = {}
	for task: TaskData in tasks:
		counts[task.task_type] = counts.get(task.task_type, 0) + 1
	var target_type: Constants.TaskType = tasks[0].task_type
	var best_count: int = -1
	for task_type: Constants.TaskType in counts.keys():
		if counts[task_type] > best_count:
			best_count = counts[task_type]
			target_type = task_type
	for task: TaskData in tasks:
		if task.task_type == target_type:
			return task
	return tasks[0]
