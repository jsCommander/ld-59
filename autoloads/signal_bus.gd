class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_destroyed(task: TaskData)

signal task_requested(developer: Developer, task_position: Vector2)
signal task_assigned(task: TaskData, developer: Developer, task_position: Vector2)
signal task_fly_started(task: TaskData, developer: Developer)
signal task_fly_ended(task: TaskData, developer: Developer)

signal valuation_changed

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
signal developer_chosen(dev_data: DeveloperData)
