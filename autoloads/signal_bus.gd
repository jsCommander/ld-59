class_name SignalBus extends BaseSignalBus

@warning_ignore("unused_signal")
signal entity_selected(target: Node2D, popup_position: Vector2)
@warning_ignore("unused_signal")
signal selection_cleared

@warning_ignore("unused_signal")
signal task_queue_changed(slots: Array)
@warning_ignore("unused_signal")
signal task_destroyed(task: TaskData)

@warning_ignore("unused_signal")
signal task_requested(developer: Developer, task_position: Vector2)
@warning_ignore("unused_signal")
signal task_assigned(task: TaskData, developer: Developer, task_position: Vector2)
@warning_ignore("unused_signal")
signal task_fly_started(task: TaskData, developer: Developer)
@warning_ignore("unused_signal")
signal task_fly_ended(task: TaskData, developer: Developer)

@warning_ignore("unused_signal")
signal valuation_changed

@warning_ignore("unused_signal")
signal game_timer_changed(remaining: float)
@warning_ignore("unused_signal")
signal level_up(level: int)
@warning_ignore("unused_signal")
signal game_over(valuation: int)
@warning_ignore("unused_signal")
signal upgrade_chosen(upgrade: UpgradeData)
@warning_ignore("unused_signal")
signal developer_hire_requested
@warning_ignore("unused_signal")
signal developer_chosen(dev_data: DeveloperData)
@warning_ignore("unused_signal")
signal pending_upgrades_changed
@warning_ignore("unused_signal")
signal player_boost_applied(developer: Developer)
@warning_ignore("unused_signal")
signal auto_boost_applied(developer: Developer)
@warning_ignore("unused_signal")
signal boost_help_show_requested
@warning_ignore("unused_signal")
signal boost_help_hide_requested
