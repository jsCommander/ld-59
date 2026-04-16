# Upgrade Button UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace automatic upgrade/hire popups with a player-driven queue and a pulsing "Upgrade" button in the HUD.

**Architecture:** `PlayerData` accumulates `pending_upgrades: Array[Constants.UpgradeType]` on level-up. A new `UiUpgradeButton` component shows/hides based on queue size. When clicked, `UiHud` iterates the queue opening dialogs sequentially. First hire at game start stays as auto-popup.

**Tech Stack:** Godot 4, GDScript

**Spec:** `docs/superpowers/specs/2026-04-16-upgrade-button-ui-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `globals/constants.gd` | Modify | Add `UpgradeType` enum |
| `autoloads/signal_bus.gd` | Modify | Add `pending_upgrades_changed` signal |
| `autoloads/player_data.gd` | Modify | Add `pending_upgrades` array, rewrite `_check_level_up` as while-loop, remove `_awaiting_choice` |
| `components/ui/ui_upgrade_button/ui_upgrade_button.gd` | Create | Button script — listen to signal, update text, pulse animation |
| `components/ui/ui_upgrade_button/ui_upgrade_button.tscn` | Create | Button scene |
| `components/ui/ui_hud/ui_hud.gd` | Modify | Add `_on_upgrade_button_pressed` handler, remove old level-up/hire-from-levelup logic |
| `components/ui/ui_hud/ui_hud.tscn` | Modify | Add UiUpgradeButton instance |

---

### Task 1: Add UpgradeType enum and pending_upgrades_changed signal

**Files:**
- Modify: `globals/constants.gd:6-25` (enums section)
- Modify: `autoloads/signal_bus.gd:36-38` (after `developer_hire_requested`)

- [ ] **Step 1: Add enum to Constants**

In `globals/constants.gd`, add after the `UpgradeGroup` enum (line 25):

```gdscript
enum UpgradeType { HIRE, UPGRADE }
```

- [ ] **Step 2: Add signal to SignalBus**

In `autoloads/signal_bus.gd`, add after the `developer_chosen` signal (line 38):

```gdscript
@warning_ignore("unused_signal")
signal pending_upgrades_changed
```

- [ ] **Step 3: Commit**

```bash
git add globals/constants.gd autoloads/signal_bus.gd
git commit -m "feat: add UpgradeType enum and pending_upgrades_changed signal"
```

---

### Task 2: Rewrite PlayerData — queue-based upgrades, remove _awaiting_choice

**Files:**
- Modify: `autoloads/player_data.gd`

This task has multiple sub-steps. Read the full file before making changes.

- [ ] **Step 1: Add pending_upgrades state, remove _awaiting_choice**

In the `# --- State ---` section, add:

```gdscript
var pending_upgrades: Array[Constants.UpgradeType] = []
```

Remove:

```gdscript
var _awaiting_choice: bool = false
```

- [ ] **Step 2: Rewrite _check_level_up as while-loop**

Replace the current `_check_level_up()` method (lines 241-252) with:

```gdscript
func _check_level_up() -> void:
	var changed: bool = false
	while true:
		var next_threshold: int = get_xp_for_level(level + 1)
		if next_threshold <= 0:
			break
		if valuation < next_threshold:
			break
		level += 1
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
		if level in Constants.HIRE_LEVELS:
			pending_upgrades.append(Constants.UpgradeType.HIRE)
		pending_upgrades.append(Constants.UpgradeType.UPGRADE)
		changed = true
	if changed:
		SB.pending_upgrades_changed.emit()
```

- [ ] **Step 3: Update _on_tick — remove _awaiting_choice check**

Replace lines 141-142:

```gdscript
# Before:
if not _game_active or _awaiting_choice:
    return

# After:
if not _game_active:
    return
```

- [ ] **Step 4: Update _on_upgrade_chosen — remove _awaiting_choice**

Replace the method (lines 154-158):

```gdscript
func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_check_level_up()
```

- [ ] **Step 5: Update _on_developer_chosen — remove _awaiting_choice**

Replace the method (lines 161-163):

```gdscript
func _on_developer_chosen(dev_data: DeveloperData) -> void:
	hire_developer(dev_data)
```

- [ ] **Step 6: Update _apply_task_rewards — remove guard**

In `_apply_task_rewards` (line 261-262), replace:

```gdscript
# Before:
if not _awaiting_choice:
    _check_level_up()

# After:
_check_level_up()
```

