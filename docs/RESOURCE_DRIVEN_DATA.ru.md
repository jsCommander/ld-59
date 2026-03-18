# Data-Driven архитектура через Godot Resources

Паттерн: все статические игровые данные в `.tres` файлах, централизованная загрузка через autoload.

---

## Суть подхода

```
Resources (autoload)
    ├── items: Dictionary         # {"sword": Item, "axe": Item, ...}
    ├── enemies: Dictionary        # {"goblin": Enemy, ...}
    └── abilities: Dictionary      # {"fireball": Ability, ...}
           ↑
           │ загружается из
           │
    resources/game_data/item/tres/
           ├── sword.tres
           ├── axe.tres
           └── potion.tres
```

**Разделение:**

- **Resources (.tres)** = неизменяемые данные (характеристики, конфиги)
- **SaveFile (JSON)** = изменяемое состояние (прогресс, инвентарь)

---

## Реализация

### 1. Resource класс

```gdscript
# resources/game_data/item/item.gd
class_name Item
extends Resource

@export var id: String
@export var damage: int = 10
@export var price: int = 100
@export var icon: Texture2D

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

### 3. Централизованная загрузка

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

const SWORD: String = "sword"
const AXE: String = "axe"
const POTION: String = "potion"
const GOBLIN: String = "goblin"
```

### 5. Использование

```gdscript
# Прямой доступ
var sword: Item = Resources.items[Constants.SWORD]
print(sword.damage)  # 25

# Безопасный доступ (для динамических ID из SaveFile)
var item_id = SaveFile.equipped_weapon_id
var item: Item = Resources.items.get(item_id, null)
if item == null:
    return

# Хранение только ID в SaveFile
var inventory: Array[String] = [Constants.SWORD, Constants.AXE, Constants.POTION]

func get_total_damage() -> int:
    var total = 0
    for item_id in inventory:
        total += Resources.items[item_id].damage
    return total
```

---

## Связи между ресурсами

```gdscript
class_name Enemy
extends Resource

@export var id: String
@export var hp: int
@export var loot_ids: Array[String] = []  # Только ID

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
loot_ids = ["sword", "gold", "potion"]  # В .tres всё равно строки
```

**В коде используем константы:**

```gdscript
# При создании врага в коде
var enemy = Enemy.new()
enemy.loot_ids = [Constants.SWORD, Constants.GOLD, Constants.POTION]

# При получении лута
func get_loot() -> Array[Item]:
    var result: Array[Item] = []
    for loot_id in loot_ids:
        result.append(Resources.items[loot_id])
    return result
```

**Почему String ID, а не ExtResource:**

- Нет циклических зависимостей между .tres файлами
- Lazy loading (не грузим всю цепочку сразу)
- Легко сериализовать в JSON (для SaveFile)

---

## Strategy Pattern через Resources

**Пример: функции стоимости (cost scaling)**

```gdscript
# cost_function.gd (базовый класс)
class_name CostFunction
extends Resource

func get_cost(base_cost: int, level: int) -> int:
    return base_cost  # По умолчанию константа
```

**Реализации:**

```gdscript
# linear.gd
extends CostFunction

func get_cost(base_cost: int, level: int) -> int:
    return base_cost * level  # Линейный рост

# exponential.gd
extends CostFunction

func get_cost(base_cost: int, level: int) -> int:
    return int(pow(base_cost, level))  # Экспоненциальный рост
```

**Использование в ресурсе:**

```gdscript
class_name Building
extends Resource

@export var id: String
@export var base_cost: int = 100
@export var cost_function: CostFunction  # Ссылка на .tres

func get_cost_at_level(level: int) -> int:
    if cost_function:
        return cost_function.get_cost(base_cost, level)
    return base_cost
```

**В .tres файле:**

```tres
[resource]
id = "house"
base_cost = 50
cost_function = ExtResource("res://.../exponential.tres")
```

**Результат:**

- Level 1: 50
- Level 2: 2500
- Level 3: 125000

**Зачем:** Меняешь формулу роста цены выбором .tres в инспекторе, без кода.

---

## Статика vs динамика

### ❌ Неправильно

```gdscript
class_name Item
extends Resource

@export var damage: int
var current_durability: int = 100  # Динамика в Resource!

# Проблема: Resources общие для всех экземпляров
# Изменение durability одного меча влияет на ВСЕ мечи
```

### ✅ Правильно

```gdscript
# item_data.gd (Resource - template)
class_name ItemData
extends Resource

@export var id: String
@export var base_damage: int
@export var max_durability: int

# item_instance.gd (Node - state)
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

**Правило:** Resource = неизменяемый template, экземпляры хранят state.

---

## Проблема String ID

**Без констант:**

```gdscript
# Опечатка в ID → краш
var item = Resources.items["swrod"]  # KeyError! Опечатка в "sword"

# Нет compile-time проверки
var item_id: String = "invalid_id"
var item = Resources.items[item_id]  # Упадет в runtime
```

**С константами:**

```gdscript
# Опечатка невозможна (autocomplete)
var item = Resources.items[Constants.SOWRD]  # Compile error! Константы нет

# Константа гарантирует существование ID
var item = Resources.items[Constants.SWORD]  # ✅ Безопасно
```

### Решение: Константы ID

```gdscript
# global/const/constants.gd (не autoload, просто class_name)
class_name Constants

const WORKER: String = "worker"
const SWORD: String = "sword"
const AXE: String = "axe"
const GOBLIN: String = "goblin"
const FIREBALL: String = "fireball"

# Можно группировать
const WEAPON_IDS: Array[String] = [SWORD, AXE, "dagger"]
const CONSUMABLE_IDS: Array[String] = ["potion", "scroll"]
```

**Использование:**

```gdscript
# В любом месте игры
var worker_count = SaveFile.resources.get(Constants.WORKER, 0)
var sword = Resources.items[Constants.SWORD]
var enemy = Resources.enemies[Constants.GOBLIN]

# Autocomplete работает, опечатки невозможны
```

**Плюсы:**

- Все ID в одном месте
- Autocomplete + compile-time проверка
- Легко найти все использования (Find Usages)
- Рефакторинг безопасен (переименование константы обновит все места)

---
