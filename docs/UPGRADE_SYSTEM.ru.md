# Система апгрейдов зданий

## TL;DR

Здания можно апгрейдить после постройки. Апгрейды хранятся в `BuildingData.tres` как массив `BuildingUpgrade` ресурсов. Каждый апгрейд имеет цену и эффекты (бонус к скорости, доп. юниты и т.д.). При сносе здания — возврат ресурсов за постройку и апгрейды.

---

## Какую задачу решает

Здания после постройки статичны — поставил и забыл. Апгрейды дают возможность развивать конкретное здание: ускорить производство, добавить робота, расширить хранилище. Это создаёт выбор — построить новое здание или улучшить существующее.

---

## Верхнеуровневая архитектура

```
BuildingData (.tres)
  └── upgrades: Array[BuildingUpgrade]
        ├── extra_robot.tres   {cost: 5, extra_units: 1}
        ├── speed_boost.tres   {cost: 3, speed_bonus: 0.5}
        └── ...

Building (инстанс на уровне)
  ├── purchased_upgrades: Array[BuildingUpgrade]  ← рантайм
  ├── effective_crafting_speed: float              ← пересчитанный стат
  └── signal upgrade_applied(upgrade)
        │
        └──► трейты слушают и реагируют
```

**Поток данных:**

```
Клик по зданию
    │
    ▼
BuildingPopup
    ├── building.get_available_upgrades() → список доступных
    ├── Wallet.can_afford(upgrade.cost)   → подсветка/блокировка кнопок
    │
    ▼ (игрок нажал "купить")
    ├── Wallet.spend(upgrade.cost)
    └── building.apply_upgrade(upgrade)   ← прямой вызов, попап держит ссылку на building
            ├── purchased_upgrades.append(upgrade)
            ├── пересчёт effective-статов (один раз, не каждый тик)
            └── upgrade_applied.emit(upgrade)
                    │
                    ├──► ProduceTrait: пересчёт таймера
                    └──► SpawnUnitTrait: спавн доп. юнита
```

---

## Компоненты

### 1. BuildingUpgrade (ресурс)

Данные одного апгрейда. Чистые цифры, без логики.

```gdscript
class_name BuildingUpgrade extends Resource

@export var upgrade_name: String
@export var icon: Texture2D
@export var cost: int
@export var extra_units: int = 0
@export var speed_bonus: float = 0.0
```

**Файл .tres:**

```
extra_robot.tres    → {upgrade_name: "Extra Robot", cost: 5, extra_units: 1}
speed_boost.tres    → {upgrade_name: "Speed Boost", cost: 3, speed_bonus: 0.5}
```

---

### 2. BuildingData (расширение)

Добавляется поле с доступными апгрейдами.

```gdscript
# building_data.gd — новые поля
@export var cost: int = 0                            # цена постройки
@export var upgrades: Array[BuildingUpgrade] = []    # доступные апгрейды
@export var spawn_unit: UnitData                     # юнит при постройке (для robot house)
```

---

### 3. Building (рантайм состояние)

Здание хранит купленные апгрейды и пересчитывает статы. Пересчёт происходит один раз при покупке (как в Factorio — event-driven, не каждый тик).

```gdscript
# building.gd — новые поля и методы
signal upgrade_applied(upgrade: BuildingUpgrade)

var purchased_upgrades: Array[BuildingUpgrade] = []
var effective_crafting_speed: float = 1.0

func apply_upgrade(upgrade: BuildingUpgrade) -> void:
    purchased_upgrades.append(upgrade)
    _recalculate_stats()
    upgrade_applied.emit(upgrade)

func _recalculate_stats() -> void:
    # Аддитивные бонусы × база (как в Factorio)
    var total_speed_bonus: float = 0.0
    for u in purchased_upgrades:
        total_speed_bonus += u.speed_bonus
    effective_crafting_speed = data.crafting_speed * (1.0 + total_speed_bonus)

func get_available_upgrades() -> Array[BuildingUpgrade]:
    return data.upgrades.filter(
        func(u: BuildingUpgrade) -> bool:
            return u not in purchased_upgrades
    )

func get_refund() -> int:
    var total: int = data.cost
    for upgrade in purchased_upgrades:
        total += upgrade.cost
    return total
```

---

### 4. BuildingPopup (UI покупки)

Попап показывает доступные апгрейды, проверяет кошелёк, списывает ресурсы.

