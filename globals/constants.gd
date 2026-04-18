class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

# --- Enums ---

enum DevType {VIBECODER, DEVELOPER, SENIOR}
enum TaskType {FEATURE, REFACTORING}
enum Music {FR, FR3, SG, SPB}
enum Sfx {PICKUP, HIT_HURT, EXPLOSION, CLICK}
enum UpgradeStat {
	GLOBAL_DAMAGE,
	FEATURE_DAMAGE,
	REFACTORING_DAMAGE,
	FEATURE_CHANCE,
	REFACTORING_CHANCE,
	BOOST_SPEED,
	AUTO_CLICK_SPEED,
}
enum UpgradeRarity {COMMON, UNCOMMON, EPIC, LEGENDARY}
enum TradeOffType {PURE, TRADE_OFF_CROSS_GROUP}
enum UpgradeGroup {DPS_DEV, CLICK_BOOST, TASK_TYPE, ECONOMY}
enum UpgradeType {HIRE, UPGRADE}
enum DiffType {NONE, POSITIVE, NEGATIVE}

const DEV_TYPE_DISPLAY_NAMES: Dictionary[DevType, String] = {
	DevType.VIBECODER: "Vibe Coder",
	DevType.DEVELOPER: "Regular",
	DevType.SENIOR: "Senior",
}

# --- Combat ---

const BASE_HP: int = 1000
const BASE_DAMAGE: int = int(BASE_HP * 0.4)
const BASE_ATTACK_SPEED: float = 2
const SPEED_CAP: float = 0.05
const HP_GROWTH_EXPONENTS: Array[Dictionary] = [
	{"min_lvl": 1, "growth_exponent": 1.3},
	{"min_lvl": 5, "growth_exponent": 1.2},
	{"min_lvl": 10, "growth_exponent": 1.2},
	{"min_lvl": 20, "growth_exponent": 1.2},
	{"min_lvl": 30, "growth_exponent": 1.2},
	{"min_lvl": 40, "growth_exponent": 1.5},
]

# --- Boost ---

const MAX_BOOST_STACKS: int = 6
const BOOST_STACK_MAX_LIFETIME: float = 3
const BOOST_STACK_TICK_INTERVAL: float = 0.1
const BASE_BOOST_SPEED: float = 1.2
const AUTO_CLICK_BASE_INTERVAL: float = 3.0
const AUTO_CLICK_CAP: float = 0.1
const BOOST_HELP_DELAY: float = 5.0
const BOOST_HELP_CLICKS_TO_LEARN: int = 5

# --- Progression ---

const MAX_SPRINT_SIZE: int = 12
const SPRINT_SIZES: Array[Dictionary] = [
	{"min_level": 0, "size": 2}, # 1 dev
	{"min_level": 3, "size": 4}, # 2 devs
	{"min_level": 5, "size": 6}, # 3 devs
	{"min_level": 7, "size": 8}, # 4 devs
	{"min_level": 9, "size": 10}, # 5 devs
	{"min_level": 15, "size": 12}, # 6 devs
]
const HIRE_LEVELS: Array[int] = [0, 3, 5, 7, 9, 11, 13, 15, 17]
const SPRINTS_TO_LEVEL_UP: Array[Dictionary] = [
	{"level": 1, "sprints": 1},
	{"level": 30, "sprints": 2},
	{"level": 40, "sprints": 3},
]
const MAX_DEV_STAT_MULTIPLIER: float = 2.0
const BASE_TOTAL_GAME_TIME: float = 480.0

# --- Tasks ---

const BASE_FEATURE_CHANCE: float = 0.5
const BASE_REFACTORING_CHANCE: float = 0.5


# --- Upgrades ---

const UPGRADE_CHOICES: int = 3
const INITIAL_REROLLS: int = 1
const ADD_REROLL_EVERY_X_LEVEL: int = 3
const TRADE_OFF_RETURN_RATE: float = 1.0

const RARITY_MAX_STAT_COUNT: Dictionary[UpgradeRarity, int] = {
	UpgradeRarity.COMMON: 2,
	UpgradeRarity.UNCOMMON: 2,
	UpgradeRarity.EPIC: 3,
	UpgradeRarity.LEGENDARY: 4,
}

