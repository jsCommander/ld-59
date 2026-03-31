# Система сохранения (Save System) в Godot

## TL;DR

Централизованная система сохранения через autoload singleton с ключевыми фичами:
- **JSON формат** — человекочитаемый, легко дебажить
- **Автосохранение** — игрок не потеряет прогресс
- **Множественные слоты** — неограниченное количество save файлов
- **Import/Export** — обмен save через Base64 строки

---

## Какую задачу решает

### Проблема 1: Потеря прогресса

```gdscript
# Плохо: игрок должен вручную сохранять
func _on_save_button_pressed():
    save_game()
# Забыл нажать → 2 часа прогресса потеряно
```

**Решение:** Автосохранение каждые N секунд + при закрытии игры.

### Проблема 2: Повреждённые save файлы

```json
// Файл повреждён при крэше (неполная запись)
{"resources":{"gold":1000},"invent
```

**Решение:** Сигнатура `$$$` в конце файла — если нет, файл повреждён.

### Проблема 3: Несовместимость версий

```gdscript
# Плохо: старый save не работает с новой версией
# v1: {"health": 100}
# v2: {"hp": 100}  # Переименовали поле → старые save сломаны
```

**Решение:** Версионирование + миграции при загрузке.

### Проблема 4: Один слот = один игрок

```gdscript
# Плохо: перезапись save при новой игре
# Хочу дать другу попробовать → мой прогресс потерян
```

**Решение:** Множественные слоты — каждый save в отдельном файле.

### Проблема 5: Нет обмена save между игроками

```
# Плохо: надо искать файл на диске, копировать вручную
# Где вообще user:// на этой ОС?
```

**Решение:** Export в Base64 строку → копируется в clipboard → отправляется другу.

---

## Верхнеуровневая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                SaveFile (autoload singleton)            │
│                                                         │
│  resources: Dictionary    settings: Dictionary          │
│  inventory: Dictionary    metadata: Dictionary          │
│                                                         │
│  save_datas: Dictionary   # Все загруженные слоты       │
│  active_file_name: String # Текущий активный слот       │
└─────────────────────────────────────────────────────────┘
        │                           │
        │ _export_save_data()       │ _import_save_data()
        ▼                           ▼
┌─────────────────┐         ┌─────────────────┐
│ JSON.stringify  │         │   JSON.parse    │
└────────┬────────┘         └────────┬────────┘
         │                           │
         ▼                           ▼
┌─────────────────────────────────────────────────────────┐
│                    user://saves/                        │
│  ├── slot1.json                                         │
│  ├── slot2.json                                         │
│  └── autosave.json                                      │
└─────────────────────────────────────────────────────────┘
```

**Поток данных:**

```
ЗАПУСК ИГРЫ
      │
      ▼
SaveFile._ready() → _load_save_files()
      │
      ▼
Сканирует user://, загружает все .json в save_datas
      │
      ▼
UI: SavePicker → игрок выбирает слот
      │
      ▼
SaveFile.initialize("slot1") → _import_save_data()
      │
      ▼
resources = {...}, inventory = {...}
      │
      ▼
ИГРА РАБОТАЕТ (системы читают/пишут в SaveFile)
      │
      ▼ каждые 60 сек
АВТОСОХРАНЕНИЕ → _export_save_data() → JSON → файл
```

---

## Компоненты

### 1. SaveFile (центральное хранилище)

```gdscript
# global/autoload/save_file.gd
extends Node

# === Игровое состояние ===
var resources: Dictionary = {}
var inventory: Dictionary = {}
var progress: Dictionary = {}
var settings: Dictionary = {}
var metadata: Dictionary = {}

# === Управление слотами ===
var save_datas: Dictionary = {}     # Все загруженные save
var active_file_name: String = ""   # Текущий активный

const SAVE_FILE_EXTENSION = ".json"
const SIGNATURE = "$$$"
const AUTOSAVE_SECONDS: int = 60

@onready var autosave_timer: Timer = $AutosaveTimer
```

**Доступ из любого места:**

```gdscript
SaveFile.resources["gold"] += 100
SaveFile.progress["level_complete"] = true
var hp = SaveFile.resources.get("hp", 100)
```

---

### 2. Сохранение (RAM → Файл)

```gdscript
func _export_save_data() -> Dictionary:
    return {
        "resources": resources,
        "inventory": inventory,
        "progress": progress,
        "settings": settings,
        "metadata": metadata
    }

func _write(file_name: String, data: Dictionary) -> void:
    # Dictionary → JSON String
    var content: String = JSON.stringify(data)

    # Добавить сигнатуру
    content += SIGNATURE  # "$$$"

    # Записать в файл
    var path: String = "user://" + file_name
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_line(content)
    file.close()
