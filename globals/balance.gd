class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + global_damage) × (1 + type_damage) × (1 + stacks × boost_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, stats: Dictionary, boost_stacks: int = 0) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_DAMAGE, stats)
	var type_field: String = Constants.STAT_FEATURE_DAMAGE if task_type == Constants.TaskType.FEATURE else Constants.STAT_REFACTORING_DAMAGE
	var type_dmg_mult: float = 1.0 + _get_stat(type_field, stats)
	var boost_dmg_mult: float = 1.0 + boost_stacks * _get_stat(Constants.STAT_BOOST_DAMAGE, stats)
	return base * task_mult * global_dmg_mult * type_dmg_mult * boost_dmg_mult


## Attack speed = base / ((1 + global_speed) × (1 + type_speed) × (1 + stacks × boost_duration)), clamped to SPEED_CAP
static func calculate_attack_speed(dev_data: DeveloperData, boost_stacks: int = 0, stats: Dictionary = {}, task_type: Constants.TaskType = Constants.TaskType.FEATURE) -> float:
	var raw: float = _raw_attack_interval(dev_data, stats, task_type)
	var boost_mult: float = 1.0 + boost_stacks * _get_stat(Constants.STAT_BOOST_DURATION, stats)
	return maxf(raw / boost_mult, Constants.SPEED_CAP)


## True if base attack interval (no boost) already hits SPEED_CAP — further speed stats are wasted
static func is_attack_speed_capped(dev_data: DeveloperData, stats: Dictionary, task_type: Constants.TaskType) -> bool:
	return _raw_attack_interval(dev_data, stats, task_type) <= Constants.SPEED_CAP


## Auto click interval = BASE_INTERVAL / (1 + auto_click_speed), clamped to AUTO_CLICK_CAP. Returns 0 if no auto_click_speed.
static func calculate_auto_click_interval(stats: Dictionary) -> float:
	var speed: float = _get_stat(Constants.STAT_AUTO_CLICK_SPEED, stats)
	if is_zero_approx(speed):
		return 0.0
	return maxf(Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + speed), Constants.AUTO_CLICK_CAP)


## True if auto click interval is already at AUTO_CLICK_CAP — further auto_click_speed is wasted
static func is_auto_click_capped(stats: Dictionary) -> bool:
	var speed: float = _get_stat(Constants.STAT_AUTO_CLICK_SPEED, stats)
	if is_zero_approx(speed):
		return false
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + speed) <= Constants.AUTO_CLICK_CAP


## Task type weights based on Feature/Refactoring Chance stats
static func calculate_task_type_weights(stats: Dictionary) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE + _get_stat(Constants.STAT_FEATURE_CHANCE, stats)
	var refactoring_w: float = Constants.BASE_REFACTORING_CHANCE + _get_stat(Constants.STAT_REFACTORING_CHANCE, stats)
	feature_w = maxf(feature_w, 0.01)
	refactoring_w = maxf(refactoring_w, 0.01)
	var total: float = feature_w + refactoring_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.REFACTORING: refactoring_w / total,
	}


## Roll a rarity based on player level
static func roll_rarity(player_level: int) -> Constants.UpgradeRarity:
	var weights: Dictionary = _get_rarity_weights(player_level)
	var roll: float = randf()
	var cumulative: float = 0.0
	for rarity: Constants.UpgradeRarity in weights:
		cumulative += weights[rarity] as float
		if roll <= cumulative:
			return rarity
	return Constants.UpgradeRarity.COMMON


## Distribute `count` slots between rarities proportionally to their weights.
## Uses largest-remainder method: floor each (weight*count), then hand out leftover
## slots to rarities with the largest fractional remainders. Result is shuffled
## so rarity isn't tied to a specific slot index.
static func distribute_rarities(player_level: int, count: int) -> Array[Constants.UpgradeRarity]:
	var weights: Dictionary = _get_rarity_weights(player_level)
	var quotas: Array = []
	for rarity: Constants.UpgradeRarity in weights:
		var exact: float = (weights[rarity] as float) * count
		quotas.append({"rarity": rarity, "floor": int(exact), "remainder": exact - int(exact)})
	var assigned: int = 0
	for q: Dictionary in quotas:
		assigned += q["floor"]
	quotas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["remainder"] > b["remainder"])
	var idx: int = 0
	while assigned < count:
		quotas[idx]["floor"] += 1
		assigned += 1
		idx = (idx + 1) % quotas.size()
	var result: Array[Constants.UpgradeRarity] = []
	for q: Dictionary in quotas:
		for i in q["floor"]:
			result.append(q["rarity"])
	result.shuffle()
	return result


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func get_task_hp(player_level: int) -> float:
	var exponent: float = 1.0
	for bracket in Constants.HP_GROWTH_EXPONENTS:
		if player_level >= bracket["min_lvl"]:
			exponent = bracket["growth_exponent"]
	return Growth.power(player_level, Constants.BASE_HP, exponent)


static func get_sprints_to_level_up(player_level: int) -> int:
	var result: int = 1
	for bracket in Constants.SPRINTS_TO_LEVEL_UP:
		if player_level >= bracket["level"]:
			result = bracket["sprints"]
	return result


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Read a stat value from the totals dictionary
static func _get_stat(field: String, stats: Dictionary) -> float:
	return stats.get(field, 0.0)


## Attack interval before boost stacks and SPEED_CAP clamp
static func _raw_attack_interval(dev_data: DeveloperData, stats: Dictionary, task_type: Constants.TaskType) -> float:
	var base: float = dev_data.base_attack_speed
	var global_speed_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_SPEED, stats)
	var type_field: String = Constants.STAT_FEATURE_SPEED if task_type == Constants.TaskType.FEATURE else Constants.STAT_REFACTORING_SPEED
	var type_speed_mult: float = 1.0 + _get_stat(type_field, stats)
	return base / (global_speed_mult * type_speed_mult)


## Pick the rates from the bracket whose min_lvl is the highest <= player_level.
static func _get_rarity_weights(player_level: int) -> Dictionary:
	var result: Dictionary = {}
	for bracket: Dictionary in Constants.RARITY_APPEARANCE_RATES:
		if player_level >= bracket["min_lvl"]:
			result = bracket["rates"]
	return result
