class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

var valuation: int = 0
var level: int = 0
var timer_remaining: float = Constants.GAME_DURATION
var _game_active: bool = false
var _awaiting_choice: bool = false

# Sprint state
var sprint_number: int = 0
var sprint_timer: float = 0.0
var sprint_duration: float = Constants.SPRINT_DURATION
var _sprint_active: bool = false

var task_queue: Array[TaskData] = []
var developers: Array[Developer] = []
var hired_data: Array[DeveloperData] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
var _empty_upgrades: Array[UpgradeData] = []

var _tick_timer: Timer


func get_dev_upgrades(dev_type: Constants.DevType) -> Array[UpgradeData]:
	if dev_type in dev_upgrades:
		return dev_upgrades[dev_type] as Array[UpgradeData]
	return _empty_upgrades


func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.developer_chosen.connect(_on_developer_chosen)
	_tick_timer = _create_tick_timer()


func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


func start_game() -> void:
	reset()
	developers.assign(Groups.get_all_of_type(get_tree(), "developer", Developer))
	_game_active = true
	_tick_timer.start()
	_start_sprint()


func reset() -> void:
	valuation = 0
	level = 0
	timer_remaining = Constants.GAME_DURATION
	_game_active = false
	_awaiting_choice = false
	sprint_number = 0
	sprint_timer = 0.0
	_sprint_active = false
	task_queue.clear()
	developers.clear()
	hired_data.clear()
	upgrades_taken.clear()
	global_upgrades.clear()
	dev_upgrades.clear()
	_tick_timer.stop()


func _on_tick() -> void:
	SB.game_timer_changed.emit(timer_remaining)


func _process(delta: float) -> void:
	if not _game_active or _awaiting_choice:
		return

	# Game timer
	timer_remaining -= delta
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		_sprint_active = false
		_tick_timer.stop()
		get_tree().paused = true
		SB.game_over.emit(valuation)
		return

	# Sprint timer
	if _sprint_active:
		sprint_timer -= delta
		SB.sprint_timer_changed.emit(sprint_timer, sprint_duration)


# --- Sprint system ---

func _start_sprint() -> void:
	sprint_number += 1
	sprint_duration = Balance.get_sprint_duration(global_upgrades)
	sprint_timer = sprint_duration
	_sprint_active = true
	_generate_sprint_tasks()
	SB.sprint_started.emit(sprint_number)
	Log.log_info(name, "Sprint %d started with %d tasks" % [sprint_number, task_queue.size()])


func _generate_sprint_tasks() -> void:
	var task_templates: Array[TaskData] = [TASK_DATA_FEATURE, TASK_DATA_BUG, TASK_DATA_REFACTOR]
	var difficulties: Array[int] = [1, 1, 2, 2, 3]
	for i: int in Constants.MAX_SPRINT_TASKS:
		var template: TaskData = task_templates[randi() % task_templates.size()]
		var task: TaskData = template.duplicate()
		task.difficulty = difficulties[randi() % difficulties.size()]
		_scale_task_hp(task)
		task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)


func _scale_task_hp(task: TaskData) -> void:
	var hp: float = Balance.scale_task_hp(task.difficulty, sprint_number)
	task.current_hp = hp
	task.max_hp = hp


func _check_sprint_complete() -> void:
	if not task_queue.is_empty():
		return
	# Check no dev is still working on a task
	for dev: Developer in developers:
		if dev._current_task:
			return
	_end_sprint()


func _end_sprint() -> void:
	var bonus: int = 0
	if sprint_timer > 0.0:
		var speed_ratio: float = sprint_timer / sprint_duration
		bonus = int(100.0 * sprint_number * speed_ratio)
		valuation += bonus
		SB.valuation_changed.emit()
	_sprint_active = false
	SB.sprint_ended.emit(sprint_number, bonus)
	Log.log_info(name, "Sprint %d ended. Bonus: %d" % [sprint_number, bonus])
	_check_level_up()
	if _game_active and not _awaiting_choice:
		_start_sprint()


# --- Upgrade application ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_hire_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.SPRINT:
		global_upgrades.append(upgrade)
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


func _check_hire_level() -> void:
	if level in Constants.HIRE_LEVELS:
		_awaiting_choice = true
		SB.developer_hire_requested.emit()
	else:
		_resume_after_choice()


# --- Level-up ---

func _check_level_up() -> void:
	if valuation >= get_xp_for_level(level + 1):
		level += 1
		_awaiting_choice = true
		get_tree().paused = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
	else:
		_resume_after_choice()


func _resume_after_choice() -> void:
	get_tree().paused = false
	if _game_active and not _sprint_active:
		_start_sprint()


func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)


# --- Task management ---

func take_task(task: TaskData) -> TaskData:
	if task not in task_queue:
		return null
	task_queue.erase(task)
	SB.task_queue_changed.emit(task_queue)
	return task


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s (difficulty %d)" % [Constants.TaskType.keys()[task.task_type], task.difficulty])
	_check_sprint_complete()


func _apply_task_rewards(task: TaskData) -> void:
	var reward: int = int(task.max_hp)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		_check_level_up()


# --- Developers ---

func hire_developer(dev_data: DeveloperData) -> void:
	var desk: Developer = Groups.get_first_filtered(get_tree(), "developer", func(d: Developer) -> bool: return not d.data) as Developer
	if not desk:
		Log.log_warn(name, "No empty desks available")
		return
	desk.data = dev_data
	developers.append(desk)
	hired_data.append(dev_data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[dev_data.dev_type])


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	hired_data.erase(developer.data)
	Log.log_info(name, "Fired %s" % Constants.DevType.keys()[developer.data.dev_type])


func _on_developer_chosen(dev_data: DeveloperData) -> void:
	hire_developer(dev_data)
	_awaiting_choice = false
	_check_level_up()