```

**Результат на диске:**

```
user://slot1.json:
{"resources":{"gold":1000},"inventory":{"sword":1},...}$$$
```

---

### 3. Загрузка (Файл → RAM)

```gdscript
func _read(file_name: String) -> Dictionary:
    var path = "user://" + file_name
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}

    var content = file.get_as_text()
    file.close()

    # Защита от повреждения
    content = _handle_corrupt_end_of_file(content)
    content = content.replace(SIGNATURE, "")

    # Парсинг JSON
    var json = JSON.new()
    if json.parse(content) != OK:
        push_error("Failed to parse save file")
        return {}

    return json.get_data()

func _handle_corrupt_end_of_file(content: String) -> String:
    var signature_index = content.find(SIGNATURE)
    if signature_index == -1:
        return content  # Нет сигнатуры — возможно повреждён
    return content.substr(0, signature_index + SIGNATURE.length())
```

---

### 4. Автосохранение

```gdscript
func _ready() -> void:
    autosave_timer.wait_time = 0.1  # Проверка часто, сохранение редко
    autosave_timer.timeout.connect(_on_autosave_timeout)
    autosave_timer.start()

func _on_autosave_timeout() -> void:
    _autosave()

func _autosave(force: bool = false) -> void:
    var seconds_since = _get_seconds_since_last_save()
    if not force and seconds_since < AUTOSAVE_SECONDS:
        return  # Ещё рано

    if not _is_gameplay_scene():
        return  # Не сохраняем в меню

    _update_metadata()
    var save_data = _export_save_data()
    _write(active_file_name, save_data)

func _update_metadata() -> void:
    metadata["last_save_time"] = Time.get_datetime_dict_from_system(true)
    metadata["version"] = CURRENT_VERSION
```

---

### 5. Версионирование и миграции

```gdscript
const CURRENT_VERSION = 3

func _migrate_if_needed(save_data: Dictionary) -> void:
    var version = save_data.get("metadata", {}).get("version", 1)
    if version < CURRENT_VERSION:
        _migrate(save_data, version, CURRENT_VERSION)

func _migrate(data: Dictionary, from: int, to: int) -> void:
    for v in range(from, to):
        match v:
            1:  # v1 → v2: переименовали поле
                if data.has("health"):
                    data["hp"] = data["health"]
                    data.erase("health")
            2:  # v2 → v3: добавили категорию
                if not data.has("achievements"):
                    data["achievements"] = {}

    data["metadata"]["version"] = to
```

**Схема:**

```
Старый save (v1)          Миграция              Новый формат (v3)
┌─────────────────┐                           ┌─────────────────┐
│ health: 100     │ ──► v1→v2: health→hp ──► │ hp: 100         │
│ gold: 500       │ ──► v2→v3: +achievements │ gold: 500       │
│                 │                           │ achievements: {}│
└─────────────────┘                           └─────────────────┘
```

---

## Множественные слоты

### Сканирование при старте

```gdscript
func _load_save_files() -> void:
    var dir = DirAccess.open("user://")
    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.ends_with(SAVE_FILE_EXTENSION):
            var save_data = _read(file_name)
            _migrate_if_needed(save_data)

            var save_name = file_name.trim_suffix(SAVE_FILE_EXTENSION)
            save_datas[save_name] = save_data

        file_name = dir.get_next()

# Результат:
# save_datas = {
#   "slot1": {...},
#   "slot2": {...},
#   "autosave": {...}
# }
```

### Выбор слота

```gdscript
func initialize(save_file_name: String) -> void:
    active_file_name = save_file_name + SAVE_FILE_EXTENSION

    if save_datas.has(save_file_name):
        var save_data = save_datas[save_file_name].duplicate(true)
        _import_save_data(save_data)
    else:
        _import_save_data({})  # Новый save

func _import_save_data(save_data: Dictionary) -> void:
    resources = save_data.get("resources", {})
    inventory = save_data.get("inventory", {})
    progress = save_data.get("progress", {})
    settings = save_data.get("settings", _default_settings())
    metadata = save_data.get("metadata", {})
```

### UI выбора слота

```gdscript
func _display_save_slots() -> void:
    for save_name in SaveFile.save_datas.keys():
        var metadata = SaveFile.save_datas[save_name].get("metadata", {})

        var slot_button = Button.new()
        slot_button.text = metadata.get("player_name", save_name)
        slot_button.pressed.connect(_on_slot_selected.bind(save_name))
        add_child(slot_button)

func _on_slot_selected(save_name: String) -> void:
    SaveFile.initialize(save_name)
    Scene.change_scene("main_scene")
