class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + global_damage) × (1 + type_damage) × (1 + stacks × boost_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, stats: Dictionary, boost_stacks: int = 0) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_DAMAGE, stats)
	var type_field: String = Constants.STAT_FEATURE_DAMAGE if task_type == Constants.TaskType.FEATURE else Constants.STAT_BUG_DAMAGE
	var type_dmg_mult: float = 1.0 + _get_stat(type_field, stats)
	var boost_dmg_mult: float = 1.0 + boost_stacks * _get_stat(Constants.STAT_BOOST_DAMAGE, stats)
	return base * task_mult * global_dmg_mult * type_dmg_mult * boost_dmg_mult


## Attack speed = base / ((1 + global_speed) × (1 + type_speed) × (1 + stacks × boost_duration)), clamped to SPEED_CAP
static func calculate_attack_speed(dev_data: DeveloperData, boost_stacks: int = 0, stats: Dictionary = {}, task_type: Constants.TaskType = Constants.TaskType.FEATURE) -> float:
	var base: float = dev_data.base_attack_speed
	var global_speed_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_SPEED, stats)
	var type_field: String = Constants.STAT_FEATURE_SPEED if task_type == Constants.TaskType.FEATURE else Constants.STAT_BUG_SPEED
	var type_speed_mult: float = 1.0 + _get_stat(type_field, stats)
	var boost_mult: float = 1.0 + boost_stacks * _get_stat(Constants.STAT_BOOST_DURATION, stats)
	var interval: float = base / (global_speed_mult * type_speed_mult * boost_mult)
	return maxf(interval, Constants.SPEED_CAP)


## Auto click interval = BASE_INTERVAL / (1 + auto_click_speed). Returns 0 if no auto_click_speed.
static func calculate_auto_click_interval(stats: Dictionary) -> float:
	var speed: float = _get_stat(Constants.STAT_AUTO_CLICK_SPEED, stats)
	if is_zero_approx(speed):
		return 0.0
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + speed)


## Task type weights based on Feature/Bug Chance stats
static func calculate_task_type_weights(stats: Dictionary) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE + _get_stat(Constants.STAT_FEATURE_CHANCE, stats)
	var bug_w: float = Constants.BASE_BUG_CHANCE + _get_stat(Constants.STAT_BUG_CHANCE, stats)
	feature_w = maxf(feature_w, 0.01)
	bug_w = maxf(bug_w, 0.01)
	var total: float = feature_w + bug_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.BUG: bug_w / total,
	}


## Roll a rarity based on player level
static func roll_rarity(player_level: int) -> Constants.UpgradeRarity:
	var bracket: int = clampi(player_level - 1, 0, Constants.RARITY_APPEARANCE_RATES.size() - 1)
	var weights: Dictionary = Constants.RARITY_APPEARANCE_RATES[bracket]
	var roll: float = randf()
	var cumulative: float = 0.0
	for rarity: Constants.UpgradeRarity in weights:
		cumulative += weights[rarity] as float
		if roll <= cumulative:
			return rarity
	return Constants.UpgradeRarity.COMMON


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func get_task_hp(player_level: int) -> float:
	const LINEAR_PHASE_CAP: int = 5
	const X2_EVERY_N_LEVELS: float = 2.0
	const CURVE_SHIFT: float = 0.4
	var clamped: int = maxi(player_level, 1)
	if clamped <= LINEAR_PHASE_CAP:
		return float(Constants.BASE_HP * clamped)
	return float(Constants.BASE_HP) * round(pow(2.0, clamped / X2_EVERY_N_LEVELS - CURVE_SHIFT))


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Read a stat value from the totals dictionary
static func _get_stat(field: String, stats: Dictionary) -> float:
	return stats.get(field, 0.0)
