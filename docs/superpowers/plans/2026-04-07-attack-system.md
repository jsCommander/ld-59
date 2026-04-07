# Attack System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace timer-based produce mechanic with auto-attack system where developers periodically attack the first task in queue.

**Architecture:** Developers contain an internal timer that ticks at `base_attack_speed`. On tick, developer calculates damage and emits `SB.developer_attack`. PlayerData listens, applies damage to first task's HP. When HP <= 0, task is destroyed. Game runs continuously — no sprints.

**Tech Stack:** Godot 4.x, GDScript

**Spec:** `docs/superpowers/specs/2026-04-07-attack-system-design.md`

---

### Task 1: Update DeveloperData — replace speed stats with damage stats

**Files:**
- Modify: `game_data/developer/developer_data.gd:6-8` (replace speed exports)
- Modify: `game_data/developer/developer_data_vibecoder.tres:13-15`
- Modify: `game_data/developer/developer_data_regular.tres:13-15`
- Modify: `game_data/developer/developer_data_senior.tres:13-15`

- [ ] **Step 1: Update DeveloperData script**

Replace `feature_speed`, `bug_speed`, `refactor_speed` with damage stats and add `base_attack_speed`:

```gdscript
# game_data/developer/developer_data.gd
class_name DeveloperData
extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var feature_damage: int = 50
@export var bug_damage: int = 50
@export var refactor_damage: int = 50
@export var tech_debt: int = 30
@export var base_attack_speed: float = 2.0
@export var salary_mult: float = 2.5
@export var upgrades: Array[DeveloperUpgrade] = []
```

- [ ] **Step 2: Update Vibecoder .tres**

In `game_data/developer/developer_data_vibecoder.tres`, replace:
```
feature_speed = 80
bug_speed = 20
refactor_speed = 10
```
with:
```
feature_damage = 80
bug_damage = 20
refactor_damage = 10
base_attack_speed = 2.0
```

- [ ] **Step 3: Update Regular .tres**

In `game_data/developer/developer_data_regular.tres`, replace:
```
feature_speed = 50
bug_speed = 50
refactor_speed = 50
```
with:
```
feature_damage = 50
bug_damage = 50
refactor_damage = 50
base_attack_speed = 2.0
```

- [ ] **Step 4: Update Senior .tres**

In `game_data/developer/developer_data_senior.tres`, replace:
```
feature_speed = 30
bug_speed = 70
refactor_speed = 80
```
with:
```
feature_damage = 30
bug_damage = 70
refactor_damage = 80
base_attack_speed = 2.0
```

- [ ] **Step 5: Commit**

```bash
git add game_data/developer/
git commit -m "feat: replace speed stats with damage stats in DeveloperData"
```

---

### Task 2: Update TaskData — add HP fields

**Files:**
- Modify: `game_data/task/task_data.gd:6` (replace base_time with base_hp)
- Modify: `game_data/task/task_data_feature.tres`
- Modify: `game_data/task/task_data_bug.tres`
- Modify: `game_data/task/task_data_refactor.tres`

- [ ] **Step 1: Update TaskData script**

Replace `base_time` with HP fields:

```gdscript
# game_data/task/task_data.gd
class_name TaskData
extends Resource

@export var task_type: Constants.TaskType = Constants.TaskType.FEATURE
@export var texture: Texture2D
@export var base_hp: float = 100.0
var current_hp: float = 0.0
var max_hp: float = 0.0
```

`current_hp` and `max_hp` are runtime — set when task enters queue. Not exported, not saved in `.tres`.

- [ ] **Step 2: Update .tres files**

