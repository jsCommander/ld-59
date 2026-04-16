# Upgrade Button UI

## Summary

Replace the automatic upgrade/hire popup on level-up with a player-driven system. Upgrades accumulate in a queue. A pulsing button appears when upgrades are available. The player opens the menu when ready and processes all pending upgrades in sequence.

**Exception:** The very first hire at game start remains an auto-popup — the player has zero developers and cannot play without one.

## Current State

- On level-up, `UiHud._on_level_up()` immediately opens the upgrade dialog (pauses game)
- On hire levels, `SB.developer_hire_requested` triggers hire dialog first, then a deferred upgrade dialog via `_pending_upgrade_level`
- `PlayerData._awaiting_choice` pauses the tick timer during dialogs — redundant with `DialogManager`'s `pause_game: true`
- No visible indicator of pending upgrades; player has no control over timing

## Changes

### 1. New Enum

In `Constants`:

```gdscript
enum UpgradeType { HIRE, UPGRADE }
```

### 2. New Signal

In `SignalBus`:

```gdscript
signal pending_upgrades_changed
```

### 3. PlayerData Changes

New state:

```gdscript
var pending_upgrades: Array[Constants.UpgradeType] = []
```

Removed state:

- `_awaiting_choice: bool` — redundant with `DialogManager` pause

Modified methods:

- `_check_level_up()`: use a `while` loop to handle multi-level jumps. Instead of emitting `SB.developer_hire_requested`, push to `pending_upgrades`:
  - Hire level → push `HIRE`, then `UPGRADE`
  - Normal level → push `UPGRADE`
  - Keep emitting `SB.level_up(level)` — `UiXpBar` listens to it
  - Emit `SB.pending_upgrades_changed` once after the loop
- `_on_upgrade_chosen()`: remove `_awaiting_choice = false`. Keep `_check_level_up()` call — if applying an upgrade triggers another level-up, it safely pushes to the queue; the while-loop in `_on_upgrade_button_pressed` picks up new items naturally
- `_on_developer_chosen()`: remove `_awaiting_choice = false`
- `_on_tick()`: remove `_awaiting_choice` check — `DialogManager` pause handles this
- `_apply_task_rewards()`: remove `if not _awaiting_choice:` guard — `_check_level_up()` is now always safe to call since it only pushes to a queue
- `start_game()`: first hire stays as auto-popup via `SB.developer_hire_requested` (player needs a dev to start). Do not push to `pending_upgrades` for this initial hire
- `reset()`: clear `pending_upgrades`

### 4. UiUpgradeButton Component

New component: `components/ui/ui_upgrade_button/`

- `Button` node with text `"Upgrade (N)"` where N = `PD.pending_upgrades.size()`
- Uses default button theme tokens (`BUTTON_DEFAULT_*`)
- Listens to `SB.pending_upgrades_changed`:
  - `pending_upgrades.size() > 0` → visible, start scale pulse animation
  - `pending_upgrades.size() == 0` → hidden, stop animation
- Scale pulse: tween loop, scale 1.0 → 1.05 → 1.0
- Emits `pressed` signal on click

### 5. UiHud Changes

Removed:

- `_pending_upgrade_level` state variable
- `_on_level_up()` handler
- Connection to `SB.level_up`

Kept:

- `_on_hire_requested()` — still needed for the initial game-start hire

Added:

- `UiUpgradeButton` child node, positioned next to sprint panel
- `_on_upgrade_button_pressed()` handler:
  - While `PD.pending_upgrades` is not empty:
    - `pop_front()` the first element
    - If `HIRE`: open `UI_HIRE_CHOICE` dialog (pause=true), emit `SB.developer_chosen` with result
    - If `UPGRADE`: open `UI_UPGRADE_CHOICE` dialog (pause=true), emit `SB.upgrade_chosen` with result
    - Emit `SB.pending_upgrades_changed` after each pop
  - When array is empty, return

Note: the await chain works during pause because `DialogManager` sets `process_mode = PROCESS_MODE_ALWAYS`.

### 6. Signal Cleanup

- Remove `SB.developer_hire_requested` signal — only used by UiHud and PlayerData. Replace with direct queue push for all cases except the initial game-start hire, which keeps using it.

Wait — the initial hire still uses it. Keep the signal but remove its use from `_check_level_up()`. It is now only emitted once in `start_game()`.

## Edge Cases

- **Multi-level jump:** A large task reward can push the player past multiple levels. The `while` loop in `_check_level_up` handles this by iterating until valuation < next threshold.
- **New upgrades during processing:** If choosing an upgrade triggers another level-up (via `_on_upgrade_chosen` → `_check_level_up`), new items are pushed to `pending_upgrades`. The while-loop in `_on_upgrade_button_pressed` naturally picks them up.
- **Dialog always returns a result:** Current hire and upgrade dialogs require a choice — there is no close/cancel. If a dialog returns null, the item is forfeited (not pushed back).

## Files Affected

| File | Change |
|------|--------|
| `globals/constants.gd` | New `UpgradeType` enum |
| `autoloads/signal_bus.gd` | New `pending_upgrades_changed` signal |
| `autoloads/player_data.gd` | `pending_upgrades` array, remove `_awaiting_choice`, `while`-loop in `_check_level_up`, remove guards |
| `components/ui/ui_upgrade_button/` | New component (scene + script) |
| `components/ui/ui_hud/ui_hud.gd` | Add button, new handler, remove `_on_level_up`, keep `_on_hire_requested` for initial hire |
| `components/ui/ui_hud/ui_hud.tscn` | Add UiUpgradeButton node |
