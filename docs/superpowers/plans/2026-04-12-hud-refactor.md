# HUD Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decompose the monolithic HUD into autonomous UI components, rearrange the layout (capitalization + XP bar + timer on top, sprint panel + task cards on bottom), and centralize popup management in HUD.

**Architecture:** Each UI component is a self-contained scene (.tscn + .gd) that subscribes to `SB` signals directly. `UiHud` is a dumb layout container that also holds `UiPopupManager` and manages all popups (developer, upgrade, hire, game over). All UI components move to `components/ui/`. The old `components/hud/` directory is deleted entirely.

**Tech Stack:** Godot 4.x, GDScript

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `components/ui/ui_game_timer/ui_game_timer.tscn` | Game timer scene |
| Create | `components/ui/ui_game_timer/ui_game_timer.gd` | Game timer logic |
| Create | `components/ui/ui_xp_bar/ui_xp_bar.tscn` | XP progress bar scene |
| Create | `components/ui/ui_xp_bar/ui_xp_bar.gd` | XP bar logic |
| Create | `components/ui/ui_capitalization/ui_capitalization.tscn` | Capitalization display scene |
| Create | `components/ui/ui_capitalization/ui_capitalization.gd` | Capitalization + company flash logic |
| Create | `components/ui/ui_sprint_panel/ui_sprint_panel.tscn` | Sprint panel scene |
| Create | `components/ui/ui_sprint_panel/ui_sprint_panel.gd` | Sprint info + task cards logic |
| Move | `components/hud/ceo_commentator.*` → `components/ui/ui_ceo_commentator/` | Rename to UiCeoCommentator |
| Create | `components/ui/ui_hud/ui_hud.tscn` | New HUD layout scene |
| Create | `components/ui/ui_hud/ui_hud.gd` | HUD popup management |
| Modify | `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd` | Remove self-managed signal subscription |
| Modify | `components/ui/ui_hire_choice/ui_hire_choice.gd` | Remove self-managed signal subscription |
| Modify | `components/ui/ui_game_over/ui_game_over.gd` | Remove self-managed signal subscription |
| Modify | `globals/constants.gd` | Add COMPANY_MILESTONES |
| Modify | `levels/base_level.tscn` | Replace HUD instance, remove popup nodes |
| Modify | `levels/test_level.tscn` | Replace HUD instance, remove popup nodes |
| Create | `components/ui/ui_hud/hud_popup_manager.gd` | Minimal UiPopupManager override — emits selection_cleared on close |
| Delete | `components/hud/` | Entire old directory |

---

### Task 1: Move COMPANY_MILESTONES to Constants

**Files:**
- Modify: `globals/constants.gd`
- Modify: `components/hud/hud.gd`
- Modify: `components/ui/ui_game_over/ui_game_over.gd`

This constant is duplicated in `hud.gd` and `ui_game_over.gd`. Move it to `Constants` so both (and the new `UiCapitalization`) use a single source.

- [ ] **Step 1: Add COMPANY_MILESTONES to Constants**

Add after `BURNOUT_DURATION` line in `globals/constants.gd`:

```gdscript
const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 50, "name": "Zynga"},
	{"valuation": 200, "name": "Niantic"},
	{"valuation": 500, "name": "Ubisoft"},
	{"valuation": 1500, "name": "EA"},
	{"valuation": 5000, "name": "Valve"},
	{"valuation": 15000, "name": "Epic Games"},
	{"valuation": 50000, "name": "Apple"},
]
```

- [ ] **Step 2: Update ui_game_over.gd to use Constants**

In `components/ui/ui_game_over/ui_game_over.gd`:
- Remove the `COMPANY_MILESTONES` constant (lines 10–18)
- Replace `COMPANY_MILESTONES` references with `Constants.COMPANY_MILESTONES` in `_show_company_comparison`

- [ ] **Step 3: Update hud.gd to use Constants**

In `components/hud/hud.gd`:
- Remove the `COMPANY_MILESTONES` constant (lines 6–14)
- Replace `COMPANY_MILESTONES` reference with `Constants.COMPANY_MILESTONES` in `_update_company_comparison`

- [ ] **Step 4: Run the game and verify milestones still display correctly**

- [ ] **Step 5: Commit**

```
refactor: move COMPANY_MILESTONES to Constants
```

---

### Task 2: Create UiGameTimer

