class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")

var valuation: int = 0
var level: int = 0
var tech_debt: float = 0.0
var timer_remaining: float = Constants.GAME_DURATION
var _game_active: bool = false
var _awaiting_choice: bool = false

var _click_progress: int = 0
var _task_bag: Array[TaskData] = []

var task_queue: Array[TaskData] = []
var developers: Array[Developer] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
var _empty_upgrades: Array[UpgradeData] = []


func get_dev_upgrades(dev_type: Constants.DevType) -> Array[UpgradeData]:
	if dev_type in dev_upgrades:
		return dev_upgrades[dev_type] as Array[UpgradeData]
	return _empty_upgrades

var auto_click_unlocked: bool = false

var _tick_timer: Timer
var _auto_click_timer: Timer


func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.backlog_clicked.connect(_on_backlog_clicked)
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.tech_debt_produced.connect(_on_tech_debt_produced)
	_tick_timer = _create_tick_timer()


func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


func start_game() -> void:
	reset()
	_game_active = true
	_tick_timer.start()


func reset() -> void:
	valuation = 0
	level = 0
	tech_debt = 0.0
	timer_remaining = Constants.GAME_DURATION
	_game_active = false
	_awaiting_choice = false
	_click_progress = 0
	_task_bag.clear()
	task_queue.clear()
	developers.clear()
	upgrades_taken.clear()
	global_upgrades.clear()
	dev_upgrades.clear()
	auto_click_unlocked = false
	_tick_timer.stop()
	if _auto_click_timer:
		_auto_click_timer.stop()
		_auto_click_timer.queue_free()
		_auto_click_timer = null


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
		_tick_timer.stop()
		get_tree().paused = true
		SB.game_over.emit(valuation)
		return


func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)


# --- Upgrade application ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_hire_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
		if upgrade.stat == Constants.UpgradeStat.AUTO_CLICK_SPEED:
			_update_auto_click_timer()
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.UNLOCK:
		match upgrade.stat:
			Constants.UpgradeStat.AUTO_CLICK: _unlock_auto_click()
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


func _check_hire_level() -> void:
	if level in Constants.HIRE_LEVELS:
		_awaiting_choice = true
		SB.developer_hire_requested.emit()
	else:
		_check_level_up()


# --- Level-up ---

func _check_level_up() -> void:
	if valuation >= get_xp_for_level(level + 1):
		level += 1
		_awaiting_choice = true
		get_tree().paused = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
	else:
		get_tree().paused = false


# --- Backlog clicks ---

func _on_backlog_clicked(count: int) -> void:
	if not _game_active or _awaiting_choice:
		return
	if task_queue.size() >= Constants.BASE_QUEUE_SIZE:
		return
	_click_progress += count
	while _click_progress >= _get_clicks_needed():
		_click_progress -= _get_clicks_needed()
		_spawn_task_to_queue()
		SB.backlog_task_spawned.emit()


func _get_clicks_needed() -> int:
	return Balance.get_clicks_needed()


func _spawn_task_to_queue() -> void:
	if _task_bag.is_empty():
		_fill_task_bag()
	var task: TaskData = _task_bag.pop_front()
	_scale_task_hp(task)
	task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task spawned to queue (total: %d)" % task_queue.size())


# --- Auto-click ---

func _unlock_auto_click() -> void:
	if auto_click_unlocked:
		return
	auto_click_unlocked = true
	_auto_click_timer = Timer.new()
	_auto_click_timer.wait_time = Constants.BASE_AUTO_CLICK_INTERVAL
	_auto_click_timer.timeout.connect(_on_auto_click_tick)
	add_child(_auto_click_timer)
	if _game_active:
		_auto_click_timer.start()
	Log.log_info(name, "Auto-click unlocked")


func _on_auto_click_tick() -> void:
	var count_mult: float = Balance._calc_mult(Constants.UpgradeStat.AUTO_CLICK_COUNT, global_upgrades, [])
	var count: int = int(Constants.BASE_AUTO_CLICK_COUNT * count_mult)
	SB.backlog_clicked.emit(count)


func _update_auto_click_timer() -> void:
	if _auto_click_timer:
		var speed_mult: float = Balance._calc_mult(Constants.UpgradeStat.AUTO_CLICK_SPEED, global_upgrades, [])
		_auto_click_timer.wait_time = Constants.BASE_AUTO_CLICK_INTERVAL / speed_mult


# --- Task spawning ---

func _fill_task_bag() -> void:
	var bag_size: int = Constants.BASE_QUEUE_SIZE
	var bug_chance: float = tech_debt * Constants.BUG_SPAWN_MULTIPLIER
	var bug_count: int = int(bag_size * bug_chance)
	var feature_count: int = bag_size - bug_count
	for i: int in bug_count:
		_task_bag.append(TASK_DATA_BUG.duplicate())
	for i: int in feature_count:
		_task_bag.append(TASK_DATA_FEATURE.duplicate())
	_task_bag.shuffle()


func _scale_task_hp(task: TaskData) -> void:
	var minutes_elapsed: float = (Constants.GAME_DURATION - timer_remaining) / 60.0
	var hp: float = Balance.scale_task_hp(task.base_hp_mult, minutes_elapsed)
	task.current_hp = hp
	task.max_hp = hp


# --- Task management ---

func take_task(task: TaskData) -> TaskData:
	if task not in task_queue:
		return null
	task_queue.erase(task)
	SB.task_queue_changed.emit(task_queue)
	return task


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])


func _apply_task_rewards(task: TaskData) -> void:
	var reward: int = int(task.max_hp * task.base_reward_mult)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		_check_level_up()
	if task.base_debt_reduction > 0.0:
		increase_tech_debt(-task.base_debt_reduction)
	Log.log_info(name, "Task done: +%d valuation, -%.1f debt" % [reward, task.base_debt_reduction])


# --- Tech debt ---

func _on_tech_debt_produced(delta: float) -> void:
	increase_tech_debt(delta)


# --- Developers ---

func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])
	_awaiting_choice = false
	_check_level_up()


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)


func increase_tech_debt(delta: float) -> void:
	tech_debt = clampf(tech_debt + delta, 0.0, 100.0)
	SB.resource_tech_debt_changed.emit()
