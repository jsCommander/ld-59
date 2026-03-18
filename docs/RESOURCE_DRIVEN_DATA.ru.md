# Data-Driven архитектура через Godot Resources

## TL;DR

Все статические игровые данные в `.tres` файлах с тремя ключевыми принципами:
- **Resources (.tres)** — неизменяемые данные (характеристики, конфиги)
- **SaveFile (JSON)** — изменяемое состояние (прогресс, инвентарь)
- **Константы для ID** — защита от опечаток, autocomplete

---

## Какую задачу решает

### Проблема 1: Данные размазаны по коду

```gdscript
# Плохо: характеристики захардкожены
func create_sword():
    var sword = Item.new()
    sword.damage = 25
    sword.price = 150
    # Чтобы изменить — ищи по всему коду
```

**Решение:** Данные в `.tres` файлах — меняешь в инспекторе Godot, код не трогаешь.

### Проблема 2: Опечатки в строковых ID

```gdscript
# Плохо: опечатка = краш в runtime
var item = Resources.items["swrod"]  # KeyError! "sword" → "swrod"

# Ещё хуже: опечатка не крашит, но данные неверные
SaveFile.resources["workerr"] += 1  # Создался новый ключ
```

**Решение:** Константы — опечатка = ошибка компиляции, autocomplete работает.

### Проблема 3: Циклические зависимости в .tres

```gdscript
# Плохо: Enemy.tres ссылается на Item.tres, Item.tres на Enemy.tres
@export var dropped_by: Enemy  # Циклическая зависимость!
```

**Решение:** Хранить только String ID, резолвить в runtime через Dictionary.

### Проблема 4: Динамика в Resource = баги

```gdscript
# Плохо: состояние в Resource
class_name Item extends Resource
var current_durability: int = 100  # Shared между всеми экземплярами!

# sword1.current_durability = 50
# sword2.current_durability тоже станет 50!
```

**Решение:** Resource = template (статика), отдельный класс = instance (динамика).

---

## Верхнеуровневая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                  Resources (autoload)                   │
│                                                         │
│  items: Dictionary        enemies: Dictionary           │
│  {"sword": Item}          {"goblin": Enemy}             │
│  {"axe": Item}            {"dragon": Enemy}             │
│                                                         │
└─────────────────────────────────────────────────────────┘
        ↑                           ↑
        │ загрузка при старте       │
        │                           │
┌───────┴───────┐           ┌───────┴───────┐
│ resources/    │           │ resources/    │
│ item/tres/    │           │ enemy/tres/   │
│ ├── sword.tres│           │ ├── goblin.tres
│ ├── axe.tres  │           │ └── dragon.tres
│ └── potion.tres           │
└───────────────┘           └───────────────┘
```

**Поток данных:**

```
Запрос данных
      │
      ▼
Constants.SWORD ──► "sword" (String ID)
      │
      ▼
Resources.items["sword"] ──► Item (.tres)
      │
      ▼
item.damage, item.price, item.icon
```

**Разделение данных:**

```
┌────────────────────┐      ┌────────────────────┐
│   Resources        │      │     SaveFile       │
│   (статика)        │      │    (динамика)      │
├────────────────────┤      ├────────────────────┤
│ Item.damage = 25   │      │ inventory = [...]  │
│ Item.price = 100   │      │ gold = 5000        │
│ Enemy.hp = 50      │      │ equipped = "sword" │
│ Enemy.loot = [...] │      │ quest_progress = {}│
└────────────────────┘      └────────────────────┘
     Не меняется                 Сохраняется
```

---

## Компоненты

### 1. Resource класс

```gdscript
# resources/game_data/item/item.gd
class_name Item
extends Resource

@export var id: String
@export var damage: int = 10
@export var price: int = 100
@export var icon: Texture2D

# Методы для вычислений
func get_value() -> int:
    return price + damage * 10
