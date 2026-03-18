# Signal Bus (Шина событий) в Godot

Паттерн: централизованная коммуникация между компонентами через глобальный синглтон с сигналами.

---

## Суть подхода

```
SignalBus (autoload)
    ├── signal resource_updated(id, amount)
    ├── signal button_pressed(button_id)
    ├── signal enemy_damaged(enemy, damage)
    └── signal game_over()
           ↑
    emit() │ connect()
           │
    ┌──────┴──────┐
    │             │
UI Layer    Game Logic    Audio    Save System
```

**Проблема без Signal Bus:**

```gdscript
# Без шины: жёсткая связность
class_name HealthBar

var player: Player  # Нужна прямая ссылка!

func _ready():
    player.health_changed.connect(_on_health_changed)  # Зависим от Player
```

**С Signal Bus:**

```gdscript
# С шиной: слабая связность
class_name HealthBar

func _ready():
    SignalBus.health_changed.connect(_on_health_changed)  # Не знаем про Player
```

---

## Реализация

### 1. Autoload скрипт

```gdscript
# signal_bus.gd
extends Node

# === UI сигналы ===
signal button_hover(button_id: String)
signal button_pressed(button_id: String)
signal tab_changed(tab_index: int)

# === Игровые сигналы ===
signal resource_generated(id: String, amount: int)
signal resource_updated(id: String, new_value: int)
signal enemy_damaged(enemy_id: String, damage: int)
signal player_death()

# === Системные сигналы ===
signal save_requested()
signal settings_changed(setting: String, value: Variant)
signal language_updated(locale: String)
```

### 2. Регистрация в project.godot

```ini
[autoload]

SignalBus="*res://global/autoload/signal_bus.gd"
```

Звёздочка `*` означает — создать при старте игры.

### 3. Emit (отправка)

```gdscript
# В любом месте игры
func _on_button_click():
    SignalBus.button_pressed.emit("upgrade_sword")

func take_damage(amount: int):
    health -= amount
    SignalBus.player_damaged.emit(amount, health)

    if health <= 0:
        SignalBus.player_death.emit()
```

### 4. Connect (подписка)

```gdscript
# UI компонент
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
extends Node

# ╔════════════════════════════════════════╗
# ║              UI → Controller           ║
# ╚════════════════════════════════════════╝
# UI отправляет намерения пользователя
signal button_pressed(id: String)
signal slider_changed(id: String, value: float)
signal item_dropped(from_slot: int, to_slot: int)

# ╔════════════════════════════════════════╗
# ║           Controller → Manager         ║
# ╚════════════════════════════════════════╝
# Контроллеры командуют менеджерам
signal add_resource(id: String, amount: int)
signal spawn_enemy(type: String, position: Vector2)
signal save_game()

# ╔════════════════════════════════════════╗
# ║            Manager → UI                ║
# ╚════════════════════════════════════════╝
# Менеджеры уведомляют об изменениях
signal resource_updated(id: String, new_value: int)
signal enemy_spawned(enemy: Node)
signal game_saved()

# ╔════════════════════════════════════════╗
# ║              Глобальные                ║
# ╚════════════════════════════════════════╝
signal game_paused()
signal game_resumed()
signal scene_changing(to: String)
```

### Naming convention

| Слой | Паттерн | Пример |
|------|---------|--------|
| UI → Logic | `{action}_{target}` | `button_pressed`, `item_dropped` |
| Logic → UI | `{target}_{past_tense}` | `resource_updated`, `enemy_killed` |
| Состояние | `{noun}_{change}` | `health_changed`, `level_up` |
| Запрос | `{action}_requested` | `save_requested`, `pause_requested` |

---

## Типизированные сигналы

### С параметрами

```gdscript
# Типизация помогает IDE и предотвращает ошибки
signal damage_dealt(
    target_id: String,
    amount: int,
    damage_type: String,
    is_critical: bool
)

# Использование
SignalBus.damage_dealt.emit("goblin_01", 50, "fire", true)

# Подписка с правильными типами
func _on_damage_dealt(target_id: String, amount: int, type: String, crit: bool):
    if crit:
        _show_critical_effect(target_id, amount)
```

### Enum вместо String

```gdscript
# Безопаснее использовать enum
enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING }

signal damage_dealt(target_id: String, amount: int, type: DamageType)

# Использование
SignalBus.damage_dealt.emit("goblin", 50, DamageType.FIRE)
```

