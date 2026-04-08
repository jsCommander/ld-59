# Autonomous Dev Combat — Design Spec

## Суть изменений

Каждый разработчик становится автономным агентом. Сам выбирает таску из очереди через TaskSelectFunction, сам бьёт её локально, показывает таску над собой с HP баром и damage numbers. PD больше не считает урон — только хранит стейт и обрабатывает rewards.

---

## 1. Developer — автономный боец

### Новый flow

1. Дев не имеет таски → вызывает `data.task_select.select(data, PD.task_queue)`
2. Получает лучшую таску, вызывает `PD.take_task(task)` — PD удаляет из очереди и возвращает таску (или null если уже забрали)
3. Бьёт локально в `_process` по таймеру атаки
4. Урон считает через `Balance.calculate_damage(data, task.task_type, PD.global_upgrades, PD.dev_upgrades.get(data.dev_type, []))`
5. Показывает damage numbers над собой, обновляет HP бар таски
6. Добил → эмитит `SB.task_destroyed(task)`, считает debt через `Balance.calculate_debt(...)`, эмитит `SB.tech_debt_produced(delta)` → берёт следующую
7. Очередь пустая → idle

### Новые поля в Developer.gd

```gdscript
var _current_task: TaskData = null
@onready var task_display: TaskDisplay = %TaskDisplay
```

### Атака (в _process)

```gdscript
if not _current_task:
    _pick_task()
    if not _current_task:
        return  # idle

var speed: float = Balance.calculate_attack_speed(data, PD.global_upgrades, PD.dev_upgrades.get(data.dev_type, []))
_attack_timer += delta
if _attack_timer >= speed:
    _attack_timer -= speed
    _perform_attack()
```

### _pick_task()

```gdscript
func _pick_task() -> void:
    if PD.task_queue.is_empty():
        return
    var task: TaskData = data.task_select.select(data, PD.task_queue)
    if task:
        _current_task = PD.take_task(task)
        if _current_task:
            task_display.show_task(_current_task)
```

Дев выбирает через TaskSelectFunction, затем вызывает `PD.take_task(task)`. PD подтверждает и удаляет из очереди. Если таску уже забрал другой дев — возвращает `null`.

```gdscript
# PlayerData
func take_task(task: TaskData) -> TaskData:
    if task not in task_queue:
        return null
    task_queue.erase(task)
    SB.task_queue_changed.emit(task_queue)
    return task
```

### _perform_attack()

```gdscript
func _perform_attack() -> void:
    var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, PD.dev_upgrades.get(data.dev_type, []))
    _current_task.current_hp -= damage
    show_damage(int(damage))
    task_display.update_hp(_current_task.current_hp, _current_task.max_hp)
    if _current_task.current_hp <= 0.0:
        _on_task_killed()
```

### _on_task_killed()

```gdscript
func _on_task_killed() -> void:
    var debt: float = Balance.calculate_debt(data, PD.global_upgrades, PD.dev_upgrades.get(data.dev_type, []))
    SB.task_destroyed.emit(_current_task)
    SB.tech_debt_produced.emit(debt)
    task_display.hide_task()
    _current_task = null
```

---

## 2. TaskSelectFunction — ресурс выбора таски

```gdscript
class_name TaskSelectFunction extends Resource

func select(dev_data: DeveloperData, tasks: Array[TaskData]) -> TaskData:
    var best_task: TaskData = null
    var best_score: float = -1.0
    for task: TaskData in tasks:
        var score: float = Balance.get_task_mult(dev_data, task.task_type)
        if score > best_score:
            best_score = score
            best_task = task
    return best_task
```

Сабресурс в DeveloperData:

```gdscript
@export var task_select: TaskSelectFunction
```

Дефолтная реализация: возвращает таску с максимальным мультом для дева. Один .tres шарится между всеми девами.

---

## 3. Balance — глобальный класс формул

`globals/balance.gd`, `class_name Balance`. Все функции статические, принимают сырые данные.

```gdscript
class_name Balance

static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
    var base: float = Constants.BASE_DAMAGE
    var task_mult: float = get_task_mult(dev_data, task_type)
    var damage_mult: float = _calc_mult(Constants.UpgradeStat.DAMAGE, global_upgrades, dev_upgrades)
    return base * task_mult * damage_mult

static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
    var base: float = dev_data.base_attack_speed
    var speed_mult: float = _calc_mult(Constants.UpgradeStat.SPEED, global_upgrades, dev_upgrades)
    return base / speed_mult

static func calculate_debt(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
    var base: float = Constants.BASE_DEBT_PER_TASK
    var debt_mult: float = dev_data.base_debt_mult * _calc_mult(Constants.UpgradeStat.DEBT, global_upgrades, dev_upgrades)
    return base * debt_mult

static func calculate_refactor_reward() -> float:
    return Constants.DEBT_REDUCTION_PER_REFACTOR

static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
    match task_type:
        Constants.TaskType.FEATURE: return dev_data.base_feature_mult
        Constants.TaskType.BUG: return dev_data.base_bug_mult
        Constants.TaskType.REFACTOR: return dev_data.base_refactor_mult
    return 1.0

static func scale_task_hp(base_hp_mult: float, minutes_elapsed: float) -> float:
    return Constants.BASE_HP * base_hp_mult * pow(2.0, minutes_elapsed)

static func get_xp_for_level(level: int) -> int:
    return Constants.XP_BASE * int(pow(2, level - 1))

static func get_clicks_needed() -> int:
    return Constants.BASE_CLICKS_PER_TASK

static func _calc_mult(stat: Constants.UpgradeStat, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
    var mult: float = 1.0
    for upgrade: UpgradeData in global_upgrades:
        if upgrade.stat == stat:
            mult *= upgrade.multiplier
    for upgrade: UpgradeData in dev_upgrades:
        if upgrade.stat == stat:
            mult *= upgrade.multiplier
    return mult
```

