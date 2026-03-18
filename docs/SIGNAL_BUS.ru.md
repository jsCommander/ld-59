# Signal Bus (Шина событий) в Godot

## TL;DR

Централизованная коммуникация между системами через autoload singleton с сигналами:
- **Слабая связность** — компоненты не знают друг о друге
- **Broadcast** — один emit, много подписчиков
- **Типизированные сигналы** — IDE подсказки, меньше багов

---

## Какую задачу решает

### Проблема 1: Жёсткая связность компонентов

```gdscript
# Плохо: HealthBar зависит от Player
class_name HealthBar

var player: Player  # Нужна прямая ссылка!

func _ready():
    player.health_changed.connect(_on_health_changed)

# Проблемы:
# - Как получить ссылку на player?
# - Что если player ещё не создан?
# - Что если несколько player'ов?
```

**Решение:** Signal Bus — HealthBar подписывается на глобальный сигнал, не зная кто его отправит.

### Проблема 2: Спагетти-зависимости

```
# Плохо: всё связано со всем
Player ←→ UI ←→ Audio ←→ SaveSystem ←→ Achievements
   ↑________↑_______↑__________↑____________↑

# Добавить новую систему = менять 5 других файлов
```

**Решение:** Все общаются через шину — добавление системы = подписка на нужные сигналы.

### Проблема 3: Сложно отследить поток событий

```gdscript
# Плохо: событие передаётся по цепочке
player.emit_signal("damaged")  # Кто слушает? Где искать?
# → health_bar.gd? audio.gd? achievements.gd? analytics.gd?
```

**Решение:** Все сигналы в одном файле — легко найти что происходит в игре.

### Проблема 4: Race conditions при инициализации

```gdscript
# Плохо: порядок _ready() не гарантирован
func _ready():
    var player = get_node("/root/Main/Player")  # Может не существовать!
    player.health_changed.connect(_on_health_changed)
```

**Решение:** SignalBus — autoload, всегда существует первым.

---

## Верхнеуровневая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                  SignalBus (autoload)                   │
│                                                         │
│  signal resource_generated(id, amount, source)          │
│  signal resource_updated(id, new_value)                 │
│  signal enemy_damaged(enemy_id, damage)                 │
│  signal tab_changed(tab_data)                           │
│  signal game_paused()                                   │
│  ...                                                    │
└─────────────────────────────────────────────────────────┘
              ↑ emit()              ↓ connect()
    ┌─────────┴─────────┐ ┌────────┴────────┐
    │                   │ │                 │
┌───┴───┐ ┌───┴───┐ ┌───┴───┐ ┌───┴───┐ ┌───┴───┐
│  UI   │ │ Audio │ │ Save  │ │Manager│ │  ...  │
└───────┘ └───────┘ └───────┘ └───────┘ └───────┘

Компоненты НЕ знают друг о друге — только о SignalBus
```

**Поток данных (пример):**

```
Игрок кликнул кнопку "Добыть дерево"
              │
              ▼
UI: SignalBus.progress_button_pressed.emit("wood", 10)
              │
              ▼
         SignalBus
              │
     ┌────────┼────────┬────────┐
     ▼        ▼        ▼        ▼
Controller  Audio   Analytics  Achievements
(добавляет) (звук)  (логирует) (проверяет)
     │
     ▼
SignalBus.resource_generated.emit("wood", 10)
     │
     ┌────────┼────────┐
     ▼        ▼        ▼
  Manager    UI     SaveFile
(сохраняет) (обновл) (автосейв)
```

---

## Компоненты

### 1. SignalBus (autoload)

```gdscript
# global/autoload/signal_bus.gd
extends Node

# === UI → Controller ===
signal button_pressed(id: String)
signal tab_changed(tab_data: TabData)
signal slider_changed(id: String, value: float)

# === Controller → Manager ===
signal resource_generated(id: String, amount: int, source: String)
signal enemy_damage(damage: int, source: String)
signal save_requested()