```gdscript
# building_popup — при показе апгрейдов
func _show_upgrades(building: Building) -> void:
    var available: Array[BuildingUpgrade] = building.get_available_upgrades()
    for upgrade in available:
        var can_buy: bool = Wallet.can_afford(upgrade.cost)
        _create_upgrade_button(upgrade, can_buy)

func _on_upgrade_button_pressed(building: Building, upgrade: BuildingUpgrade) -> void:
    Wallet.spend(upgrade.cost)
    building.apply_upgrade(upgrade)
```

---

### 5. SpawnUnitTrait (реакция на апгрейд "+1 робот")

Спавнит юнитов при постройке и при апгрейде. Деспавнит при сносе.

```gdscript
class_name SpawnUnitTrait extends Node

const UNIT_SCENE: PackedScene = preload("res://components/unit/unit.tscn")

var spawned_units: Array[Unit] = []

func _ready() -> void:
    var building: Building = get_parent() as Building
    if not building or not building.data.spawn_unit:
        return
    building.upgrade_applied.connect(_on_upgrade_applied)
    tree_exiting.connect(_on_tree_exiting)
    _spawn_unit(building.data.spawn_unit)

func _on_upgrade_applied(upgrade: BuildingUpgrade) -> void:
    if upgrade.extra_units <= 0:
        return
    var building: Building = get_parent() as Building
    for i in upgrade.extra_units:
        _spawn_unit(building.data.spawn_unit)

func _spawn_unit(unit_data: UnitData) -> void:
    var unit_manager: Node2D = get_tree().get_first_node_in_group("unit_manager")
    var unit: Unit = UNIT_SCENE.instantiate()
    unit.data = unit_data
    unit_manager.add_child(unit)
    unit.global_position = get_parent().global_position
    spawned_units.append(unit)

func _on_tree_exiting() -> void:
    for unit in spawned_units:
        if is_instance_valid(unit):
            unit.queue_free()
```

---

### 6. UnitManager (контейнер юнитов)

Нода на уровне в группе `"unit_manager"`. Все юниты — его чайлды.

```gdscript
class_name UnitManager extends Node2D

func _ready() -> void:
    add_to_group("unit_manager")
```

---

### 7. Wallet (кошелёк игрока)

Autoload. Хранит ресурсы, проверяет и списывает.

```gdscript
class_name Wallet extends Node

signal balance_changed(amount: int)

var _balance: int = 0

func get_balance() -> int:
    return _balance

func can_afford(cost: int) -> bool:
    return _balance >= cost

func add(amount: int) -> void:
    _balance += amount
    balance_changed.emit(_balance)

func spend(cost: int) -> void:
    _balance -= cost
    balance_changed.emit(_balance)
```

HUD подписывается на `Wallet.balance_changed` для отображения.

---

### 8. Возврат ресурсов при сносе

`BuildManager` при сносе считает возврат и возвращает в кошелёк.

```gdscript
# build_manager.gd
func _on_demolish_requested(building: Building) -> void:
    var refund: int = building.get_refund()
    if refund > 0:
        Wallet.add(refund)
    # ... остальной снос
```

---

## Структура файлов

```
game_data/
├── building/
│   ├── building_data.gd           # + cost, upgrades, spawn_unit
│   ├── building_robot_house.tres  # spawn_unit: unit_worker, upgrades: [extra_robot]
│   └── ...
├── upgrade/
│   ├── building_upgrade.gd        # Resource класс
│   ├── extra_robot.tres           # {cost: 5, extra_units: 1}
│   └── speed_boost.tres           # {cost: 3, speed_bonus: 0.5}
└── unit/
    └── ...

components/
├── building/
│   ├── building.gd                # + purchased_upgrades, effective stats, refund
│   └── build_manager.gd           # + refund при сносе
├── traits/
│   └── spawn_unit_trait.gd        # спавн/деспавн юнитов
└── unit/
    └── unit_manager.gd            # контейнер юнитов

autoloads/
└── wallet.gd                     # баланс, can_afford, spend, add
```

---

## Пример: Robot House с апгрейдом

```
building_robot_house.tres:
  cost: 10
  spawn_unit: unit_worker.tres
  upgrades: [extra_robot.tres]

Флоу:
1. Игрок строит Robot House → Wallet.spend(10) → SpawnUnitTrait спавнит 1 робота
2. Клик по зданию → попап с кнопкой "Extra Robot (5 DNA)"
3. Нажал → Wallet.spend(5) → building.apply_upgrade() → SpawnUnitTrait спавнит ещё 1
4. Снос → Wallet.add(15) → оба робота queue_free()
```
