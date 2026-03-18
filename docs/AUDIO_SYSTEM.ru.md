# Audio System (Аудиосистема) в Godot

## TL;DR

Централизованная аудиосистема через autoload с тремя ключевыми фичами:
- **Crossfade** между музыкальными треками
- **Адаптивная музыка** (Idle/Combat треки играют параллельно, микшируются по ситуации)
- **Object pooling** для SFX (без создания новых нод на каждый звук)

---

## Какую задачу решает

### Проблема 1: Резкие переходы музыки

```gdscript
# Плохо: резкий переход
track_1.stop()
track_2.play()  # Слышен "щелчок"
```

**Решение:** Crossfade — плавное затухание одного трека и нарастание другого за 2 секунды.

### Проблема 2: Музыка не реагирует на геймплей

```gdscript
# Плохо: одна и та же музыка везде
background_music.play()
```

**Решение:** Dual-track система — для каждой композиции есть Idle и Combat версии, они играют параллельно, микшер плавно переключает между ними.

### Проблема 3: Лаги и утечки памяти от SFX

```gdscript
# Плохо: новая нода на каждый звук
func play_sound(stream):
    var player = AudioStreamPlayer.new()
    add_child(player)
    player.stream = stream
    player.play()
    # Кто удалит эту ноду? Когда?
```

**Решение:** Object pool — фиксированный набор плееров (8-16 штук), переиспользуются по кругу.

### Проблема 4: Однообразные звуки

```gdscript
# Плохо: один и тот же звук шага 1000 раз
footstep.play()  # Звучит как робот
```

**Решение:** Pitch variance — случайное отклонение pitch ±20% делает звуки живыми.

---

## Верхнеуровневая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    Audio (autoload)                     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │  SfxQueue   │  │   SfxMap    │  │  Music Tracks   │ │
│  │  (pooling)  │  │ (ID→Stream) │  │  (AudioPlayer)  │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
         │                 │                  │
         ▼                 ▼                  ▼
   ┌──────────┐      ┌──────────┐      ┌───────────┐
   │ SFX Bus  │      │ Preload  │      │ Music Bus │
   └──────────┘      │ Streams  │      └───────────┘
                     └──────────┘
```

**Поток данных:**

```
Игровое событие (SignalBus)
        │
        ▼
   Audio Manager
        │
        ├── SFX? ──► SfxMap.get(id) ──► SfxQueue.play()
        │
        └── Music? ──► AudioPlayer.fade_in/fade_out()
```

---

## Audio Bus Layout

```
Master (общая громкость)
├── Music (фоновая музыка)
└── SFX (звуковые эффекты)
```

Позволяет независимо регулировать громкость музыки и эффектов.

---

## Компоненты

### 1. Audio Manager

Точка входа. Управляет всеми плеерами и очередью SFX.

```gdscript
extends Node

var _track: int = 0
var _current_audio_player: AudioPlayer

@onready var sfx_queue: AudioQueue = %SfxQueue
@onready var sfx_map: Node = %SfxMap
@onready var music_tracks: Node = %Music

# === API для SFX ===

func play_sfx_id(sfx_id: String, pitch_variance: float = 0.5, volume: float = 1.0) -> void:
    var sfx_stream: AudioStream = sfx_map.SFX_ID.get(sfx_id, null)
    if sfx_stream:
        sfx_queue.play(sfx_id, sfx_stream, pitch_variance, volume)

func stop_sfx_id(sfx_id: String) -> void:
    sfx_queue.stop(sfx_id)

# === API для музыки ===

func swap_crossfade_audio(audio_player: AudioPlayer) -> void:
    if _current_audio_player == audio_player:
        return
    _current_audio_player.fade_out()
    _current_audio_player = audio_player
    _current_audio_player.fade_in()

func swap_crossfade_music_next() -> void:
    _track = (_track + 1) % MAIN_MUSIC_TRACKS
    swap_crossfade_audio(music_tracks.get_child(_track))
```

**Использование:**

```gdscript
Audio.play_sfx_id("click")
Audio.play_sfx_id("hit", 0.3, 0.8)  # pitch_variance, volume
Audio.swap_crossfade_music_next()
```

---

### 2. AudioPlayer (музыкальный плеер)

Один трек с поддержкой fade и dual-track (Idle/Combat).

```gdscript
class_name AudioPlayer extends Node

signal finished

const TWEEN_FADE_DURATION: float = 2.0

@export var default_audio: Resource  # AudioStream или Song
@export var max_volume_idle: float = 1.0
@export var max_volume_combat: float = 1.0
@export var is_looping: bool = false

var _fade_tween: Tween
var _idle_playback_position: float = 0.0
var _combat_playback_position: float = 0.0

@onready var idle_track: AudioStreamPlayer = %Idle
@onready var combat_track: AudioStreamPlayer = %Combat

func fade_in(restart: bool = false) -> void:
    transition_master_volume(0.0, get_max_volume())
    play(restart)

func fade_out(pause: bool = true) -> void:
    transition_master_volume(get_max_volume(), 0.0)
    _fade_tween.tween_callback(_fade_out_callback.bind(pause))

