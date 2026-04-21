# Teamlead

An idle/clicker about being a team lead. You run an office of developers (vibe coders, regulars, seniors); each sprint they chew through a pool of tasks — features and refactoring. You speed them up with clicks (boost stacks increase attack speed on the current task), closed tasks grow the company valuation, level-ups give you upgrades and new hire slots. The goal is to climb to "World Domination" in under 8 minutes.

Play it: [jscommander.itch.io/this-is-ai](https://jscommander.itch.io/this-is-ai)

Built on **Godot 4.6**.

---

## Running and Building

- Open the project via `project.godot` in Godot 4.6
- Main scene: `levels/base_level.tscn` (configured in `project.godot`)
- Web build: `./build_web.sh`, publish: `./publish_web.sh`
- Android build: `./build_android.sh`
- Export presets: `export_presets.cfg`

---

## Balance and Constants

All numeric tuning lives in two files. Nothing else in the game has hardcoded numbers — if you see one, it's a bug.

### `globals/constants.gd` — the knobs

Plain `const` values, grouped by section. This is where you change _what_ the numbers are.

| Section            | What's there                                                                         |
| ------------------ | ------------------------------------------------------------------------------------ |
| `# --- Enums ---`  | `DevType`, `TaskType`, `UpgradeStat`, `UpgradeRarity`, `UpgradeGroup`, `Music`, `Sfx` |
| `# --- Combat ---` | `BASE_HP`, `BASE_DAMAGE`, `BASE_ATTACK_SPEED`, `SPEED_CAP`, HP growth exponents       |
| `# --- Boost ---`  | `MAX_BOOST_STACKS`, stack lifetime, `BASE_BOOST_SPEED`, auto-click base/cap           |
| `# --- Progression ---` | sprint sizes per level, `HIRE_LEVELS`, sprints-per-level-up, `BASE_TOTAL_GAME_TIME` (480s) |
| `# --- Tasks ---`  | base feature/refactoring chances                                                     |
| `# --- Upgrades ---` | `UPGRADE_CHOICES`, `INITIAL_REROLLS`, rarity budgets, rarity caps, rarity appearance rates per level |
| `# --- Milestones ---` | valuation tiers from "PS5" to "World Domination"                                   |

Want longer runs? Change `BASE_TOTAL_GAME_TIME`. Want legendaries to show up earlier? Edit `RARITY_APPEARANCE_RATES`. Want a new hire slot at level 20? Add to `HIRE_LEVELS`.

### `globals/balance.gd` — the formulas

Stateless static methods that turn constants + runtime state into numbers the game uses. This is where you change _how_ the numbers combine.

| Function                          | Purpose                                                    |
| --------------------------------- | ---------------------------------------------------------- |
| `get_player_stats_from_upgrades`  | Single source of truth for player stats (gameplay + UI)    |
| `calculate_damage`                | `BASE_DAMAGE × task_mult × task_damage_mult`               |
| `calculate_attack_speed`          | `base / (1 + stacks × boost_per_stack)`, clamped to cap    |
| `get_task_hp` / HP growth         | Task HP scaling by level                                   |
| `get_sprint_composition`          | How many feature vs refactoring tasks a sprint contains    |
| `distribute_rarities`             | Rolls upgrade rarities from the per-level appearance table |
| `is_auto_click_capped` / `is_boost_speed_capped` | Diminishing-returns checks for upgrade filtering |

Rule of thumb: tuning a number → `constants.gd`. Changing the shape of a curve or how stats combine → `balance.gd`.

### `game_data/*.tres` — per-entity stats

Per-entity numbers (a developer's base attack speed, a task's base HP multiplier, an upgrade's stat deltas) live in `.tres` resources under `game_data/`. These feed into the formulas above. Change a single developer's strength without touching any script — just edit its `.tres`.

---

## Directory Layout

### `autoloads/` — global state and the event bus

Autoloads are registered in `project.godot` under short aliases:

| Alias | File               | Purpose                                               |
| ----- | ------------------ | ----------------------------------------------------- |
| `SB`  | `signal_bus.gd`    | Signal bus (tasks, boosts, level up, game over)       |
| `SD`  | `save_data.gd`     | Save/load                                             |
| `AM`  | `audio_manager.gd` | Music and SFX (tracks registered in `_ready`)         |
| `DR`  | `data_registry.gd` | Registry of `.tres` resources (upgrades, developers)  |
| `PD`  | `player_data.gd`   | Runtime game state: valuation, level, sprints, hiring |

### `globals/` — stateless helpers, constants, tokens

```
constants.gd       # all enums, tuning numbers, milestones
balance.gd         # formulas: damage, task HP, sprint composition, rarity weights
theme_tokens.gd    # colors, font sizes (used everywhere in UI)
```

No state, static methods only.

### `components/` — game entities

```
developer/            # a developer (keyboard + head), boost stack, task_card
background_office/    # office background
traits/               # reusable child components
    clickable_trait.gd    # catches clicks, emits `clicked`
    selectable_trait.gd   # selection
    flashable_trait.gd    # flash on hit
ui/                   # in-game UI
    ui_hud, ui_sprint_panel, ui_task_card, ui_hire_choice,
    ui_upgrade_choice, ui_upgrade_button, ui_player_stats,
    ui_ceo_commentator, ui_boost_stack, ui_game_info, ui_game_over,
    dialog_pause, ui_arrow
```

### `levels/` — levels

```
base_level.tscn/.gd   # main scene: 9 developer desks, music, boost hint
```

A level only assembles entities from `components/` and calls `PD.start_game(desks)`. Behavior lives on entities and autoloads.

### `game_data/` — game data (resource class + instances side by side)

```
developer/
    developer_data.gd                   # Resource class
    developer_data_vibecoder.tres       # a specific vibe coder
    developer_data_developer.tres
    developer_data_senior.tres
task/
    task_data.gd
    task_data_feature.tres
    task_data_refactoring.tres
upgrades/
    upgrade_data.gd
    common/ uncommon/ epic/ legendary/  # .tres files grouped by rarity
cost_function/                          # strategies for upgrade cost
task_select_function*.gd/.tres          # strategies for which task a dev picks
player_stats_resource.gd                # snapshot of player stats
```

### `assets/` — art, music, SFX

```
icons/    # UI icons
music/    # tracks (registered in audio_manager under Constants.Music)
sfx/      # sounds (under Constants.Sfx)
exports/  # export assets from PSD
```

### `resources/`

```
ui_game_theme.tres   # main UI theme for the project
```

### `logs/`, `releases/`, `balance_warnings.txt`

Runtime and build artifacts. Should not be tracked in git (see `.gitignore`).

---

## Common Operations

- **Add a developer type** — new `.tres` in `game_data/developer/`, set `head_texture`, `head_offset`, `task_select` strategy. No script changes.
- **Add an upgrade** — new `.tres` in `game_data/upgrades/<rarity>/`. `DR` picks it up automatically.
- **Tweak balance** — numbers live in `globals/constants.gd`, formulas in `globals/balance.gd`.
- **Add a cross-system event** — declare the signal in `autoloads/signal_bus.gd`, emit where it happens, listen where you react.
- **New UI panel** — scene in `components/ui/`, colors/fonts through `ThemeTokens`.
