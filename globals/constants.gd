class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

# --- Enums ---

enum DevType {VIBECODER, DEVELOPER, SENIOR}
enum TaskType {FEATURE, BUG}
enum Music {FR, FR3, SG, SPB}
enum Sfx {PICKUP, HIT_HURT, EXPLOSION, CLICK}
enum UpgradeStat {
	GLOBAL_DAMAGE,
	FEATURE_DAMAGE,
	BUG_DAMAGE,
	FEATURE_CHANCE,
	BUG_CHANCE,
	BOOST_DAMAGE,
	BOOST_DURATION,
	AUTO_CLICK_SPEED,
	REWARD_BONUS,
	RARITY_LUCK,
}
enum UpgradeRarity {COMMON, UNCOMMON, EPIC, LEGENDARY}
enum TradeOffType {PURE, TRADE_OFF_CROSS_GROUP}
enum UpgradeGroup {DPS_DEV, CLICK_BOOST, TASK_TYPE, ECONOMY}
enum UpgradeType {HIRE, UPGRADE}

# --- Combat ---

const BASE_HP: int = 100
const BASE_DAMAGE: int = int(BASE_HP * 0.4)
const BASE_ATTACK_SPEED: float = 2.0
const SPEED_CAP: float = 0.1

# --- Boost ---

const MAX_BOOST_STACKS: int = 5
const BOOST_STACK_MAX_LIFETIME: float = 1
const BOOST_STACK_TICK_INTERVAL: float = 0.1
const AUTO_CLICK_BASE_INTERVAL: float = 2.0

# --- Progression ---

const XP_BASE: int = 100
const SPRINT_SIZE: int = 12
const MAX_DEV_STAT_MULTIPLIER: float = 2.0
const BASE_TOTAL_GAME_TIME: float = 600.0
const HIRE_LEVELS: Array[int] = [0, 3, 6, 10, 14, 18, 23, 28, 34]

# --- Tasks ---

const BASE_FEATURE_CHANCE: float = 50.0
const BASE_BUG_CHANCE: float = 50.0

# --- Upgrades ---

const UPGRADE_CHOICES: int = 4
const TRADE_OFF_RETURN_RATE: float = 0.3

const RARITY_MAX_COUNT_DICT: Dictionary[UpgradeRarity, int] = {
	UpgradeRarity.COMMON: 99,
	UpgradeRarity.UNCOMMON: 5,
	UpgradeRarity.EPIC: 3,
	UpgradeRarity.LEGENDARY: 1,
}

const OFFER_RARITY_CAP_DICT: Dictionary[UpgradeRarity, int] = {
	UpgradeRarity.COMMON: UPGRADE_CHOICES,
	UpgradeRarity.UNCOMMON: 3,
	UpgradeRarity.EPIC: 2,
	UpgradeRarity.LEGENDARY: 1,
}

const STAT_COSTS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: 1.0,
	UpgradeStat.FEATURE_DAMAGE: 1.0,
	UpgradeStat.BUG_DAMAGE: 1.0,
	UpgradeStat.FEATURE_CHANCE: 1.0,
	UpgradeStat.BUG_CHANCE: 1.0,
	UpgradeStat.BOOST_DAMAGE: 1.0,
	UpgradeStat.BOOST_DURATION: 1.0,
	UpgradeStat.AUTO_CLICK_SPEED: 1.0,
	UpgradeStat.REWARD_BONUS: 1,
	UpgradeStat.RARITY_LUCK: 3.0,
}

const RARITY_BUDGETS: Dictionary = {
	UpgradeRarity.COMMON: 10,
	UpgradeRarity.UNCOMMON: 30,
	UpgradeRarity.EPIC: 60,
	UpgradeRarity.LEGENDARY: 100,
}

const STAT_FIELDS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: "global_damage",
	UpgradeStat.FEATURE_DAMAGE: "feature_damage",
	UpgradeStat.BUG_DAMAGE: "bug_damage",
	UpgradeStat.FEATURE_CHANCE: "feature_chance",
	UpgradeStat.BUG_CHANCE: "bug_chance",
	UpgradeStat.BOOST_DAMAGE: "boost_damage",
	UpgradeStat.BOOST_DURATION: "boost_duration",
	UpgradeStat.AUTO_CLICK_SPEED: "auto_click_speed",
	UpgradeStat.REWARD_BONUS: "reward_bonus",
	UpgradeStat.RARITY_LUCK: "rarity_luck",
}