- [ ] **Step 7: Update start_game — remove _awaiting_choice, keep auto-popup**

In `start_game()` (lines 64-72), remove the `_awaiting_choice = true` line (it no longer exists). Keep `SB.developer_hire_requested.emit()` — the first hire stays as an auto-popup.

- [ ] **Step 8: Update reset — clear pending_upgrades**

In `reset()`, remove `_awaiting_choice = false` and add `pending_upgrades.clear()` after `total_stats.clear()`.

- [ ] **Step 9: Verify no remaining references to _awaiting_choice**

Search the file for `_awaiting_choice` — should have zero occurrences.

- [ ] **Step 10: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat: queue-based pending_upgrades, remove _awaiting_choice from PlayerData"
```

---

### Task 3: Create UiUpgradeButton component

**Files:**
- Create: `components/ui/ui_upgrade_button/ui_upgrade_button.gd`
- Create: `components/ui/ui_upgrade_button/ui_upgrade_button.tscn`

- [ ] **Step 1: Create the script**

Create `components/ui/ui_upgrade_button/ui_upgrade_button.gd`:

```gdscript
class_name UiUpgradeButton
extends Button

# --- Constants ---

const PULSE_DURATION: float = 0.6
const PULSE_SCALE: float = 1.05

# --- State ---

var _pulse_tween: Tween

# --- Lifecycle ---

func _ready() -> void:
	SB.pending_upgrades_changed.connect(_on_pending_upgrades_changed)
	_update()


# --- Handlers ---

func _on_pending_upgrades_changed() -> void:
	_update()


# --- Private ---

func _update() -> void:
	var count: int = PD.pending_upgrades.size()
	visible = count > 0
	text = "Upgrade (%d)" % count
	if count > 0:
		_start_pulse()
	else:
		_stop_pulse()


func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		return
	pivot_offset = size / 2.0
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_DURATION * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, PULSE_DURATION * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	scale = Vector2.ONE
```

- [ ] **Step 2: Create the scene**

Create `components/ui/ui_upgrade_button/ui_upgrade_button.tscn`. This is a minimal scene — a single Button node with the script attached:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://components/ui/ui_upgrade_button/ui_upgrade_button.gd" id="1_script"]

[node name="UiUpgradeButton" type="Button"]
custom_minimum_size = Vector2(200, 50)
theme_override_font_sizes/font_size = 22
text = "Upgrade (0)"
script = ExtResource("1_script")
```

Note: The scene file needs valid UIDs. Create the `.gd` file first, then create the `.tscn` manually or via the Godot editor. If creating via code, UIDs will be assigned on next editor open.

- [ ] **Step 3: Commit**

```bash
git add components/ui/ui_upgrade_button/
git commit -m "feat: add UiUpgradeButton component with pulse animation"
```

---

### Task 4: Update UiHud — wire up button, remove old popup logic

**Files:**
- Modify: `components/ui/ui_hud/ui_hud.gd`
- Modify: `components/ui/ui_hud/ui_hud.tscn`

- [ ] **Step 1: Update ui_hud.gd**

Replace the full file content. Key changes:
- Remove `_pending_upgrade_level` state
- Remove `_on_level_up()` handler
- Remove `SB.level_up.connect(...)` from `_ready`
- Keep `_on_hire_requested()` for initial game-start hire (simplified — no deferred upgrade logic)
- Add `@onready var upgrade_button: UiUpgradeButton = %UiUpgradeButton`
- Add `_on_upgrade_button_pressed()` handler

Updated `ui_hud.gd`:

