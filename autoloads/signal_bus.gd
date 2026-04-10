class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal valuation_changed

signal sprint_started(sprint_number: int)
signal sprint_ended(sprint_number: int, bonus: int)
signal sprint_timer_changed(remaining: float, total: float)

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
