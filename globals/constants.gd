class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }

const BASE: int = 100
const STARTING_BUDGET: int = BASE * 25
const DEBT_PER_TASK: float = 0.6
const MAX_CAPACITY: float = 2.0

const PRIORITY_TIERS: Array[Dictionary] = [
	{"max_debt": 30.0, "priority": 1.0},
	{"max_debt": 60.0, "priority": 1.5},
	{"max_debt": 90.0, "priority": 2.0},
]
const MAX_PRIORITY: float = 2.5