---

## 4. TaskDisplay — визуал таски над девом

Отдельная сцена `components/developer/task_display.tscn`, child в developer.tscn.

### Состав

- TextureRect — иконка типа таски
- ProgressBar — HP бар
- Позиция: над спрайтом дева

### Интерфейс

```gdscript
class_name TaskDisplay extends Control

func show_task(task: TaskData) -> void
func update_hp(current_hp: float, max_hp: float) -> void
func hide_task() -> void
```

Скрыт когда дев idle. Появляется при взятии таски.

---

## 5. PlayerData изменения

### Убираем

- Все кешированные мультипликаторы (9 штук: global_damage_mult, vibecoder_damage_mult, ...)
- `_on_developer_attack()`, `_calculate_damage()`, `_calculate_debt()`, `_get_task_mult()`
- `_apply_upgrade()` — переписываем
- Коннект к `SB.developer_attack`

### Добавляем

```gdscript
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}  # Constants.DevType → Array[UpgradeData]
```

### _apply_upgrade() — новая версия

```gdscript
func _apply_upgrade(upgrade: UpgradeData) -> void:
    if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
        global_upgrades.append(upgrade)
    elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
        if upgrade.target_dev_type not in dev_upgrades:
            dev_upgrades[upgrade.target_dev_type] = []
        dev_upgrades[upgrade.target_dev_type].append(upgrade)
    elif upgrade.upgrade_type == Constants.UpgradeType.UNLOCK:
        match upgrade.stat:
            Constants.UpgradeStat.AUTO_CLICK: _unlock_auto_click()
    Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])
```

Автоклик-апгрейды (AUTO_CLICK_COUNT, AUTO_CLICK_SPEED) — тоже GLOBAL, попадут в `global_upgrades`. Balance._calc_mult их подхватит.

### Коннекты

```gdscript
SB.task_destroyed.connect(_on_task_destroyed)
SB.tech_debt_produced.connect(_on_tech_debt_produced)
```

`_on_task_destroyed(task: TaskData)` — rewards. Дев уже удалил таску из очереди при `_pick_task`, поэтому PD не трогает очередь. Только:
- FEATURE → `valuation += int(task.max_hp)`, emit `valuation_changed`, `_check_level_up()`
- BUG → ничего
- REFACTOR → `increase_tech_debt(-Constants.DEBT_REDUCTION_PER_REFACTOR)`

`_on_tech_debt_produced`:
```gdscript
func _on_tech_debt_produced(delta: float) -> void:
    increase_tech_debt(delta)
```

### reset()

```gdscript
global_upgrades.clear()
dev_upgrades.clear()
```

Вместо сброса 9 мультов.

### Автоклик

`_on_auto_click_tick()` и `_unlock_auto_click()` — остаются. Скорость автоклика теперь через Balance:

```gdscript
func _update_auto_click_timer() -> void:
    if _auto_click_timer:
        var speed_mult: float = Balance._calc_mult(Constants.UpgradeStat.AUTO_CLICK_SPEED, global_upgrades, [])
        _auto_click_timer.wait_time = Constants.BASE_AUTO_CLICK_INTERVAL / speed_mult
```

---

## 6. Сигналы

### Новые

- `SB.tech_debt_produced(delta: float)` — дев произвёл техдолг

### Убираем

- `SB.developer_attack` — не нужен, дев сам бьёт
- `SB.task_hp_changed` — не нужен, дев сам обновляет свой TaskDisplay

---

## 7. Constants

### Добавить

```gdscript
const BASE_DEBT_PER_TASK: float = 1.0
const DEBT_REDUCTION_PER_REFACTOR: float = 5.0
```

### Убрать

- `BASE_DEBT_PER_HP` — заменён на `BASE_DEBT_PER_TASK`
- `DEBT_PER_TASK` — заменён на `DEBT_REDUCTION_PER_REFACTOR` (более явное имя)

### Пояснение по изменению модели debt

Debt теперь фиксированный за таску (не пропорциональный HP/урону). Это осознанное решение — при экспоненциальном росте HP per-hit debt улетал в потолок. Фиксированный debt за таску создаёт саморегулирующийся цикл через состав task bag.

---

## 8. Новые файлы

| Файл | Назначение |
|------|-----------|
| `globals/balance.gd` | Все формулы баланса, class_name Balance |
| `game_data/task_select_function.gd` | TaskSelectFunction ресурс |
| `game_data/task_select_function_default.tres` | Дефолтная реализация (по мульту) |
| `components/developer/task_display.gd` | Визуал таски над девом |
| `components/developer/task_display.tscn` | Сцена визуала |
