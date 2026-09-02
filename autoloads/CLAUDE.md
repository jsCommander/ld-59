# Autoloads

- Put global state and cross-system coordination here. Not entity behavior or pure math — those go in `components/` and `globals/`.
- Extend a `game_kit/autoloads/` base class. Game-specific logic here, reusable plumbing in the kit.
- Route cross-system notifications through SB (SignalBus). Direct autoload calls are allowed for commands and queries owned by that service.
- Register in `project.godot` with a 2-3 letter uppercase alias (SB, SD, AM, DR, PD).
- Access by alias everywhere: `SB.task_destroyed.emit()`, `PD.level`, `AM.play_sfx(Constants.Sfx.CLICK)`.

---

## State That Survives Scene Changes

Store values in autoloads when they must persist across scene transitions and be readable from anywhere.

```gdscript
var valuation: int = 0
var level: int = 1
```

Not state that belongs to one entity (`current_target`, `is_attacking`) — that lives on the component that owns the behavior.

---

## Signals on the Bus

Define cross-system signals in `signal_bus.gd`. Emit from wherever the event originates, connect from wherever the reaction lives.

```gdscript
# signal_bus.gd
signal level_up(new_level: int)

# emitter (player_data.gd)
SB.level_up.emit(level)

# listener (any scene)
SB.level_up.connect(_on_level_up)
```

Not signals on other autoloads — SB is the single event bus. Not polling autoload state every frame — connect to the signal.

---

## Extending the Kit Base

Override and extend `game_kit` base classes. Register game-specific assets in `_ready()`.

```gdscript
# audio_manager.gd extends BaseAudioManager
func _ready() -> void:
    register_music(Constants.Music.FR, MUSIC_FR)
    register_sfx(Constants.Sfx.CLICK, SFX_CLICK)
```

Not reimplementing playlist logic or SFX pooling — the kit base handles that.

---

## Adding a New Autoload

Verify the logic truly needs global lifetime. If only one component calls it, put it on that component. If an existing autoload already owns that domain, extend it.

1. Create the script in `autoloads/`, extend a `game_kit` base or `Node`
2. Register in `project.godot` under `[autoload]` with a short alias
3. Add signals to SB if other systems need to react to state changes
