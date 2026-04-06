class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_clicked(task: TaskData)
signal task_finished(developer: Developer, task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_money_changed
signal resource_tech_debt_changed
signal valuation_changed

signal game_state_changed(state: Constants.GameState)
signal sprint_started
signal sprint_ended
