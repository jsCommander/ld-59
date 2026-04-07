class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }

const BASE: int = 100
const DEBT_PER_TASK: float = 0.6
const TECH_DEBT_PER_HIT: float = 0.01

const PRIORITY_TIERS: Array[Dictionary] = [
	{"max_debt": 30.0, "priority": 1.0},
	{"max_debt": 60.0, "priority": 1.5},
	{"max_debt": 90.0, "priority": 2.0},
]
const MAX_PRIORITY: float = 2.5

const MIN_QUEUE_SIZE: int = 10
const BACKLOG_SIZE: int = 15
const BUG_SPAWN_MULTIPLIER: float = 0.01
const REFACTOR_SPAWN_MULTIPLIER: float = 0.005

enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT }
