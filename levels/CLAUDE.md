# Levels

- Level scenes (`.tscn`) assemble entities from `components/` and configure them. Not new entity logic.
- Level scripts handle level-specific orchestration: music, win/lose conditions, game start, UI visibility.
- Keep level scripts thin. Entities are autonomous — the level places them, not wires them.
- Add to group `"level"` in `_ready()`. Dynamic spawns use this group to find the level node.

---

## Assemble, Don't Build

Place entities from `components/` as child nodes in the scene. Configure via exports and `game_data/` resources.

```gdscript
func _ready() -> void:
    add_to_group("level")
    AM.play_playlist([Constants.Music.SPB])
    PD.start_game(desks)
```

Not entity behavior (`move_toward`, `take_damage`) in the level script — that belongs on the component.

---

## Keep Game Flow in Player Data

The current game has one main level. `PD` owns the game lifecycle and publishes state changes through `SB`; the level only starts the game and reacts to those events.

```gdscript
func _ready() -> void:
    SB.boost_help_show_requested.connect(_on_boost_help_show_requested)
    PD.start_game(desks)
```

Not gameplay progression or persistent state owned by the level.

---

## Connect Signals for Level-Specific Reactions

Use SB signals for cross-system events that only matter during this level (boost help, tutorials, cutscenes).

```gdscript
func _ready() -> void:
    SB.boost_help_show_requested.connect(_on_boost_help_show_requested)
```

Not polling state in `_process()` — react to events.