```

### 2. .tres файл

```tres
[gd_resource type="Resource" script_class="Item" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/game_data/item/item.gd" id="1"]

[resource]
script = ExtResource("1")
id = "sword"
damage = 25
price = 150
icon = null
```

Редактируется в инспекторе Godot — без кода.

### 3. Централизованная загрузка (autoload)

```gdscript
# global/autoload/resources.gd
extends Node

var items: Dictionary = {}
var enemies: Dictionary = {}

const ITEM_PATH = "res://resources/game_data/item/tres/"
const ENEMY_PATH = "res://resources/game_data/enemy/tres/"

func _ready() -> void:
    items = _load_from_dir(ITEM_PATH)
    enemies = _load_from_dir(ENEMY_PATH)

func _load_from_dir(path: String) -> Dictionary:
    var result: Dictionary = {}
    var dir = DirAccess.open(path)
    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.ends_with(".tres"):
            var resource = ResourceLoader.load(path + file_name)
            result[resource.id] = resource
        file_name = dir.get_next()

    return result
```

### 4. Константы для ID

```gdscript
# global/const/constants.gd
class_name Constants

# Items
const SWORD: String = "sword"
const AXE: String = "axe"
const POTION: String = "potion"

# Enemies
const GOBLIN: String = "goblin"
const DRAGON: String = "dragon"

# Workers
const WORKER: String = "worker"
const SWORDSMAN: String = "swordsman"

# Группировка
const WEAPON_IDS: Array[String] = [SWORD, AXE]
const CONSUMABLE_IDS: Array[String] = [POTION]
```

**Почему class_name, а не autoload:**
- Константы — статические данные, не нужен Node
- `Constants.SWORD` работает везде без инстанцирования

---

## Использование

### Прямой доступ (известный ID)

```gdscript
# Безопасно — константа гарантирует существование
var sword: Item = Resources.items[Constants.SWORD]
print(sword.damage)  # 25
```

### Безопасный доступ (динамический ID)

```gdscript
# ID из SaveFile — может быть невалидным
var item_id: String = SaveFile.equipped_weapon_id
var item: Item = Resources.items.get(item_id, null)
if item == null:
    push_error("Item not found: %s" % item_id)
    return
```

### Работа с SaveFile

```gdscript
# SaveFile хранит только ID, не сами ресурсы
var inventory: Array[String] = [Constants.SWORD, Constants.AXE, Constants.POTION]

func get_total_damage() -> int:
    var total = 0
    for item_id in inventory:
        total += Resources.items[item_id].damage
    return total

func get_inventory_items() -> Array[Item]:
    var result: Array[Item] = []
    for item_id in inventory:
        result.append(Resources.items[item_id])
    return result
```

---

## Связи между ресурсами

### Через String ID (рекомендуется)

```gdscript
class_name Enemy
extends Resource

@export var id: String
@export var hp: int
@export var loot_ids: Array[String] = []  # Только ID!

func get_loot() -> Array[Item]:
    var result: Array[Item] = []
    for loot_id in loot_ids:
        result.append(Resources.items[loot_id])
    return result
```

```tres
[resource]
id = "goblin"
hp = 50
loot_ids = ["sword", "gold", "potion"]
```

### Почему НЕ через ExtResource

```gdscript
# Плохо: прямая ссылка
@export var loot: Array[Item] = []  # ExtResource в .tres
```

| Проблема | String ID | ExtResource |
|----------|-----------|-------------|
| Циклические зависимости | Нет | Возможны |
| Lazy loading | Да | Нет (грузит всю цепочку) |
| Сериализация в JSON | Просто | Сложно |
| Читаемость .tres | Понятные строки | UUID ссылки |

---

## Strategy Pattern через Resources

Выбор алгоритма без изменения кода — через .tres в инспекторе.

### Базовый класс

```gdscript
# cost_function.gd
class_name CostFunction
extends Resource

func get_cost(base_cost: int, level: int) -> int:
    return base_cost  # По умолчанию константа
```

### Реализации

```gdscript
# linear_cost.gd
class_name LinearCost
extends CostFunction

func get_cost(base_cost: int, level: int) -> int:
    return base_cost * level

# exponential_cost.gd
class_name ExponentialCost
extends CostFunction

@export var exponent: float = 1.5

func get_cost(base_cost: int, level: int) -> int:
    return int(base_cost * pow(level, exponent))
```

### Использование

```gdscript
class_name Building
extends Resource

@export var id: String
@export var base_cost: int = 100
@export var cost_function: CostFunction  # Выбор в инспекторе!

func get_cost_at_level(level: int) -> int:
    if cost_function:
        return cost_function.get_cost(base_cost, level)
    return base_cost
```

```tres
# house.tres
[resource]
id = "house"
base_cost = 50
cost_function = ExtResource("res://resources/cost_functions/exponential.tres")
```

**Результат:** Меняешь формулу стоимости выбором .tres в инспекторе, без кода.

---

## Статика vs Динамика

### Неправильно — состояние в Resource

```gdscript
class_name Item
extends Resource

@export var max_durability: int = 100
var current_durability: int = 100  # ОШИБКА!

# Resources shared между экземплярами
# Изменение durability одного меча → изменение ВСЕХ мечей
```

### Правильно — разделение

```gdscript
# item_data.gd — Resource (template)
class_name ItemData
extends Resource

@export var id: String
@export var base_damage: int
@export var max_durability: int

# item_instance.gd — обычный класс (state)
class_name ItemInstance

var data: ItemData              # Ссылка на template
var durability: int             # Уникальное состояние
var enchantments: Array = []    # Уникальные модификаторы

func _init(item_data: ItemData):
    data = item_data
    durability = data.max_durability

func get_damage() -> int:
    return data.base_damage + _calculate_enchantment_bonus()
```

**Схема:**

```
ItemData (.tres)              ItemInstance (runtime)
┌─────────────────┐           ┌─────────────────┐
│ id = "sword"    │◄──────────│ data: ItemData  │
│ base_damage = 25│           │ durability = 87 │
│ max_durability  │           │ enchantments    │
│ = 100           │           └─────────────────┘
└─────────────────┘                   │
        ▲                             │
        │                     ┌───────┴───────┐
        │                     │               │
┌───────┴───────┐     ┌───────┴───┐   ┌───────┴───┐
│ Все мечи      │     │ sword_1   │   │ sword_2   │
│ используют    │     │ dur = 87  │   │ dur = 100 │
│ одни данные   │     │ +fire     │   │ (новый)   │
└───────────────┘     └───────────┘   └───────────┘
```

---

## Структура файлов

```
resources/
├── game_data/
│   ├── item/
│   │   ├── item.gd           # Resource класс
│   │   └── tres/
│   │       ├── sword.tres
│   │       ├── axe.tres
│   │       └── potion.tres
│   │
│   ├── enemy/
│   │   ├── enemy.gd
│   │   └── tres/
│   │       ├── goblin.tres
│   │       └── dragon.tres
│   │
│   └── cost_functions/
│       ├── cost_function.gd  # Базовый класс
│       ├── linear.tres
│       └── exponential.tres

global/
├── autoload/
│   └── resources.gd          # Загрузчик
└── const/
    └── constants.gd          # ID константы
```

---

## Резюме

| Проблема | Решение |
|----------|---------|
| Данные в коде | .tres файлы + инспектор Godot |
| Опечатки в ID | Константы (Constants.SWORD) |
| Циклические зависимости | String ID вместо ExtResource |
| Состояние в Resource | Разделение: Resource = template, класс = instance |
| Выбор алгоритма в коде | Strategy Pattern через .tres |
| Сериализация в JSON | Хранить только ID, резолвить через Resources |
