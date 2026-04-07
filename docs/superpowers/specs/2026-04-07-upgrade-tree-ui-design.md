# Upgrade Tree UI — Design Spec

## Overview

Replace personal developer upgrades with a shared upgrade tree. Add an "Upgrades" button to the HUD that opens a fullscreen modal with a skill tree. Rework the developer popup to show colored stat bars instead of text stats and upgrade buttons.

---

## 1. Files to Delete

### Personal developer upgrades
- `game_data/upgrade/` — entire folder including `.uid` files

### Kit runtime UI (moved to game)
- `game_kit/ui/components/skill_tree/skill_tree_view.gd` + `.uid`
- `game_kit/ui/components/skill_tree/skill_tree_view.tscn`
- `game_kit/ui/components/skill_tree/skill_tree_node.gd` + `.uid`
- `game_kit/ui/components/skill_tree/skill_tree_node.tscn`
- `game_kit/ui/components/skill_tree/skill_tree_tooltip.gd` + `.uid`
- `game_kit/ui/components/skill_tree/skill_tree_tooltip.tscn`

---

## 2. Files to Modify

### developer.gd
- Remove: `purchased_upgrades` dict, `get_damage_multiplier()`, `get_upgrade_level()`, `get_available_upgrades()`, `apply_upgrade()`

### developer_data.gd
- Remove: `@export var upgrades: Array[DeveloperUpgrade] = []` (line 12)

### developer .tres files
- Remove upgrade references from `developer_data_regular.tres`, `developer_data_senior.tres`, `developer_data_vibecoder.tres` (if they reference DeveloperUpgrade resources)

### popup_developer.gd + .tscn
- Remove: `UpgradesContainer`, upgrade button logic, `_build_upgrade_buttons()`, `_on_upgrade_pressed()`, `get_damage_multiplier()` call
- Rework to stat bars layout (see Section 5)

### upgrade_tree.gd
- Add: `@export var cost: int = 100`
- `prerequisites` already exists

### Upgrade .tres files
- Add `cost` value to: `budget_boost.tres`, `bug_hunter.tres`, `fast_features.tres`, `leadership.tres`, `refactor_guru.tres`

### player_data.gd
- Add: `var purchased_upgrades: Dictionary = {}` — `{id: String → true}`
- Add: `func purchase_upgrade(upgrade: UpgradeTree) -> void` — deducts money, stores id, emits signal
- Add: `func is_upgrade_purchased(id: String) -> bool`

### signal_bus.gd
- Add: `signal upgrade_purchased(upgrade_id: String)`

### hud.gd + hud.tscn
- Add: "Апгрейды" button right of "Бэклог", larger size
- Add: `@onready var upgrade_button: Button = %UpgradeButton`
- Connect button to toggle `UiUpgradeTree` visibility

---

## 3. Kit Retains (Base Only)

The editor only uses `SkillTreeNodePlacement`, `SkillTreeLayout`, and `BaseUpgrade` — it does not reference the runtime view/node/tooltip classes, so it is self-contained.

```
game_kit/ui/components/skill_tree/
├── base_upgrade.gd              # Resource contract: id, display_name, description, icon
├── skill_tree_layout.gd         # Root config: nodes[], root, cell_size
├── skill_tree_node_placement.gd # Node: upgrade, grid_x, grid_y, children[]
├── skill_tree_editor.gd         # @tool editor for layout editing
└── skill_tree_editor.tscn
```

---

## 4. New Files — Upgrade Tree UI

```
components/ui/ui_upgrade_tree/
├── ui_upgrade_tree.gd / .tscn       # Fullscreen modal wrapper
├── upgrade_tree_view.gd / .tscn     # Runtime tree display
├── upgrade_tree_node.gd / .tscn     # Diamond node
└── upgrade_tree_tooltip.gd / .tscn  # Tooltip with "Buy" button
```

New class names (`UpgradeTreeView`, `UpgradeTreeNode`, `UpgradeTreeTooltip`) avoid collision with deleted kit classes.

### ui_upgrade_tree (Modal)
- CanvasLayer (layer 10, same as backlog)
- Group: "upgrade_tree" (for discovery via groups pattern)
- Dark semi-transparent background overlay
- Header: title "Дерево апгрейдов" + close button "✕"
- Contains UpgradeTreeView with layout loaded from `game_data/upgrade_tree/upgrades_tree.tres`
- Starts hidden, toggled by HUD button

### upgrade_tree_view (Copied from kit SkillTreeView, adapted)
- Reads layout, builds nodes, draws connection lines
- Queries PD to determine each node's state on build/refresh:
  - `PURCHASED` (green) — `PD.is_upgrade_purchased(id)` returns true
  - `AVAILABLE` (white) — all prerequisites purchased (checked via `PD.is_upgrade_purchased`)
  - `LOCKED` (gray) — prerequisites not met
