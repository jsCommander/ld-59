class_name Balance


static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var damage_mult: float = _calc_mult(Constants.UpgradeStat.DAMAGE, global_upgrades, dev_upgrades)
	return base * task_mult * damage_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = dev_data.base_attack_speed
	var speed_mult: float = _calc_mult(Constants.UpgradeStat.SPEED, global_upgrades, dev_upgrades)
	return base / speed_mult


static func calculate_debt(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DEBT_PER_TASK
	var debt_mult: float = dev_data.base_debt_mult * _calc_mult(Constants.UpgradeStat.DEBT, global_upgrades, dev_upgrades)
	return base * debt_mult


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	match task_type:
		Constants.TaskType.FEATURE: return dev_data.base_feature_mult
		Constants.TaskType.BUG: return dev_data.base_bug_mult
	return 1.0


static func scale_task_hp(base_hp_mult: float, minutes_elapsed: float) -> float:
	return Constants.BASE_HP * base_hp_mult * pow(2.0, minutes_elapsed)


static func get_xp_for_level(level: int) -> int:
	return Constants.XP_BASE * int(pow(1.5, level - 1))


static func get_clicks_needed() -> int:
	return Constants.BASE_CLICKS_PER_TASK


static func _calc_mult(stat: Constants.UpgradeStat, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0
	for upgrade: UpgradeData in global_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	for upgrade: UpgradeData in dev_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	return mult
