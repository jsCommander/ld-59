# Developer Console (Консоль разработчика) в Godot

## TL;DR

In-game консоль для отладки с тремя ключевыми фичами:
- **Регистрация команд через Dictionary** (легко добавлять новые)
- **История команд** с навигацией ↑/↓
- **Интеграция через SignalBus** (команды не ломают игровую логику)

---

## Какую задачу решает

### Проблема 1: Долгий цикл тестирования

```
# Плохо: чтобы протестировать late-game
1. Открыть код
2. Захардкодить resources["gold"] = 999999
3. Перезапустить игру
4. Протестировать
5. Убрать хардкод
6. Повторить для другого ресурса
```

**Решение:** Консоль — вводишь `add gold 999999` прямо в игре, без перезапуска.

### Проблема 2: Команды ломают игровую логику

```gdscript
# Плохо: прямое изменение данных
func cheat_add_gold(amount):
    SaveFile.resources["gold"] += amount
    # UI не обновился
    # Achievements не сработали
    # Логика сломалась
```

**Решение:** Команды работают через SignalBus — тот же путь что и обычный геймплей.

### Проблема 3: Забыл что вводил

```
# Плохо: набирать длинную команду заново
> add worker 1000
> add wood 5000
> add stone 5000
> add worker 1000  # опять набирать вручную
```

**Решение:** История команд — нажал ↑, получил предыдущую команду.

### Проблема 4: Чит-команды в релизе

```gdscript
# Плохо: консоль доступна игрокам
# Игрок открыл консоль → add gold max → игра сломана
```

**Решение:** Консоль работает только в debug билдах (или с ограниченными командами в release).

---

## Верхнеуровневая архитектура

```
┌────────────────────────────────────────────────────────┐
│                 DeveloperConsole (Control)             │
│                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   commands   │  │ input_buffer │  │ output_buffer│ │
│  │  Dictionary  │  │   Array      │  │    Array     │ │
│  │  {id: func}  │  │  [history]   │  │    [log]     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │                      UI                          │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │         CommandOutput (RichTextLabel)   │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │         CommandInput (LineEdit)         │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

**Поток данных:**

```
Ввод команды "add gold 100"
        │
        ▼
   _process_command()
        │
        ├── Парсинг: ["add", "gold", "100"]
        │
        ├── Lookup: commands["add"]
        │
        ▼
   _cmd_add_resource(["gold", "100"])
        │
        ▼
   SignalBus.resource_generated.emit("gold", 100, "console")
        │
        ▼
   ResourceManager обрабатывает как обычный ресурс
```

---

## Input Bindings

```
`  (Grave)    — открыть/закрыть консоль
↑  (Up)       — предыдущая команда
↓  (Down)     — следующая команда
Esc           — очистить строку ввода
Enter         — выполнить команду
```

---

## Компоненты

### 1. Регистрация команд

```gdscript
var commands: Dictionary = {
    &"help": {
        "func": _cmd_help,
        "description": "Shows available commands",
        "usage": ""
    },
    &"add": {
        "func": _cmd_add_resource,
        "description": "Adds resource to player",
        "usage": "[resource_id] [amount | max]"
    },
    &"set": {
        "func": _cmd_set_resource,
        "description": "Sets resource amount",
        "usage": "[resource_id] [amount | max]"
    },
    &"cls": {
        "func": _cmd_cls,
        "description": "Clears console output",
        "usage": ""
    },
    &"env": {
        "func": _cmd_env,
        "description": "Shows build environment",
        "usage": ""
    },
    &"timetravel": {
        "func": _cmd_time_travel,
        "description": "Simulates offline time",
        "usage": "[seconds >= 0]"
    },
}
```

**Почему Dictionary, а не match/case:**
- Автогенерация `help` из description
- Легко добавлять команды без изменения парсера
- Можно расширять метаданные (permissions, aliases)

---

### 2. Парсинг и выполнение

```gdscript
func _process_command(command_text: String) -> void:
    var tokens: PackedStringArray = command_text.split(" ")
    var command_name: StringName = tokens[0].to_lower()
    var args: PackedStringArray = tokens.slice(1)

    if not commands.has(command_name):
        _write_error("Command '%s' not found." % command_name)
        return

    var command: Dictionary = commands[command_name]
    var result: int = command["func"].call(args)

    # При ошибке показать usage
    if result == FAILED and command["usage"] != "":
        _write_line("Usage: %s %s" % [command_name, command["usage"]])
```

**Контракт команды:**
- Принимает `PackedStringArray` аргументов
- Возвращает `OK` или `FAILED`
- При `FAILED` автоматически показывается usage

---

### 3. История команд (Ring Buffer)

```gdscript
@export var buffer_size: int = 16

var input_buffer: Array[String] = []
var input_pointer: int = -1

func _add_to_history(command: String) -> void:
    # Не добавлять дубликаты подряд
    if input_buffer.size() > 0 and input_buffer[-1] == command:
        return

    input_buffer.push_back(command)

    # Ограничить размер
    if input_buffer.size() > buffer_size:
        input_buffer.pop_front()

    input_pointer = -1  # Сбросить указатель

func _navigate_history(direction: int) -> void:
    if input_buffer.is_empty():
        return

    if input_pointer < 0:
        input_pointer = input_buffer.size() - 1
    else:
        input_pointer = clamp(input_pointer + direction, 0, input_buffer.size() - 1)

    command_input.text = input_buffer[input_pointer]
```

**Схема:**