**Files:**
- Create: `components/ui/ui_game_timer/ui_game_timer.gd`
- Create: `components/ui/ui_game_timer/ui_game_timer.tscn`

A simple Label that listens to `SB.game_timer_changed` and formats MM:SS. Positioned in the top-right of the HUD.

- [ ] **Step 1: Create ui_game_timer.gd**

```gdscript
class_name UiGameTimer
extends Label

# --- Lifecycle ---

func _ready() -> void:
	SB.game_timer_changed.connect(_on_game_timer_changed)

# --- Handlers ---

func _on_game_timer_changed(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	text = "%d:%02d" % [minutes, seconds]
```

- [ ] **Step 2: Create ui_game_timer.tscn**

Scene root: `Label` node named `UiGameTimer` with script `ui_game_timer.gd`. Set `text = "10:00"` as default. Set `horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT`.

- [ ] **Step 3: Commit**

```
feat(ui): add UiGameTimer component
```

---

### Task 3: Create UiXpBar

**Files:**
- Create: `components/ui/ui_xp_bar/ui_xp_bar.gd`
- Create: `components/ui/ui_xp_bar/ui_xp_bar.tscn`

A ProgressBar that shows progress toward the next level. Listens to `SB.valuation_changed` and `SB.level_up`.

- [ ] **Step 1: Create ui_xp_bar.gd**

```gdscript
class_name UiXpBar
extends ProgressBar

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update)
	SB.level_up.connect(_on_level_up)
	_update()

# --- Handlers ---

func _on_level_up(_level: int) -> void:
	_update()

# --- Private ---

func _update() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	if next_xp > 0:
		value = float(PD.valuation) / float(next_xp)
	else:
		value = 1.0
```

- [ ] **Step 2: Create ui_xp_bar.tscn**

Scene root: `ProgressBar` node named `UiXpBar` with script `ui_xp_bar.gd`. Set `max_value = 1.0`, `show_percentage = false`.

- [ ] **Step 3: Commit**

```
feat(ui): add UiXpBar component
```

---

### Task 4: Create UiCapitalization

**Files:**
- Create: `components/ui/ui_capitalization/ui_capitalization.gd`
- Create: `components/ui/ui_capitalization/ui_capitalization.tscn`

A VBoxContainer with a large valuation label (centered) and a company flash label below it that fades out after ~2 seconds.

- [ ] **Step 1: Create ui_capitalization.gd**

```gdscript
class_name UiCapitalization
extends VBoxContainer

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var company_label: Label = %CompanyLabel

# --- State ---

var _flash_tween: Tween

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	company_label.modulate.a = 0.0
	_update_valuation()

# --- Handlers ---

func _on_level_up(_level: int) -> void:
	_update_valuation()

# --- Private ---

func _update_valuation() -> void:
	valuation_label.text = "$%d" % PD.valuation
	_update_company_comparison()

func _update_company_comparison() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company:
		company_label.text = "Больше чем у %s!" % current_company
		_flash_company_label()

func _flash_company_label() -> void:
	if _flash_tween:
		_flash_tween.kill()
	company_label.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(2.0)
	_flash_tween.tween_property(company_label, "modulate:a", 0.0, 0.5)
```

- [ ] **Step 2: Create ui_capitalization.tscn**

Scene tree:
```
UiCapitalization (VBoxContainer) [ui_capitalization.gd]
  alignment = ALIGNMENT_CENTER
  └── ValuationLabel (Label) [unique name]
      horizontal_alignment = CENTER
      theme_override_font_sizes/font_size = 32
      text = "$0"
  └── CompanyLabel (Label) [unique name]
      horizontal_alignment = CENTER
```

- [ ] **Step 3: Commit**

```
feat(ui): add UiCapitalization component with company flash
```

---

### Task 5: Create UiSprintPanel

**Files:**
- Create: `components/ui/ui_sprint_panel/ui_sprint_panel.gd`
- Create: `components/ui/ui_sprint_panel/ui_sprint_panel.tscn`

A VBoxContainer with sprint label, sprint timer bar, and the task card container. Owns the card rebuild logic (extracted from `hud.gd`).

- [ ] **Step 1: Create ui_sprint_panel.gd**

