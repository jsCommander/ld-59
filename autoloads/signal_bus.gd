class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_tech_debt_changed
signal valuation_changed

signal backlog_clicked(count: int)
signal backlog_task_spawned

signal tech_debt_produced(delta: float)

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
