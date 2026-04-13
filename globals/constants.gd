class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType {VIBECODER, REGULAR, SENIOR}
enum TaskType {FEATURE, BUG, REFACTOR}
enum Music {FR, FR3, SG, SPB}
enum Sfx {PICKUP, HIT_HURT, EXPLOSION, CLICK}
enum UpgradeType {GLOBAL, DEV}
enum UpgradeStat {DAMAGE, SPEED}
enum UpgradeRarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

const BASE_HP: int = 100
const BASE_DAMAGE: int = int(BASE_HP * 0.4)
const XP_BASE: int = 100
const SPEED_CAP: float = 0.1

const BASE_TOTAL_GAME_TIME: float = 600.0
const HIRE_LEVELS: Array[int] = [0, 3, 6, 10, 14, 18, 23, 28, 34]

const MAX_TASK_QUEUE: int = 8
const TASK_BAG_SIZE: int = 10
const MAX_LEVEL: int = 40

const BASE_ATTACK_SPEED: float = 2.0
const MAX_BOOST: int = 10
const BOOST_DECAY_RATE: float = 1.0
const BOOST_SPEED_MULT: float = 0.05

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

# game_level threshold -> task type weights (threshold-based: use max key ≤ current level)
const TASK_TYPE_WEIGHTS: Dictionary[int, Dictionary] = {
	1: {TaskType.FEATURE: 1.0, TaskType.BUG: 0.0, TaskType.REFACTOR: 0.0},
	4: {TaskType.FEATURE: 0.7, TaskType.BUG: 0.2, TaskType.REFACTOR: 0.1},
	8: {TaskType.FEATURE: 0.3, TaskType.BUG: 0.3, TaskType.REFACTOR: 0.3},
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
	UpgradeRarity.UNCOMMON: Color(0.2, 0.8, 0.2),
	UpgradeRarity.RARE: Color(0.2, 0.4, 1.0),
	UpgradeRarity.EPIC: Color(0.6, 0.2, 0.8),
	UpgradeRarity.LEGENDARY: Color(1.0, 0.5, 0.0),
}

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
