class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType {VIBECODER, DEVELOPER, SENIOR}
enum TaskType {FEATURE, BUG}
enum Music {FR, FR3, SG, SPB}
enum Sfx {PICKUP, HIT_HURT, EXPLOSION, CLICK}
enum UpgradeType {GLOBAL, DEV}
enum UpgradeStat {
	GLOBAL_DAMAGE,
	FEATURE_DAMAGE,
	BUG_DAMAGE,
	FEATURE_CHANCE,
	BUG_CHANCE,
	BOOST_POWER,
	BOOST_DURATION,
	AUTO_CLICK_SPEED,
	REWARD_BONUS,
	UPGRADE_CHOICES,
}
enum UpgradeRarity {COMMON, UNCOMMON, EPIC, LEGENDARY}
enum TradeOffType {PURE, TRADE_OFF}

const BASE_HP: int = 100
const BASE_DAMAGE: int = int(BASE_HP * 0.4)
const XP_BASE: int = 100
const SPEED_CAP: float = 0.1
const MAX_DEV_STAT_MULTIPLIER: float = 2.0

const BASE_TOTAL_GAME_TIME: float = 600.0
const HIRE_LEVELS: Array[int] = [0, 3, 6, 10, 14, 18, 23, 28, 34]

const SPRINT_SIZE: int = 10
const MAX_LEVEL: int = 40

const BASE_ATTACK_SPEED: float = 2.0
const MAX_BOOST: int = 5
const BOOST_DECAY_RATE: float = 5.0
const BOOST_SPEED_MULT: float = 0.2
const AUTO_CLICK_BASE_INTERVAL: float = 3.0

const STAT_COSTS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: 1.5,
	UpgradeStat.FEATURE_DAMAGE: 1.0,
	UpgradeStat.BUG_DAMAGE: 1.0,
	UpgradeStat.FEATURE_CHANCE: 0.5,
	UpgradeStat.BUG_CHANCE: 0.5,
	UpgradeStat.BOOST_POWER: 1.0,
	UpgradeStat.BOOST_DURATION: 0.8,
	UpgradeStat.AUTO_CLICK_SPEED: 1.2,
	UpgradeStat.REWARD_BONUS: 0.7,
	UpgradeStat.UPGRADE_CHOICES: 10.0,
}

const RARITY_BUDGETS: Dictionary = {
	UpgradeRarity.COMMON: 10,
	UpgradeRarity.UNCOMMON: 20,
	UpgradeRarity.EPIC: 35,
	UpgradeRarity.LEGENDARY: 50,
}

const TRADE_OFF_RETURN_RATE: float = 0.5

const BASE_FEATURE_CHANCE: float = 50.0
const BASE_BUG_CHANCE: float = 50.0
const BASE_UPGRADE_CHOICES: int = 3
const MAX_UPGRADE_CHOICES: int = 5

const STAT_GLOBAL_DAMAGE: String = "global_damage"
const STAT_FEATURE_DAMAGE: String = "feature_damage"
const STAT_BUG_DAMAGE: String = "bug_damage"
const STAT_FEATURE_CHANCE: String = "feature_chance"
const STAT_BUG_CHANCE: String = "bug_chance"
const STAT_BOOST_POWER: String = "boost_power"
const STAT_BOOST_DURATION: String = "boost_duration"
const STAT_AUTO_CLICK_SPEED: String = "auto_click_speed"
const STAT_REWARD_BONUS: String = "reward_bonus"

const STAT_DISPLAY_NAMES: Dictionary = {
	STAT_GLOBAL_DAMAGE: "Global Damage",
	STAT_FEATURE_DAMAGE: "Feature Damage",
	STAT_BUG_DAMAGE: "Bug Damage",
	STAT_FEATURE_CHANCE: "Feature Chance",
	STAT_BUG_CHANCE: "Bug Chance",
	STAT_BOOST_POWER: "Boost Power",
	STAT_BOOST_DURATION: "Boost Duration",
	STAT_AUTO_CLICK_SPEED: "Auto Click Speed",
	STAT_REWARD_BONUS: "Reward Bonus",
}