- Connects to `SB.upgrade_purchased` to auto-refresh states after any purchase
- Panning with right-mouse drag
- Signals: `node_clicked(upgrade)`, `purchase_requested(upgrade: UpgradeTree)`

### upgrade_tree_node (Diamond)
- Visual diamond with icon inside
- Colors: gray (LOCKED), white (AVAILABLE), green (PURCHASED)
- Clickable when AVAILABLE

### upgrade_tree_tooltip (Redesigned)
- Header: upgrade display_name (no icon)
- Body: upgrade description
- Footer: "Купить ($cost)" button
  - Disabled if `!PD.can_afford(cost)`
  - On press: emits `buy_pressed(upgrade)` signal
- Clicking "Buy" also closes the tooltip
- Clicking outside a node closes the tooltip (existing kit behavior)
- No icon in tooltip

---

## 5. HUD Changes

### New button: "Апгрейды"
- Position: right of "Бэклог" button in the bottom HBoxContainer
- Size: larger than "Бэклог" button
- Opens/closes ui_upgrade_tree modal
- Modify `hud.tscn` to add the button and `hud.gd` to wire the toggle

---

## 6. Developer Popup Rework

### New layout
```
┌──────────────────────────┐
│      Фронтендер          │  ← name, centered
├──────────────────────────┤
│ Фичи       [████████░░]  │  ← green bar
│ Баги       [████░░░░░░]  │  ← red bar
│ Рефактор   [██░░░░░░░░]  │  ← blue bar
│ Скорость   [██████░░░░]  │  ← yellow bar
└──────────────────────────┘
```

### Implementation
- Remove: `StatsLabel`, `TaskLabel`, `UpgradesContainer`
- Add: 4x HBoxContainer rows, each with Label (left, min_size 80px) + ProgressBar (right, fills remaining)
- Bar colors: Фичи=#4CAF50, Баги=#F44336, Рефактор=#2196F3, Скорость=#FFEB3B
- Bar max value: fixed scale of 100
- Damage stats (feature_damage, bug_damage, refactor_damage) map directly to bar values
- Speed bar: `base_attack_speed` is inverted (lower = faster). Map as `bar.value = 100.0 / base_attack_speed` so faster devs have fuller bars. With base_attack_speed=2.0 → bar=50, base_attack_speed=1.0 → bar=100.
- No upgrade buttons, no damage multiplier

---

## 7. Purchase Logic

### Player Data (PD) additions
- `var purchased_upgrades: Dictionary = {}` — keys are upgrade id strings, values are `true`
- `func purchase_upgrade(upgrade: UpgradeTree) -> void` — checks can_afford, calls spend(), stores id, emits signal
- `func is_upgrade_purchased(id: String) -> bool` — `return id in purchased_upgrades`

### Signal Bus addition
- `signal upgrade_purchased(upgrade_id: String)` — emitted by PD after purchase

### UpgradeTree Resource
- Already has: `id`, `display_name`, `description`, `icon` (from BaseUpgrade), `prerequisites`
- Add: `@export var cost: int = 100`

### Purchase flow
1. Player clicks AVAILABLE node in tree
2. Tooltip shows with name, description, "Купить ($cost)"
3. Player clicks "Купить"
4. UpgradeTreeView emits `purchase_requested(upgrade)`
5. UiUpgradeTree calls `PD.purchase_upgrade(upgrade)`
6. PD deducts money, stores id, emits `SB.upgrade_purchased(id)`
7. UpgradeTreeView (connected to signal) refreshes all node states

---

## 8. Signal Flow

```
UpgradeTreeNode.clicked(upgrade)
  → UpgradeTreeView shows tooltip
    → UpgradeTreeTooltip.buy_pressed(upgrade)
      → UpgradeTreeView emits purchase_requested(upgrade)
        → UiUpgradeTree calls PD.purchase_upgrade(upgrade)
          → PD calls spend(cost), stores id
          → PD emits SB.upgrade_purchased(id)
            → UpgradeTreeView._on_upgrade_purchased() refreshes states
            → SB.resource_money_changed also emits (from spend)
```

---

## 9. Existing Data Preserved

- `game_data/upgrade_tree/upgrades_tree.tres` — existing layout resource, keep as-is
- `game_data/upgrade_tree/tree.tres` — appears to be a secondary layout file, keep for now
- Individual upgrade .tres files — update with `cost` field
- `data_registry.gd` — no changes needed, already loads UpgradeTree resources correctly