const RARITY_MAX_COUNT_DICT: Dictionary[UpgradeRarity, int] = {
	UpgradeRarity.COMMON: 99,
	UpgradeRarity.UNCOMMON: 99,
	UpgradeRarity.EPIC: 99,
	UpgradeRarity.LEGENDARY: 99,
}

const OFFER_RARITY_CAP_DICT: Dictionary[UpgradeRarity, int] = {
	UpgradeRarity.COMMON: 99,
	UpgradeRarity.UNCOMMON: 10,
	UpgradeRarity.EPIC: 4,
	UpgradeRarity.LEGENDARY: 2,
}

const STAT_COSTS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: 1.5,
	UpgradeStat.FEATURE_DAMAGE: 1.0,
	UpgradeStat.REFACTORING_DAMAGE: 1.0,
	UpgradeStat.FEATURE_CHANCE: 1.0,
	UpgradeStat.REFACTORING_CHANCE: 1.0,
	UpgradeStat.BOOST_SPEED: 1.0,
	UpgradeStat.AUTO_CLICK_SPEED: 1.0,
}

const RARITY_BUDGETS: Dictionary = {
	UpgradeRarity.COMMON: 10,
	UpgradeRarity.UNCOMMON: 30,
	UpgradeRarity.EPIC: 60,
	UpgradeRarity.LEGENDARY: 90,
}

const STAT_FIELDS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: "global_damage",
	UpgradeStat.FEATURE_DAMAGE: "feature_damage",
	UpgradeStat.REFACTORING_DAMAGE: "refactoring_damage",
	UpgradeStat.FEATURE_CHANCE: "feature_chance",
	UpgradeStat.REFACTORING_CHANCE: "refactoring_chance",
	UpgradeStat.BOOST_SPEED: "boost_speed",
	UpgradeStat.AUTO_CLICK_SPEED: "auto_click_speed",
}

const BUDGET_TOLERANCE: float = 0.15

const NEGATIVE_BUDGET_LIMITS: Dictionary = {
	UpgradeRarity.COMMON: 5,
	UpgradeRarity.UNCOMMON: 10,
	UpgradeRarity.EPIC: 20,
	UpgradeRarity.LEGENDARY: 40
}

const STAT_TO_GROUP_DICT: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.FEATURE_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.REFACTORING_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.BOOST_SPEED: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.AUTO_CLICK_SPEED: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.FEATURE_CHANCE: UpgradeGroup.TASK_TYPE,
	UpgradeStat.REFACTORING_CHANCE: UpgradeGroup.TASK_TYPE,
}

const UPGRADE_MIN_COUNT_DICT: Dictionary = {
	TradeOffType.PURE: {
		UpgradeRarity.COMMON: 1,
		UpgradeRarity.UNCOMMON: 1,
		UpgradeRarity.EPIC: 1,
		UpgradeRarity.LEGENDARY: 1,
	},
	TradeOffType.TRADE_OFF_CROSS_GROUP: {
		UpgradeRarity.COMMON: 1,
		UpgradeRarity.UNCOMMON: 1,
		UpgradeRarity.EPIC: 1,
		UpgradeRarity.LEGENDARY: 1,
	},
}

const UPGRADE_MAX_COUNT_DICT: Dictionary = {
	TradeOffType.PURE: {
		UpgradeRarity.COMMON: 15,
		UpgradeRarity.UNCOMMON: 15,
		UpgradeRarity.EPIC: 15,
		UpgradeRarity.LEGENDARY: 15,
	},
	TradeOffType.TRADE_OFF_CROSS_GROUP: {
		UpgradeRarity.COMMON: 15,
		UpgradeRarity.UNCOMMON: 15,
		UpgradeRarity.EPIC: 15,
		UpgradeRarity.LEGENDARY: 15,
	},
}

# --- Stat Keys ---

const STAT_GLOBAL_DAMAGE: String = "global_damage"
const STAT_FEATURE_DAMAGE: String = "feature_damage"
const STAT_REFACTORING_DAMAGE: String = "refactoring_damage"
const STAT_FEATURE_CHANCE: String = "feature_chance"
const STAT_REFACTORING_CHANCE: String = "refactoring_chance"
const STAT_BOOST_SPEED: String = "boost_speed"
const STAT_AUTO_CLICK_SPEED: String = "auto_click_speed"