const BUDGET_TOLERANCE: float = 0.15

const NEGATIVE_BUDGET_LIMITS: Dictionary = {
	UpgradeRarity.COMMON: 3,
	UpgradeRarity.UNCOMMON: 6,
	UpgradeRarity.EPIC: 9,
	UpgradeRarity.LEGENDARY: 12,
}

const STAT_TO_GROUP_DICT: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.FEATURE_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.BUG_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.BOOST_DAMAGE: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.BOOST_DURATION: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.AUTO_CLICK_SPEED: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.FEATURE_CHANCE: UpgradeGroup.TASK_TYPE,
	UpgradeStat.BUG_CHANCE: UpgradeGroup.TASK_TYPE,
	UpgradeStat.REWARD_BONUS: UpgradeGroup.ECONOMY,
	UpgradeStat.RARITY_LUCK: UpgradeGroup.ECONOMY,
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
const STAT_BUG_DAMAGE: String = "bug_damage"
const STAT_FEATURE_CHANCE: String = "feature_chance"
const STAT_BUG_CHANCE: String = "bug_chance"
const STAT_BOOST_DAMAGE: String = "boost_damage"
const STAT_BOOST_DURATION: String = "boost_duration"
const STAT_AUTO_CLICK_SPEED: String = "auto_click_speed"
const STAT_REWARD_BONUS: String = "reward_bonus"
const STAT_RARITY_LUCK: String = "rarity_luck"

const FORBIDDEN_POSITIVE_STAT_COMBINATIONS: Array[Array] = [
	[STAT_FEATURE_CHANCE, STAT_BUG_CHANCE],
	[STAT_FEATURE_DAMAGE, STAT_BUG_DAMAGE],
]

const STAT_DISPLAY_NAMES: Dictionary = {
	STAT_GLOBAL_DAMAGE: "Global Damage",
	STAT_FEATURE_DAMAGE: "Feature Damage",
	STAT_BUG_DAMAGE: "Bug Damage",
	STAT_FEATURE_CHANCE: "Feature Chance",
	STAT_BUG_CHANCE: "Bug Chance",
	STAT_BOOST_DAMAGE: "Boost Damage",
	STAT_BOOST_DURATION: "Boost Speed",
	STAT_AUTO_CLICK_SPEED: "Auto Click Speed",
	STAT_REWARD_BONUS: "Reward Bonus",
	STAT_RARITY_LUCK: "Rarity Luck",
}

# --- Rarity Rates (by player level) ---

