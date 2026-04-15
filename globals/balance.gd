class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + sum global_damage) × (1 + sum type_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _sum_stat(Constants.STAT_GLOBAL_DAMAGE, global_upgrades, dev_upgrades)
	var type_field: String = Constants.STAT_FEATURE_DAMAGE if task_type == Constants.TaskType.FEATURE else Constants.STAT_BUG_DAMAGE
	var type_dmg_mult: float = 1.0 + _sum_stat(type_field, global_upgrades, dev_upgrades)
	return base * task_mult * global_dmg_mult * type_dmg_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData], boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var boost_power: float = calculate_boost_power(global_upgrades, dev_upgrades)
	var boost_mult: float = 1.0 + boost_stacks * boost_power
	var interval: float = base / boost_mult
	return maxf(interval, Constants.SPEED_CAP)


## Boost power = BOOST_SPEED_MULT × (1 + sum boost_power)
static func calculate_boost_power(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0 + _sum_stat(Constants.STAT_BOOST_POWER, global_upgrades, dev_upgrades)
	return Constants.BOOST_SPEED_MULT * mult


## Boost decay interval = (1/DECAY_RATE) × (1 + sum boost_duration)
static func calculate_boost_decay_interval(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0 + _sum_stat(Constants.STAT_BOOST_DURATION, global_upgrades, dev_upgrades)
	return (1.0 / Constants.BOOST_DECAY_RATE) * mult


## Auto click interval = BASE_INTERVAL / (1 + sum auto_click_speed). Returns 0 if no upgrade.
static func calculate_auto_click_interval(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var sum_val: float = _sum_stat(Constants.STAT_AUTO_CLICK_SPEED, global_upgrades, dev_upgrades)
	if is_zero_approx(sum_val):
		return 0.0
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + sum_val)


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


## How many upgrade choices the player gets at level-up
static func calculate_upgrade_choices(all_upgrades: Array[UpgradeData]) -> int:
	var bonus: int = 0
	for upgrade: UpgradeData in all_upgrades:
		bonus += upgrade.upgrade_choices
	return mini(Constants.BASE_UPGRADE_CHOICES + bonus, Constants.MAX_UPGRADE_CHOICES)


## Roll a rarity based on current player level
static func roll_rarity(player_level: int) -> Constants.UpgradeRarity:
	var bracket: int = clampi((player_level - 1) / 10, 0, Constants.RARITY_APPEARANCE_RATES.size() - 1)
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


static func get_game_level(elapsed_time: float) -> int:
	var lvl: int = 1
	for i: int in Constants.GAME_LEVEL_THRESHOLDS.size():
		if elapsed_time >= Constants.GAME_LEVEL_THRESHOLDS[i]:
			lvl = i + 1
	return lvl


static func get_task_hp(game_level: int) -> float:
	var clamped: int = clampi(game_level, 1, Constants.TASK_HP_BY_LEVEL.size())
	return float(Constants.TASK_HP_BY_LEVEL[clamped])


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.LEVEL_THRESHOLDS.size():
		return 0
	return Constants.LEVEL_THRESHOLDS[level - 1]


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Sum a stat field across all upgrades (additive stacking)
static func _sum_stat(field: String, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var total: float = 0.0
	for upgrade: UpgradeData in global_upgrades:
		total += upgrade.get(field) as float
	for upgrade: UpgradeData in dev_upgrades:
		total += upgrade.get(field) as float
	return total