func transition_master_volume(from: float, to: float) -> void:
    if _fade_tween:
        _fade_tween.kill()
    _fade_tween = create_tween()
    _fade_tween.tween_method(set_master_volume, from, to, TWEEN_FADE_DURATION)
```

**Crossfade визуально:**

```
Track A: ████████▓▓▓░░░░░░░░░░
Track B: ░░░░░░░░▓▓▓████████████
                ↑
           crossfade
```

---

### 3. Song Resource (адаптивная музыка)

```gdscript
class_name Song extends Resource

@export var idle_audio_stream: AudioStream
@export var combat_audio_stream: AudioStream
```

**Файл .tres:**

```
exploration_theme.tres
├── idle_audio_stream: calm_exploration.ogg
└── combat_audio_stream: intense_battle.ogg
```

**Как работает dual-track:**

```
Idle Track:   ████████▓▓░░░░░░░░░░▓▓████████
Combat Track: ░░░░░░░░▓▓████████████▓▓░░░░░░
                      ↑            ↑
                 enter combat  exit combat

Оба трека играют ОДНОВРЕМЕННО, но громкость одного = 0
```

---

### 4. AudioQueue (пул для SFX)

```gdscript
class_name AudioQueue extends Node

@export var stream_player_count: int = 8

var _available: Array[AudioStreamPlayer] = []
var _playing: Dictionary = {}
var _queue: Array[AudioItem] = []

class AudioItem:
    var stream: AudioStream
    var pitch_scale: float
    var id: String
    var volume: float

func _ready() -> void:
    # Создаём пул один раз
    for i in stream_player_count:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        player.finished.connect(_on_finished.bind(player))
        _available.append(player)

func play(id: String, stream: AudioStream, pitch_variance: float, volume: float) -> void:
    var item = AudioItem.new()
    item.stream = stream
    item.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
    item.id = id
    item.volume = volume

    if _available.size() > 0:
        _play_item(_available.pop_front(), item)
    else:
        _queue.push_back(item)  # Все заняты — в очередь

func _on_finished(player: AudioStreamPlayer) -> void:
    if _queue.size() > 0:
        _play_item(player, _queue.pop_front())
    else:
        _available.append(player)
```

**Схема работы:**

```
play() ──► Есть свободный плеер?
                │
          Да ◄──┴──► Нет
          │           │
          ▼           ▼
       Играть    В очередь
                      │
                      ▼ (плеер освободился)
                   Играть
```

---

### 5. SfxMap (каталог звуков)

```gdscript
extends Node

const SFX_ID: Dictionary = {
    # UI
    "click": preload("res://audio/sfx/ui/click.ogg"),
    "success": preload("res://audio/sfx/ui/success.ogg"),
    "fail": preload("res://audio/sfx/ui/fail.ogg"),

    # Combat
    "hit": preload("res://audio/sfx/combat/hit.ogg"),
    "slash": preload("res://audio/sfx/combat/slash.ogg"),

    # Ambient
    "coin": preload("res://audio/sfx/ambient/coin.ogg"),
    "fire": preload("res://audio/sfx/ambient/fire.ogg"),
}
```

---

## Pitch Variance

Делает повторяющиеся звуки менее монотонными:

```gdscript
var pitch_scale = randf_range(1.0 - variance, 1.0 + variance)
# variance = 0.2 → pitch от 0.8 до 1.2
```

| Variance | Эффект |
|----------|--------|
| 0.0 | Без изменений |
| 0.2 | Лёгкая вариация (шаги, клики) |
| 0.5 | Заметная (удары, взрывы) |

---

## Интеграция с игрой

```gdscript
func _connect_signals() -> void:
    SignalBus.tab_changed.connect(_on_tab_changed)
    SignalBus.boss_start.connect(_on_boss_start)
    SignalBus.boss_end.connect(_on_boss_end)

func _on_tab_changed(tab_data: TabData) -> void:
    if tab_data.id == "combat":
        _current_audio_player.states.transition_to("Combat")
    else:
        _current_audio_player.states.transition_to("Idle")

func _on_boss_start() -> void:
    swap_crossfade_audio(boss_music_player)
```

---

## Структура файлов

```
autoload/audio/
├── audio.gd              # Главный менеджер
├── audio.tscn
├── audio_player/
│   ├── audio_player.gd   # Плеер с fade + dual-track
│   └── track_state.gd    # State machine Idle/Combat
├── audio_queue/
│   └── audio_queue.gd    # Object pool для SFX
└── sfx_map/
    └── sfx_map.gd        # ID → AudioStream

resources/
├── audio_bus_layout.tres
└── songs/
    ├── song.gd           # Resource класс
    └── *.tres            # Конкретные треки
```

---

## Резюме

| Проблема | Решение |
|----------|---------|
| Резкие переходы музыки | Crossfade (tween громкости) |
| Музыка не реагирует на геймплей | Dual-track (Idle + Combat) |
| Лаги/утечки от SFX | Object pooling |
| Монотонные звуки | Pitch variance |
| Раздельная громкость | Audio Bus (Music/SFX) |