```gdscript
class_name UiSprintPanel
extends VBoxContainer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

# --- @onready ---

@onready var sprint_label: Label = %SprintLabel
@onready var sprint_timer_bar: ProgressBar = %SprintTimerBar
@onready var card_container: HBoxContainer = %CardContainer

# --- Lifecycle ---

func _ready() -> void:
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)
	SB.sprint_timer_changed.connect(_on_sprint_timer_changed)
	SB.task_queue_changed.connect(_rebuild_cards)

# --- Handlers ---

func _on_sprint_started(sprint_num: int) -> void:
	sprint_label.text = "Спринт %d" % sprint_num
	sprint_timer_bar.modulate = Color.GREEN

func _on_sprint_ended(sprint_num: int, bonus: int) -> void:
	if bonus > 0:
		sprint_label.text = "Спринт %d завершён! Бонус: $%d" % [sprint_num, bonus]
	else:
		sprint_label.text = "Спринт %d просрочен" % sprint_num

func _on_sprint_timer_changed(remaining: float, total: float) -> void:
	if total <= 0.0:
		return
	var ratio: float = clampf(remaining / total, 0.0, 1.0)
	sprint_timer_bar.value = ratio
	if ratio > 0.5:
		sprint_timer_bar.modulate = Color.GREEN.lerp(Color.YELLOW, 1.0 - (ratio - 0.5) * 2.0)
	else:
		sprint_timer_bar.modulate = Color.YELLOW.lerp(Color.RED, 1.0 - ratio * 2.0)

func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
```

- [ ] **Step 2: Create ui_sprint_panel.tscn**

Scene tree:
```
UiSprintPanel (VBoxContainer) [ui_sprint_panel.gd]
  └── SprintLabel (Label) [unique name]
      text = "Спринт 1"
      horizontal_alignment = CENTER
  └── SprintTimerBar (ProgressBar) [unique name]
      custom_minimum_size = Vector2(400, 20)
      max_value = 1.0
      value = 1.0
      show_percentage = false
  └── CardContainer (HBoxContainer) [unique name]
      alignment = CENTER
      theme_override_constants/separation = 8
```

- [ ] **Step 3: Commit**

```
feat(ui): add UiSprintPanel component with task cards
```

---

### Task 6: Move CeoCommentator to components/ui/

**Files:**
- Create: `components/ui/ui_ceo_commentator/ui_ceo_commentator.gd` (from `components/hud/ceo_commentator.gd`)
- Create: `components/ui/ui_ceo_commentator/ui_ceo_commentator.tscn` (from `components/hud/ceo_commentator.tscn`)

Rename `class_name` from `CeoCommentator` to `UiCeoCommentator`. Logic stays the same.

- [ ] **Step 1: Copy and rename ceo_commentator.gd**

Copy `components/hud/ceo_commentator.gd` to `components/ui/ui_ceo_commentator/ui_ceo_commentator.gd`. Change the class_name:

```gdscript
class_name UiCeoCommentator
extends Control
```

Rest of the script stays identical.

- [ ] **Step 2: Copy and update ceo_commentator.tscn**

Copy `components/hud/ceo_commentator.tscn` to `components/ui/ui_ceo_commentator/ui_ceo_commentator.tscn`. Update:
- Root node name: `UiCeoCommentator`
- Script path: `res://components/ui/ui_ceo_commentator/ui_ceo_commentator.gd`

- [ ] **Step 3: Commit**

```
refactor(ui): move CeoCommentator to components/ui/ as UiCeoCommentator
```

---

### Task 7: Refactor popup scenes — remove self-managed signal subscriptions

**Files:**
- Modify: `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd`
- Modify: `components/ui/ui_hire_choice/ui_hire_choice.gd`
- Modify: `components/ui/ui_game_over/ui_game_over.gd`

These popups currently subscribe to `SB` signals in `_ready()` and manage their own visibility. Since UiHud will now instantiate and show them on demand, they no longer need to self-subscribe. Instead, they expose public methods that UiHud calls.

- [ ] **Step 1: Refactor UiUpgradeChoice**

Replace `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd`:

```gdscript
class_name UiUpgradeChoice
extends CanvasLayer

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Lifecycle ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public ---

func show_for_level(level: int) -> void:
	title_label.text = "Уровень %d — выбери апгрейд" % level
	var upgrades: Array[UpgradeData] = DR.get_level_up_upgrades()
	_build_cards(upgrades)
	visible = true

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.chosen.connect(_on_upgrade_chosen)
		card_container.add_child(card)

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	visible = false
	SB.upgrade_chosen.emit(upgrade)
```

