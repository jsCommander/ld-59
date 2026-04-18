# Stats Panel Clarity Redesign

**Date:** 2026-04-18
**Status:** Design — awaiting user review before implementation

## Problem

Players report they don't understand what the stats do. The current upgrade dialog shows 7 stat names with bare percentages (`Boost Speed: 15%`, `Auto Click Speed: 100%`). Nothing explains what the numbers actually mean mechanically. The most opaque cases:

- `auto_click_speed = 0` means the feature is **completely disabled**; any positive value activates it. Nothing in UI hints at this.
- `feature_chance` / `refactoring_chance` affect **sprint composition** (how many features vs refactorings per sprint), not hit-chance or crit-chance as the name suggests.
- `global_damage`, `feature_damage`, `refactoring_damage` stack **multiplicatively**; a card with `+10% feature_damage` is worth more than a card with the same `+10% global_damage` if the player plays mostly features, but the UI shows both as identical "+10%".
- `boost_speed` — "boost" refers to clicking on a developer to speed them up, but nothing in the name conveys this.

## Goal

Make the stats panel tell the player, in concrete terms, what the current state of their build is and what an upgrade will change. Replace abstract percentages with derived gameplay values wherever meaningful. Add a two-tap preview flow so the player can hover/select an upgrade card and see exactly which numbers move before committing.

## Non-goals

- Not renaming stats in code (`global_damage`, `feature_chance`, etc. stay the same in `Constants`). Only display changes.
- Not redesigning upgrade cards themselves (rarity colours, icons, descriptions stay as-is).
- Not touching save/load, resource `.tres` files, or balance formulas.
- Not adding tooltips, long-press help, or per-stat explanations. The derived numbers are the explanation.

## Design

### 1. Panel layout — three columns

The `StatsGrid` in `ui_upgrade_choice.tscn` becomes a 3-column layout. Each column shows a grouped, self-explanatory view of a part of the build.

```
┌──────────────────┬──────────────────────────┬────────────────────┐
│  ⚔️ DAMAGE       │  ⚡ CLICK BOOST          │  📋 SPRINT TASKS   │
├──────────────────┼──────────────────────────┼────────────────────┤
│ Features: ×1.27  │ Dev Speed Per Stack: +30%│ Features:    7/12  │
│ Refactor: ×1.15  │ Auto click:  1.5s        │ Refactoring: 5/12  │
└──────────────────┴──────────────────────────┴────────────────────┘
```

**Damage column.** Two rows, one per task type. Each row shows the **full effective multiplier** a developer gets when working on that task type:

- `Features = (1 + global_damage) × (1 + feature_damage)`
- `Refactor = (1 + global_damage) × (1 + refactoring_damage)`

Values rendered as `×1.27` (two decimal places). With no upgrades both rows show `×1.00`. A `+global_damage` upgrade moves both rows; a `+feature_damage` upgrade moves only the Features row. This directly communicates "this upgrade is specialised vs universal" without any explanation.

**Click Boost column.** Two rows:

- `Dev Speed Per Stack` — shown as a percentage (`+30%`). Represents `BASE_BOOST_SPEED + boost_speed` as a percentage bonus per stack. This is kept as a percentage because "seconds per click" depends on the dev's `base_attack_speed` and current stack count, so a single concrete number would be misleading.
- `Auto click` — shown as the **actual firing interval** in seconds (`1.5s`, `0.8s`, etc.) computed by `Balance.calculate_auto_click_interval`. When `auto_click_speed == 0`, the row shows **`Off`** — this immediately tells the player "no auto-click right now; an upgrade to this stat will turn it on".

**Sprint Tasks column.** Two rows showing **expected task counts out of total sprint size**, not percentages:

- `Features: N/S` where `N = round(S × feature_weight_fraction)` and `S = _get_sprint_size(player_level)`
- `Refactoring: (S − N)/S`

Sprint size comes from the `SPRINT_SIZES` progression table (2 → 12 as the player levels up). Showing `7/12` rather than `58%` makes the impact of a chance upgrade tangible: "this card turns 1 refactoring task into 1 feature per sprint."

### 2. Two-tap selection flow

Replace the current "click card = immediately apply" behaviour with a select-then-confirm flow that works identically on desktop and mobile.

**States of a card:** `idle`, `selected`.

**Flow:**

1. Dialog opens. No card is selected. Stats panel shows current values. `Take` button is **disabled**.
2. Player taps a card → that card enters `selected` state (visual: existing hover variation theme, or a stronger border treatment); any previously selected card returns to `idle`.
3. Stats panel re-renders as a **diff view**:
   - Rows unaffected by the selected upgrade: dimmed (reduced opacity, e.g. 50%).
   - Rows that would change: full opacity, with the new value appended after an arrow. E.g. `Features: ×1.27 → ×1.40 (+10%)`. Positive delta in green, negative in red, per existing `ThemeTokens.STAT_POSITIVE` / `STAT_NEGATIVE`.
   - `Auto click` special case: `Off → 1.5s` when the upgrade unlocks auto-click. Same arrow format; the transition from `Off` is self-explanatory.
