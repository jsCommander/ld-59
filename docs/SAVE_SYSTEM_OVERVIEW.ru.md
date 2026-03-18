# Система сохранения (JSON + Singleton + Автосохранение)

Описание конкретного подхода к реализации save/load системы.

---

## Архитектура

```
┌──────────────────────────────────────────────────────┐
│              SaveFile (Autoload Singleton)            │
│  Хранит всё состояние игры в Dictionary переменных   │
│                                                       │
│  var resources: Dictionary = {}                       │
│  var inventory: Dictionary = {}                       │
│  var settings: Dictionary = {}                        │
│  var metadata: Dictionary = {}                        │
└───────────────────┬──────────────────────────────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │   JSON Serialization  │
         └──────────┬────────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │  user://save.json     │
         │  {"resources": {...}} │
         └──────────────────────┘
```

**Паттерн:** Singleton (Autoload) + JSON файлы + Автосохранение

---

## Компоненты системы

### 1. SaveFile — центральное хранилище

```gdscript
# global/save_file.gd (autoload)
extends Node

# === Игровое состояние ===
var resources: Dictionary = {}      # Все ресурсы игрока
var inventory: Dictionary = {}      # Инвентарь
var progress: Dictionary = {}       # Флаги прогресса
var settings: Dictionary = {}       # Настройки игры
var metadata: Dictionary = {}       # Мета (timestamps, версия)

# === Управление save файлами ===
var save_datas: Dictionary = {}     # Все загруженные save файлы
var active_file_name: String = ""   # Текущий активный save

const SAVE_FILE_EXTENSION = ".json"
const SIGNATURE = "$$$"              # Защита от повреждения

@onready var autosave_timer: Timer = $AutosaveTimer
```

**Все системы читают и пишут напрямую:**
```gdscript
# В любом месте игры
SaveFile.resources["gold"] += 100
SaveFile.progress["level_complete"] = true
var hp = SaveFile.resources.get("hp", 100)
```

---

## Сохранение

### Шаг 1: Экспорт данных (RAM → Dictionary)

```gdscript
func _export_save_data() -> Dictionary:
    var save_data: Dictionary = {}

    # Копируем все активные данные
    save_data["resources"] = resources
    save_data["inventory"] = inventory
    save_data["progress"] = progress
    save_data["settings"] = settings
    save_data["metadata"] = metadata

    return save_data
```

### Шаг 2: Запись на диск (Dictionary → JSON → Файл)

```gdscript
func _write(file_name: String, data: Dictionary) -> void:
    # 1. Dictionary → JSON String
    var content: String = JSON.stringify(data)

    # 2. Добавить сигнатуру (защита от повреждения)
    content += SIGNATURE  # "$$$"

    # 3. Записать в файл
    var path: String = "user://" + file_name
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    file.store_line(content)
    file.close()
```

**Результат на диске:**
```
user://save.json:
{"resources":{"gold":1000},"inventory":{"sword":1},...}$$$
```

### Шаг 3: Автосохранение

```gdscript
const AUTOSAVE_SECONDS: int = 60  # Интервал автосохранения

func _ready() -> void:
    autosave_timer.wait_time = 0.1  # Проверка каждые 0.1 сек
    autosave_timer.timeout.connect(_on_autosave_timer_timeout)
    autosave_timer.start()

func _on_autosave_timer_timeout() -> void:
    _autosave()

func _autosave(force: bool = false) -> void:
    # 1. Проверка времени
    var seconds_since_save = _get_seconds_since_last_save()
    if not force and seconds_since_save < AUTOSAVE_SECONDS:
        return  # Ещё рано

    # 2. Проверка: находимся ли в игре?
    if not _is_gameplay_scene():
        return  # Не сохраняем в меню

    # 3. Обновить metadata
    _update_metadata()

    # 4. Сохранить
    var save_data = _export_save_data()
    _write(active_file_name, save_data)

func _update_metadata() -> void:
    metadata["last_save_time"] = Time.get_datetime_dict_from_system(true)
    metadata["version"] = "1.0"
```

