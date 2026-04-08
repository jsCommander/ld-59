# Idle Roguelike Redesign — Design Spec

## Суть изменений

Полная смена концепции: из пошаговой стратегии со спринтами в idle game с roguelike прогрессией. Один ран = 15 минут. Набери максимальную стоимость компании. При левел-апе выбирай 1 из 4 мультипликативных апгрейдов. Собери билд.

---

## 1. Архитектура данных

### PlayerData (runtime state)

```gdscript
var valuation: int = 0          # одновременно XP и финальный счёт
var level: int = 0
var tech_debt: float = 0.0
var timer_remaining: float = 900.0

var task_queue: Array[TaskData]     # макс 10
var backlog: Array[TaskData]        # макс 15
var developers: Array[Developer]

var upgrades_taken: Array[UpgradeData] = []  # история для UI

# кешированные мультипликаторы — пересчитываются при взятии апгрейда
var global_damage_mult: float = 1.0
var global_speed_mult: float = 1.0
var global_debt_mult: float = 1.0
var vibecoder_damage_mult: float = 1.0
var vibecoder_debt_mult: float = 1.0
var regular_damage_mult: float = 1.0
var regular_speed_mult: float = 1.0
var senior_damage_mult: float = 1.0
var senior_debt_mult: float = 1.0
```

`valuation` — единственная переменная, которая служит и XP (сравнивается с кумулятивным порогом уровня), и финальным счётом.

При взятии апгрейда: добавляем в `upgrades_taken` + домножаем соответствующий мультипликатор.

Не все комбинации тип×стат имеют апгрейды в пуле. `get_type_*_mult()` возвращает 1.0 для комбинаций без апгрейда. Мультипликаторы в PlayerData создаются только для тех комбинаций, которые реально есть в пуле апгрейдов.

### DeveloperData (Resource)

Заменяет текущие `feature_damage`, `bug_damage`, `refactor_damage`, `tech_debt`, `salary_mult`.

```gdscript
class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType
@export var texture: Texture2D
@export var base_feature_mult: float = 1.0
@export var base_bug_mult: float = 1.0
@export var base_refactor_mult: float = 1.0
@export var base_debt_mult: float = 1.0     # vibecoder=3.0, regular=1.0, senior=0.0
@export var base_attack_speed: float = 2.0
```

`base_damage` и `base_debt_per_hp` — не в ресурсе, а в `Constants` (якоря баланса):

```gdscript
const BASE_DAMAGE: float = 10.0
const BASE_DEBT_PER_HP: float = 0.01
```

### Уровни (не ресурс, формула + константа)

```gdscript
const XP_BASE: int = 30
const MAX_LEVEL: int = 35
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

func get_xp_for_level(level: int) -> int:
    return XP_BASE * int(pow(2, level - 1))
```

### UpgradeData (Resource, заменяет UpgradeTree)

```gdscript
class_name UpgradeData extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D

enum UpgradeType { GLOBAL, DEV, UNLOCK }
enum Stat { DAMAGE, SPEED, DEBT }

@export var upgrade_type: UpgradeType
@export var target_dev_type: Constants.DevType  # только для DEV, иначе null
@export var stat: Stat
@export var multiplier: float  # 2.0 = ×2, 0.5 = ×0.5
```

- `GLOBAL` — множит глобальный мультипликатор (damage/speed/debt)
- `DEV` — множит мультипликатор конкретного типа дева (`target_dev_type`)
- `UNLOCK` — задел на будущее, пока не используется

Пул апгрейдов — `.tres` файлы в `game_data/upgrades/`.

---

## 2. Game Loop

### Таймер

`_process(delta)` тикает `timer_remaining -= delta`. Дошёл до 0 → экран результата с итоговой стоимостью.

### Рост HP задач

При создании задачи в бэклоге:

```gdscript
var minutes_elapsed: float = (900.0 - PD.timer_remaining) / 60.0
var hp: float = base_hp * pow(2.0, minutes_elapsed)
```

`base_hp` берётся из `TaskData` ресурса (100/80/60 для feature/bug/refactor).

HP растёт ×2 в минуту — медленнее чем DPS → power fantasy к концу рана.

### Урон

```gdscript
func calculate_damage(dev: Developer, task_type: Constants.TaskType) -> float:
    var base: float = Constants.BASE_DAMAGE
    var task_mult: float = _get_task_mult(dev.data, task_type)
    var type_mult: float = PD.get_type_damage_mult(dev.data.dev_type)
    var global_mult: float = PD.global_damage_mult
    return base * task_mult * type_mult * global_mult

func _get_task_mult(data: DeveloperData, task_type: Constants.TaskType) -> float:
    match task_type:
        Constants.TaskType.FEATURE: return data.base_feature_mult
        Constants.TaskType.BUG: return data.base_bug_mult
        Constants.TaskType.REFACTOR: return data.base_refactor_mult
    return 1.0
```