4. `Take` button becomes **enabled** while a card is selected.
5. Player can tap a different card → preview swaps. Tap the same card again → equivalent to pressing Take (shortcut for power users who want one-button-per-card feel).
6. Player taps Take → dialog closes, upgrade applies. Same `chosen` signal as today; no change to callers.
7. `Reroll` also deselects any selected card and resets the panel to the current-state view.

### 3. Component architecture

**New: `Balance.get_display_stats(stats: Dictionary, player_level: int) -> Dictionary`**

A single pure function that produces the rendering data for all three columns given a stats dictionary and the player level. Returns a structure like:

```gdscript
{
    "damage": {
        "features":  1.27,   # full multiplier
        "refactor":  1.15,
    },
    "click_boost": {
        "dev_speed_per_stack": 1.80,  # BASE_BOOST_SPEED + boost_speed, as 1 + fraction
        "auto_click_interval": 1.5,   # seconds, or 0.0 meaning Off
    },
    "sprint": {
        "size":       12,
        "features":   7,
        "refactoring": 5,
    },
}
```

All mechanics reused from the existing functions in `balance.gd` (`calculate_damage` formula, `calculate_auto_click_interval`, `calculate_task_type_weights`) — no new game logic. This keeps the display 100% consistent with actual in-game values: if the formula changes, the display changes with it automatically.

**Replace: `StatSummaryItem` → `StatRow` component (single row only)**

One small widget, one job: render one stat line. No column scenes, no parent panel scene. All assembly of the three columns happens directly inside `ui_upgrade_choice.tscn` — three `VBoxContainer`s side by side, each holding a header `Label` and a few pre-placed `StatRow` instances, referenced from the script via `unique_name_in_owner`.

`StatRow` is a pure renderer. It takes formatted strings — it does not know what a "multiplier" or an "interval" is. All formatting (×1.27, +30%, 1.5s, Off, 7/12) lives in `ui_upgrade_choice.gd`. API:

```gdscript
class_name StatRow extends Control

func show_plain(label: String, value: String) -> void        # no preview active
func show_dimmed(label: String, value: String) -> void       # preview active, this row unchanged
func show_diff(label: String, current: String, preview: String, delta: String, positive: bool) -> void
```

Three explicit states cover every case. `show_diff` renders as `Features:  ×1.27 → ×1.40  (+10%)` with the delta segment coloured via existing `ThemeTokens.STAT_POSITIVE` / `STAT_NEGATIVE`. `show_dimmed` applies a modulate/alpha reduction so the eye naturally focuses on the changed rows.

**Modify: `UpgradeCard`**

Add `selected` state:

```gdscript
signal selected_changed(card: UpgradeCard, is_selected: bool)
var is_selected: bool
func set_selected(value: bool) -> void
```

Replace the `_gui_input` → emit `chosen` logic with: click → emit `selected_changed(self, true)`. The dialog handles the actual selection state (enforces single-selection, re-emits `chosen` when Take is pressed or when the same card is tapped twice).

**Modify: `ui_upgrade_choice.gd`**

- Drop `stats_grid`. Add `@onready` references to each pre-placed `StatRow` in the scene via unique names, e.g.:
  - `%RowDamageFeatures`, `%RowDamageRefactor`
  - `%RowClickPerStack`, `%RowClickAuto`
  - `%RowSprintFeatures`, `%RowSprintRefactor`
- Add `@onready var take_button: Button = %TakeButton`.
- Track `var _selected_card: UpgradeCard`.
- Add private helpers that own all formatting:
  - `_render_plain(stats, level)` — calls `Balance.get_display_stats`, formats each value, calls `show_plain` on every row.
  - `_render_preview(current_stats, preview_stats, level)` — calls `Balance.get_display_stats` twice, and for each row decides `show_dimmed` (unchanged) or `show_diff` (changed) based on value equality.
- `_build_cards`: connect `selected_changed` instead of `chosen`.
- `_on_card_selected(card, is_selected)`: if `is_selected` and same card already selected → treat as Take. Else: update `_selected_card`, deselect others, compute `preview_stats` by iterating `Constants.STAT_ORDER` and summing `PD.total_stats[field] + card.upgrade.get(field)` for each field, call `_render_preview(...)`, enable Take button.
- `_on_take_pressed`: close with the selected upgrade's data.
- `_on_reroll_pressed`: after rebuilding cards, clear `_selected_card`, call `_render_plain(...)`, disable Take.