---

## Загрузка

### Шаг 1: Сканирование всех save файлов при старте

```gdscript
func _load_save_files() -> void:
    # 1. Получить все файлы из user://
    var dir = DirAccess.open("user://")
    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        # 2. Пропустить не-.json файлы
        if not file_name.ends_with(SAVE_FILE_EXTENSION):
            file_name = dir.get_next()
            continue

        # 3. Прочитать файл
        var save_data: Dictionary = _read(file_name)

        # 4. Применить миграции
        _migrate_if_needed(save_data)

        # 5. Сохранить в памяти
        var save_name = file_name.trim_suffix(SAVE_FILE_EXTENSION)
        save_datas[save_name] = save_data

        file_name = dir.get_next()

# Результат:
# save_datas = {
#   "save_slot_1": {...},
#   "save_slot_2": {...},
#   "autosave": {...}
# }
```

### Шаг 2: Чтение файла с диска

```gdscript
func _read(file_name: String) -> Dictionary:
    var path = "user://" + file_name

    # 1. Открыть файл
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}

    # 2. Прочитать содержимое
    var content = file.get_as_text()
    file.close()

    # 3. Проверить и удалить мусор после сигнатуры
    content = _handle_corrupt_end_of_file(content)

    # 4. Удалить сигнатуру
    content = content.replace(SIGNATURE, "")

    # 5. Парсинг JSON
    var json = JSON.new()
    var error = json.parse(content)
    if error != OK:
        push_error("Failed to parse save file")
        return {}

    return json.get_data()

func _handle_corrupt_end_of_file(content: String) -> String:
    # Защита: удалить всё после сигнатуры
    var signature_index = content.find(SIGNATURE)
    if signature_index == -1:
        return content
    return content.substr(0, signature_index + SIGNATURE.length())
```

### Шаг 3: Импорт данных (Dictionary → RAM)

```gdscript
func initialize(save_file_name: String) -> void:
    active_file_name = save_file_name + SAVE_FILE_EXTENSION

    # Проверка: существует ли save?
    if save_datas.has(save_file_name):
        # Загрузка существующего save
        var save_data = save_datas[save_file_name].duplicate(true)
        _import_save_data(save_data)
    else:
        # Создание нового save
        _import_save_data({})

func _import_save_data(save_data: Dictionary) -> void:
    # Копируем данные с fallback значениями
    resources = save_data.get("resources", {})
    inventory = save_data.get("inventory", {})
    progress = save_data.get("progress", {})
    settings = save_data.get("settings", _default_settings())
    metadata = save_data.get("metadata", {})
```

---

## Защита данных

### 1. Сигнатура (проверка целостности)

```gdscript
const SIGNATURE = "$$$"

# При записи добавляем в конец
content += SIGNATURE

# При чтении проверяем наличие
if not content.find(SIGNATURE):
    push_warning("Save file may be corrupted")
```

**Зачем:** Защита от повреждения файла (неполная запись при крэше)

### 2. Резервные копии

```gdscript
func save_game() -> void:
    # Создать backup перед перезаписью
    if FileAccess.file_exists("user://save.json"):
        var backup_path = "user://save.json.backup"
        DirAccess.copy_absolute("user://save.json", backup_path)

    # Сохранить новые данные
    _write("save.json", _export_save_data())

func restore_backup() -> void:
    if FileAccess.file_exists("user://save.json.backup"):
        DirAccess.copy_absolute("user://save.json.backup", "user://save.json")
```

### 3. Версионирование и миграции

