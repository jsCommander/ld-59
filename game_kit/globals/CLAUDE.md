# Game Kit — Globals

- Static utility classes reusable across any game. No game-specific imports, enums, or references.
- All methods are static. No node lifecycle, no signals, no state (except `Log.show_debug`).
- NEVER import from game code, game autoloads, or game data. The kit knows nothing about the game.

---

## Game-Agnostic Utilities Only

Provide helpers any Godot project can use. Accept all context through parameters.

```gdscript
# utils.gd — takes explicit args, no game knowledge
static func find_closest_target(targets: Array, node: Node2D) -> Node2D:
```

Not `find_closest_enemy()` or references to game-specific types (`Player`, `EnemyStat`) — those belong in the game's `globals/`.

---

## Groups Helper Over Raw Calls

`Groups` centralizes empty-result handling and optional runtime type filtering for group queries. Existing code may still use raw group calls where the helper adds no value.

```gdscript
var player: Node = Groups.get_first(get_tree(), "player")
var actors: Array = Groups.get_all_of_type(get_tree(), "actor", Node2D)
```

Prefer `Groups` when its filtering behavior avoids duplicated query code.

---

## Animations as Tween Factories

Use `Animations` to create reusable tweens. Each method returns a `Tween` for chaining or lifecycle control.

```gdscript
var tween: Tween = Animations.pulse(sprite)
var tween: Tween = Animations.shake(sprite, 5.0, 0.3)
```

Not one-off tween setup scattered across components — `Animations` keeps motion patterns consistent and reusable.

---

## Growth for Progression Curves

Use `Growth` for any value that scales with level or progression: `linear`, `power`, `exponential`, `logarithmic`, `sigmoid`.

```gdscript
var hp: float = Growth.power(level, base_hp, 1.3)
var chance: float = Growth.sigmoid(level, 0.1, 0.5, 10, 1.0)
```

Not hand-rolled formulas at each call site — centralizing curves makes balance changes one-line edits.

---

## Log for Structured Logging

Use `Log` for all diagnostic output. Format: `[timestamp] [LEVEL] (Component) message`.

```gdscript
Log.log_info(self.name, "Scene loaded: %s" % scene_name)
Log.log_debug(self.name, "State: %s -> %s" % [old, new])
```

Not `print()` or `push_warning()` directly — `Log` adds timestamps, component context, and a debug toggle.
