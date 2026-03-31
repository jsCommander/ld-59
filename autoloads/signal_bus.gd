class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal hire_requested(slot: Slot, developer_data: DeveloperData)
signal fire_requested(developer: Developer)

signal task_spawned(task_data: TaskData)
signal task_completed(developer: Developer, task_data: TaskData)
signal task_expired(task_data: TaskData)

signal task_drop_requested(task_data: TaskData, screen_pos: Vector2)
signal task_drop_consumed(task_data: TaskData)

signal queue_empty
signal sprint_started(sprint_number: int, duration: float)
signal sprint_ended(sprint_number: int)
signal sprint_tick(time_remaining: float)

signal money_changed
signal tech_debt_changed