Скорость атаки:

```gdscript
func get_attack_speed(dev: Developer) -> float:
    var base: float = dev.data.base_attack_speed
    var type_mult: float = PD.get_type_speed_mult(dev.data.dev_type)
    var global_mult: float = PD.global_speed_mult
    return base / (type_mult * global_mult)
```

### Техдолг

Каждый удар:

```gdscript
tech_debt += Constants.BASE_DEBT_PER_HP * damage * dev.data.base_debt_mult * PD.get_type_debt_mult(dev.data.dev_type) * PD.global_debt_mult
```

Техдолг влияет на состав бэклога:
- `bug_chance = tech_debt * 0.01`
- `refactor_chance = tech_debt * 0.005`
- Остальное — фичи

### Награда за задачу

```
valuation += task.max_hp  # награда = HP задачи при создании
```

### Левел-ап

```
if valuation >= get_xp_for_level(level + 1) and level < MAX_LEVEL:
    level += 1
    pause game
    show_upgrade_choice(4 random из пула)
    if level in HIRE_LEVELS:
        show_hire_screen()  # после выбора апгрейда
    unpause game
```

### Конец игры

`timer_remaining <= 0` → экран результата. Нет win/lose — только счёт.

---

## 3. UI Flow

### Основной экран

Без изменений. Добавляется таймер обратного отсчёта в HUD.

HUD показывает: стоимость компании (текущая / порог следующего уровня), шкалу техдолга, таймер.

### Экран выбора апгрейдов

Левел-ап → пауза → оверлей с 4 карточками. Каждая: иконка, название, описание, множитель. Клик → применилось → оверлей закрылся.

На уровнях 3, 6, 9, 12, 15 — после выбора апгрейда второй оверлей: выбор дева (3 карточки: vibecoder/regular/senior).

### Экран результата

Таймер вышел → пауза → оверлей:
- Итоговая стоимость компании
- Достигнутый уровень
- Состав команды
- Кнопка "Заново"

---

## 4. Пул апгрейдов

9 апгрейдов, все повторяемые:

### Глобальные

| ID | Название | Эффект |
|---|---|---|
| `global_damage_2x` | Мотивационная речь | ×2 урон всем |
| `global_speed_15x` | Стендапы покороче | ×1.5 скорость атаки всем |
| `global_debt_07x` | Code Review | ×0.7 техдолг всем |

### DEV (типовые)

| ID | Название | Тип дева | Эффект |
|---|---|---|---|
| `vibecoder_damage_3x` | Cursor Pro | VIBECODER | ×3 урон |
| `vibecoder_debt_05x` | Линтер | VIBECODER | ×0.5 техдолг |
| `regular_damage_3x` | IDE плагины | REGULAR | ×3 урон |
| `regular_speed_2x` | Второй монитор | REGULAR | ×2 скорость |
| `senior_damage_3x` | Архитектурный паттерн | SENIOR | ×3 урон |
| `senior_debt_0x` | Clean Code | SENIOR | ×0 техдолг |

Анлоки отложены на потом.

---

## 5. Что выпиливаем

### Код

- `UiUpgradeTree` — UI дерева апгрейдов
- `UpgradeTreeView`, `UpgradeTreeTooltip`
- `money` из PlayerData и HUD
- Попап девелопера (найм/увольнение)
- Вся логика фаз

### Ресурсы (.tres)

- `game_data/upgrade_tree/` — все ноды дерева и layout
- `game_data/phase/` — все фазы

### Game Kit (не трогаем, просто перестаём юзать)

- `SkillTreeLayout`, `SkillTreeNodePlacement`, `UpgradeTree` — могут пригодиться в других проектах
- `CostFunction`, `CostFunctionExponential`

### Constants — убрать

`PRIORITY_TIERS`, `MAX_PRIORITY`, `STARTING_BUDGET`, всё связанное со спринтами и фазами.

### Constants — добавить

```gdscript
const GAME_DURATION: float = 900.0
const MAX_LEVEL: int = 35
const XP_BASE: int = 30
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]
const MAX_QUEUE_SIZE: int = 10
const BACKLOG_SIZE: int = 15
const BASE_DAMAGE: float = 10.0
const BASE_DEBT_PER_HP: float = 0.01
```

---

## 6. Арифметика (справочно)

### DPS scaling для достижения ~1T

- Стартовый DPS: 8 (1 vibecoder, 16 dmg / 2s)
- Нужный рост: ~10⁹× за 15 минут
- Источники: 6 девов (×6) + мультипликативные апгрейды урона (~24 штуки ×2) + скорость (~5 штук ×1.5)

### Пороги уровней

Геометрическая прогрессия: `30 × 2^(N-1)`. Сумма 35 уровней ≈ 1.03T.

### HP задач

`base_hp × 2^минута`. Растёт в ~32K раз за игру — существенно медленнее DPS, обеспечивая power fantasy.
