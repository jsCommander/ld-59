class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")

# --- State ---

var valuation: int = 0
var level: int = 0
var game_level: int = 1
var timer_remaining: float = Constants.BASE_TOTAL_GAME_TIME
var _game_active: bool = false
var _awaiting_choice: bool = false

var sprint_number: int = 0
var sprint_slots: Array = []

var developers: Array[Developer] = []
var hired_data: Array[DeveloperData] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
var _empty_upgrades: Array[UpgradeData] = []

var _tick_timer: Timer

# --- Public ---

func get_dev_upgrades(dev_type: Constants.DevType) -> Array[UpgradeData]:
	if dev_type in dev_upgrades:
		return dev_upgrades[dev_type] as Array[UpgradeData]
	return _empty_upgrades


func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)


func get_level_up_upgrades() -> Array[UpgradeData]:
	var count: int = Balance.calculate_upgrade_choices(upgrades_taken)
	var result: Array[UpgradeData] = []
	var used_ids: Array[String] = []
	for i: int in count:
		var rarity: Constants.UpgradeRarity = Balance.roll_rarity(level)
		var pick: UpgradeData = _pick_upgrade_by_rarity(rarity, used_ids)
		if pick:
			result.append(pick)
			used_ids.append(pick.id)
	return result


func start_game() -> void:
	reset()
	developers.assign(Groups.get_all_of_type(get_tree(), "developer", Developer))
	_game_active = true
	_tick_timer.start()
	_generate_sprint()
	# Hire first dev at game start
	_awaiting_choice = true
	SB.developer_hire_requested.emit()


func reset() -> void:
	valuation = 0
	level = 0
	game_level = 1
	sprint_number = 0
	timer_remaining = Constants.BASE_TOTAL_GAME_TIME
	_game_active = false
	_awaiting_choice = false
	sprint_slots.clear()
	developers.clear()
	hired_data.clear()
	upgrades_taken.clear()
	global_upgrades.clear()
	dev_upgrades.clear()
	_tick_timer.stop()


func take_task(task: TaskData) -> TaskData:
	var idx: int = sprint_slots.find(task)
	if idx == -1:
		return null
	sprint_slots[idx] = null
	SB.task_queue_changed.emit(sprint_slots)
	if _all_slots_empty():
		_generate_sprint()
	return task


func hire_developer(dev_data: DeveloperData) -> void:
	var desk: Developer = Groups.get_first_filtered(get_tree(), "developer", func(d: Developer) -> bool: return not d.data) as Developer
	if not desk:
		Log.log_warn(name, "No empty desks available")
		return
	desk.data = dev_data
	developers.append(desk)
	hired_data.append(dev_data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[dev_data.dev_type])

# --- Lifecycle ---

func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.developer_chosen.connect(_on_developer_chosen)
	SB.task_requested.connect(_on_task_requested)
	_tick_timer = _create_tick_timer()


func _process(delta: float) -> void:
	if not _game_active or _awaiting_choice:
		return

	timer_remaining -= delta
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		_tick_timer.stop()
		SB.game_over.emit(valuation)
		return

# --- Handlers ---

func _on_task_requested(developer: Developer, task_position: Vector2) -> void:
	var available: Array[TaskData] = _get_available_tasks()
	if available.is_empty():
		return
	var task: TaskData
	if developer.data.task_select:
		task = developer.data.task_select.select(developer.data, available)
	else:
		task = available[0]
	var taken: TaskData = take_task(task)
	if taken:
		SB.task_assigned.emit(taken, developer, task_position)


func _on_tick() -> void:
	var elapsed: float = Constants.BASE_TOTAL_GAME_TIME - timer_remaining
	game_level = Balance.get_game_level(elapsed)
	SB.game_timer_changed.emit(timer_remaining)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_level_up()