```gdscript
class_name UiHud
extends CanvasLayer

const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")

const FLY_DURATION: float = 0.4
const FLY_ICON_SIZE: Vector2 = Vector2(64, 64)

# --- @onready ---

@onready var sprint_panel: UiSprintPanel = %UiSprintPanel
@onready var dialog_manager: DialogManager = %DialogManager
@onready var upgrade_button: UiUpgradeButton = %UiUpgradeButton

# --- Lifecycle ---

func _ready() -> void:
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.game_over.connect(_on_game_over)
	SB.task_assigned.connect(_on_task_assigned)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

# --- Handlers ---

func _on_hire_requested() -> void:
	var result: Dictionary = await dialog_manager.open_dialog(UI_HIRE_CHOICE, {}, true)
	var dev_data: DeveloperData = result.get("dev_data")
	if dev_data:
		SB.developer_chosen.emit(dev_data)

func _on_game_over(final_valuation: int) -> void:
	var result: Dictionary = await dialog_manager.open_dialog(UI_GAME_OVER, {"valuation": final_valuation}, true)
	if result.get("action") == "restart":
		get_tree().reload_current_scene()

func _on_task_assigned(task: TaskData, developer: Developer, task_position: Vector2) -> void:
	_fly_task_to_developer(task, developer, task_position)

func _on_upgrade_button_pressed() -> void:
	while not PD.pending_upgrades.is_empty():
		var upgrade_type: Constants.UpgradeType = PD.pending_upgrades.pop_front()
		SB.pending_upgrades_changed.emit()
		if upgrade_type == Constants.UpgradeType.HIRE:
			var result: Dictionary = await dialog_manager.open_dialog(UI_HIRE_CHOICE, {}, true)
			var dev_data: DeveloperData = result.get("dev_data")
			if dev_data:
				SB.developer_chosen.emit(dev_data)
		elif upgrade_type == Constants.UpgradeType.UPGRADE:
			var result: Dictionary = await dialog_manager.open_dialog(UI_UPGRADE_CHOICE, {"level": PD.level}, true)
			var upgrade: UpgradeData = result.get("upgrade")
			if upgrade:
				SB.upgrade_chosen.emit(upgrade)

# --- Private ---

func _fly_task_to_developer(task: TaskData, developer: Developer, task_position: Vector2) -> void:
	var start_pos: Vector2 = sprint_panel.get_card_position(task)
	var canvas_transform: Transform2D = developer.get_viewport().get_canvas_transform()
	var end_pos: Vector2 = canvas_transform * task_position

	var icon: TextureRect = TextureRect.new()
	icon.texture = task.texture
	icon.custom_minimum_size = FLY_ICON_SIZE
	icon.size = FLY_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = start_pos - FLY_ICON_SIZE * 0.5
	add_child(icon)

	SB.task_fly_started.emit(task, developer)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", end_pos - FLY_ICON_SIZE * 0.5, FLY_DURATION)
	tween.tween_callback(func() -> void:
		icon.queue_free()
		SB.task_fly_ended.emit(task, developer)
	)
```

- [ ] **Step 2: Update ui_hud.tscn — add UiUpgradeButton**

Add the UiUpgradeButton instance to the scene. Position it to the right of the sprint panel. The sprint panel is at bottom-left (`offset_left: 0, offset_top: -128, offset_right: 600, offset_bottom: 0`, anchored bottom-left). Place the button just right of it.

Add these lines to `ui_hud.tscn` (after the UiSprintPanel node):

```
[ext_resource type="PackedScene" path="res://components/ui/ui_upgrade_button/ui_upgrade_button.tscn" id="11_upgrade_btn"]

[node name="UiUpgradeButton" parent="." unique_id=... instance=ExtResource("11_upgrade_btn")]
unique_name_in_owner = true
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 610.0
offset_top = -78.0
offset_right = 810.0
offset_bottom = -28.0
grow_vertical = 0
```

Note: `unique_id` will be auto-generated. The exact offsets may need visual tuning in the Godot editor. The key constraint is: bottom-left area, to the right of the sprint panel (which ends at x=600).

- [ ] **Step 3: Commit**

```bash
git add components/ui/ui_hud/ui_hud.gd components/ui/ui_hud/ui_hud.tscn
git commit -m "feat: wire UiUpgradeButton into UiHud, remove auto-popup on level-up"
```

---

### Task 5: Manual playtest verification

**Files:** None (verification only)

- [ ] **Step 1: Launch the game in Godot editor**

Run the project and verify:

1. Game starts → first hire popup shows automatically (unchanged behavior)
2. Play until first level-up → "Upgrade (1)" button appears at bottom, pulsing
3. Click the button → upgrade dialog opens (game pauses)
4. Choose an upgrade → if more pending, next dialog opens; if empty, button hides
5. Reach a hire level (level 3) → button shows with count including the hire
6. Click button → hire dialog shows first (if HIRE was first in queue), then upgrade dialog
7. Let multiple level-ups accumulate without clicking → counter increments correctly
8. After processing all → button disappears, game resumes

- [ ] **Step 2: Verify edge cases**

1. Multi-level jump: if a big reward skips levels, verify all upgrades/hires are queued
2. Game timer continues ticking when button is visible but not clicked
3. Game over dialog still works as before