- [ ] **Step 2: Refactor UiHireChoice**

Replace `components/ui/ui_hire_choice/ui_hire_choice.gd`:

```gdscript
class_name UiHireChoice
extends CanvasLayer

const HIRE_CARD: PackedScene = preload("res://components/ui/ui_hire_choice/hire_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Lifecycle ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public ---

func show_hire() -> void:
	title_label.text = "Найми разработчика"
	_build_cards()
	visible = true

# --- Private ---

func _build_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for dev_data: DeveloperData in DR.developers.values():
		var card: HireCard = HIRE_CARD.instantiate()
		card.setup(dev_data)
		card.chosen.connect(_on_dev_chosen)
		card_container.add_child(card)

func _on_dev_chosen(dev_data: DeveloperData) -> void:
	SB.developer_chosen.emit(dev_data.duplicate())
	visible = false
```

- [ ] **Step 3: Refactor UiGameOver**

Replace `components/ui/ui_game_over/ui_game_over.gd`:

```gdscript
class_name UiGameOver
extends CanvasLayer

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var company_label: Label = %CompanyLabel
@onready var restart_button: Button = %RestartButton

# --- Lifecycle ---

func _ready() -> void:
	restart_button.pressed.connect(_on_restart)
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public ---

func show_game_over(final_valuation: int) -> void:
	valuation_label.text = "$%d" % final_valuation
	level_label.text = "Уровень: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	_show_company_comparison(final_valuation)
	visible = true

# --- Private ---

func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if val >= milestone["valuation"]:
			best_company = milestone["name"]
	if best_company:
		company_label.text = "Your startup beat %s! 🚀" % best_company
		company_label.visible = true
	else:
		company_label.text = "Keep grinding..."
		company_label.visible = true

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Commit**

```
refactor(ui): make popup scenes passive — called by UiHud instead of self-subscribing
```

---

### Task 8: Create UiHud

**Files:**
- Create: `components/ui/ui_hud/ui_hud.gd`
- Create: `components/ui/ui_hud/ui_hud.tscn`

The root CanvasLayer that assembles the layout and manages popups. TopBar has XP bar (left), capitalization (center), timer (right). BottomBar has sprint panel. CEO commentator in the bottom-right corner. UiPopupManager as a child for developer popups. HUD listens to signals for fullscreen popups and instantiates them.

- [ ] **Step 1: Create hud_popup_manager.gd**

A minimal script override for the UiPopupManager node inside UiHud. Only job: emit `SB.selection_cleared` when a popup closes.

```gdscript
class_name HudPopupManager
extends UiPopupManager

func _after_popup_closed() -> void:
	SB.selection_cleared.emit()
```

- [ ] **Step 2: Create ui_hud.gd**

```gdscript
class_name UiHud
extends CanvasLayer

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")
const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")

# --- @onready ---

@onready var popup_manager: UiPopupManager = %UiPopupManager

# --- Lifecycle ---

func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.level_up.connect(_on_level_up)
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.game_over.connect(_on_game_over)

# --- Handlers ---

func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Developer:
		var dev: Developer = target as Developer
		if dev.data == null:
			return
		var popup: PopupDeveloper = POPUP_DEVELOPER.instantiate()
		popup.setup(dev)
		popup_manager.show_popup(target, popup, popup_position)

func _on_level_up(level: int) -> void:
	var popup: UiUpgradeChoice = UI_UPGRADE_CHOICE.instantiate()
	add_child(popup)
	popup.show_for_level(level)

func _on_hire_requested() -> void:
	var popup: UiHireChoice = UI_HIRE_CHOICE.instantiate()
	add_child(popup)
	popup.show_hire()

func _on_game_over(final_valuation: int) -> void:
	var popup: UiGameOver = UI_GAME_OVER.instantiate()
	add_child(popup)
	popup.show_game_over(final_valuation)