# === Manager → UI ===
signal resource_updated(id: String, new_value: int)
signal enemy_damaged(enemy_id: String, remaining_hp: int)
signal save_completed(success: bool)

# === Глобальные ===
signal main_ready()
signal game_paused()
signal game_resumed()
signal language_updated(locale: String)
```

### 2. Регистрация в project.godot

```ini
[autoload]

SignalBus="*res://global/autoload/signal_bus/signal_bus.tscn"
```

---

## Использование

### Emit (отправка)

```gdscript
# Из любого места в игре
func _on_button_click():
    SignalBus.button_pressed.emit("upgrade_sword")

func take_damage(amount: int):
    health -= amount
    SignalBus.player_damaged.emit(amount, health)

    if health <= 0:
        SignalBus.player_death.emit()
```

### Connect (подписка)

```gdscript
func _ready():
    SignalBus.player_damaged.connect(_on_player_damaged)
    SignalBus.player_death.connect(_on_player_death)

func _on_player_damaged(damage: int, current_health: int):
    health_bar.value = current_health
    _show_damage_number(damage)

func _on_player_death():
    _show_game_over_screen()
```

---

## Организация сигналов

### По слоям архитектуры

```gdscript
# ╔════════════════════════════════════════╗
# ║              UI → Controller           ║
# ╚════════════════════════════════════════╝
signal button_pressed(id: String)
signal item_dropped(from_slot: int, to_slot: int)

# ╔════════════════════════════════════════╗
# ║           Controller → Manager         ║
# ╚════════════════════════════════════════╝
signal add_resource(id: String, amount: int)
signal spawn_enemy(type: String, position: Vector2)

# ╔════════════════════════════════════════╗
# ║            Manager → UI                ║
# ╚════════════════════════════════════════╝
signal resource_updated(id: String, new_value: int)
signal enemy_spawned(enemy: Node)
```

### Naming convention

| Направление | Паттерн | Пример |
|-------------|---------|--------|
| UI → Logic | `{action}_{target}` | `button_pressed`, `item_dropped` |
| Logic → UI | `{target}_{past_tense}` | `resource_updated`, `enemy_killed` |
| Состояние | `{noun}_{change}` | `health_changed`, `level_up` |
| Запрос | `{action}_requested` | `save_requested`, `pause_requested` |

---

## Типизированные сигналы

```gdscript
# Типизация = IDE подсказки + меньше багов
signal damage_dealt(
    target_id: String,
    amount: int,
    damage_type: String,
    is_critical: bool
)

# Emit
SignalBus.damage_dealt.emit("goblin_01", 50, "fire", true)

# Connect — IDE покажет типы параметров
func _on_damage_dealt(target_id: String, amount: int, type: String, crit: bool):
    if crit:
        _show_critical_effect(target_id, amount)
```

### Enum вместо String

```gdscript
enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING }

signal damage_dealt(target_id: String, amount: int, type: DamageType)

# Использование — autocomplete работает
SignalBus.damage_dealt.emit("goblin", 50, DamageType.FIRE)
```

---

## Паттерны

### Broadcast (один ко многим)

```gdscript
# Один emit
SignalBus.game_paused.emit()

# Много подписчиков (каждый реагирует по-своему)
# - UI: показать меню паузы
# - Audio: приглушить музыку
# - Enemies: остановить AI
# - Particles: заморозить
```

### Request-Response

```gdscript
# signal_bus.gd
signal save_requested()
signal save_completed(success: bool)

# save_manager.gd
func _ready():
    SignalBus.save_requested.connect(_on_save_requested)

func _on_save_requested():
    var success = _do_save()
    SignalBus.save_completed.emit(success)

# ui.gd
func _on_save_button():
    SignalBus.save_requested.emit()
    SignalBus.save_completed.connect(_on_save_done, CONNECT_ONE_SHOT)

func _on_save_done(success: bool):
    _show_notification("Saved!" if success else "Failed!")
