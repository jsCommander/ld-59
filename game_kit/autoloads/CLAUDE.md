# Game Kit — Autoloads

- Base classes for autoload singletons. Game-specific autoloads extend these in `autoloads/`.
- Public base classes intended for game subclassing are prefixed with `Base` (`BaseSignalBus`, `BaseAudioManager`, `BaseDataRegistry`).
- NEVER import game code, game data, or game autoloads. Dependencies flow one way: game extends kit.
- NEVER add game-specific enums, signals, constants, or asset paths here.

---

## Base Classes, Not Concrete Singletons

Provide reusable plumbing that any game can extend. One base class per autoload concern.

```gdscript
# base_signal_bus.gd — debug logging for any signal bus
class_name BaseSignalBus extends Node

# game's signal_bus.gd — adds game-specific signals
class_name SignalBus extends BaseSignalBus
signal task_destroyed
```

Not a "universal" signal bus with signals for specific game events — that couples the kit to one game.

---

## Prefix Public Base Classes with Base

Name classes `Base*` so the game can claim the unprefixed name.

```gdscript
class_name BaseAudioManager extends Node
class_name BaseDataRegistry extends Node
class_name BaseGameData extends Resource
```

Not `AudioManager` or `DataRegistry` — the game needs those names for its concrete subclasses.

---

## No Game Assets or Paths

Reference no specific `.tres`, `.tscn`, textures, sounds, or `res://game_data/` paths. Accept data through registration methods or exports.

```gdscript
# base_audio_manager.gd — game registers tracks at runtime
func register_music(id: int, stream: AudioStream) -> void:
func register_sfx(id: int, stream: AudioStream) -> void:
```

Not `preload("res://assets/music/theme.mp3")` — the kit has no knowledge of what assets exist.

---

## No Game Enums or Constants

Reference `BaseConstants` for kit-level values only (built-in signal names, framework defaults).

```gdscript
# base_constants.gd
const BUILTIN_SIGNALS: Array = ["ready", "tree_entered", ...]
```

Not `enum TaskType { FEATURE, REFACTORING }` — game enums live in the game's `globals/constants.gd`.