const RARITY_APPEARANCE_RATES: Array[Dictionary] = [
	# lvl 1-5: common + uncommon only
	{UpgradeRarity.COMMON: 0.75, UpgradeRarity.UNCOMMON: 0.25, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.70, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.65, UpgradeRarity.UNCOMMON: 0.35, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.60, UpgradeRarity.UNCOMMON: 0.40, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.55, UpgradeRarity.UNCOMMON: 0.45, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	# lvl 6-10: epics unlock
	{UpgradeRarity.COMMON: 0.45, UpgradeRarity.UNCOMMON: 0.45, UpgradeRarity.EPIC: 0.10, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.40, UpgradeRarity.UNCOMMON: 0.40, UpgradeRarity.EPIC: 0.20, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.35, UpgradeRarity.UNCOMMON: 0.35, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.30, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.40, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.25, UpgradeRarity.UNCOMMON: 0.25, UpgradeRarity.EPIC: 0.50, UpgradeRarity.LEGENDARY: 0.0},
	# lvl 11-15: epic dominant
	{UpgradeRarity.COMMON: 0.20, UpgradeRarity.UNCOMMON: 0.20, UpgradeRarity.EPIC: 0.60, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.18, UpgradeRarity.UNCOMMON: 0.17, UpgradeRarity.EPIC: 0.65, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.15, UpgradeRarity.UNCOMMON: 0.15, UpgradeRarity.EPIC: 0.70, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.12, UpgradeRarity.UNCOMMON: 0.13, UpgradeRarity.EPIC: 0.75, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.80, UpgradeRarity.LEGENDARY: 0.0},
	# lvl 16-20: epic peaks, legendaries unlock at 20
	{UpgradeRarity.COMMON: 0.08, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.82, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.07, UpgradeRarity.UNCOMMON: 0.08, UpgradeRarity.EPIC: 0.85, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.07, UpgradeRarity.EPIC: 0.88, UpgradeRarity.LEGENDARY: 0.0},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.85, UpgradeRarity.LEGENDARY: 0.05},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.80, UpgradeRarity.LEGENDARY: 0.10},
	# lvl 21-25: legendary rises
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.12, UpgradeRarity.EPIC: 0.43, UpgradeRarity.LEGENDARY: 0.40},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.40, UpgradeRarity.LEGENDARY: 0.45},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.35, UpgradeRarity.LEGENDARY: 0.50},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.30, UpgradeRarity.LEGENDARY: 0.55},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.10, UpgradeRarity.EPIC: 0.25, UpgradeRarity.LEGENDARY: 0.60},
	# lvl 26-30: legendary dominant
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.08, UpgradeRarity.EPIC: 0.22, UpgradeRarity.LEGENDARY: 0.65},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.07, UpgradeRarity.EPIC: 0.18, UpgradeRarity.LEGENDARY: 0.70},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.15, UpgradeRarity.LEGENDARY: 0.75},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.12, UpgradeRarity.LEGENDARY: 0.78},
	{UpgradeRarity.COMMON: 0.05, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.10, UpgradeRarity.LEGENDARY: 0.80},
	# lvl 31-35: mostly legendary
	{UpgradeRarity.COMMON: 0.03, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.10, UpgradeRarity.LEGENDARY: 0.82},
	{UpgradeRarity.COMMON: 0.03, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.08, UpgradeRarity.LEGENDARY: 0.84},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.05, UpgradeRarity.EPIC: 0.07, UpgradeRarity.LEGENDARY: 0.86},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.04, UpgradeRarity.EPIC: 0.06, UpgradeRarity.LEGENDARY: 0.88},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
	# lvl 36-40: endgame
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
	{UpgradeRarity.COMMON: 0.02, UpgradeRarity.UNCOMMON: 0.03, UpgradeRarity.EPIC: 0.05, UpgradeRarity.LEGENDARY: 0.90},
]


# --- Milestones ---

const COMPANY_MILESTONES: Array[Dictionary] = [
	# Everyday items
	{"valuation": 100, "name": "Cup of Coffee"},
	{"valuation": 300, "name": "Pair of AirPods"},
	{"valuation": 500, "name": "Kebab Stand"},
	{"valuation": 1500, "name": "PS5"},
	{"valuation": 5000, "name": "MacBook Pro"},
	{"valuation": 15000, "name": "Used Car"},
	{"valuation": 50000, "name": "Tesla Model 3"},
	{"valuation": 150000, "name": "Developer Salary"},
	{"valuation": 500000, "name": "Studio Apartment"},
	{"valuation": 1500000, "name": "House"},
	{"valuation": 3000000, "name": "Penthouse"},
	{"valuation": 5000000, "name": "Yacht"},
	# Companies
	{"valuation": 8000000, "name": "Indie Game Studio"},
	{"valuation": 15000000, "name": "Mobile Game Studio"},
	{"valuation": 30000000, "name": "Supergiant Games"},
	{"valuation": 50000000, "name": "Ubisoft"},
	{"valuation": 80000000, "name": "Zynga"},
	{"valuation": 150000000, "name": "Valve"},
	{"valuation": 300000000, "name": "Discord"},
	{"valuation": 500000000, "name": "Epic Games"},
	{"valuation": 800000000, "name": "Roblox"},
	{"valuation": 1500000000, "name": "EA"},
	{"valuation": 3000000000, "name": "Spotify"},
	{"valuation": 5000000000, "name": "Nintendo"},
	{"valuation": 10000000000, "name": "AMD"},
	{"valuation": 15000000000, "name": "Netflix"},
	{"valuation": 30000000000, "name": "Sony"},
	{"valuation": 50000000000, "name": "Samsung"},
	{"valuation": 80000000000, "name": "Oracle"},
	{"valuation": 150000000000, "name": "Meta"},
	{"valuation": 300000000000, "name": "Tesla"},
	{"valuation": 500000000000, "name": "Google"},
	{"valuation": 1000000000000, "name": "World Domination"},
]
