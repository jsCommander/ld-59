class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

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

# Cached multipliers
var global_damage_mult: float = 1.0
var global_speed_mult: float = 1.0
var global_debt_mult: float = 1.0
var vibecoder_damage_mult: float = 1.0
var vibecoder_debt_mult: float = 1.0
var regular_damage_mult: float = 1.0
var regular_speed_mult: float = 1.0
var senior_damage_mult: float = 1.0
var senior_debt_mult: float = 1.0
var auto_click_unlocked: bool = false
var auto_click_count_mult: float = 1.0
var auto_click_speed_mult: float = 1.0

var _tick_timer: Timer
var _auto_click_timer: Timer


func _ready() -> void:
	SB.developer_attack.connect(_on_developer_attack)
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.backlog_clicked.connect(_on_backlog_clicked)
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
	global_damage_mult = 1.0
	global_speed_mult = 1.0
	global_debt_mult = 1.0
	vibecoder_damage_mult = 1.0
	vibecoder_debt_mult = 1.0
	regular_damage_mult = 1.0
	regular_speed_mult = 1.0
	senior_damage_mult = 1.0
	senior_debt_mult = 1.0
	auto_click_unlocked = false
	auto_click_count_mult = 1.0
	auto_click_speed_mult = 1.0
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
	return Constants.XP_BASE * int(pow(2, lvl - 1))


# --- Multiplier queries ---

func get_type_damage_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.VIBECODER: return vibecoder_damage_mult
		Constants.DevType.REGULAR: return regular_damage_mult
		Constants.DevType.SENIOR: return senior_damage_mult
	return 1.0


func get_type_speed_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.REGULAR: return regular_speed_mult
	return 1.0


func get_type_debt_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.VIBECODER: return vibecoder_debt_mult
		Constants.DevType.SENIOR: return senior_debt_mult
	return 1.0


# --- Upgrade application ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_hire_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		match upgrade.stat:
			Constants.UpgradeStat.DAMAGE: global_damage_mult *= upgrade.multiplier
			Constants.UpgradeStat.SPEED: global_speed_mult *= upgrade.multiplier
			Constants.UpgradeStat.DEBT: global_debt_mult *= upgrade.multiplier
			Constants.UpgradeStat.AUTO_CLICK_COUNT: auto_click_count_mult *= upgrade.multiplier
			Constants.UpgradeStat.AUTO_CLICK_SPEED:
				auto_click_speed_mult *= upgrade.multiplier
				_update_auto_click_timer()
	elif upgrade.upgrade_type == Constants.UpgradeType.UNLOCK:
		match upgrade.stat:
			Constants.UpgradeStat.AUTO_CLICK: _unlock_auto_click()
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		var dt: Constants.DevType = upgrade.target_dev_type
		match upgrade.stat:
			Constants.UpgradeStat.DAMAGE:
				match dt:
					Constants.DevType.VIBECODER: vibecoder_damage_mult *= upgrade.multiplier
					Constants.DevType.REGULAR: regular_damage_mult *= upgrade.multiplier
					Constants.DevType.SENIOR: senior_damage_mult *= upgrade.multiplier
			Constants.UpgradeStat.SPEED:
				match dt:
					Constants.DevType.REGULAR: regular_speed_mult *= upgrade.multiplier
			Constants.UpgradeStat.DEBT:
				match dt:
					Constants.DevType.VIBECODER: vibecoder_debt_mult *= upgrade.multiplier
					Constants.DevType.SENIOR: senior_debt_mult *= upgrade.multiplier
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
	return Constants.BASE_CLICKS_PER_TASK


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
	var count: int = int(Constants.BASE_AUTO_CLICK_COUNT * auto_click_count_mult)
	SB.backlog_clicked.emit(count)


func _update_auto_click_timer() -> void:
	if _auto_click_timer:
		_auto_click_timer.wait_time = Constants.BASE_AUTO_CLICK_INTERVAL / auto_click_speed_mult


# --- Task spawning ---

func _fill_task_bag() -> void:
	var bag_size: int = Constants.BASE_QUEUE_SIZE
	var bug_chance: float = tech_debt * Constants.BUG_SPAWN_MULTIPLIER
	var refactor_chance: float = tech_debt * Constants.REFACTOR_SPAWN_MULTIPLIER
	var bug_count: int = int(bag_size * bug_chance)
	var refactor_count: int = int(bag_size * refactor_chance)
	var feature_count: int = bag_size - bug_count - refactor_count
	for i: int in bug_count:
		_task_bag.append(TASK_DATA_BUG.duplicate())
	for i: int in refactor_count:
		_task_bag.append(TASK_DATA_REFACTOR.duplicate())
	for i: int in feature_count:
		_task_bag.append(TASK_DATA_FEATURE.duplicate())
	_task_bag.shuffle()


func _scale_task_hp(task: TaskData) -> void:
	var minutes_elapsed: float = (Constants.GAME_DURATION - timer_remaining) / 60.0
	var hp: float = Constants.BASE_HP * task.base_hp_mult * pow(2.0, minutes_elapsed)
	task.current_hp = hp
	task.max_hp = hp


# --- Combat ---

func _on_developer_attack(developer: Developer) -> void:
	if task_queue.is_empty():
		return
	var task: TaskData = task_queue[0]
	var damage: float = _calculate_damage(developer, task.task_type)
	var actual_damage: float = minf(damage, task.current_hp)
	var debt_delta: float = _calculate_debt(developer, actual_damage)
	task.current_hp -= damage
	developer.show_damage(int(damage))
	increase_tech_debt(debt_delta)
	SB.task_hp_changed.emit(task, task.current_hp, task.max_hp)
	if task.current_hp <= 0.0:
		task_queue.pop_front()
		_on_task_destroyed(task)


func _calculate_damage(developer: Developer, task_type: Constants.TaskType) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = _get_task_mult(developer.data, task_type)
	var type_mult: float = get_type_damage_mult(developer.data.dev_type)
	var global_mult: float = global_damage_mult
	return base * task_mult * type_mult * global_mult


func _get_task_mult(data: DeveloperData, task_type: Constants.TaskType) -> float:
	match task_type:
		Constants.TaskType.FEATURE: return data.base_feature_mult
		Constants.TaskType.BUG: return data.base_bug_mult
		Constants.TaskType.REFACTOR: return data.base_refactor_mult
	return 1.0


func _calculate_debt(developer: Developer, damage: float) -> float:
	return Constants.BASE_DEBT_PER_HP * damage * developer.data.base_debt_mult * get_type_debt_mult(developer.data.dev_type) * global_debt_mult


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	SB.task_destroyed.emit(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])


func _apply_task_rewards(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			valuation += int(task.max_hp)
			SB.valuation_changed.emit()
			_check_level_up()
			Log.log_info(name, "Feature done: +%d valuation (total: %d)" % [int(task.max_hp), valuation])
		Constants.TaskType.BUG:
			Log.log_info(name, "Bug fixed")
		Constants.TaskType.REFACTOR:
			increase_tech_debt(-Constants.DEBT_PER_TASK)
			Log.log_info(name, "Refactor done: -%.1f debt" % Constants.DEBT_PER_TASK)


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