```

---

## Import/Export (Base64)

### Экспорт

```gdscript
func export_save_as_string(save_name: String) -> String:
    var save_data = save_datas[save_name]
    var json_string = JSON.stringify(save_data)
    return Marshalls.utf8_to_base64(json_string)
    # → "eyJyZXNvdXJjZXMiOnsiZ29sZCI6MTAwMH19"

func copy_save_to_clipboard(save_name: String) -> void:
    var export_string = export_save_as_string(save_name)
    DisplayServer.clipboard_set(export_string)
```

### Импорт

```gdscript
func import_save_from_string(encoded: String) -> bool:
    # Декодировать Base64
    var json_string = Marshalls.base64_to_utf8(encoded)
    if json_string == "":
        return false

    # Парсить JSON
    var json = JSON.new()
    if json.parse(json_string) != OK:
        return false

    var save_data = json.get_data()

    # Уникальное имя слота
    var slot_name = save_data.get("metadata", {}).get("player_name", "Imported")
    while save_datas.has(slot_name):
        slot_name = _increment_name(slot_name)

    save_datas[slot_name] = save_data
    return true

func paste_save_from_clipboard() -> bool:
    return import_save_from_string(DisplayServer.clipboard_get())
```

**Сценарий:**

```
Игрок A                              Игрок B
────────                             ────────
Export → Base64 строка
         │
         │ (Discord, email, etc.)
         ▼
                                     Import ← Base64 строка
                                     Новый слот создан
```

---

## Защита данных

### Сигнатура

```gdscript
const SIGNATURE = "$$$"

# При записи
content += SIGNATURE

# При чтении
if not content.contains(SIGNATURE):
    push_warning("Save file may be corrupted")
```

### Backup перед перезаписью

```gdscript
func save_game() -> void:
    if FileAccess.file_exists("user://save.json"):
        DirAccess.copy_absolute(
            "user://save.json",
            "user://save.json.backup"
        )
    _write("save.json", _export_save_data())

func restore_backup() -> void:
    if FileAccess.file_exists("user://save.json.backup"):
        DirAccess.copy_absolute(
            "user://save.json.backup",
            "user://save.json"
        )
```

---

## Специальные механики

### Удаление save

```gdscript
func delete_save(save_name: String) -> void:
    DirAccess.remove_absolute("user://" + save_name + SAVE_FILE_EXTENSION)
    save_datas.erase(save_name)
```

### Престиж (partial reset)

```gdscript
func prestige() -> void:
    # Backup
    _write(active_file_name + ".backup_prestige", _export_save_data())

    # Сохранить то что нужно
    var keep_settings = settings
    var keep_prestige = resources.get("prestige_points", 0) + 1

    # Сбросить
    resources = {"prestige_points": keep_prestige}
    inventory = {}
    progress = {}
    settings = keep_settings

    # Обновить счётчик
    metadata["prestige_count"] = metadata.get("prestige_count", 0) + 1

    _autosave(true)
```

---

## Структура файлов

```
global/autoload/
└── save_file/
    ├── save_file.gd      # Логика
    └── save_file.tscn    # Нода с Timer

user://                   # Runtime директория
├── slot1.json
├── slot2.json
├── slot1.json.backup
└── config.cfg            # Отдельно от save (ConfigStorage)
```

---

## Плюсы и минусы

### Плюсы

| Фича | Польза |
|------|--------|
| JSON формат | Человекочитаемый, легко дебажить |
| Singleton | Простой доступ из любого места |
| Автосохранение | Игрок не потеряет прогресс |
| Множественные слоты | Несколько игроков на одном ПК |
| Import/Export | Обмен save между игроками |

### Минусы

| Проблема | Когда критично |
|----------|----------------|
| Легко редактировать JSON | Competitive/online игры |
| Глобальное состояние | Сложное тестирование |
| Нет типизации | Большие проекты |
| Размер файла | Огромные save (используй binary) |

---

## Альтернативы

### Бинарный формат (защита от читов)

```gdscript
var bytes = var_to_bytes(save_data)
file.store_buffer(bytes)
```

### Component-based (модульность)

```gdscript
class Player:
    func save() -> Dictionary:
        return {"hp": hp, "position": position}
```

### Godot Resources (типизация)

```gdscript
class_name SaveData extends Resource
@export var hp: int
@export var gold: int
```

---

## Резюме

| Проблема | Решение |
|----------|---------|
| Потеря прогресса | Автосохранение по таймеру |
| Повреждённые файлы | Сигнатура + backup |
| Несовместимость версий | Версионирование + миграции |
| Один слот | Множественные .json файлы |
| Нет обмена save | Import/Export через Base64 |
| Сложный доступ к данным | Singleton autoload |
