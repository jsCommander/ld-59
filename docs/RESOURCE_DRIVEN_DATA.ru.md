# Реестр ресурсов и доступ по константам

## TL;DR

Централизованное хранилище всех игровых данных (`.tres`), доступное из любой точки кода по строковым ID, защищенным константами.

---

## 1. Ресурс-шаблон

Каждый класс данных должен иметь поле `id`. Это единственный способ надежно найти ресурс в реестре.

```gdscript
# item_stat.gd
class_name ItemStat
extends Resource

@export var id: String
@export var damage: int = 10
@export var icon: Texture2D
```

---

## 2. Глобальный Реестр (Autoload `Resources`)

Скрипт-синглтон, который при старте игры один раз сканирует папки и загружает все ресурсы в словари.

```gdscript
# global/autoload/resources.gd
extends Node

# Словари для быстрого доступа: {"id": Resource}
var items: Dictionary = {}
var buildings: Dictionary = {}

func _ready() -> void:
    items = _load_resources("res://game_data/items/")
    buildings = _load_resources("res://game_data/buildings/")

func _load_resources(path: String) -> Dictionary:
    var result = {}
    var dir = DirAccess.open(path)
    if not dir:
        return result
        
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var res = load(path + file_name)
            if res and "id" in res:
                result[res.id] = res
        file_name = dir.get_next()
    return result
```

---

## 3. Константы (для защиты от опечаток)

Вместо того чтобы писать `"sword"` руками (где легко ошибиться в букве), используем статический класс с константами.

```gdscript
# global/const/constants.gd
class_name Constants

# IDs предметов
const SWORD = "sword"
const AXE = "axe"

# IDs зданий
const DRILL = "drill"
const HOUSE = "house"
```

---

## 4. Использование в коде

Теперь любая динамическая настройка объекта сводится к одной строчке:

```gdscript
# Пример: Спавн предмета из кода или загрузка сохранения
func setup_item(item_id: String):
    # Получаем готовый ресурс из памяти по ID
    var stat = Resources.items.get(item_id)
    
    if stat:
        sprite.texture = stat.icon
        damage = stat.damage
    else:
        push_error("Ресурс не найден: " + item_id)

# Пример вызова с использованием константы:
setup_item(Constants.SWORD)
```

---

## Преимущества этого подхода:
1. **Безопасность:** Если вы переименуете файл `.tres` на диске, ничего не сломается — реестр найдет его по внутреннему `id`.
2. **Удобство для сохранений:** В JSON сохранения пишем только короткую строку `"sword"`, а при загрузке мгновенно находим ресурс через `Resources.items["sword"]`.
3. **Автодополнение:** В редакторе при вводе `Constants.` вы сразу видите список всех доступных ID.