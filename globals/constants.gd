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
const HIRE_LEVELS: Array[int] = [0, 2, 4, 6, 8, 10, 12, 13, 14]

const MAX_TASK_QUEUE: int = 8
const TASK_BAG_SIZE: int = 10
const MAX_LEVEL: int = 25

const BASE_ATTACK_SPEED: float = 2.0
const MAX_BOOST: int = 10
const BOOST_DECAY_RATE: float = 1.0
const BOOST_SPEED_MULT: float = 0.05

# game_level -> task HP
const TASK_LEVEL_THRESHOLDS: Dictionary[int, int] = {
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
	XP_BASE * 2, # lvl 2
	XP_BASE * 5, # lvl 3
	XP_BASE * 10, # lvl 4
	XP_BASE * 18, # lvl 5
	XP_BASE * 30, # lvl 6
	XP_BASE * 50, # lvl 7
	XP_BASE * 80, # lvl 8
	XP_BASE * 130, # lvl 9
	XP_BASE * 200, # lvl 10
	XP_BASE * 320, # lvl 11
	XP_BASE * 500, # lvl 12
	XP_BASE * 800, # lvl 13
	XP_BASE * 1300, # lvl 14
	XP_BASE * 2000, # lvl 15
	XP_BASE * 3200, # lvl 16
	XP_BASE * 5000, # lvl 17
	XP_BASE * 8000, # lvl 18
	XP_BASE * 13000, # lvl 19
	XP_BASE * 20000, # lvl 20
	XP_BASE * 32000, # lvl 21
	XP_BASE * 50000, # lvl 22
	XP_BASE * 80000, # lvl 23
	XP_BASE * 130000, # lvl 24
	XP_BASE * 200000, # lvl 25
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
	{"valuation": 1000000000000, "name": "Мировое господство"},
]