```

### Chain (цепочка)

```gdscript
# UI → Controller → Manager → UI

# 1. UI отправляет намерение
SignalBus.upgrade_button_pressed.emit("sword")

# 2. Controller проверяет и командует
func _on_upgrade_pressed(item_id: String):
    if _can_afford(item_id):
        SignalBus.apply_upgrade.emit(item_id)

# 3. Manager применяет изменение
func _on_apply_upgrade(item_id: String):
    items[item_id].level += 1
    SignalBus.item_upgraded.emit(item_id, items[item_id].level)

# 4. UI обновляется
func _on_item_upgraded(item_id: String, new_level: int):
    _update_item_display(item_id, new_level)
```

---

## Флаги подключения

### CONNECT_ONE_SHOT

```gdscript
# Автоотключение после первого вызова
SignalBus.level_loaded.connect(_on_first_load, CONNECT_ONE_SHOT)

func _on_first_load():
    _play_intro_cutscene()  # Только один раз
```

### CONNECT_DEFERRED

```gdscript
# Выполнится в конце frame (безопаснее для удаления нод)
SignalBus.enemy_killed.connect(_on_enemy_killed, CONNECT_DEFERRED)

func _on_enemy_killed(enemy: Node):
    enemy.queue_free()  # Безопасно — deferred
```

---

## Когда НЕ использовать Signal Bus

### Parent ↔ Child

```gdscript
# Плохо: шина для локальной коммуникации
class_name InventorySlot

func _on_click():
    SignalBus.inventory_slot_clicked.emit(slot_index)  # Избыточно!

# Хорошо: прямой сигнал
signal clicked(slot_index: int)

func _on_click():
    clicked.emit(slot_index)  # Parent подпишется напрямую
```

### Получение данных

```gdscript
# Плохо: данные через шину
SignalBus.get_player_health.emit()  # Как получить ответ?

# Хорошо: прямой доступ
var health = SaveFile.resources.get("hp", 100)
```

### Таблица решений

| Сценарий | Signal Bus? |
|----------|-------------|
| UI ↔ Game Logic | Да |
| Глобальные события (пауза, смерть) | Да |
| Несвязанные системы | Да |
| Parent ↔ Child | Нет |
| Получение данных | Нет |
| Один конкретный получатель | Нет |

---

## Отладка

### Логирование всех сигналов

```gdscript
# debug_signal_logger.gd (только для dev)
extends Node

func _ready():
    for sig in SignalBus.get_signal_list():
        SignalBus.connect(sig.name, _log_signal.bind(sig.name))

func _log_signal(signal_name: String):
    print("[SignalBus] %s" % signal_name)
```

### Проверка подписчиков

```gdscript
var connections = SignalBus.get_signal_connection_list("player_death")
print("Подписчиков: ", connections.size())

for conn in connections:
    print("  - ", conn.callable)
```

---

## Структура файлов

```
global/autoload/signal_bus/
├── signal_bus.gd     # Все сигналы
└── signal_bus.tscn   # Нода (если нужны дочерние)
```

---

## Плюсы и минусы

### Плюсы

| Фича | Польза |
|------|--------|
| Слабая связность | Компоненты независимы |
| Централизация | Все события в одном месте |
| Broadcast | Один emit → много реакций |
| Простота добавления | Новая система = только connect |

### Минусы

| Проблема | Когда критично |
|----------|----------------|
| Неявный поток данных | Сложно отследить кто на что подписан |
| Глобальное состояние | Много сигналов = хаос |
| Нет возврата значения | Не для получения данных |

---

## Резюме

| Проблема | Решение |
|----------|---------|
| Жёсткая связность | Компоненты знают только SignalBus |
| Спагетти-зависимости | Все общаются через шину |
| Сложно найти обработчики | Все сигналы в одном файле |
| Race conditions при init | Autoload существует первым |
| Broadcast события | Один emit → много connect |

**Главное правило:** Signal Bus — для слабосвязанных систем. Parent-child и получение данных — напрямую.
