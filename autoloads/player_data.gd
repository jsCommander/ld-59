class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_REFACTORING: TaskData = preload("res://game_data/task/task_data_refactoring.tres")

# --- State ---

var valuation: int = 0
var level: int = 0
var timer_remaining: float = Constants.BASE_TOTAL_GAME_TIME
var _game_active: bool = false
var pending_upgrades: Array[Constants.UpgradeType] = []

var sprint_number: int = 0
var sprint_time: float = 0.0
var sprint_slots: Array = []
var _sprints_to_level_up: int = 0

var developers: Array[Developer] = []
var hired_data: Array[DeveloperData] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var total_stats: Dictionary = {}

var is_user_knows_how_to_boost: bool = false
var player_boost_count: int = 0
var _tick_timer: Timer
var _boost_help_timer: Timer

# --- Public ---

func get_level_up_upgrades() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var used_ids: Array[String] = []
	var used_groups: Array[Constants.UpgradeGroup] = []
	var rarities: Array[Constants.UpgradeRarity] = Balance.distribute_rarities(level, Constants.UPGRADE_CHOICES)
	for rarity: Constants.UpgradeRarity in rarities:
		var pick: UpgradeData = _pick_upgrade_by_rarity(rarity, used_ids, used_groups)
		if pick:
			result.append(pick)
			used_ids.append(pick.id)
			used_groups.append(pick.group)
	return result


func start_game(desks: Array[Developer]) -> void:
	reset()
	developers.assign(desks)
	timer_remaining = Balance.get_game_duration()
	_game_active = true
	# Emit initial state so UI resets
	SB.valuation_changed.emit()
	SB.game_timer_changed.emit(timer_remaining)
	SB.level_up.emit(level)
	SB.pending_upgrades_changed.emit()
	SB.task_queue_changed.emit(sprint_slots)
	_tick_timer.start()
	_generate_sprint()
	# Hire first dev at game start
	SB.developer_hire_requested.emit()


func reset() -> void:
	valuation = 0
	level = 0
	sprint_number = 0
	sprint_time = 0.0
	timer_remaining = Constants.BASE_TOTAL_GAME_TIME
	_game_active = false
	is_user_knows_how_to_boost = false
	player_boost_count = 0
	pending_upgrades.clear()
	sprint_slots.clear()
	developers.clear()
	hired_data.clear()

	upgrades_taken.clear()
	global_upgrades.clear()
	total_stats.clear()
	_tick_timer.stop()
	_boost_help_timer.stop()


func take_task(task: TaskData) -> TaskData:
	var idx: int = sprint_slots.find(task)
	if idx == -1:
		return null
	sprint_slots[idx] = null
	SB.task_queue_changed.emit(sprint_slots)
	if _all_slots_empty():
		_sprints_to_level_up += 1
		if _sprints_to_level_up >= Balance.get_sprints_to_level_up(level):
			_sprints_to_level_up = 0
			_level_up()
		_generate_sprint()
	return task


func hire_developer(dev_data: DeveloperData) -> void:
	var desk: Developer = _find_next_desk()
	if not desk:
		Log.log_warn(name, "No empty desks available")
		return
	desk.data = dev_data
	hired_data.append(dev_data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[dev_data.dev_type])

# --- Lifecycle ---

func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.developer_chosen.connect(_on_developer_chosen)
	SB.task_requested.connect(_on_task_requested)
	SB.player_boost_applied.connect(_on_player_boost_applied)
	_tick_timer = _create_tick_timer()
	_boost_help_timer = _create_boost_help_timer()



# --- Handlers ---

func _on_player_boost_applied(_developer: Developer) -> void:
	if is_user_knows_how_to_boost:
		return
	player_boost_count += 1
	if player_boost_count < Constants.BOOST_HELP_CLICKS_TO_LEARN:
		return
	is_user_knows_how_to_boost = true
	_boost_help_timer.stop()
	SB.boost_help_hide_requested.emit()


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
	if not _game_active:
		return
	timer_remaining -= 1.0
	sprint_time += 1.0
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		_tick_timer.stop()
		SB.game_over.emit(valuation)
		return
	SB.game_timer_changed.emit(timer_remaining)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)


func _on_developer_chosen(dev_data: DeveloperData) -> void:
	hire_developer(dev_data)
	if not is_user_knows_how_to_boost and _boost_help_timer.is_stopped():
		_boost_help_timer.start()


func _on_boost_help_timer_timeout() -> void:
	if is_user_knows_how_to_boost:
		return
	SB.boost_help_show_requested.emit()


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s (level %d)" % [Constants.TaskType.keys()[task.task_type], task.level])

# --- Private ---

func _find_next_desk() -> Developer:
	for desk: Developer in developers:
		if not desk.data:
			return desk
	return null



