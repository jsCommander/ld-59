class_name UpgradeData extends BaseGameData

# --- Exports ---
@export_group("Display")
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
@export_group("Stat Effects")
@export var global_damage: float = 0.0
@export var feature_damage: float = 0.0
@export var bug_damage: float = 0.0
@export var feature_chance: float = 0.0
@export var bug_chance: float = 0.0
@export var boost_power: float = 0.0
@export var boost_duration: float = 0.0
@export var auto_click_speed: float = 0.0
@export var reward_bonus: float = 0.0
@export var rarity_luck: float = 0.0

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
	var diff: float = absf(budget - target) / target
	if diff > Constants.BUDGET_TOLERANCE:
		return "%s: budget %.1f, target %d (%.0f%% off)" % [id, budget, int(target), diff * 100]
	return ""