**Modify: `ui_upgrade_choice.tscn`**

- Replace `StatsGrid` (GridContainer) with a 3-column `HBoxContainer` named e.g. `StatsPanel`.
- Each child column is a `VBoxContainer` with:
  - A header `Label` (theme variation `LabelH3`-ish): `⚔️ DAMAGE`, `⚡ CLICK BOOST`, `📋 SPRINT TASKS`.
  - Two pre-placed `StatRow` scene instances, each with a unique name matching the `@onready` references in the script.
- Remove `StatsSectionLabel` ("Current Stats") — redundant once columns have their own headers.
- Add `TakeButton` below the reroll button (or beside it; layout TBD during implementation — keep within existing VBox flow).

### 4. Data flow for preview

```
User taps Card
     │
     ▼
Card.selected_changed(card, true)
     │
     ▼
ui_upgrade_choice._on_card_selected
     │
     ├─ deselect previous card
     ├─ store selected card
     ├─ compute preview_stats = PD.total_stats merged with card.upgrade's stat deltas
     └─ _render_preview(PD.total_stats, preview_stats, PD.player_level)
            │
            ├─ current_display = Balance.get_display_stats(current, level)
            ├─ preview_display = Balance.get_display_stats(preview, level)
            └─ For each StatRow reference (6 total):
                   current_str = format(current_display[row])
                   preview_str = format(preview_display[row])
                   if current_str == preview_str:
                       row.show_dimmed(label, current_str)
                   else:
                       delta_str = format_delta(current, preview)
                       row.show_diff(label, current_str, preview_str, delta_str, positive)
```

No new state outside the dialog. The preview is purely a re-render triggered by selection.

### 5. Files touched

**New:**
- `components/ui/ui_upgrade_choice/stat_row.gd` + `.tscn` — the single-row widget

**Modified:**
- `globals/balance.gd` — add `get_display_stats`
- `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd` — two-tap flow, preview wiring, all value formatting
- `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn` — replace grid with three columns of pre-placed `StatRow` instances, add Take button
- `components/ui/ui_upgrade_choice/upgrade_card.gd` — `selected` state, replace `chosen` input with `selected_changed`

**Deleted:**
- `components/ui/ui_upgrade_choice/stat_summary_item.gd` + `.tscn`

### 6. Edge cases

- **Player level 1, no upgrades:** all damage rows show `×1.00`, `Dev Speed Per Stack: +150%` (because `BASE_BOOST_SPEED = 1.5`), `Auto click: Off`, sprint shows `Features: 1/2, Refactoring: 1/2`. No "empty state" treatment needed.
- **Upgrade that reduces a stat (negative delta):** arrow renders red, same format: `Features: ×1.27 → ×1.20 (−7%)`. Trade-off upgrades already exist in the system (`TradeOffType.TRADE_OFF_CROSS_GROUP`), so preview must handle both directions correctly.
- **Auto-click unlock with already-capped value:** if upgrade pushes interval below `AUTO_CLICK_CAP`, `calculate_auto_click_interval` already clamps. Preview shows the clamped value; no special UI affordance for the cap (the player can infer from two successive upgrades producing the same number).
- **Sprint rounding:** `roundi(sprint_size × feature_fraction)` matches exactly how `player_data._generate_sprint` rounds, so preview counts match what the player will actually see in-game. No separate rounding logic.
- **Feature/refactor chance preview when both would change:** shouldn't happen per `FORBIDDEN_POSITIVE_STAT_COMBINATIONS`, but handle cleanly anyway — both rows update independently.

### 7. Testing

Manual:
- Open dialog at level 1 with no upgrades — panel renders correctly with baseline values.
- Tap each card — preview diff highlights only the affected rows.
- Tap a second card — first deselects, second's preview renders.
- Tap same card twice — upgrade applies.
- Tap Take button — upgrade applies.
- Trade-off card (one positive, one negative stat) — both rows highlight, one green, one red.
- Card that unlocks auto-click — row transitions from `Off → 1.5s`.
- Card with `+feature_chance` — sprint task counts shift by 1.
- Reroll — selection clears, panel returns to current-state view, Take disabled.

Balance regression: since `get_display_stats` calls the same `calculate_*` functions used in combat, a quick in-game sanity check — compare displayed auto-click interval against the actual firing interval of an auto-click timer — should match exactly.

## Out of scope / future

- Tooltips on stat rows explaining the formula itself (e.g. "×1.27 = 1.15 global × 1.10 feature"). Deferred; the goal of this pass is clarity of *impact*, not clarity of *math*.
- Icons for each stat / column. Emoji headers are a placeholder; proper icons can come later without changing the layout.
- Showing expected DPS-over-time or sprint completion time. Complex to compute, depends on all devs and their task_mults — too much for this iteration.
