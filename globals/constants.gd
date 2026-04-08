class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG }
enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT, EXPLOSION, CLICK }
enum UpgradeType { GLOBAL, DEV, UNLOCK }
enum UpgradeStat { DAMAGE, SPEED, DEBT, AUTO_CLICK, AUTO_CLICK_COUNT, AUTO_CLICK_SPEED }

const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const BASE_DEBT_PER_TASK: float = 1.0
const XP_BASE: int = int(BASE_HP * 0.3)
const BASE_CLICKS_PER_TASK: int = 1
const BASE_AUTO_CLICK_INTERVAL: float = 2.0
const BASE_AUTO_CLICK_COUNT: int = 1

const GAME_DURATION: float = 900.0
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const BASE_QUEUE_SIZE: int = 10
const BUG_SPAWN_MULTIPLIER: float = 0.008
