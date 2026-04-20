# Globals

- Keep classes stateless — static methods with explicit parameters, no side effects.
- Add enums, constants, and tuning numbers to `Constants`. Not scattered across game scripts.
- Add balance formulas and game math to `Balance`. Not inline calculations in components.
- Use `Growth` scaling curves from `game_kit/globals/`. Not hand-rolled math per call site.
- Add colors and font sizes to `ThemeTokens`. Not hardcoded values in scenes.
- Dependencies flow one way: game code reads globals. Globals NEVER import autoloads or components.

---

## Stateless Methods Only

Write static methods that take parameters and return values. No `_ready()`, no `_process()`, no signals, no node references.

```gdscript
static func calculate_damage(base: float, task_mult: float) -> float:
    return base * task_mult
```

Not methods that call `get_tree()`, emit signals, or read autoload state — move those to the autoload that owns that state.

---

## Constants as Single Source of Truth

Define enums, tuning numbers, and display mappings in `constants.gd`. Group related values together.

```gdscript
const BASE_HP: int = 1000
const BASE_DAMAGE: int = 400
enum TaskType { FEATURE, REFACTORING }
```

Not magic numbers in component scripts — a tuning change should require editing one file.

---

## ThemeTokens for All Visual Values

Reference `ThemeTokens` constants for colors, font sizes, and component variants.

```gdscript
var color: Color = ThemeTokens.RARITY_EPIC
var size: int = ThemeTokens.FONT_SIZE_H2
```

Not `Color(0.6, 0.2, 0.8)` in scripts or scenes — changing a token updates every UI element at once.
