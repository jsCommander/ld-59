class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])

signal task_drop_requested(task_data: TaskData, screen_pos: Vector2)
signal task_drop_consumed(task_data: TaskData)

signal sprint_execute_requested
signal sprint_started
signal sprint_ended

signal task_finished(developer: Developer, task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_money_changed
signal resource_tech_debt_changed
