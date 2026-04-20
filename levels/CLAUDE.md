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

## Emit Finished, Don't Route

Signal completion with `finished.emit()`. The scene manager decides what loads next.

```gdscript
signal finished(data: Dictionary)

func _on_win_condition_met() -> void:
    finished.emit({})
```

Not `get_tree().change_scene_to_file("res://levels/Level2.tscn")` — levels don't know the scene order.

---

## Connect Signals for Level-Specific Reactions

Use SB signals for cross-system events that only matter during this level (boost help, tutorials, cutscenes).

```gdscript
func _ready() -> void:
    SB.boost_help_show_requested.connect(_on_boost_help_show_requested)
```

Not polling state in `_process()` — react to events.
