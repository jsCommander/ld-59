class_name Balance


## Build the unified PlayerStatsResource from a list of applied upgrades.
## This is the single source of truth — both gameplay (damage, attack speed,
## sprint generation) and UI (player stats panel) consume the resulting resource.
static func get_player_stats_from_upgrades(upgrades: Array[UpgradeData]) -> PlayerStatsResource:
	var deltas: Dictionary = _sum_upgrade_deltas(upgrades)
	var global_mult: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_DAMAGE, deltas)
	var weights: Dictionary = _task_type_weights(deltas)

	var res: PlayerStatsResource = PlayerStatsResource.new()
	res.damage_features = global_mult * (1.0 + _get_stat(Constants.STAT_FEATURE_DAMAGE, deltas))
	res.damage_refactor = global_mult * (1.0 + _get_stat(Constants.STAT_REFACTORING_DAMAGE, deltas))
	res.boost_per_stack = Constants.BASE_BOOST_SPEED + _get_stat(Constants.STAT_BOOST_SPEED, deltas)
	res.auto_click_interval = _auto_click_interval(deltas)
	res.feature_ratio = weights[Constants.TaskType.FEATURE] as float
	res.refactoring_ratio = weights[Constants.TaskType.REFACTORING] as float
	return res


## Damage = BASE_DAMAGE × task_mult × task_damage_mult
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, player_stats: PlayerStatsResource) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var dmg_mult: float = player_stats.damage_refactor if task_type == Constants.TaskType.REFACTORING else player_stats.damage_features
	return base * task_mult * dmg_mult


## Attack speed = base / (1 + stacks × boost_per_stack), clamped to SPEED_CAP
static func calculate_attack_speed(dev_data: DeveloperData, boost_stacks: int, player_stats: PlayerStatsResource) -> float:
	var boost_mult: float = 1.0 + boost_stacks * player_stats.boost_per_stack
	return maxf(dev_data.base_attack_speed / boost_mult, Constants.SPEED_CAP)


## True if auto click interval is already at AUTO_CLICK_CAP — further auto_click_speed is wasted
static func is_auto_click_capped(player_stats: PlayerStatsResource) -> bool:
	if is_zero_approx(player_stats.auto_click_interval):
		return false
	return player_stats.auto_click_interval <= Constants.AUTO_CLICK_CAP


## True if every hired dev already reaches SPEED_CAP at MAX_BOOST_STACKS — further boost_speed is wasted.
## Returns false when no devs are hired (upgrade may still benefit future hires).
static func is_boost_speed_capped(player_stats: PlayerStatsResource, hired_devs: Array[DeveloperData]) -> bool:
	if hired_devs.is_empty():
		return false
	var boost_mult: float = 1.0 + Constants.MAX_BOOST_STACKS * player_stats.boost_per_stack
	for dev: DeveloperData in hired_devs:
		if dev.base_attack_speed / boost_mult > Constants.SPEED_CAP:
			return false
	return true


## Feature/refactoring task counts for a sprint at the given level with the given stats.
## Returns {size: int, features: int, refactoring: int}; features + refactoring == size.
static func get_sprint_composition(player_stats: PlayerStatsResource, player_level: int) -> Dictionary:
	var size: int = get_sprint_size(player_level)
	var features: int = roundi(size * player_stats.feature_ratio)
	return {
		"size": size,
		"features": features,
		"refactoring": size - features,
	}


## Total sprint size (task count) for a given player level.
static func get_sprint_size(player_level: int) -> int:
	var result: int = Constants.SPRINT_SIZES[0]["size"]
	for bracket: Dictionary in Constants.SPRINT_SIZES:
		if player_level >= bracket["min_level"]:
			result = bracket["size"]
	return result


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


# --- Private ---

static func _sum_upgrade_deltas(upgrades: Array[UpgradeData]) -> Dictionary:
	var result: Dictionary = {}
	for field: String in Constants.STAT_ORDER:
		var total: float = 0.0
		for upgrade: UpgradeData in upgrades:
			total += upgrade.get(field) as float
		if not is_zero_approx(total):
			result[field] = total
	return result


static func _auto_click_interval(deltas: Dictionary) -> float:
	var speed: float = _get_stat(Constants.STAT_AUTO_CLICK_SPEED, deltas)
	if is_zero_approx(speed):
		return 0.0
	return maxf(Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + speed), Constants.AUTO_CLICK_CAP)


static func _task_type_weights(deltas: Dictionary) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE + _get_stat(Constants.STAT_FEATURE_CHANCE, deltas)
	var refactoring_w: float = Constants.BASE_REFACTORING_CHANCE + _get_stat(Constants.STAT_REFACTORING_CHANCE, deltas)
	feature_w = maxf(feature_w, 0.01)
	refactoring_w = maxf(refactoring_w, 0.01)
	var total: float = feature_w + refactoring_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.REFACTORING: refactoring_w / total,
	}


static func _get_stat(field: String, deltas: Dictionary) -> float:
	return deltas.get(field, 0.0)


## Pick the rates from the bracket whose min_lvl is the highest <= player_level.
static func _get_rarity_weights(player_level: int) -> Dictionary:
	var result: Dictionary = {}
	for bracket: Dictionary in Constants.RARITY_APPEARANCE_RATES:
		if player_level >= bracket["min_lvl"]:
			result = bracket["rates"]
	return result