# game level ranges -> rarity weights for rolling upgrade rarity
const RARITY_APPEARANCE_RATES: Array[Dictionary] = [
	# levels 1-10
	{UpgradeRarity.COMMON: 0.80, UpgradeRarity.UNCOMMON: 0.20, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	# levels 11-20
	{UpgradeRarity.COMMON: 0.40, UpgradeRarity.UNCOMMON: 0.35, UpgradeRarity.EPIC: 0.20, UpgradeRarity.LEGENDARY: 0.05},
	# levels 21-30
	{UpgradeRarity.COMMON: 0.15, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.35, UpgradeRarity.LEGENDARY: 0.20},
	# levels 31-40
	{UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.20, UpgradeRarity.EPIC: 0.40, UpgradeRarity.LEGENDARY: 0.30},
]

# elapsed time thresholds -> game_level
const GAME_LEVEL_THRESHOLDS: Array[float] = [
	BASE_TOTAL_GAME_TIME * 0.0, # level 1
	BASE_TOTAL_GAME_TIME * 0.1, # level 2
	BASE_TOTAL_GAME_TIME * 0.2, # level 3
	BASE_TOTAL_GAME_TIME * 0.3, # level 4
	BASE_TOTAL_GAME_TIME * 0.4, # level 5
	BASE_TOTAL_GAME_TIME * 0.5, # level 6
	BASE_TOTAL_GAME_TIME * 0.6, # level 7
	BASE_TOTAL_GAME_TIME * 0.7, # level 8
	BASE_TOTAL_GAME_TIME * 0.8, # level 9
	BASE_TOTAL_GAME_TIME * 0.9, # level 10
]

# game_level -> task HP
const TASK_HP_BY_LEVEL: Dictionary[int, int] = {
	1: BASE_HP * 1, # 100
	2: BASE_HP * 3, # 300
	3: BASE_HP * 6, # 600
	4: BASE_HP * 30, # 3000
	5: BASE_HP * 60, # 6000
	6: BASE_HP * 600, # 60000
	7: BASE_HP * 1200, # 120000
	8: BASE_HP * 30000, # 3000000
	9: BASE_HP * 60000, # 6000000
	10: BASE_HP * 150000, # 15000000
}

# Placeholder values — tune during playtesting
# Cumulative XP needed to reach each level
const LEVEL_THRESHOLDS: Array[int] = [
	XP_BASE * 1, # lvl 1
	XP_BASE * 3, # lvl 2
	XP_BASE * 6, # lvl 3
	XP_BASE * 10, # lvl 4
	XP_BASE * 16, # lvl 5
	XP_BASE * 24, # lvl 6
	XP_BASE * 35, # lvl 7
	XP_BASE * 50, # lvl 8
	XP_BASE * 70, # lvl 9
	XP_BASE * 100, # lvl 10
	XP_BASE * 140, # lvl 11
	XP_BASE * 200, # lvl 12
	XP_BASE * 280, # lvl 13
	XP_BASE * 400, # lvl 14
	XP_BASE * 560, # lvl 15
	XP_BASE * 800, # lvl 16
	XP_BASE * 1100, # lvl 17
	XP_BASE * 1600, # lvl 18
	XP_BASE * 2200, # lvl 19
	XP_BASE * 3200, # lvl 20
	XP_BASE * 4500, # lvl 21
	XP_BASE * 6400, # lvl 22
	XP_BASE * 9000, # lvl 23
	XP_BASE * 13000, # lvl 24
	XP_BASE * 18000, # lvl 25
	XP_BASE * 25000, # lvl 26
	XP_BASE * 36000, # lvl 27
	XP_BASE * 50000, # lvl 28
	XP_BASE * 70000, # lvl 29
	XP_BASE * 100000, # lvl 30
	XP_BASE * 140000, # lvl 31
	XP_BASE * 200000, # lvl 32
	XP_BASE * 280000, # lvl 33
	XP_BASE * 400000, # lvl 34
	XP_BASE * 560000, # lvl 35
	XP_BASE * 800000, # lvl 36
	XP_BASE * 1100000, # lvl 37
	XP_BASE * 1600000, # lvl 38
	XP_BASE * 2200000, # lvl 39
	XP_BASE * 3200000, # lvl 40
]

const RARITY_COLORS: Dictionary = {
	UpgradeRarity.COMMON: Color(0.6, 0.6, 0.6),
	UpgradeRarity.UNCOMMON: Color(0.2, 0.4, 1.0),
	UpgradeRarity.EPIC: Color(0.6, 0.2, 0.8),
	UpgradeRarity.LEGENDARY: Color(0.9, 0.2, 0.2),
}

const STAT_POSITIVE_COLOR: Color = Color(0.2, 0.8, 0.2)
const STAT_NEGATIVE_COLOR: Color = Color(0.9, 0.2, 0.2)

const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 500, "name": "Zynga"},
	{"valuation": 5000, "name": "Niantic"},
	{"valuation": 50000, "name": "Ubisoft"},
	{"valuation": 500000, "name": "EA"},
	{"valuation": 5000000, "name": "Valve"},
	{"valuation": 50000000, "name": "Epic Games"},
	{"valuation": 500000000, "name": "Apple"},
	{"valuation": 5000000000, "name": "Microsoft"},
	{"valuation": 100000000000, "name": "US GDP"},
	{"valuation": 1000000000000, "name": "World Domination"},
]
