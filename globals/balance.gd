class_name Balance


static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var damage_mult: float = _calc_mult(Constants.UpgradeStat.DAMAGE, global_upgrades, dev_upgrades)
	return base * task_mult * damage_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData], boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var speed_mult: float = _calc_mult(Constants.UpgradeStat.SPEED, global_upgrades, dev_upgrades)
	var boost_mult: float = 1.0 + boost_stacks * Constants.BOOST_SPEED_MULT
	var interval: float = base / (speed_mult * boost_mult)
	return maxf(interval, Constants.SPEED_CAP)


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func get_task_hp(task_level: int) -> float:
	var clamped: int = clampi(task_level, 1, Constants.TASK_LEVEL_THRESHOLDS.size())
	return float(Constants.TASK_LEVEL_THRESHOLDS[clamped])


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.LEVEL_THRESHOLDS.size():
		return 0
	return Constants.LEVEL_THRESHOLDS[level - 1]


static func get_task_type_weights(game_level: int) -> Dictionary:
	var best_key: int = 1
	for key: int in Constants.TASK_TYPE_WEIGHTS:
		if key <= game_level and key > best_key:
			best_key = key
	return Constants.TASK_TYPE_WEIGHTS[best_key]


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


static func _calc_mult(stat: Constants.UpgradeStat, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0
	for upgrade: UpgradeData in global_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	for upgrade: UpgradeData in dev_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	return mult
