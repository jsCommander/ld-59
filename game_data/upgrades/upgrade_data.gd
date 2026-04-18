class_name UpgradeData extends BaseGameData

# --- Exports ---
@export_group("Display")
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var group: Constants.UpgradeGroup = Constants.UpgradeGroup.DPS_DEV
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
@export_group("Stat Effects")
@export var global_damage: float = 0.0
@export var feature_damage: float = 0.0
@export var refactoring_damage: float = 0.0
@export var feature_chance: float = 0.0
@export var refactoring_chance: float = 0.0
@export var boost_speed: float = 0.0
@export var auto_click_speed: float = 0.0

# --- Public ---

func calculate_budget() -> float:
	var total: float = 0.0
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = get(field) as float
		var cost: float = Constants.STAT_COSTS[stat] as float
		var percent: float = value * 100.0
		if value > 0.0:
			total += percent * cost
		elif value < 0.0:
			total += percent * cost * Constants.TRADE_OFF_RETURN_RATE
	return total


func validate_budget() -> String:
	var budget: float = calculate_budget()
	var target: float = Constants.RARITY_BUDGETS[rarity] as float
	if is_zero_approx(target):
		return ""
	var warnings: Array[String] = []
	var diff: float = absf(budget - target) / target
	if diff > Constants.BUDGET_TOLERANCE:
		warnings.append("%s: budget %.1f, target %d (%.0f%% off)" % [id, budget, int(target), diff * 100])
	var neg_total: float = _calculate_negative_budget()
	var neg_limit: float = Constants.NEGATIVE_BUDGET_LIMITS[rarity] as float
	if neg_total > neg_limit:
		warnings.append("%s: negative budget %.1f exceeds limit %d" % [id, neg_total, int(neg_limit)])
	warnings.append_array(_validate_stat_count())
	warnings.append_array(_validate_trade_off())
	warnings.append_array(_validate_forbidden_combinations())
	return "\n".join(warnings)


func _validate_stat_count() -> Array[String]:
	var warnings: Array[String] = []
	var limit: int = Constants.RARITY_MAX_STAT_COUNT[rarity]
	var count: int = 0
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = get(field) as float
		if not is_zero_approx(value):
			count += 1
	if count > limit:
		warnings.append("%s: has %d stats, max for %s is %d" % [
			id,
			count,
			Constants.UpgradeRarity.keys()[rarity],
			limit,
		])
	return warnings


func _validate_forbidden_combinations() -> Array[String]:
	var warnings: Array[String] = []
	for combo: Array in Constants.FORBIDDEN_POSITIVE_STAT_COMBINATIONS:
		var positive_fields: Array[String] = []
		for field: String in combo:
			if (get(field) as float) > 0.0:
				positive_fields.append(field)
		if positive_fields.size() == combo.size():
			warnings.append("%s: forbidden positive combination [%s]" % [id, ", ".join(positive_fields)])
	return warnings


func _calculate_negative_budget() -> float:
	var total: float = 0.0
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = get(field) as float
		if value < 0.0:
			var cost: float = Constants.STAT_COSTS[stat] as float
			total += absf(value) * 100.0 * cost
	return total


func _validate_trade_off() -> Array[String]:
	var warnings: Array[String] = []
	var positive_groups: Array[Constants.UpgradeGroup] = []
	var negative_groups: Array[Constants.UpgradeGroup] = []
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = get(field) as float
		var stat_group: Constants.UpgradeGroup = Constants.STAT_TO_GROUP_DICT[stat] as Constants.UpgradeGroup
		if value > 0.0 and stat_group not in positive_groups:
			positive_groups.append(stat_group)
		elif value < 0.0 and stat_group not in negative_groups:
			negative_groups.append(stat_group)

	# Check 1: PURE with negative stats
	if trade_off_type == Constants.TradeOffType.PURE and not negative_groups.is_empty():
		warnings.append("%s: marked as PURE but has negative stats" % id)

	# Check 2: CROSS_GROUP with same-group negative
	if trade_off_type == Constants.TradeOffType.TRADE_OFF_CROSS_GROUP:
		for neg_group: Constants.UpgradeGroup in negative_groups:
			if neg_group == group:
				warnings.append("%s: TRADE_OFF_CROSS_GROUP but has negative stat from same group %s" % [
					id,
					Constants.UpgradeGroup.keys()[group],
				])

	# Check 3: Group mismatch — all positive stats from one group, but group field differs
	if positive_groups.size() == 1 and positive_groups[0] != group:
		warnings.append("%s: group is %s but all positive stats are in %s" % [
			id,
			Constants.UpgradeGroup.keys()[group],
			Constants.UpgradeGroup.keys()[positive_groups[0]],
		])

	return warnings