In all three `.tres` files, remove `base_time` if present (it's currently using the default 5.0 and not explicitly set in feature/bug .tres). Add `base_hp`:

`task_data_feature.tres` — add line: `base_hp = 100.0`
`task_data_bug.tres` — add line: `base_hp = 80.0`
`task_data_refactor.tres` — add line: `base_hp = 60.0`

- [ ] **Step 3: Commit**

```bash
git add game_data/task/
git commit -m "feat: add HP fields to TaskData, remove base_time"
```

---

### Task 3: Update DeveloperUpgrade — replace speed_bonus with damage_bonus

**Files:**
- Modify: `game_data/upgrade/developer_upgrade.gd:8` (rename field)
- Modify: `game_data/upgrade/developer_upgrade_damage.tres:12`
- Modify: `game_data/upgrade/developer_upgrade_speed.tres:13`

- [ ] **Step 1: Update DeveloperUpgrade script**

Replace `speed_bonus` with `damage_bonus`:

```gdscript
# game_data/upgrade/developer_upgrade.gd
class_name DeveloperUpgrade
extends Resource

@export var upgrade_name: String
@export var base_cost: int = 100
@export var cost_function: CostFunction
@export var max_level: int = 0
@export var damage_bonus: float = 0.0


func get_scaled_cost(level: int) -> int:
	if not cost_function:
		return base_cost
	return cost_function.get_cost(base_cost, level)
```

- [ ] **Step 2: Update .tres files**

In `developer_upgrade_speed.tres`:
- Remove the stale `damage_multiplier = 0.0` line
- Replace `speed_bonus = 0.3` with `damage_bonus = 0.3`

In `developer_upgrade_damage.tres`, replace `speed_bonus = 0.5` with `damage_bonus = 0.5`.

- [ ] **Step 3: Commit**

```bash
git add game_data/upgrade/
git commit -m "feat: replace speed_bonus with damage_bonus in DeveloperUpgrade"
```

---

### Task 4: Update SignalBus — new attack signals, remove sprint signals

**Files:**
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Update SignalBus**

```gdscript
# autoloads/signal_bus.gd
class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_clicked(task: TaskData)

signal developer_attack(developer: Developer, damage: float)
signal task_hp_changed(task: TaskData, hp: float, max_hp: float)
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_money_changed
signal resource_tech_debt_changed
signal valuation_changed
```

Removed: `task_finished`, `game_state_changed`, `sprint_started`, `sprint_ended`.

- [ ] **Step 2: Commit**

```bash
git add autoloads/signal_bus.gd
git commit -m "feat: update SignalBus — add attack signals, remove sprint signals"
```

---

### Task 5: Update Constants — remove GameState and sprint constants

**Files:**
- Modify: `globals/constants.gd`

- [ ] **Step 1: Update Constants**

Remove `GameState` enum and `SPRINT_SIZE`. Keep `BACKLOG_SIZE` (still needed for backlog UI).

```gdscript
# globals/constants.gd
class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }

const BASE: int = 100
const DEBT_PER_TASK: float = 0.6
const TECH_DEBT_PER_HIT: float = 0.01

const PRIORITY_TIERS: Array[Dictionary] = [
	{"max_debt": 30.0, "priority": 1.0},
	{"max_debt": 60.0, "priority": 1.5},
	{"max_debt": 90.0, "priority": 2.0},
]
const MAX_PRIORITY: float = 2.5

const MIN_QUEUE_SIZE: int = 10
const BACKLOG_SIZE: int = 15
const BUG_SPAWN_MULTIPLIER: float = 0.01
const REFACTOR_SPAWN_MULTIPLIER: float = 0.005

enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT }
```

Added `TECH_DEBT_PER_HIT = 0.01` — the small fixed tech debt increase per attack hit.
Removed `GameState` enum, `SPRINT_SIZE`.

- [ ] **Step 2: Commit**

```bash
git add globals/constants.gd
git commit -m "feat: remove GameState enum, add TECH_DEBT_PER_HIT constant"
```

---

### Task 6: Rewrite Developer — auto-attack logic

**Files:**
- Modify: `components/developer/developer.gd` (full rewrite of logic)

- [ ] **Step 1: Rewrite developer.gd**

```gdscript
# components/developer/developer.gd
@tool
class_name Developer
extends Node2D

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var desk_sprite: Sprite2D = %DeskSprite
@onready var dev_sprite: Sprite2D = %DevSprite
@onready var damage_number: DamageNumber = $DamageNumber

var purchased_upgrades: Dictionary = {}
var _attack_timer: float = 0.0


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return
	if PD.task_queue.is_empty():
		_attack_timer = 0.0
		return
	_attack_timer += delta
	if _attack_timer >= data.base_attack_speed:
		_attack_timer -= data.base_attack_speed
		_perform_attack()


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)


func get_damage_for_task(task_type: Constants.TaskType) -> float:
	if not data:
		return 0.0
	var base_damage: int = 0
	match task_type:
		Constants.TaskType.FEATURE: base_damage = data.feature_damage
		Constants.TaskType.BUG: base_damage = data.bug_damage
		Constants.TaskType.REFACTOR: base_damage = data.refactor_damage
	return float(base_damage) * get_damage_multiplier()


func get_damage_multiplier() -> float:
	var mult: float = 1.0
	for upgrade: DeveloperUpgrade in purchased_upgrades:
		mult += upgrade.damage_bonus * purchased_upgrades[upgrade]
	return mult


func get_upgrade_level(upgrade: DeveloperUpgrade) -> int:
	return purchased_upgrades.get(upgrade, 0)


func get_available_upgrades() -> Array[DeveloperUpgrade]:
	if not data:
		return []
	return data.upgrades.filter(
		func(u: DeveloperUpgrade) -> bool:
			return u.max_level == 0 or get_upgrade_level(u) < u.max_level
	)


func apply_upgrade(upgrade: DeveloperUpgrade) -> void:
	purchased_upgrades[upgrade] = get_upgrade_level(upgrade) + 1
	Log.log_info(name, "Upgraded %s to Lv.%d" % [upgrade.upgrade_name, purchased_upgrades[upgrade]])


func _perform_attack() -> void:
	if PD.task_queue.is_empty():
		return
	var first_task: TaskData = PD.task_queue[0]
	var damage: float = get_damage_for_task(first_task.task_type)
	SB.developer_attack.emit(self, damage)
	damage_number.spawn("-%d" % int(damage), Vector2.UP, Color.YELLOW)
	Log.log_debug(name, "Attacked %s for %.1f damage" % [
		Constants.TaskType.keys()[first_task.task_type], damage
	])


func _apply_data() -> void:
	if not is_instance_valid(dev_sprite):
		return

	if data:
		dev_sprite.texture = data.texture
		dev_sprite.visible = true
		if not Engine.is_editor_hint():
			add_to_group("developer")
			if is_in_group("desk"):
				remove_from_group("desk")
	else:
		dev_sprite.visible = false
		if not Engine.is_editor_hint():
			add_to_group("desk")
			if is_in_group("developer"):
				remove_from_group("developer")
```

Removed: `produce_trait`, `progress_bar`, `task_icon`, `current_task`, `is_idle()`, `_try_grab_task()`, `_on_work_done()`, `_show_completion()`, `_update_task_icon()`, `get_speed_for_task()`, `get_work_time()`, `get_speed_multiplier()`, `_on_task_queue_changed()`.

Added: `_attack_timer`, `_process()` with attack tick, `_perform_attack()`, `get_damage_for_task()`, `get_damage_multiplier()`.

- [ ] **Step 2: Update developer.tscn — remove ProduceTrait and ProduceProgressBar nodes**

Remove these nodes from `components/developer/developer.tscn`:
- `ProduceTrait` node (line 47-49)
- `ProduceProgressBar` node (line 51-55)
- `TaskIcon` node (line 34-45)
- Remove ext_resource references for ProduceProgressBar (id="4") and produce_trait script (id="5")

- [ ] **Step 3: Commit**

```bash
git add components/developer/
git commit -m "feat: rewrite Developer with auto-attack logic"
```

---

### Task 7: Update PopupDeveloper — use damage stats

**Files:**
- Modify: `components/developer/ui/popup_developer.gd:25-32`

- [ ] **Step 1: Update _update_stats()**

Replace speed references with damage stats:

```gdscript
func _update_stats() -> void:
	var dmg_mult: float = _developer.get_damage_multiplier()
	stats_label.text = "Фичи: %d  Баги: %d  Рефактор: %d" % [
		_developer.data.feature_damage,
		_developer.data.bug_damage,
		_developer.data.refactor_damage,
	]
	task_label.text = "Урон: x%.1f" % dmg_mult
```

- [ ] **Step 2: Commit**

```bash
git add components/developer/ui/popup_developer.gd
git commit -m "feat: update PopupDeveloper to show damage stats"
```

---

### Task 8: Rewrite PlayerData — continuous gameplay, attack damage handling

> Note: `DeveloperData.tech_debt` stat is intentionally kept but unused in this iteration. Per-hit tech debt uses flat `TECH_DEBT_PER_HIT` constant. The `tech_debt` stat may be used later for per-developer scaling.

**Files:**
- Modify: `autoloads/player_data.gd` (replace sprint logic with attack handling)

- [ ] **Step 1: Rewrite player_data.gd**

```gdscript
# autoloads/player_data.gd
class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

var money: int = 0
var tech_debt: float = 0.0
var valuation: int = 0
var task_queue: Array[TaskData] = []
var backlog: Array[TaskData] = []
var developers: Array[Developer] = []


func _ready() -> void:
	SB.developer_attack.connect(_on_developer_attack)
	fill_backlog()


func fill_backlog() -> void:
	while backlog.size() < Constants.BACKLOG_SIZE:
		var bug_chance: float = tech_debt * Constants.BUG_SPAWN_MULTIPLIER
		var refactor_chance: float = tech_debt * Constants.REFACTOR_SPAWN_MULTIPLIER
		var roll: float = randf()
		if roll < bug_chance:
			backlog.append(TASK_DATA_BUG.duplicate())
		elif roll < bug_chance + refactor_chance:
			backlog.append(TASK_DATA_REFACTOR.duplicate())
		else:
			backlog.append(TASK_DATA_FEATURE.duplicate())


func add_tasks_to_queue(tasks: Array[TaskData]) -> void:
	for task: TaskData in tasks:
		backlog.erase(task)
		task.current_hp = task.base_hp
		task.max_hp = task.base_hp
		task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)
	fill_backlog()
	Log.log_info(name, "Added %d tasks to queue (total: %d)" % [tasks.size(), task_queue.size()])


func _on_developer_attack(_developer: Developer, damage: float) -> void:
	if task_queue.is_empty():
		return
	var task: TaskData = task_queue[0]
	task.current_hp -= damage
	increase_tech_debt(Constants.TECH_DEBT_PER_HIT)
	SB.task_hp_changed.emit(task, task.current_hp, task.max_hp)
	if task.current_hp <= 0.0:
		task_queue.pop_front()
		_on_task_destroyed(task)


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	SB.task_destroyed.emit(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])


func _apply_task_rewards(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			var earned: int = Constants.BASE
			earn(earned)
			valuation += earned
			SB.valuation_changed.emit()
			Log.log_info(name, "Feature done: +$%d, valuation=%d" % [earned, valuation])
		Constants.TaskType.BUG:
			Log.log_info(name, "Bug fixed")
		Constants.TaskType.REFACTOR:
			var debt_reduction: float = Constants.DEBT_PER_TASK
			increase_tech_debt(-debt_reduction)
			Log.log_info(name, "Refactor done: -%.1f debt" % debt_reduction)


func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)
	Log.log_info(name, "Fired %s" % Constants.DevType.keys()[developer.data.dev_type])


func can_afford(amount: int) -> bool:
	return money >= amount


func earn(amount: int) -> void:
	money += amount
	SB.resource_money_changed.emit()


func spend(amount: int) -> void:
	money = maxi(0, money - amount)
	SB.resource_money_changed.emit()


func increase_tech_debt(delta: float) -> void:
	tech_debt = clampf(tech_debt + delta, 0.0, 100.0)
	SB.resource_tech_debt_changed.emit()


func get_bug_priority() -> float:
	for tier: Dictionary in Constants.PRIORITY_TIERS:
		if tech_debt < tier["max_debt"]:
			return tier["priority"]
	return Constants.MAX_PRIORITY
```

Removed: `game_state`, `_elapsed`, `_process()`, `get_time_scale()`, `start_sprint()`, `end_sprint()`, `_check_sprint_complete()`, `_on_task_finished()`, `_apply_tech_debt()`.

Added: `add_tasks_to_queue()`, `_on_developer_attack()`, `_on_task_destroyed()`.

Changed: `_apply_task_rewards()` no longer needs developer reference. Refactor now reduces debt by `DEBT_PER_TASK` (flat amount, not based on developer stat).

- [ ] **Step 2: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat: rewrite PlayerData — continuous gameplay, attack damage handling"
```

---

### Task 9: Update SprintPlanning — backlog UI with add-to-queue

**Files:**
- Modify: `components/sprint_planning/sprint_planning.gd`

- [ ] **Step 1: Rewrite sprint_planning.gd**

The UI now opens/closes via a button press (not game state). "Start Sprint" button becomes "Add to Queue" button. No more sprint concept.

```gdscript
# components/sprint_planning/sprint_planning.gd
class_name SprintPlanning
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var backlog_grid: GridContainer = %BacklogGrid
@onready var sprint_grid: GridContainer = %SprintGrid
@onready var sprint_label: Label = %SprintLabel
@onready var start_button: Button = %StartButton

var selected_tasks: Array[TaskData] = []


func _ready() -> void:
	start_button.pressed.connect(_on_add_pressed)
	visible = false


func open() -> void:
	selected_tasks.clear()
	visible = true
	_rebuild_grids()


func close() -> void:
	visible = false


func _on_add_pressed() -> void:
	if selected_tasks.is_empty():
		return
	PD.add_tasks_to_queue(selected_tasks)
	selected_tasks.clear()
	_rebuild_grids()


func _move_to_selected(task: TaskData) -> void:
	PD.backlog.erase(task)
	selected_tasks.append(task)
	SB.task_clicked.emit(task)
	_rebuild_grids()


func _move_to_backlog(task: TaskData) -> void:
	selected_tasks.erase(task)
	PD.backlog.append(task)
	_rebuild_grids()


func _rebuild_grids() -> void:
	_clear_grid(backlog_grid)
	_clear_grid(sprint_grid)

	for task: TaskData in PD.backlog:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_backlog_card_input.bind(task))
		backlog_grid.add_child(card)

	for i: int in range(PD.backlog.size(), Constants.BACKLOG_SIZE):
		backlog_grid.add_child(_make_empty_slot())

	for task: TaskData in selected_tasks:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_selected_card_input.bind(task))
		sprint_grid.add_child(card)

	sprint_label.text = "Очередь (%d)" % selected_tasks.size()
	start_button.disabled = selected_tasks.is_empty()
	start_button.text = "Добавить в очередь"