```

- [ ] **Step 3: Create ui_hud.tscn**

Scene tree:
```
UiHud (CanvasLayer, layer=5) [ui_hud.gd]
  └── MainLayout (VBoxContainer, full-screen with 8px margins, anchors_preset=15)
      └── TopBar (HBoxContainer, separation=8)
          └── UiXpBar (instance of ui_xp_bar.tscn)
              size_flags_horizontal = SIZE_EXPAND_FILL
          └── UiCapitalization (instance of ui_capitalization.tscn)
              size_flags_horizontal = SIZE_EXPAND_FILL
          └── UiGameTimer (instance of ui_game_timer.tscn)
              size_flags_horizontal = SIZE_EXPAND_FILL
      └── BottomBar (HBoxContainer, size_flags_vertical=SIZE_SHRINK_END)
          └── UiSprintPanel (instance of ui_sprint_panel.tscn)
              size_flags_horizontal = SIZE_EXPAND_FILL
  └── UiPopupManager (instance of game_kit ui_popup_manager.tscn) [unique name, script override: hud_popup_manager.gd]
  └── UiCeoCommentator (instance of ui_ceo_commentator.tscn)
      anchors_preset = 3 (bottom-right)
```

Key layout properties:
- `MainLayout`: `anchors_preset=15` (full rect), margins 8px all sides
- `TopBar`: children each get `size_flags_horizontal = SIZE_EXPAND_FILL` so they split evenly into thirds
- `BottomBar`: `size_flags_vertical = SIZE_SHRINK_END` (pins to bottom)
- `UiPopupManager`: `mouse_filter = MOUSE_FILTER_IGNORE`

- [ ] **Step 4: Commit**

```
feat(ui): add UiHud — assembles layout and manages all popups
```

---

### Task 9: Update levels to use UiHud and remove popup nodes

**Files:**
- Modify: `levels/base_level.tscn`
- Modify: `levels/test_level.tscn`

Replace the old HUD instance with the new UiHud. Remove `UiUpgradeChoice`, `UiHireChoice`, `UiGameOver` nodes — they're now instantiated by UiHud on demand.

- [ ] **Step 1: Update base_level.tscn**

In `levels/base_level.tscn`:
- Change the HUD ext_resource path from `res://components/hud/hud.tscn` to `res://components/ui/ui_hud/ui_hud.tscn`
- Remove the `UiUpgradeChoice` node and its ext_resource
- Remove the `UiHireChoice` node and its ext_resource
- Remove the `UiGameOver` node and its ext_resource

- [ ] **Step 2: Update test_level.tscn**

In `levels/test_level.tscn`:
- Change the HUD ext_resource path from `res://components/hud/hud.tscn` to `res://components/ui/ui_hud/ui_hud.tscn`
- Remove the `UiUpgradeChoice` node and its ext_resource
- Remove the `UiHireChoice` node and its ext_resource
- Remove the `UiGameOver` node and its ext_resource

- [ ] **Step 3: Run the game, verify everything works**

Test:
- Game timer counts down in top-right
- Capitalization updates in center when tasks complete
- XP bar fills on left
- Company flash appears and fades below capitalization at milestones
- Sprint panel at bottom shows sprint label, timer bar (color shifts), and task cards
- Drag-and-drop reordering of task cards works
- CEO commentator shows quips in bottom-right
- Developer click popup appears near the developer
- Level-up upgrade choice popup appears
- Hire popup appears at hire levels
- Game over screen shows at timer end

- [ ] **Step 4: Commit**

```
refactor: update levels to use UiHud, remove inline popup nodes
```

---

### Task 10: Delete old components/hud/ directory

**Files:**
- Delete: `components/hud/hud.gd`
- Delete: `components/hud/hud.tscn`
- Delete: `components/hud/popup_manager.gd`
- Delete: `components/hud/ceo_commentator.gd`
- Delete: `components/hud/ceo_commentator.tscn`

- [ ] **Step 1: Verify no remaining references to components/hud/**

Search the entire project for `components/hud` or `res://components/hud` to make sure nothing still references the old paths.

- [ ] **Step 2: Delete the directory**

```bash
rm -rf components/hud/
```

- [ ] **Step 3: Also delete the dead `components/task_queue/task_queue.gd` and `task_queue.tscn` if they exist**

There's a standalone `TaskQueue` CanvasLayer in `components/task_queue/task_queue.gd` that duplicates the card rebuild logic from the old HUD. It's not used in any level. Check if `task_card.gd` and `task_card.tscn` are the only files needed in that directory, and remove the dead `task_queue.*` files.

- [ ] **Step 4: Run the game one final time to verify nothing broke**

- [ ] **Step 5: Commit**

```
chore: delete old components/hud/ and dead TaskQueue files
```