const FORBIDDEN_POSITIVE_STAT_COMBINATIONS: Array[Array] = [
	[STAT_FEATURE_CHANCE, STAT_REFACTORING_CHANCE],
	[STAT_FEATURE_DAMAGE, STAT_REFACTORING_DAMAGE],
]

const STAT_ORDER: Array[String] = [
	# Damage
	STAT_GLOBAL_DAMAGE,
	STAT_FEATURE_DAMAGE,
	STAT_REFACTORING_DAMAGE,
	# Boosts
	STAT_BOOST_SPEED,
	STAT_AUTO_CLICK_SPEED,
	# Chances
	STAT_FEATURE_CHANCE,
	STAT_REFACTORING_CHANCE,
]

const STAT_DISPLAY_NAMES: Dictionary = {
	STAT_GLOBAL_DAMAGE: "Global Damage",
	STAT_FEATURE_DAMAGE: "Feature Damage",
	STAT_REFACTORING_DAMAGE: "Refactoring Damage",
	STAT_FEATURE_CHANCE: "Feature Chance",
	STAT_REFACTORING_CHANCE: "Refactoring Chance",
	STAT_BOOST_SPEED: "Boost Speed",
	STAT_AUTO_CLICK_SPEED: "Auto Click Speed",
}

# --- Rarity Rates (by player level) ---

const RARITY_APPEARANCE_RATES: Array[Dictionary] = [
	{"min_lvl": 1, "rates": {UpgradeRarity.COMMON: 0.75, UpgradeRarity.UNCOMMON: 0.25, UpgradeRarity.EPIC: 0.00, UpgradeRarity.LEGENDARY: 0.00}},
	{"min_lvl": 6, "rates": {UpgradeRarity.COMMON: 0.45, UpgradeRarity.UNCOMMON: 0.45, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.05}},
	{"min_lvl": 11, "rates": {UpgradeRarity.COMMON: 0.20, UpgradeRarity.UNCOMMON: 0.65, UpgradeRarity.EPIC: 0.10, UpgradeRarity.LEGENDARY: 0.05}},
	{"min_lvl": 16, "rates": {UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.60, UpgradeRarity.EPIC: 0.20, UpgradeRarity.LEGENDARY: 0.10}},
	{"min_lvl": 21, "rates": {UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.40, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.20}},
	{"min_lvl": 26, "rates": {UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.30}},
	{"min_lvl": 31, "rates": {UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.30}},
	{"min_lvl": 36, "rates": {UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.30}},
]


# --- Milestones ---

const COMPANY_MILESTONES: Array[Dictionary] = [
	# Everyday items
	{"valuation": 2000, "name": "PS5"},
	{"valuation": 5000, "name": "MacBook Pro"},
	{"valuation": 15000, "name": "Used Car"},
	{"valuation": 40000, "name": "Tesla Model 3"},
	{"valuation": 200000, "name": "Developer Salary"},
	{"valuation": 800000, "name": "Studio Apartment"},
	{"valuation": 2000000, "name": "House"},
	{"valuation": 10000000, "name": "Penthouse"},
	{"valuation": 30000000, "name": "Yacht"},
	# Companies
	{"valuation": 50000000, "name": "Team Cherry"},
	{"valuation": 300000000, "name": "Devolver Digital"},
	{"valuation": 800000000, "name": "Supergiant Games"},
	{"valuation": 3000000000, "name": "Ubisoft"},
	{"valuation": 10000000000, "name": "Valve"},
	{"valuation": 13000000000, "name": "Zynga"},
	{"valuation": 15000000000, "name": "Discord"},
	{"valuation": 32000000000, "name": "Epic Games"},
	{"valuation": 40000000000, "name": "EA"},
	{"valuation": 60000000000, "name": "Roblox"},
	{"valuation": 75000000000, "name": "Nintendo"},
	{"valuation": 100000000000, "name": "Spotify"},
	{"valuation": 130000000000, "name": "Sony"},
	{"valuation": 250000000000, "name": "AMD"},
	{"valuation": 300000000000, "name": "Netflix"},
	{"valuation": 400000000000, "name": "Samsung"},
	{"valuation": 800000000000, "name": "Oracle"},
	{"valuation": 1000000000000, "name": "Tesla"},
	{"valuation": 1500000000000, "name": "Meta"},
	{"valuation": 2000000000000, "name": "Google"},
	{"valuation": 10000000000000, "name": "World Domination"},
]