---

## Отключение сигналов

### При удалении ноды

```gdscript
func _ready():
    SignalBus.game_event.connect(_on_game_event)

func _exit_tree():
    # Godot 4 делает это автоматически, но explicit лучше
    if SignalBus.game_event.is_connected(_on_game_event):
        SignalBus.game_event.disconnect(_on_game_event)
```

### One-shot сигналы

```gdscript
# Автоотключение после первого вызова
SignalBus.level_loaded.connect(_on_first_load, CONNECT_ONE_SHOT)

func _on_first_load():
    _play_intro_cutscene()  # Только один раз
```

---

## Deferred vs Immediate

### Immediate (по умолчанию)

```gdscript
# Выполняется сразу в текущем frame
SignalBus.button_pressed.emit("attack")
print("После emit")  # Выведется ПОСЛЕ обработки всех подписчиков
```

### Deferred

```gdscript
# Выполнится в конце frame (безопаснее для удаления нод)
SignalBus.enemy_killed.connect(_on_enemy_killed, CONNECT_DEFERRED)

func _on_enemy_killed(enemy: Node):
    enemy.queue_free()  # Безопасно, т.к. deferred
```

---

## Паттерны использования

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
    if success:
        _show_notification("Saved!")
```

### Broadcast

```gdscript
# Один emit — много подписчиков
SignalBus.game_paused.emit()

# Подписаны: UI, Audio, Enemies, Physics, Particles...
# Все получат сигнал и среагируют по-своему
```

### Chain

```gdscript
# UI → Controller → Manager → UI

# 1. UI отправляет
SignalBus.upgrade_button_pressed.emit("sword")

# 2. Controller обрабатывает
func _on_upgrade_pressed(item_id: String):
    if _can_afford(item_id):
        SignalBus.apply_upgrade.emit(item_id)

# 3. Manager применяет
func _on_apply_upgrade(item_id: String):
    items[item_id].level += 1
    SignalBus.item_upgraded.emit(item_id, items[item_id].level)

# 4. UI обновляется
func _on_item_upgraded(item_id: String, new_level: int):
    _update_item_display(item_id, new_level)
```

---

## Когда НЕ использовать Signal Bus

### ❌ Для parent-child

```gdscript
# Плохо: шина для локальной коммуникации
class_name InventorySlot

func _on_click():
    SignalBus.inventory_slot_clicked.emit(slot_index)  # Избыточно

# Хорошо: прямой сигнал
signal clicked(slot_index: int)

func _on_click():
    clicked.emit(slot_index)  # Parent подпишется напрямую
```

### ❌ Для tight coupling

```gdscript
# Плохо: данные летают через шину
SignalBus.get_player_health.emit()
# Как получить ответ? Куда?

# Хорошо: прямой доступ или dependency injection
var health = player.get_health()
```

### ✅ Когда использовать

| Сценарий | Signal Bus? |
|----------|-------------|
| UI ↔ Game Logic | Да |
| Глобальные события | Да |
| Несвязанные системы | Да |
| Parent ↔ Child | Нет |
| Получение данных | Нет |
| Один конкретный получатель | Нет |

---

## Отладка

### Логирование всех сигналов

```gdscript
# debug_signal_logger.gd (только для разработки)
extends Node

func _ready():
    for sig in SignalBus.get_signal_list():
        SignalBus.connect(sig.name, _log_signal.bind(sig.name))

func _log_signal(signal_name: String):
    print("[SignalBus] %s" % signal_name)
```

### Проверка подписчиков

```gdscript
# Сколько подписчиков у сигнала?
var connections = SignalBus.get_signal_connection_list("player_death")
print("Подписчиков: ", connections.size())

for conn in connections:
    print("  - ", conn.callable)
```

---

## Резюме

| Аспект | Рекомендация |
|--------|--------------|
| Где хранить | `autoload/signal_bus.gd` |
| Именование | `{noun}_{verb}` или `{action}_{target}` |
| Типизация | Всегда указывать типы параметров |
| Отключение | Godot 4 делает автоматически, но explicit лучше |
| Scope | Только глобальные/cross-system события |
| Debug | Логировать в dev, отключать в prod |

**Главное правило:** Signal Bus — для слабосвязанных систем. Если компоненты тесно связаны, используйте прямые сигналы или dependency injection.