```gdscript
const CURRENT_VERSION = 3

func _migrate_if_needed(save_data: Dictionary) -> void:
    var version = save_data.get("metadata", {}).get("version", 1)

    if version < CURRENT_VERSION:
        _migrate(save_data, version, CURRENT_VERSION)

func _migrate(data: Dictionary, from: int, to: int) -> void:
    for v in range(from, to):
        match v:
            1:  # v1 → v2
                # Переименовали поле "health" → "hp"
                if data.has("health"):
                    data["hp"] = data["health"]
                    data.erase("health")
            2:  # v2 → v3
                # Добавили новую категорию
                if not data.has("achievements"):
                    data["achievements"] = {}

    data["metadata"]["version"] = to
```

---

## Множественные слоты

### UI выбора слота

```gdscript
# scenes/ui/save_picker.gd

func _ready() -> void:
    # SaveFile уже загрузил все .json файлы в save_datas
    _display_save_slots()

func _display_save_slots() -> void:
    for save_name in SaveFile.save_datas.keys():
        var save_data = SaveFile.save_datas[save_name]
        var metadata = save_data.get("metadata", {})

        # Создать UI элемент
        var slot_button = Button.new()
        slot_button.text = metadata.get("player_name", save_name)
        slot_button.pressed.connect(_on_slot_selected.bind(save_name))
        add_child(slot_button)

func _on_slot_selected(save_name: String) -> void:
    SaveFile.initialize(save_name)
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

### Создание нового слота

```gdscript
func create_new_slot(slot_name: String) -> void:
    # Убедиться что имя уникально
    while SaveFile.save_datas.has(slot_name):
        slot_name = _increment_name(slot_name)  # "Save 1" → "Save 2"

    # Создать пустой save
    var new_save = {
        "metadata": {"player_name": slot_name, "version": CURRENT_VERSION}
    }
    SaveFile.save_datas[slot_name] = new_save

    # Активировать
    SaveFile.initialize(slot_name)
```

---

## Импорт/Экспорт (Base64)

### Экспорт save в строку

```gdscript
func export_save_as_string(save_name: String) -> String:
    # 1. Получить данные
    var save_data = save_datas[save_name]

    # 2. JSON
    var json_string = JSON.stringify(save_data)

    # 3. Base64 кодирование
    var encoded = Marshalls.utf8_to_base64(json_string)

    return encoded
    # → "eyJyZXNvdXJjZXMiOnsiZ29sZCI6MTAwMH19"

# Использование: скопировать в clipboard
func copy_save_to_clipboard(save_name: String) -> void:
    var export_string = export_save_as_string(save_name)
    DisplayServer.clipboard_set(export_string)
```

### Импорт save из строки

```gdscript
func import_save_from_string(encoded_string: String) -> bool:
    # 1. Декодировать Base64
    var json_string = Marshalls.base64_to_utf8(encoded_string)
    if json_string == "":
        return false

    # 2. Парсить JSON
    var json = JSON.new()
    if json.parse(json_string) != OK:
        return false

    var save_data = json.get_data()

    # 3. Получить имя слота
    var slot_name = save_data.get("metadata", {}).get("player_name", "Imported")

    # 4. Сделать имя уникальным
    while save_datas.has(slot_name):
        slot_name = _increment_name(slot_name)

    # 5. Добавить в список
    save_datas[slot_name] = save_data

    return true

# Использование: вставить из clipboard
func paste_save_from_clipboard() -> bool:
    var clipboard_text = DisplayServer.clipboard_get()
    return import_save_from_string(clipboard_text)
```

**Зачем:** Обмен save файлами между игроками или платформами

---

## Специальные функции

### Удаление save

```gdscript
func delete_save(save_name: String) -> void:
    var file_name = save_name + SAVE_FILE_EXTENSION

    # Удалить файл с диска
    DirAccess.remove_absolute("user://" + file_name)

    # Удалить из памяти
    save_datas.erase(save_name)
```

### Переименование save

```gdscript
func rename_save(save_name: String, new_name: String) -> void:
    # Обновить metadata
    save_datas[save_name]["metadata"]["player_name"] = new_name

    # Перезаписать файл
    var save_data = save_datas[save_name]
    _write(save_name + SAVE_FILE_EXTENSION, save_data)
