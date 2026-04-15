class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + global_damage) × (1 + type_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, stats: Dictionary) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_DAMAGE, stats)
	var type_field: String = Constants.STAT_FEATURE_DAMAGE if task_type == Constants.TaskType.FEATURE else Constants.STAT_BUG_DAMAGE
	var type_dmg_mult: float = 1.0 + _get_stat(type_field, stats)
	return base * task_mult * global_dmg_mult * type_dmg_mult


static func calculate_attack_speed(dev_data: DeveloperData, auto_boost_stacks: int = 0, player_boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var total_stacks: int = auto_boost_stacks + player_boost_stacks
	var boost_mult: float = 1.0 + total_stacks * Constants.BOOST_SPEED_MULT
	var interval: float = base / boost_mult
	return maxf(interval, Constants.SPEED_CAP)


## Boost power = number of stacks applied per auto click (1 + boost_power)
static func calculate_boost_stacks(stats: Dictionary) -> int:
	return 1 + int(_get_stat(Constants.STAT_BOOST_POWER, stats))


## Boost decay interval = (1/DECAY_RATE) × (1 + boost_duration)
static func calculate_boost_decay_interval(stats: Dictionary) -> float:
	var mult: float = 1.0 + _get_stat(Constants.STAT_BOOST_DURATION, stats)
	return (1.0 / Constants.BOOST_DECAY_RATE) * mult


## Auto click interval = BASE_INTERVAL / (1 + auto_click_speed). Returns 0 if no boost stats.
static func calculate_auto_click_interval(stats: Dictionary) -> float:
	var has_boost: bool = not is_zero_approx(_get_stat(Constants.STAT_BOOST_POWER, stats)) \
		or not is_zero_approx(_get_stat(Constants.STAT_BOOST_DURATION, stats)) \
		or not is_zero_approx(_get_stat(Constants.STAT_AUTO_CLICK_SPEED, stats))
	if not has_boost:
		return 0.0
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + _get_stat(Constants.STAT_AUTO_CLICK_SPEED, stats))


## Reward multiplier = 1 + reward_bonus
static func calculate_reward_multiplier(stats: Dictionary) -> float:
	return 1.0 + _get_stat(Constants.STAT_REWARD_BONUS, stats)


## Task type weights based on Feature/Bug Chance stats
static func calculate_task_type_weights(stats: Dictionary) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE + _get_stat(Constants.STAT_FEATURE_CHANCE, stats)
	var bug_w: float = Constants.BASE_BUG_CHANCE + _get_stat(Constants.STAT_BUG_CHANCE, stats)
	feature_w = maxf(feature_w, 1.0)
	bug_w = maxf(bug_w, 1.0)
	var total: float = feature_w + bug_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.BUG: bug_w / total,
	}


## Roll a rarity based on game_level (time-based) with rarity_luck bonus
static func roll_rarity(player_level: int, stats: Dictionary) -> Constants.UpgradeRarity:
	var bracket: int = clampi(player_level - 1, 0, Constants.RARITY_APPEARANCE_RATES.size() - 1)
	var weights: Dictionary = Constants.RARITY_APPEARANCE_RATES[bracket].duplicate()
	var luck: float = _get_stat(Constants.STAT_RARITY_LUCK, stats)
	if luck > 0.0:
		var common_w: float = weights[Constants.UpgradeRarity.COMMON] as float
		var shift: float = minf(luck, common_w - 0.05)
		if shift > 0.0:
			weights[Constants.UpgradeRarity.COMMON] = common_w - shift
			# Distribute to higher rarities proportionally
			var higher_total: float = 0.0
			for rarity: Constants.UpgradeRarity in weights:
				if rarity != Constants.UpgradeRarity.COMMON:
					higher_total += weights[rarity] as float
			if higher_total > 0.0:
				for rarity: Constants.UpgradeRarity in weights:
					if rarity != Constants.UpgradeRarity.COMMON:
						weights[rarity] = (weights[rarity] as float) + shift * ((weights[rarity] as float) / higher_total)
			else:
				weights[Constants.UpgradeRarity.UNCOMMON] = (weights[Constants.UpgradeRarity.UNCOMMON] as float) + shift
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
	const X10_EVERY_N_LEVELS: float = 8.0
	const CURVE_SHIFT: float = 0.1
	var clamped: int = clampi(player_level, 1, Constants.MAX_LEVEL)
	if clamped <= LINEAR_PHASE_CAP:
		return float(Constants.BASE_HP * clamped)
	return float(Constants.BASE_HP) * round(pow(10.0, clamped / X10_EVERY_N_LEVELS - CURVE_SHIFT))


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.MAX_LEVEL:
		return 0
	if level <= 4:
		return Constants.XP_BASE * level * (level + 1) / 2
	return Constants.XP_BASE * int(round(pow(2.0, level / 2.0 + 1.644)))


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Read a stat value from the totals dictionary
static func _get_stat(field: String, stats: Dictionary) -> float:
	return stats.get(field, 0.0)
