class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }
enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT, EXPLOSION, CLICK }
enum UpgradeType { GLOBAL, DEV }
enum UpgradeStat { DAMAGE, SPEED, GAME_DURATION }
enum UpgradeRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
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
const BURNOUT_DURATION: float = 5.0
const YOUTUBE_CHANCE: float = 0.1

const TASK_LEVEL_THRESHOLDS: Array[float] = [
	BASE_TOTAL_GAME_TIME * 0.0,
	BASE_TOTAL_GAME_TIME * 0.1,
	BASE_TOTAL_GAME_TIME * 0.2,
	BASE_TOTAL_GAME_TIME * 0.3,
	BASE_TOTAL_GAME_TIME * 0.4,
	BASE_TOTAL_GAME_TIME * 0.5,
	BASE_TOTAL_GAME_TIME * 0.6,
	BASE_TOTAL_GAME_TIME * 0.7,
	BASE_TOTAL_GAME_TIME * 0.8,
	BASE_TOTAL_GAME_TIME * 0.9,
]

# Placeholder values — tune during playtesting
# Derived from: expected DPS at minute N × TTK (3 sec)
const TASK_HP_MULTIPLIERS: Array[int] = [
	1,    # level 1: HP = 100 × 1 = 100
	3,    # level 2: HP = 100 × 3 = 300
	6,    # level 3
	30,   # level 4
	60,   # level 5
	600,  # level 6
	1200, # level 7
	30000, # level 8
	60000, # level 9
	150000, # level 10
]

# Placeholder values — tune during playtesting
# Cumulative XP needed to reach each level
const LEVEL_THRESHOLDS: Array[int] = [
	XP_BASE * 1,      # lvl 1
	XP_BASE * 2,      # lvl 2
	XP_BASE * 5,      # lvl 3
	XP_BASE * 10,     # lvl 4
	XP_BASE * 18,     # lvl 5
	XP_BASE * 30,     # lvl 6
	XP_BASE * 50,     # lvl 7
	XP_BASE * 80,     # lvl 8
	XP_BASE * 130,    # lvl 9
	XP_BASE * 200,    # lvl 10
	XP_BASE * 320,    # lvl 11
	XP_BASE * 500,    # lvl 12
	XP_BASE * 800,    # lvl 13
	XP_BASE * 1300,   # lvl 14
	XP_BASE * 2000,   # lvl 15
	XP_BASE * 3200,   # lvl 16
	XP_BASE * 5000,   # lvl 17
	XP_BASE * 8000,   # lvl 18
	XP_BASE * 13000,  # lvl 19
	XP_BASE * 20000,  # lvl 20
	XP_BASE * 32000,  # lvl 21
	XP_BASE * 50000,  # lvl 22
	XP_BASE * 80000,  # lvl 23
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