```
input_buffer: ["add gold 100", "set wood 50", "help"]
                                              ↑
                                       input_pointer

↑ (previous): pointer moves left
↓ (next): pointer moves right
```

---

### 4. Output буфер

```gdscript
var output_buffer: Array[String] = []

func _write_line(text: String) -> void:
    output_buffer.push_back(text)
    if output_buffer.size() > buffer_size:
        output_buffer.pop_front()
    _flush_output()

func _write_error(text: String) -> void:
    _write_line("Error: %s" % text)

func _flush_output() -> void:
    command_output.text = "\n".join(output_buffer)
```

---

### 5. UI компоненты

```
DeveloperConsole (Control, z_index: 4096)
├── BackgroundOverlay (ColorRect, 50% black)
└── MarginContainer
    └── VBoxContainer
        ├── PanelContainer
        │   └── CommandOutput (RichTextLabel)
        └── CommandInput (LineEdit)
```

```gdscript
@onready var command_input: LineEdit = %CommandInput
@onready var command_output: RichTextLabel = %CommandOutput

func _ready() -> void:
    hide()
    command_input.text_submitted.connect(_on_command_submitted)

func _on_visibility_changed() -> void:
    if visible:
        command_input.grab_focus()
    else:
        command_input.clear()
```

---

## Примеры команд

### add — через SignalBus

```gdscript
func _cmd_add_resource(args: PackedStringArray) -> int:
    if args.size() != 2:
        return FAILED

    var resource_id: String = args[0]
    var amount_str: String = args[1]

    # Валидация
    if not Resources.resource_generators.has(resource_id):
        _write_error("Resource '%s' not found." % resource_id)
        return FAILED

    # Парсинг amount
    var amount: int
    if amount_str in ["max", "MAX"]:
        amount = 999999999
    elif amount_str.is_valid_int():
        amount = int(amount_str)
    else:
        return FAILED

    # Через SignalBus — как обычный геймплей
    SignalBus.resource_generated.emit(resource_id, amount, "console")
    _write_line("Added %d %s" % [amount, resource_id])
    return OK
```

### timetravel — симуляция оффлайна

```gdscript
func _cmd_time_travel(args: PackedStringArray) -> int:
    if args.size() != 1:
        return FAILED

    var seconds: int = int(args[0])
    if seconds < 0:
        _write_error("Seconds must be >= 0")
        return FAILED

    # Тот же сигнал что при загрузке сейва
    SignalBus.save_entered.emit(seconds, 0)
    _write_line("Time traveled %d seconds" % seconds)
    return OK
```

### help — автогенерация из Dictionary

```gdscript
func _cmd_help(_args: PackedStringArray) -> int:
    _write_line("Commands:")
    for cmd_name in commands:
        var cmd: Dictionary = commands[cmd_name]
        var usage: String = cmd["usage"]
        if usage.is_empty():
            _write_line("  %s - %s" % [cmd_name, cmd["description"]])
        else:
            _write_line("  %s %s - %s" % [cmd_name, usage, cmd["description"]])
    return OK
```

---

## Интеграция с игрой

### Блокировка input

```gdscript
# main.gd
@onready var console: DeveloperConsole = %DeveloperConsole

func _input(event: InputEvent) -> void:
    if console.visible:
        return  # Консоль перехватывает input
    _handle_game_input(event)

func _process(delta: float) -> void:
    if console.visible:
        return  # Игра на паузе пока консоль открыта
    _update_game(delta)
```

### Безопасность в release

```gdscript
func _ready() -> void:
    # Вариант 1: полностью отключить
    if not OS.is_debug_build():
        queue_free()
        return

    # Вариант 2: убрать опасные команды
    if not OS.is_debug_build():
        commands.erase(&"add")
        commands.erase(&"set")
        commands.erase(&"timetravel")

    hide()
```

---

## Расширения

### Алиасы

```gdscript
var aliases: Dictionary = {
    &"h": &"help",
    &"clear": &"cls",
    &"tt": &"timetravel",
}

func _process_command(command_text: String) -> void:
    var tokens = command_text.split(" ")
    var cmd_name = tokens[0].to_lower()

    # Резолвить алиас
    if aliases.has(cmd_name):
        cmd_name = aliases[cmd_name]
    # ...
```

### Автодополнение (Tab)

```gdscript
func _autocomplete(partial: String) -> void:
    var matches: Array[String] = []
    for cmd_name in commands:
        if cmd_name.begins_with(partial):
            matches.append(cmd_name)

    if matches.size() == 1:
        command_input.text = matches[0] + " "
        command_input.caret_column = command_input.text.length()
```

### Права доступа

```gdscript
var commands: Dictionary = {
    &"help": {
        "func": _cmd_help,
        "debug_only": false
    },
    &"godmode": {
        "func": _cmd_godmode,
        "debug_only": true  # Только в debug
    },
}

func _process_command(command_text: String) -> void:
    var cmd = commands[cmd_name]
    if cmd.get("debug_only", false) and not OS.is_debug_build():
        _write_error("Debug-only command.")
        return
    # ...
```

---

## Структура файлов

```
scenes/ui/developer_console/
├── developer_console.gd    # Логика консоли
└── developer_console.tscn  # UI сцена
```

---

## Резюме

| Проблема | Решение |
|----------|---------|
| Долгий цикл тестирования | Команды прямо в игре |
| Команды ломают логику | Интеграция через SignalBus |
| Забыл что вводил | История команд (↑/↓) |
| Читы в релизе | debug_only флаг / queue_free() |
| Сложно добавлять команды | Dictionary с метаданными |