func _on_backlog_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_to_selected(task)


func _on_selected_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_to_backlog(task)


func _make_card(task: TaskData) -> TaskCard:
	var card: TaskCard = TASK_CARD.instantiate()
	card.setup(task)
	card.draggable = false
	return card


func _make_empty_slot() -> PanelContainer:
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.modulate = Color(1, 1, 1, 0.3)
	return slot


func _clear_grid(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		child.queue_free()
```

Removed: `game_state_changed` connection, `_on_game_state_changed()`, `SPRINT_SIZE` limit.
Changed: `sprint_tasks` → `selected_tasks`, `_on_start_pressed` → `_on_add_pressed` (calls `PD.add_tasks_to_queue`), starts hidden.

- [ ] **Step 2: Commit**

```bash
git add components/sprint_planning/
git commit -m "feat: convert SprintPlanning to backlog UI with add-to-queue"
```

---

### Task 10: Update HUD — always visible, remove game state dependency

**Files:**
- Modify: `components/hud/hud.gd`

- [ ] **Step 1: Update hud.gd**

Remove `game_state_changed` connection. HUD is always visible.

```gdscript
# components/hud/hud.gd
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var valuation_label: Label = %ValuationLabel
@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var main_layout: VBoxContainer = %MainLayout


func _ready() -> void:
	SB.resource_money_changed.connect(_update_money)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.task_queue_changed.connect(_rebuild_cards)
	_update_money()
	_update_tech_debt()
	_update_valuation()
	main_layout.visible = true


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	valuation_label.text = "Оценка: $%d" % PD.valuation


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for task: TaskData in queue:
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(task)
		card_container.add_child(card)
```

- [ ] **Step 2: Commit**

```bash
git add components/hud/hud.gd
git commit -m "feat: HUD always visible, remove game state dependency"
```

---

### Task 11: Update AudioManager — replace task_finished with task_destroyed

**Files:**
- Modify: `autoloads/audio_manager.gd:25,32-33`

- [ ] **Step 1: Update audio_manager.gd**

Replace `task_finished` connection with `task_destroyed`:

In `_connect_signals()`, replace:
```gdscript
SB.task_finished.connect(_on_task_finished)
```
with:
```gdscript
SB.task_destroyed.connect(_on_task_destroyed)
```

Replace the handler:
```gdscript
func _on_task_destroyed(_task: TaskData) -> void:
	play_sfx(Constants.Sfx.HIT_HURT, 0.3)
```

- [ ] **Step 2: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat: AudioManager listens to task_destroyed instead of task_finished"
```

---

### Task 12: Clean up — remove ProduceTrait and ProduceProgressBar

**Files:**
- Delete: `components/traits/produce_trait.gd`
- Delete: `components/traits/produce_progress_bar.gd`
- Check: `components/traits/produce_progress_bar.tscn` (delete if exists)

- [ ] **Step 1: Check for .tscn files**

```bash
ls components/traits/*.tscn
```

- [ ] **Step 2: Delete ProduceTrait and ProduceProgressBar files**

Delete `components/traits/produce_trait.gd`, `components/traits/produce_progress_bar.gd`, and any related `.tscn` files.

- [ ] **Step 3: Verify no remaining references**

```bash
grep -r "ProduceTrait\|ProduceProgressBar\|produce_trait\|produce_progress_bar" --include="*.gd" --include="*.tscn" --include="*.tres" .
```

Should return no results. If it does, fix the remaining references.

- [ ] **Step 4: Commit**

```bash
git add -A components/traits/
git commit -m "chore: remove ProduceTrait and ProduceProgressBar"
```

---

### Task 13: Add backlog button to HUD

**Files:**
- Modify: `components/hud/hud.gd` (add button + connect to SprintPlanning)

- [ ] **Step 1: Add backlog button to HUD**

The HUD needs a button at the bottom of the screen that opens SprintPlanning. Add to `hud.gd`:

```gdscript
@onready var backlog_button: Button = %BacklogButton
```

In `_ready()`, add:
```gdscript
backlog_button.pressed.connect(_on_backlog_pressed)
```

Add handler:
```gdscript
func _on_backlog_pressed() -> void:
	var planning: SprintPlanning = get_tree().get_first_node_in_group("sprint_planning")
	if planning:
		if planning.visible:
			planning.close()
		else:
			planning.open()
```

SprintPlanning needs to be in group `"sprint_planning"`. Add to `sprint_planning.gd` in `_ready()`:
```gdscript
add_to_group("sprint_planning")
```

The `BacklogButton` node needs to be added to the HUD scene (`.tscn`) manually — a `Button` with `unique_name_in_owner = true`, text "Бэклог", anchored to bottom center.

- [ ] **Step 2: Commit**

```bash
git add components/hud/ components/sprint_planning/
git commit -m "feat: add backlog button to HUD, connect to SprintPlanning"
```

---

### Task 14: Smoke test — run the game and verify

- [ ] **Step 1: Open project in Godot editor**

Run the game. Verify:
1. HUD is visible immediately (no planning screen blocking)
2. Backlog button at bottom opens the sprint planning UI
3. Selecting tasks and clicking "Добавить в очередь" adds them to queue
4. Tasks appear in HUD card container
5. Developers auto-attack the first task (damage numbers appear)
6. Tasks get destroyed when HP reaches 0
7. Money increases on feature completion
8. Tech debt increases slightly on each hit
9. No errors in Godot console

- [ ] **Step 2: Fix any issues found**

- [ ] **Step 3: Final commit if needed**

```bash
git add -A
git commit -m "fix: smoke test fixes for attack system"
```
