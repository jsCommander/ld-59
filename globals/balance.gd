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
	return base / (speed_mult * boost_mult)


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func scale_task_hp(difficulty: int, sprint_number: int) -> float:
	var sprint_mult: float = 1.0 + sprint_number * 0.3
	return Constants.BASE_HP * difficulty * sprint_mult


static func get_xp_for_level(level: int) -> int:
	return Constants.XP_BASE * int(pow(1.5, level - 1))


static func get_sprint_duration(global_upgrades: Array[UpgradeData]) -> float:
	var mult: float = _calc_mult(Constants.UpgradeStat.SPRINT_DURATION, global_upgrades, [])
	return Constants.SPRINT_DURATION * mult


static func _calc_mult(stat: Constants.UpgradeStat, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0
	for upgrade: UpgradeData in global_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	for upgrade: UpgradeData in dev_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	return mult
