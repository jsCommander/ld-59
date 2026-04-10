class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }
enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT, EXPLOSION, CLICK }
enum UpgradeType { GLOBAL, DEV, SPRINT }
enum UpgradeStat { DAMAGE, SPEED, SPRINT_DURATION, SPRINT_TASK_COMPOSITION }

const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const XP_BASE: int = int(BASE_HP * 0.3)

const GAME_DURATION: float = 600.0
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const MAX_SPRINT_TASKS: int = 8
const SPRINT_DURATION: float = 60.0

const BASE_ATTACK_SPEED: float = 0.5
const MAX_BOOST: int = 10
const BOOST_DECAY_RATE: float = 1.0
const BOOST_SPEED_MULT: float = 0.05
const BURNOUT_DURATION: float = 5.0
const YOUTUBE_CHANCE: float = 0.1
