# Click Backlog — Design Spec

## Суть изменений

Заменяем автоматический бэклог с UI менеджментом на кнопку клика. Игрок кликает по кнопке "Бэклог" в HUD чтобы генерировать задачи в очередь. N кликов = 1 таска. N растёт линейно с уровнем. Это создаёт активный слой геймплея и подготавливает почву для автокликер-апгрейда.

---

## 1. Механика

### Клики → задача

Каждый клик по кнопке эмитит `SB.backlog_clicked`. PlayerData считает клики:

```gdscript
var _click_progress: int = 0

func _on_backlog_clicked() -> void:
    _click_progress += 1
    if _click_progress >= _get_clicks_needed():
        _click_progress = 0
        _spawn_task_to_queue()
        SB.backlog_task_spawned.emit()

func _get_clicks_needed() -> int:
    return Constants.BASE_CLICKS_PER_TASK + level
```

Уровень 0 → 3 клика. Уровень 10 → 13 кликов. Уровень 20 → 23. Линейный рост.

### Тип задачи

Определяется по tech_debt (как раньше):
- `bug_chance = tech_debt * 0.01`
- `refactor_chance = tech_debt * 0.005`
- Остальное — фичи

### HP задачи

Как раньше: `Constants.BASE_HP * task.base_hp_mult * pow(2.0, minutes_elapsed)`

---

## 2. Сигналы

### Новые

| Сигнал | Кто эмитит | Кто слушает |
|--------|-----------|-------------|
| `backlog_clicked` | HUD (кнопка) | PD (считает клики), AM (звук клика) |
| `backlog_task_spawned` | PD | HUD (сброс прогресс-бара) |

### Убираем

- `backlog_refreshed`

---

## 3. Constants

### Добавить

```gdscript
const BASE_CLICKS_PER_TASK: int = 3
```

### Убрать

- `BASE_BACKLOG_SIZE`
- `BACKLOG_REFRESH_INTERVAL`

`BUG_SPAWN_MULTIPLIER` и `REFACTOR_SPAWN_MULTIPLIER` оставляем — используются в `_create_task_by_debt()`.

---

## 4. HUD

### Кнопка

- Одна большая кнопка по центру внизу, заменяет текущую "Бэклог"
- Текст: "Бэклог (0/3)" — обновляется при каждом клике и при `backlog_task_spawned`
- `custom_minimum_size = Vector2(250, 60)`, font_size = 26

### Прогресс-бар

- Над кнопкой, той же ширины
- `value = click_progress / clicks_needed`
- При `backlog_task_spawned` — сбрасывается на 0

### Tween на клик

- Кнопка скейлится до 0.95 и обратно к 1.0 за 0.1с
- `pivot_offset` в центр кнопки

### Звук

- `AM` слушает `SB.backlog_clicked` → играет `click.wav`

---

## 5. Что удаляем

### Файлы

- `components/ui/ui_task_backlog/` — вся папка

### Из PlayerData

- `var backlog: Array[TaskData]`
- `var _backlog_timer: float`
- `func fill_backlog()`
- `func _spawn_backlog_task()`
- `func add_tasks_to_queue()`
- `func get_backlog_refresh_progress()`
- Логика авто-рефреша бэклога в `_process()`

### Из SignalBus

- `signal backlog_refreshed`

### Из Constants

- `BASE_BACKLOG_SIZE`
- `BACKLOG_REFRESH_INTERVAL`

### Из test_level.tscn

- Нода `UiTaskBacklog`

### Из hud.tscn

- Текущая кнопка "Бэклог" заменяется новой кнопкой клика с прогресс-баром

---

## 6. PlayerData изменения

### Убрать

- `backlog` массив и вся логика с ним
- `_backlog_timer` и авто-рефреш в `_process()`
- `fill_backlog()`, `_spawn_backlog_task()`, `add_tasks_to_queue()`
- `get_backlog_refresh_progress()`

### Добавить

```gdscript
var _click_progress: int = 0

func _on_backlog_clicked() -> void:
    _click_progress += 1
    if _click_progress >= _get_clicks_needed():
        _click_progress = 0
        _spawn_task_to_queue()
        SB.backlog_task_spawned.emit()

func _get_clicks_needed() -> int:
    return Constants.BASE_CLICKS_PER_TASK + level

func _spawn_task_to_queue() -> void:
    var task: TaskData = _create_task_by_debt()
    _scale_task_hp(task)
    task_queue.append(task)
    SB.task_queue_changed.emit(task_queue)
```

### В reset()

- `_click_progress = 0`

### В start_game()

- Убрать вызов `fill_backlog()`