func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


func _create_boost_help_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = Constants.BOOST_HELP_DELAY
	timer.one_shot = true
	timer.timeout.connect(_on_boost_help_timer_timeout)
	add_child(timer)
	return timer


# --- Sprint system ---

func _generate_sprint() -> void:
	sprint_number += 1
	sprint_time = 0.0
	var weights: Dictionary = Balance.calculate_task_type_weights(total_stats)
	var sprint_size: int = _get_sprint_size()
	var feature_count: int = roundi(sprint_size * (weights[Constants.TaskType.FEATURE] as float))
	var refactoring_count: int = sprint_size - feature_count
	sprint_slots.clear()
	for i: int in feature_count:
		_add_sprint_task(TASK_DATA_FEATURE, level)
	for i: int in refactoring_count:
		_add_sprint_task(TASK_DATA_REFACTORING, level)
	sprint_slots.shuffle()
	SB.task_queue_changed.emit(sprint_slots)
	Log.log_info(name, "Level %d: %d tasks" % [level, sprint_slots.size()])


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


func _get_sprint_size() -> int:
	var result: int = Constants.SPRINT_SIZES[0]["size"]
	for bracket: Dictionary in Constants.SPRINT_SIZES:
		if level >= bracket["min_level"]:
			result = bracket["size"]
	return result


# --- Upgrade application ---

func _apply_upgrade(upgrade: UpgradeData) -> void:
	global_upgrades.append(upgrade)
	_recalculate_total_stats()
	Log.log_info(name, "Applied upgrade: %s (%s)" % [upgrade.id, upgrade.display_name])


func _recalculate_total_stats() -> void:
	total_stats.clear()
	for field: String in Constants.STAT_ORDER:
		var total: float = 0.0
		for upgrade: UpgradeData in global_upgrades:
			total += upgrade.get(field) as float
		if not is_zero_approx(total):
			total_stats[field] = total


# --- Level-up ---

func _level_up() -> void:
	level += 1
	SB.level_up.emit(level)
	Log.log_info(name, "Level up! Level %d" % level)
	if level in Constants.HIRE_LEVELS:
		pending_upgrades.append(Constants.UpgradeType.HIRE)
	pending_upgrades.append(Constants.UpgradeType.UPGRADE)
	SB.pending_upgrades_changed.emit()


func _apply_task_rewards(task: TaskData) -> void:
	var reward: int = int(task.max_hp)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()


# --- Upgrade selection ---

func _pick_random_from(pool: Array[UpgradeData]) -> UpgradeData:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	var limit: int = Constants.RARITY_MAX_COUNT_DICT[upgrade.rarity]
	var count: int = 0
	for taken: UpgradeData in upgrades_taken:
		if taken.id == upgrade.id:
			count += 1
	return count < limit


func _pick_upgrade_by_rarity(target_rarity: Constants.UpgradeRarity, exclude_ids: Array[String], exclude_groups: Array[Constants.UpgradeGroup]) -> UpgradeData:
	# Try: target rarity + unused group
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in DR.upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.id in exclude_ids:
			continue
		if upgrade.group in exclude_groups:
			continue
		if not _is_upgrade_useful(upgrade):
			continue
		if upgrade.rarity == target_rarity:
			pool.append(upgrade)
	if not pool.is_empty():
		return _pick_random_from(pool)
	# Fallback 1: any rarity + unused group
	for upgrade: UpgradeData in DR.upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.id in exclude_ids:
			continue
		if upgrade.group in exclude_groups:
			continue
		if not _is_upgrade_useful(upgrade):
			continue
		pool.append(upgrade)
	if not pool.is_empty():
		return _pick_random_from(pool)
	# Fallback 2: ignore group constraint
	for upgrade: UpgradeData in DR.upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.id in exclude_ids:
			continue
		if not _is_upgrade_useful(upgrade):
			continue
		pool.append(upgrade)
	return _pick_random_from(pool)


## Skip upgrades whose positive stats are all already capped (speed, auto click).
func _is_upgrade_useful(upgrade: UpgradeData) -> bool:
	var has_positive: bool = false
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = upgrade.get(field) as float
		if value <= 0.0:
			continue
		has_positive = true
		if _is_stat_useful(field):
			return true
	return not has_positive


func _is_stat_useful(field: String) -> bool:
	match field:
		Constants.STAT_AUTO_CLICK_SPEED:
			return not Balance.is_auto_click_capped(total_stats)
		_:
			return true


func _add_sprint_task(template: TaskData, task_level: int) -> void:
	var task: TaskData = template.duplicate()
	task.level = task_level
	var hp: float = Balance.get_task_hp(task_level)
	task.current_hp = hp
	task.max_hp = hp
	sprint_slots.append(task)