func _on_developer_chosen(dev_data: DeveloperData) -> void:
	hire_developer(dev_data)
	_awaiting_choice = false


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s (level %d)" % [Constants.TaskType.keys()[task.task_type], task.level])

# --- Private ---

func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


# --- Sprint system ---

func _generate_sprint() -> void:
	sprint_number += 1
	var task_level: int = game_level
	var weights: Dictionary = Balance.calculate_task_type_weights(upgrades_taken)
	sprint_slots.clear()
	for i: int in Constants.SPRINT_SIZE:
		var template: TaskData = _pick_weighted_task(weights)
		var task: TaskData = template.duplicate()
		task.level = task_level
		var hp: float = Balance.get_task_hp(task_level)
		task.current_hp = hp
		task.max_hp = hp
		sprint_slots.append(task)
	SB.task_queue_changed.emit(sprint_slots)
	SB.sprint_number_changed.emit(sprint_number)
	Log.log_info(name, "Sprint %d: %d tasks at level %d" % [sprint_number, sprint_slots.size(), task_level])


func _all_slots_empty() -> bool:
	for slot: Variant in sprint_slots:
		if slot != null:
			return false
	return true


func _find_first_task() -> TaskData:
	for slot: Variant in sprint_slots:
		if slot != null:
			return slot as TaskData
	return null


func _get_available_tasks() -> Array[TaskData]:
	var tasks: Array[TaskData] = []
	for slot: Variant in sprint_slots:
		if slot != null:
			tasks.append(slot as TaskData)
	return tasks


# --- Upgrade application ---

func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	Log.log_info(name, "Applied upgrade: %s (%s)" % [upgrade.id, upgrade.display_name])


# --- Level-up ---

func _check_level_up() -> void:
	var next_threshold: int = get_xp_for_level(level + 1)
	if next_threshold <= 0:
		return  # max level reached
	if valuation >= next_threshold:
		level += 1
		_awaiting_choice = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
		if level in Constants.HIRE_LEVELS:
			SB.developer_hire_requested.emit()


func _apply_task_rewards(task: TaskData) -> void:
	var base_reward: int = int(task.max_hp)
	var reward_mult: float = Balance.calculate_reward_multiplier(upgrades_taken)
	var reward: int = int(base_reward * reward_mult)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		if not _awaiting_choice:
			_check_level_up()


# --- Upgrade selection ---

func _pick_random_from(pool: Array[UpgradeData]) -> UpgradeData:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	if _is_taken(upgrade.id):
		return false
	if upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if not _has_hired_dev_type(upgrade.target_dev_type):
			return false
	return true


func _is_taken(upgrade_id: String) -> bool:
	for taken: UpgradeData in upgrades_taken:
		if taken.id == upgrade_id:
			return true
	return false


func _has_hired_dev_type(dev_type: Constants.DevType) -> bool:
	for data: DeveloperData in hired_data:
		if data.dev_type == dev_type:
			return true
	return false


func _pick_upgrade_by_rarity(target_rarity: Constants.UpgradeRarity, exclude_ids: Array[String]) -> UpgradeData:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in DR.upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.id in exclude_ids:
			continue
		if upgrade.rarity == target_rarity:
			pool.append(upgrade)
	if pool.is_empty():
		# Fallback: try any rarity
		for upgrade: UpgradeData in DR.upgrades.values():
			if not _is_upgrade_available(upgrade):
				continue
			if upgrade.id in exclude_ids:
				continue
			pool.append(upgrade)
	return _pick_random_from(pool)


func _pick_weighted_task(weights: Dictionary) -> TaskData:
	var roll: float = randf()
	var cumulative: float = 0.0
	for task_type: Constants.TaskType in weights:
		cumulative += weights[task_type] as float
		if roll <= cumulative:
			match task_type:
				Constants.TaskType.FEATURE:
					return TASK_DATA_FEATURE
				Constants.TaskType.BUG:
					return TASK_DATA_BUG
	return TASK_DATA_FEATURE
