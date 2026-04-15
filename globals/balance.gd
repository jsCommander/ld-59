class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + sum global_damage) × (1 + sum type_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _sum_stat(Constants.STAT_GLOBAL_DAMAGE, upgrades)
	var type_field: String = Constants.STAT_FEATURE_DAMAGE if task_type == Constants.TaskType.FEATURE else Constants.STAT_BUG_DAMAGE
	var type_dmg_mult: float = 1.0 + _sum_stat(type_field, upgrades)
	return base * task_mult * global_dmg_mult * type_dmg_mult


static func calculate_attack_speed(dev_data: DeveloperData, auto_boost_stacks: int = 0, player_boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var total_stacks: int = auto_boost_stacks + player_boost_stacks
	var boost_mult: float = 1.0 + total_stacks * Constants.BOOST_SPEED_MULT
	var interval: float = base / boost_mult
	return maxf(interval, Constants.SPEED_CAP)


## Boost power = number of stacks applied per auto click (1 + sum boost_power)
static func calculate_boost_stacks(upgrades: Array[UpgradeData]) -> int:
	return 1 + int(_sum_stat(Constants.STAT_BOOST_POWER, upgrades))


## Boost decay interval = (1/DECAY_RATE) × (1 + sum boost_duration)
static func calculate_boost_decay_interval(upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0 + _sum_stat(Constants.STAT_BOOST_DURATION, upgrades)
	return (1.0 / Constants.BOOST_DECAY_RATE) * mult


## Auto click interval = BASE_INTERVAL / (1 + sum auto_click_speed). Returns 0 if no boost upgrade.
static func calculate_auto_click_interval(upgrades: Array[UpgradeData]) -> float:
	var sum_speed: float = 0.0
	var has_boost: bool = false
	for upgrade: UpgradeData in upgrades:
		if not is_zero_approx(upgrade.boost_power) or not is_zero_approx(upgrade.boost_duration) or not is_zero_approx(upgrade.auto_click_speed):
			has_boost = true
		sum_speed += upgrade.auto_click_speed
	if not has_boost:
		return 0.0
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + sum_speed)


## Reward multiplier = 1 + sum reward_bonus (across ALL upgrades, global + all devs)
static func calculate_reward_multiplier(all_upgrades: Array[UpgradeData]) -> float:
	var total: float = 0.0
	for upgrade: UpgradeData in all_upgrades:
		total += upgrade.reward_bonus
	return 1.0 + total


## Task type weights based on Feature/Bug Chance stats (across ALL upgrades, global + all devs)
static func calculate_task_type_weights(all_upgrades: Array[UpgradeData]) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE
	var bug_w: float = Constants.BASE_BUG_CHANCE
	for upgrade: UpgradeData in all_upgrades:
		feature_w += upgrade.feature_chance
		bug_w += upgrade.bug_chance
	feature_w = maxf(feature_w, 1.0)
	bug_w = maxf(bug_w, 1.0)
	var total: float = feature_w + bug_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.BUG: bug_w / total,
	}


## Roll a rarity based on game_level (time-based) with rarity_luck bonus from upgrades
static func roll_rarity(player_level: int, all_upgrades: Array[UpgradeData]) -> Constants.UpgradeRarity:
	var bracket: int = clampi(player_level - 1, 0, Constants.RARITY_APPEARANCE_RATES.size() - 1)
	var weights: Dictionary = Constants.RARITY_APPEARANCE_RATES[bracket].duplicate()
	# Apply rarity_luck: shift weight from Common to higher rarities
	var luck: float = 0.0
	for upgrade: UpgradeData in all_upgrades:
		luck += upgrade.rarity_luck
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
	var clamped: int = clampi(player_level, 1, Constants.TASK_HP_BY_LEVEL.size())
	return float(Constants.TASK_HP_BY_LEVEL[clamped])


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.MAX_LEVEL:
		return 0
	if level <= 4:
		return Constants.XP_BASE * level * (level + 1) / 2
	return Constants.XP_BASE * int(round(pow(2.0, level / 2.0 + 1.644)))


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Sum a stat field across all upgrades (additive stacking)
static func _sum_stat(field: String, upgrades: Array[UpgradeData]) -> float:
	var total: float = 0.0
	for upgrade: UpgradeData in upgrades:
		total += upgrade.get(field) as float
	return total