```

### Специальная механика: Престиж с бэкапами

```gdscript
func prestige() -> void:
    # 1. Создать backup текущего состояния
    var backup_name = active_file_name + ".backup_prestige"
    var save_data = _export_save_data()
    _write(backup_name, save_data)

    # 2. Сбросить прогресс (но сохранить настройки и престиж валюту)
    var keep_settings = settings
    var keep_prestige_currency = resources.get("prestige_points", 0) + 1

    resources = {"prestige_points": keep_prestige_currency}
    inventory = {}
    progress = {}
    settings = keep_settings

    # 3. Сохранить новое состояние
    metadata["prestige_count"] = metadata.get("prestige_count", 0) + 1
    _autosave(true)
```

---

## Поток данных

```
ЗАПУСК ИГРЫ
    ↓
SaveFile._ready()
    ↓
_load_save_files() → сканирует user://, загружает все .json
    ↓
save_datas = {"slot1": {...}, "slot2": {...}}
    ↓
UI: SavePicker → пользователь выбирает слот
    ↓
SaveFile.initialize("slot1")
    ↓
_import_save_data() → копирует данные в активные переменные
    ↓
resources = {...}, inventory = {...}, etc.
    ↓
ИГРА РАБОТАЕТ
    ↓
Игровые системы читают/пишут в SaveFile напрямую
    ↓
АВТОСОХРАНЕНИЕ (каждые 60 сек)
    ↓
_export_save_data() → Dictionary
    ↓
_write() → JSON → файл
    ↓
user://slot1.json обновлён
```

---

## Плюсы и минусы подхода

### ✅ Плюсы

1. **Простота** — один singleton, все данные в одном месте
2. **Глобальный доступ** — `SaveFile.resources["gold"]` из любого места
3. **JSON** — человекочитаемый, легко дебажить
4. **Автосохранение** — игрок не потеряет прогресс
5. **Множественные слоты** — неограниченное количество save файлов
6. **Импорт/Экспорт** — обмен save через Base64 строки

### ❌ Минусы

1. **Глобальное состояние** — сложнее тестировать, всё связано
2. **Размер файла** — JSON больше бинарного формата
3. **Читерство** — легко редактировать JSON вручную
4. **Прямой доступ** — любая система может сломать данные
5. **Нет типов** — Dictionary без type safety

---

## Альтернативные решения

Если нужна защита от читов → используй бинарный формат или шифрование:
```gdscript
# Вместо JSON.stringify()
var bytes = var_to_bytes(save_data)
file.store_buffer(bytes)
```

Если нужна модульность → используй component-based подход:
```gdscript
# Каждый объект сам сохраняет свои данные
class Player:
    func save() -> Dictionary:
        return {"hp": hp, "position": position}
```

Если нужна типизация → используй Godot Resources:
```gdscript
class_name SaveData extends Resource
@export var hp: int
@export var gold: int
```

---

## Резюме

**Этот подход:**
- Singleton (SaveFile autoload) хранит всё состояние
- JSON формат для простоты и читаемости
- Автосохранение по таймеру
- Сигнатура `$$$` для проверки целостности
- Backup файлы перед перезаписью
- Миграции для backward compatibility
- Импорт/Экспорт через Base64
- Множественные слоты сохранения

**Когда использовать:**
- Single-player игры
- Где не критично редактирование save файлов
- Нужна простота и скорость разработки
- Нужен обмен save между игроками

**Минимальный код:**
```gdscript
# save_file.gd (autoload)
extends Node

var game_data: Dictionary = {}
const SAVE_PATH = "user://save.json"

func save() -> void:
    var json = JSON.stringify(game_data)
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(json)
    file.close()

func load() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
        var json = JSON.new()
        json.parse(file.get_as_text())
        game_data = json.get_data()
        file.close()
```
