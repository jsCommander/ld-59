# Meme Viral Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the game from a backlog-clicker into a sprint-based meme simulator for programmers with click-boost, burnout, and YouTube mechanics.

**Architecture:** Phased transformation — each task builds on the previous, game stays playable after each task. Core changes: sprint cycle replaces backlog, 3 task types replace 2, developer gets new states (boost/burnout/YouTube), HUD rebuilt, upgrades rebalanced.

**Tech Stack:** Godot 4.6, GDScript, Resource-based data (.tres)

---

## File Structure

### Modified Files
- `globals/constants.gd` — new enums, new constants, remove old ones
- `globals/balance.gd` — new formulas for sprint scaling, boost, remove debt/backlog
- `autoloads/signal_bus.gd` — new sprint signals, remove backlog/debt signals
- `autoloads/player_data.gd` — sprint cycle replaces backlog, remove tech debt/auto-click
- `autoloads/data_registry.gd` — new upgrade pool logic for 3 categories
- `game_data/task/task_data.gd` — replace hp_mult/reward_mult with difficulty
- `game_data/developer/developer_data.gd` — replace feature/bug mults with per-type mults, remove debt
- `game_data/task_select_function.gd` — adapt to 3 task types (already works via Balance.get_task_mult)
- `components/developer/developer.gd` — boost/burnout/YouTube states, remove progress bar
- `components/developer/task_display.gd` — add white flash on hit
- `components/hud/hud.gd` — completely new layout
- `components/ui/ui_game_over/ui_game_over.gd` — add company comparison, share button
- `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd` — minor: uses new DR method name
- `levels/test_level.gd` — remove backlog references

### New Files
- `game_data/task/task_data_refactor.tres` — Refactor task resource
- `components/hud/ceo_commentator.gd` — CEO silhouette with speech bubble
- `components/hud/ceo_commentator.tscn` — CEO scene
- `components/hud/sprint_timer_bar.gd` — sprint timer with green→red color
- `components/hud/sprint_timer_bar.tscn` — sprint timer scene

### Deleted Files (contents moved or no longer needed)
- `game_data/upgrades/global_debt_07x.tres` — tech debt upgrade
- `game_data/upgrades/vibecoder_debt_05x.tres` — tech debt upgrade
- `game_data/upgrades/senior_debt_0x.tres` — tech debt upgrade
- `game_data/upgrades/unlock_auto_click.tres` — auto-click upgrade
- `game_data/upgrades/auto_click_count_2x.tres` — auto-click upgrade
- `game_data/upgrades/auto_click_speed_15x.tres` — auto-click upgrade

### Modified .tres Files
- `game_data/task/task_data_feature.tres` — remove base_hp_mult/base_reward_mult, add difficulty
- `game_data/task/task_data_bug.tres` — remove base_hp_mult/base_reward_mult/base_debt_reduction, add difficulty
- `game_data/developer/developer_data_vibecoder.tres` — new mults
- `game_data/developer/developer_data_regular.tres` — new mults
- `game_data/developer/developer_data_senior.tres` — new mults
- All remaining upgrade .tres files — remove debt-related stats, rebalance

---

## Task 1: Constants & Enums Cleanup

**Files:**
- Modify: `globals/constants.gd`

This is the foundation — all other tasks depend on these enums and constants.

- [ ] **Step 1: Update TaskType enum to add REFACTOR**

In `globals/constants.gd`, replace line 6:

```gdscript
enum TaskType { FEATURE, BUG }
```

with:

```gdscript
enum TaskType { FEATURE, BUG, REFACTOR }
```

- [ ] **Step 2: Update UpgradeType enum — remove UNLOCK, add SPRINT**

Replace line 9:

```gdscript
enum UpgradeType { GLOBAL, DEV, UNLOCK }
```

with:

```gdscript
enum UpgradeType { GLOBAL, DEV, SPRINT }
```

- [ ] **Step 3: Update UpgradeStat enum — remove debt/auto-click, add sprint stats**

Replace line 10:

```gdscript
enum UpgradeStat { DAMAGE, SPEED, DEBT, AUTO_CLICK, AUTO_CLICK_COUNT, AUTO_CLICK_SPEED }
```

with:

```gdscript
enum UpgradeStat { DAMAGE, SPEED, SPRINT_DURATION, SPRINT_TASK_COMPOSITION }
```

- [ ] **Step 4: Update constants — new values, remove old ones**

Replace lines 12-24:

```gdscript
const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const BASE_DEBT_PER_TASK: float = 1.0
const XP_BASE: int = int(BASE_HP * 0.3)
const BASE_CLICKS_PER_TASK: int = 1
const BASE_AUTO_CLICK_INTERVAL: float = 2.0
const BASE_AUTO_CLICK_COUNT: int = 1

const GAME_DURATION: float = 900.0
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const BASE_QUEUE_SIZE: int = 10
const BUG_SPAWN_MULTIPLIER: float = 0.008
```

with:

```gdscript
const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const XP_BASE: int = int(BASE_HP * 0.3)

const GAME_DURATION: float = 600.0
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const MAX_SPRINT_TASKS: int = 8
const SPRINT_DURATION: float = 60.0

const BASE_ATTACK_SPEED: float = 0.5
const MAX_BOOST: int = 10
const BOOST_DECAY_RATE: float = 1.0
const BOOST_SPEED_MULT: float = 0.05
const BURNOUT_DURATION: float = 5.0
const YOUTUBE_CHANCE: float = 0.1
```

- [ ] **Step 5: Verify the file compiles**

Open the project in Godot or run a syntax check. There will be compilation errors in other files referencing removed constants — that's expected, we fix them in subsequent tasks.

- [ ] **Step 6: Commit**

```bash
git add globals/constants.gd
git commit -m "refactor: update constants for sprint-based redesign"
```

---

## Task 2: Task Data Redesign

**Files:**
- Modify: `game_data/task/task_data.gd`
- Modify: `game_data/task/task_data_feature.tres` (in Godot editor or text editor)
- Modify: `game_data/task/task_data_bug.tres` (in Godot editor or text editor)
- Create: `game_data/task/task_data_refactor.tres`

- [ ] **Step 1: Rewrite TaskData resource class**

Replace the entire contents of `game_data/task/task_data.gd`:

```gdscript
class_name TaskData
extends Resource

@export var task_type: Constants.TaskType = Constants.TaskType.FEATURE
@export var texture: Texture2D
@export var difficulty: int = 1
var current_hp: float = 0.0
var max_hp: float = 0.0
```

Removed: `base_hp_mult`, `base_reward_mult`, `base_debt_reduction`. Added: `difficulty` (int, HP multiplier).

- [ ] **Step 2: Update task_data_feature.tres**

Open `game_data/task/task_data_feature.tres` in text editor. Update to remove old fields and set:
- `task_type = 0` (FEATURE)
- `difficulty = 1`
- Keep existing `texture`

The `.tres` file should have these resource properties:
```
task_type = 0
difficulty = 1
texture = <keep existing>
```

Remove any lines with `base_hp_mult`, `base_reward_mult`, `base_debt_reduction`.

- [ ] **Step 3: Update task_data_bug.tres**

Same as above:
- `task_type = 1` (BUG)
- `difficulty = 1`
- Keep existing `texture`

Remove `base_hp_mult`, `base_reward_mult`, `base_debt_reduction`.

- [ ] **Step 4: Create task_data_refactor.tres**

Duplicate `task_data_feature.tres` and modify:
- `task_type = 2` (REFACTOR)
- `difficulty = 1`
- `texture` — use a placeholder texture for now (can reuse bug texture or feature texture temporarily)

Create the file at `game_data/task/task_data_refactor.tres`. Easiest: duplicate in Godot editor, change `task_type` to 2.

- [ ] **Step 5: Commit**

```bash
git add game_data/task/
git commit -m "refactor: redesign TaskData with difficulty, add Refactor type"
```

---

## Task 3: Developer Data Redesign

**Files:**
- Modify: `game_data/developer/developer_data.gd`
- Modify: `game_data/developer/developer_data_vibecoder.tres`
- Modify: `game_data/developer/developer_data_regular.tres`
- Modify: `game_data/developer/developer_data_senior.tres`

- [ ] **Step 1: Rewrite DeveloperData resource class**

Replace the entire contents of `game_data/developer/developer_data.gd`:

```gdscript
class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var task_mults: Dictionary[Constants.TaskType, float] = {}
@export var base_attack_speed: float = Constants.BASE_ATTACK_SPEED
@export var task_select: TaskSelectFunction
```

Removed: `base_feature_mult`, `base_bug_mult`, `base_debt_mult`. Added: `task_mults` dictionary mapping TaskType to float multiplier. Changed: `base_attack_speed` default from 2.0 to `Constants.BASE_ATTACK_SPEED` (0.5s).

- [ ] **Step 2: Update developer_data_vibecoder.tres**

Set `task_mults`:
```
{FEATURE: 1.6, BUG: 0.4, REFACTOR: 0.4}
```
Set `base_attack_speed = 0.5`.

Remove lines for `base_feature_mult`, `base_bug_mult`, `base_debt_mult`.

- [ ] **Step 3: Update developer_data_regular.tres**

Set `task_mults`:
```
{FEATURE: 1.0, BUG: 1.0, REFACTOR: 1.0}
```
Set `base_attack_speed = 0.5`.

- [ ] **Step 4: Update developer_data_senior.tres**

Set `task_mults`:
```
{FEATURE: 0.4, BUG: 1.6, REFACTOR: 1.6}
```
Set `base_attack_speed = 0.5`.

- [ ] **Step 5: Commit**

```bash
git add game_data/developer/
git commit -m "refactor: redesign DeveloperData with task_mults dictionary"
```

---

## Task 4: Balance Module Rewrite

**Files:**
- Modify: `globals/balance.gd`

- [ ] **Step 1: Rewrite balance.gd**

Replace the entire contents of `globals/balance.gd`:

```gdscript
class_name Balance


static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var damage_mult: float = _calc_mult(Constants.UpgradeStat.DAMAGE, global_upgrades, dev_upgrades)
	return base * task_mult * damage_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData], boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var speed_mult: float = _calc_mult(Constants.UpgradeStat.SPEED, global_upgrades, dev_upgrades)
	var boost_mult: float = 1.0 + boost_stacks * Constants.BOOST_SPEED_MULT
	return base / (speed_mult * boost_mult)


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func scale_task_hp(difficulty: int, sprint_number: int) -> float:
	var sprint_mult: float = 1.0 + sprint_number * 0.3
	return Constants.BASE_HP * difficulty * sprint_mult


static func get_xp_for_level(level: int) -> int:
	return Constants.XP_BASE * int(pow(1.5, level - 1))


static func get_sprint_duration(global_upgrades: Array[UpgradeData]) -> float:
	var mult: float = _calc_mult(Constants.UpgradeStat.SPRINT_DURATION, global_upgrades, [])
	return Constants.SPRINT_DURATION * mult


static func _calc_mult(stat: Constants.UpgradeStat, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0
	for upgrade: UpgradeData in global_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	for upgrade: UpgradeData in dev_upgrades:
		if upgrade.stat == stat:
			mult *= upgrade.multiplier
	return mult
```

Key changes:
- `calculate_attack_speed` now accepts `boost_stacks` parameter and factors in boost multiplier
- `get_task_mult` reads from `dev_data.task_mults` dictionary instead of `base_feature_mult`/`base_bug_mult`
- `scale_task_hp` takes `difficulty` and `sprint_number` instead of `base_hp_mult` and `minutes_elapsed`
- `get_sprint_duration` added for sprint duration upgrades
- Removed: `calculate_debt`, `get_clicks_needed`

- [ ] **Step 2: Commit**

```bash
git add globals/balance.gd
git commit -m "refactor: rewrite Balance for sprint system, boost, 3 task types"
```

---

## Task 5: Signal Bus Cleanup

**Files:**
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Rewrite signal_bus.gd**

Replace the entire contents of `autoloads/signal_bus.gd`:

```gdscript
class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal valuation_changed

signal sprint_started(sprint_number: int)
signal sprint_ended(sprint_number: int, bonus: int)
signal sprint_timer_changed(remaining: float, total: float)

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
```

Removed signals: `resource_tech_debt_changed`, `backlog_clicked`, `backlog_task_spawned`, `tech_debt_produced`.

Added signals: `sprint_started`, `sprint_ended`, `sprint_timer_changed`.

- [ ] **Step 2: Commit**

```bash
git add autoloads/signal_bus.gd
git commit -m "refactor: update SignalBus for sprint system, remove backlog/debt signals"
```

---

## Task 6: PlayerData — Sprint System

**Files:**
- Modify: `autoloads/player_data.gd`

This is the biggest single change. PlayerData becomes the sprint orchestrator.

- [ ] **Step 1: Rewrite player_data.gd**

Replace the entire contents of `autoloads/player_data.gd`:

```gdscript
class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

var valuation: int = 0
var level: int = 0
var timer_remaining: float = Constants.GAME_DURATION
var _game_active: bool = false
var _awaiting_choice: bool = false

# Sprint state
var sprint_number: int = 0
var sprint_timer: float = 0.0
var sprint_duration: float = Constants.SPRINT_DURATION
var sprint_tasks_total: int = 0
var _sprint_active: bool = false

var task_queue: Array[TaskData] = []
var developers: Array[Developer] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
var _empty_upgrades: Array[UpgradeData] = []

var _tick_timer: Timer


func get_dev_upgrades(dev_type: Constants.DevType) -> Array[UpgradeData]:
	if dev_type in dev_upgrades:
		return dev_upgrades[dev_type] as Array[UpgradeData]
	return _empty_upgrades


func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.task_destroyed.connect(_on_task_destroyed)
	_tick_timer = _create_tick_timer()


func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


func start_game() -> void:
	reset()
	_game_active = true
	_tick_timer.start()
	_start_sprint()


func reset() -> void:
	valuation = 0
	level = 0
	timer_remaining = Constants.GAME_DURATION
	_game_active = false
	_awaiting_choice = false
	sprint_number = 0
	sprint_timer = 0.0
	_sprint_active = false
	task_queue.clear()
	developers.clear()
	upgrades_taken.clear()
	global_upgrades.clear()
	dev_upgrades.clear()
	_tick_timer.stop()


func _on_tick() -> void:
	SB.game_timer_changed.emit(timer_remaining)


func _process(delta: float) -> void:
	if not _game_active or _awaiting_choice:
		return

	# Game timer
	timer_remaining -= delta
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		_sprint_active = false
		_tick_timer.stop()
		get_tree().paused = true
		SB.game_over.emit(valuation)
		return

	# Sprint timer
	if _sprint_active:
		sprint_timer -= delta
		SB.sprint_timer_changed.emit(sprint_timer, sprint_duration)


# --- Sprint system ---

func _start_sprint() -> void:
	sprint_number += 1
	sprint_duration = Balance.get_sprint_duration(global_upgrades)
	sprint_timer = sprint_duration
	_sprint_active = true
	_generate_sprint_tasks()
	SB.sprint_started.emit(sprint_number)
	Log.log_info(name, "Sprint %d started with %d tasks" % [sprint_number, task_queue.size()])


func _generate_sprint_tasks() -> void:
	var task_templates: Array[TaskData] = [TASK_DATA_FEATURE, TASK_DATA_BUG, TASK_DATA_REFACTOR]
	var difficulties: Array[int] = [1, 1, 2, 2, 3]
	for i: int in Constants.MAX_SPRINT_TASKS:
		var template: TaskData = task_templates[randi() % task_templates.size()]
		var task: TaskData = template.duplicate()
		task.difficulty = difficulties[randi() % difficulties.size()]
		_scale_task_hp(task)
		task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)


func _scale_task_hp(task: TaskData) -> void:
	var hp: float = Balance.scale_task_hp(task.difficulty, sprint_number)
	task.current_hp = hp
	task.max_hp = hp


func _check_sprint_complete() -> void:
	if not task_queue.is_empty():
		return
	# Check no dev is still working on a task
	for dev: Developer in developers:
		if dev._current_task:
			return
	_end_sprint()


func _end_sprint() -> void:
	var bonus: int = 0
	if sprint_timer > 0.0:
		var speed_ratio: float = sprint_timer / sprint_duration
		bonus = int(100.0 * sprint_number * speed_ratio)
		valuation += bonus
		SB.valuation_changed.emit()
	_sprint_active = false
	SB.sprint_ended.emit(sprint_number, bonus)
	Log.log_info(name, "Sprint %d ended. Bonus: %d" % [sprint_number, bonus])
	_check_level_up()
	if _game_active and not _awaiting_choice:
		_start_sprint()


# --- Upgrade application ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_hire_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.SPRINT:
		global_upgrades.append(upgrade)
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


func _check_hire_level() -> void:
	if level in Constants.HIRE_LEVELS:
		_awaiting_choice = true
		SB.developer_hire_requested.emit()
	else:
		_resume_after_choice()


# --- Level-up ---

func _check_level_up() -> void:
	if valuation >= get_xp_for_level(level + 1):
		level += 1
		_awaiting_choice = true
		get_tree().paused = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
	else:
		_resume_after_choice()


func _resume_after_choice() -> void:
	get_tree().paused = false
	if _game_active and not _sprint_active:
		_start_sprint()


func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)


# --- Task management ---

func take_task(task: TaskData) -> TaskData:
	if task not in task_queue:
		return null
	task_queue.erase(task)
	SB.task_queue_changed.emit(task_queue)
	return task


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s (difficulty %d)" % [Constants.TaskType.keys()[task.task_type], task.difficulty])
	_check_sprint_complete()


func _apply_task_rewards(task: TaskData) -> void:
	var reward: int = int(task.max_hp)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		_check_level_up()


# --- Developers ---

func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])
	_awaiting_choice = false
	_check_level_up()


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)
```

Key changes:
- Sprint cycle: `_start_sprint()` → generates tasks → devs work → `_check_sprint_complete()` → `_end_sprint()` → bonus → next sprint
- `_generate_sprint_tasks()` creates `MAX_SPRINT_TASKS` with random types and difficulties
- Sprint bonus proportional to remaining time
- Removed: backlog clicking, tech debt, auto-click — entire sections gone
- `_apply_task_rewards` simplified: reward = `task.max_hp` (no more reward_mult or debt_reduction)
- Sprint timer ticks every frame in `_process`, emits `sprint_timer_changed`

- [ ] **Step 2: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat: replace backlog with sprint cycle system"
```

---

## Task 7: Developer — Boost, Burnout, YouTube States

**Files:**
- Modify: `components/developer/developer.gd`

- [ ] **Step 1: Rewrite developer.gd with new states**

Replace the entire contents of `components/developer/developer.gd`:

```gdscript
@tool
class_name Developer
extends Node2D

enum State { IDLE, WORKING, YOUTUBE, BURNOUT }

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var desk_sprite: Sprite2D = %DeskSprite
@onready var dev_sprite: Sprite2D = %DevSprite
@onready var damage_number: DamageNumber = $DamageNumber
@onready var task_display: TaskDisplay = %TaskDisplay

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _idle_tween: Tween = null
var _current_task: TaskData = null

# Boost system
var _boost_stacks: int = 0
var _boost_decay_timer: float = 0.0

# Burnout
var _burnout_timer: float = 0.0


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	match _state:
		State.IDLE:
			_process_idle()
		State.WORKING:
			_process_working(delta)
		State.YOUTUBE:
			_process_youtube()
		State.BURNOUT:
			_process_burnout(delta)

	_process_boost_decay(delta)


func _process_idle() -> void:
	_stop_idle_sway()
	_pick_task()


func _process_working(delta: float) -> void:
	if not _current_task:
		_change_state(State.IDLE)
		return
	_start_idle_sway()
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()


func _process_youtube() -> void:
	_stop_idle_sway()
	# Just sits there until player clicks


func _process_burnout(delta: float) -> void:
	_stop_idle_sway()
	_burnout_timer -= delta
	if _burnout_timer <= 0.0:
		_change_state(State.IDLE)
		Log.log_debug(name, "Recovered from burnout")


func _process_boost_decay(delta: float) -> void:
	if _boost_stacks <= 0:
		return
	_boost_decay_timer += delta
	if _boost_decay_timer >= 1.0 / Constants.BOOST_DECAY_RATE:
		_boost_decay_timer -= 1.0 / Constants.BOOST_DECAY_RATE
		_boost_stacks -= 1
		if _boost_stacks <= 0:
			_boost_stacks = 0
			dev_sprite.modulate = Color.WHITE


func _change_state(new_state: State) -> void:
	var old_state: State = _state
	_state = new_state
	Log.log_debug(name, "State: %s → %s" % [State.keys()[old_state], State.keys()[new_state]])

	match new_state:
		State.YOUTUBE:
			task_display.show_youtube()
		State.BURNOUT:
			_burnout_timer = Constants.BURNOUT_DURATION
			_boost_stacks = 0
			dev_sprite.modulate = Color.WHITE
			task_display.show_burnout()
		State.IDLE:
			_attack_timer = 0.0
			task_display.hide_task()


func _pick_task() -> void:
	if PD.task_queue.is_empty():
		return

	# YouTube chance
	if randf() < Constants.YOUTUBE_CHANCE:
		_change_state(State.YOUTUBE)
		return

	var task: TaskData = data.task_select.select(data, PD.task_queue)
	if task:
		_current_task = PD.take_task(task)
		if _current_task:
			task_display.show_task(_current_task)
			_change_state(State.WORKING)


func _perform_attack() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, dev_upgrades)
	_current_task.current_hp -= damage
	show_damage(int(damage))
	task_display.update_hp(_current_task.current_hp, _current_task.max_hp)
	task_display.flash_hit()
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _on_task_killed() -> void:
	SB.task_destroyed.emit(_current_task)
	task_display.hide_task()
	_current_task = null
	_change_state(State.IDLE)


func _get_attack_speed() -> float:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	return Balance.calculate_attack_speed(data, PD.global_upgrades, dev_upgrades, _boost_stacks)


# --- Player interaction ---

func on_clicked() -> void:
	match _state:
		State.YOUTUBE:
			_change_state(State.IDLE)
			Log.log_debug(name, "Snapped out of YouTube")
		State.WORKING, State.IDLE:
			_apply_boost()


func _apply_boost() -> void:
	_boost_stacks += 1
	var heat: float = clampf(float(_boost_stacks) / float(Constants.MAX_BOOST), 0.0, 1.0)
	dev_sprite.modulate = Color.WHITE.lerp(Color(1.5, 0.5, 0.5), heat)
	damage_number.spawn("+BOOST", Vector2.UP, Color.ORANGE_RED)
	if _boost_stacks >= Constants.MAX_BOOST:
		_change_state(State.BURNOUT)
		Log.log_info(name, "Burned out from too much boost!")


# --- Visual ---

func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)


func show_damage(damage: int) -> void:
	damage_number.spawn("-%d" % damage, Vector2.UP, Color.YELLOW)


func _start_idle_sway() -> void:
	if _idle_tween and _idle_tween.is_valid():
		return
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(dev_sprite, "rotation_degrees", 3.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(dev_sprite, "rotation_degrees", -3.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_idle_sway() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
		_idle_tween = null
		dev_sprite.rotation_degrees = 0.0


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

Key changes:
- State machine: `IDLE`, `WORKING`, `YOUTUBE`, `BURNOUT`
- YouTube: random chance when picking task, player click snaps out
- Boost: click adds stack, modulate goes red, exceeding MAX_BOOST → burnout
- Burnout: timer counts down, then self-recovers to IDLE
- Removed: `attack_progress_bar`, tech debt emission
- Added: `on_clicked()` method for player interaction
- `_perform_attack` calls `task_display.flash_hit()` for white flash

- [ ] **Step 2: Wire up click handling in SelectableTrait**

The `SelectableTrait` currently emits `SB.entity_selected` on click (which opens a popup). We need to also call `on_clicked()` on the developer. Read `components/traits/selectable_trait.gd` to see the current click handler, then add a call to the parent Developer's `on_clicked()` method.

In `components/traits/selectable_trait.gd`, find the click handler function (the one that calls `SB.entity_selected.emit(...)`) and add before/after the emit:

```gdscript
var dev: Developer = get_parent() as Developer
if dev:
	dev.on_clicked()
```

This way clicking a dev both opens the popup AND triggers boost/YouTube-snap.

- [ ] **Step 3: Commit**

```bash
git add components/developer/developer.gd components/traits/selectable_trait.gd
git commit -m "feat: add developer states — boost, burnout, YouTube procrastination"
```

---

## Task 8: Task Display — Flash, YouTube, Burnout Icons

**Files:**
- Modify: `components/developer/task_display.gd`

- [ ] **Step 1: Rewrite task_display.gd**

Replace the entire contents of `components/developer/task_display.gd`:

```gdscript
class_name TaskDisplay
extends Control

@onready var icon_rect: TextureRect = %IconRect
@onready var hp_bar: ProgressBar = %HpBar

var _flash_tween: Tween = null

# Placeholder textures — replace with actual assets later
const YOUTUBE_ICON: Texture2D = preload("res://assets/icons/youtube.png")
const BURNOUT_ICON: Texture2D = preload("res://assets/icons/burnout.png")


func show_task(task: TaskData) -> void:
	if task.texture:
		icon_rect.texture = task.texture
	hp_bar.value = 1.0
	hp_bar.visible = true
	visible = true


func update_hp(current_hp: float, max_hp: float) -> void:
	if max_hp > 0.0:
		hp_bar.value = current_hp / max_hp


func flash_hit() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	icon_rect.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(icon_rect, "modulate", Color.WHITE, 0.15)


func show_youtube() -> void:
	icon_rect.texture = YOUTUBE_ICON
	hp_bar.visible = false
	visible = true


func show_burnout() -> void:
	icon_rect.texture = BURNOUT_ICON
	hp_bar.visible = false
	visible = true


func hide_task() -> void:
	visible = false
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	icon_rect.modulate = Color.WHITE
```

Key changes:
- `flash_hit()` — white flash on attack using modulate tween
- `show_youtube()` — shows YouTube icon, hides HP bar
- `show_burnout()` — shows fire/burnout icon, hides HP bar
- Preloads icon textures from `assets/icons/`

**Note:** You need to create placeholder icon files at `assets/icons/youtube.png` and `assets/icons/burnout.png`. Use any 32x32 or 64x64 placeholder images for now. These paths can be adjusted if assets live elsewhere.

- [ ] **Step 2: Create placeholder icon assets**

Create the directory `assets/icons/` if it doesn't exist. Add two placeholder PNG files:
- `assets/icons/youtube.png` — red play button or "YT" text
- `assets/icons/burnout.png` — fire emoji or flame icon

These are temporary. Replace with proper art later.

- [ ] **Step 3: Commit**

```bash
git add components/developer/task_display.gd assets/icons/
git commit -m "feat: add task display flash, YouTube and burnout icons"
```

---

## Task 9: Developer Scene — Remove AttackProgressBar

**Files:**
- Modify: `components/developer/developer.tscn` (in Godot editor)

- [ ] **Step 1: Open developer.tscn in Godot editor**

Remove the `AttackProgressBar` node from the scene tree. The script no longer references it (removed in Task 7).

- [ ] **Step 2: Verify the scene runs without errors**

Run the game briefly. Developer should instantiate without crashing.

- [ ] **Step 3: Commit**

```bash
git add components/developer/developer.tscn
git commit -m "refactor: remove AttackProgressBar from developer scene"
```

---

## Task 10: HUD Rewrite

**Files:**
- Modify: `components/hud/hud.gd`
- Create: `components/hud/sprint_timer_bar.gd`
- Create: `components/hud/sprint_timer_bar.tscn`

- [ ] **Step 1: Create sprint_timer_bar.gd**

Create `components/hud/sprint_timer_bar.gd`:

```gdscript
class_name SprintTimerBar
extends ProgressBar


func _ready() -> void:
	SB.sprint_timer_changed.connect(_on_sprint_timer_changed)
	SB.sprint_ended.connect(_on_sprint_ended)
	min_value = 0.0
	max_value = 1.0
	value = 1.0


func _on_sprint_timer_changed(remaining: float, total: float) -> void:
	if total <= 0.0:
		return
	var ratio: float = clampf(remaining / total, 0.0, 1.0)
	value = ratio
	# Green → Yellow → Red based on ratio
	var color: Color
	if ratio > 0.5:
		color = Color.GREEN.lerp(Color.YELLOW, 1.0 - (ratio - 0.5) * 2.0)
	else:
		color = Color.YELLOW.lerp(Color.RED, 1.0 - ratio * 2.0)
	modulate = color


func _on_sprint_ended(_sprint_number: int, _bonus: int) -> void:
	value = 0.0
	modulate = Color.RED
```

- [ ] **Step 2: Create sprint_timer_bar.tscn**

Create `components/hud/sprint_timer_bar.tscn` in Godot editor:
- Root node: `SprintTimerBar` (ProgressBar) with script `sprint_timer_bar.gd`
- Set custom minimum size to something like (400, 20)
- Position at bottom of screen

- [ ] **Step 3: Rewrite hud.gd**

Replace the entire contents of `components/hud/hud.gd`:

```gdscript
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var timer_label: Label = %TimerLabel
@onready var valuation_label: Label = %ValuationLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var sprint_label: Label = %SprintLabel
@onready var company_label: Label = %CompanyLabel

const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 50, "name": "Zynga"},
	{"valuation": 200, "name": "Nianticе"},
	{"valuation": 500, "name": "Ubisoft"},
	{"valuation": 1500, "name": "EA"},
	{"valuation": 5000, "name": "Valve"},
	{"valuation": 15000, "name": "Epic Games"},
	{"valuation": 50000, "name": "Apple"},
]


func _ready() -> void:
	SB.game_timer_changed.connect(_update_timer)
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)
	_update_valuation()


func _update_timer(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_valuation() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	valuation_label.text = "$%d" % PD.valuation
	xp_bar.value = float(PD.valuation) / float(next_xp)
	_update_company_comparison()


func _update_company_comparison() -> void:
	var current_company: String = ""
	for milestone: Dictionary in COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company:
		company_label.text = "Больше чем у %s!" % current_company
		company_label.visible = true
	else:
		company_label.visible = false


func _on_level_up(_level: int) -> void:
	_update_valuation()


func _on_sprint_started(sprint_num: int) -> void:
	sprint_label.text = "Спринт %d" % sprint_num


func _on_sprint_ended(sprint_num: int, bonus: int) -> void:
	if bonus > 0:
		sprint_label.text = "Спринт %d завершён! Бонус: $%d" % [sprint_num, bonus]
	else:
		sprint_label.text = "Спринт %d просрочен" % sprint_num


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
```

Key changes:
- Removed: `tech_debt_bar`, `backlog_button`, `click_progress_bar`, `auto_click_bar`, all backlog signal connections
- Added: `xp_bar`, `sprint_label`, `company_label`, company milestone comparison
- `valuation_label` now shows just the dollar amount (large, prominent)
- Sprint events update the sprint label

**Note:** The HUD `.tscn` file needs to be rebuilt in the Godot editor to match the new layout. Remove old nodes (BacklogButton, ClickProgressBar, TechDebtBar, AutoClickBar), add new ones (XpBar, SprintLabel, CompanyLabel). Add SprintTimerBar scene as a child.

- [ ] **Step 4: Update hud.tscn in Godot editor**

Restructure the HUD scene:
- Top area: `ValuationLabel` (large font), `XpBar` (ProgressBar), `CompanyLabel`
- Bottom area: `CardContainer` (HBoxContainer for task cards), `SprintTimerBar` instance
- Corner: `TimerLabel` (game timer), `SprintLabel`
- Remove: BacklogButton, ClickProgressBar, TechDebtBar, AutoClickBar

Mark new nodes as unique names (`%`) where referenced by the script.

- [ ] **Step 5: Commit**

```bash
git add components/hud/
git commit -m "feat: rebuild HUD with evaluation, XP bar, sprint timer, company comparison"
```

---

## Task 11: CEO Commentator

**Files:**
- Create: `components/hud/ceo_commentator.gd`
- Create: `components/hud/ceo_commentator.tscn`

- [ ] **Step 1: Create ceo_commentator.gd**

Create `components/hud/ceo_commentator.gd`:

```gdscript
class_name CeoCommentator
extends Control

@onready var portrait: TextureRect = %Portrait
@onready var speech_bubble: Label = %SpeechBubble

const GOOD_COMMENTS: Array[String] = [
	"Stonks 📈",
	"To the moon!",
	"Amazing velocity!",
	"Ship it!",
	"We're crushing it!",
	"Investors will love this!",
	"10x engineers!",
	"This is the way",
]

const BAD_COMMENTS: Array[String] = [
	"Have you tried working harder?",
	"Let's circle back on this",
	"We need to pivot",
	"Per my last email...",
	"Let's take this offline",
	"Can we 2x the velocity?",
	"Why isn't this done yet?",
	"I'll put it on the agenda",
]

var _comment_timer: float = 0.0
const COMMENT_INTERVAL: float = 5.0


func _ready() -> void:
	SB.sprint_ended.connect(_on_sprint_ended)
	speech_bubble.text = ""


func _process(delta: float) -> void:
	_comment_timer += delta
	if _comment_timer >= COMMENT_INTERVAL:
		_comment_timer -= COMMENT_INTERVAL
		_show_performance_comment()


func _show_performance_comment() -> void:
	if not PD._sprint_active:
		return
	var ratio: float = PD.sprint_timer / PD.sprint_duration
	if ratio > 0.3:
		speech_bubble.text = GOOD_COMMENTS[randi() % GOOD_COMMENTS.size()]
	else:
		speech_bubble.text = BAD_COMMENTS[randi() % BAD_COMMENTS.size()]


func _on_sprint_ended(_sprint_number: int, bonus: int) -> void:
	if bonus > 0:
		speech_bubble.text = "Stonks! +$%d 📈" % bonus
	else:
		speech_bubble.text = "We need to talk..."
```

- [ ] **Step 2: Create ceo_commentator.tscn in Godot editor**

Create scene at `components/hud/ceo_commentator.tscn`:
- Root: `CeoCommentator` (Control) with script `ceo_commentator.gd`
- Child `Portrait` (%Portrait, TextureRect) — CEO silhouette image (circular)
- Child `SpeechBubble` (%SpeechBubble, Label) — positioned above portrait

Anchor to bottom-right corner. Create/use a placeholder CEO silhouette texture.

- [ ] **Step 3: Add CeoCommentator to HUD scene**

In `components/hud/hud.tscn`, add CeoCommentator scene instance as a child. Position in bottom-right corner.

- [ ] **Step 4: Commit**

```bash
git add components/hud/ceo_commentator.gd components/hud/ceo_commentator.tscn components/hud/hud.tscn
git commit -m "feat: add CEO commentator with meme phrases"
```

---

## Task 12: Upgrade System Rebalance

**Files:**
- Modify: `game_data/upgrades/upgrade_data.gd`
- Delete: 6 upgrade .tres files (debt + auto-click)
- Modify: remaining upgrade .tres files
- Create: new sprint upgrade .tres files
- Modify: `autoloads/data_registry.gd`

- [ ] **Step 1: Update UpgradeData resource (no changes needed)**

`upgrade_data.gd` already has the right shape — `upgrade_type`, `stat`, `multiplier`. The enum values changed in Task 1, so existing `.tres` files that reference `UNLOCK` or `DEBT` will break. That's expected.

- [ ] **Step 2: Delete obsolete upgrade .tres files**

Delete these files:
```
game_data/upgrades/global_debt_07x.tres
game_data/upgrades/vibecoder_debt_05x.tres
game_data/upgrades/senior_debt_0x.tres
game_data/upgrades/unlock_auto_click.tres
game_data/upgrades/auto_click_count_2x.tres
game_data/upgrades/auto_click_speed_15x.tres
```

```bash
rm game_data/upgrades/global_debt_07x.tres
rm game_data/upgrades/vibecoder_debt_05x.tres
rm game_data/upgrades/senior_debt_0x.tres
rm game_data/upgrades/unlock_auto_click.tres
rm game_data/upgrades/auto_click_count_2x.tres
rm game_data/upgrades/auto_click_speed_15x.tres
```

- [ ] **Step 3: Update remaining upgrade .tres files**

The following files stay but may need their `stat` enum values verified (enum indices changed):
- `global_damage_2x.tres` — stat should be `DAMAGE` (0). Stays the same.
- `global_speed_15x.tres` — stat should be `SPEED` (1). Stays the same.
- `vibecoder_damage_3x.tres` — stat `DAMAGE` (0), type `DEV` (1). Fine.
- `regular_damage_3x.tres` — same.
- `regular_speed_2x.tres` — stat `SPEED` (1), type `DEV` (1). Fine.
- `senior_damage_3x.tres` — same.

Verify each file in text editor. The `stat` and `upgrade_type` fields use integer indices — make sure they match the new enum order: `DAMAGE=0, SPEED=1, SPRINT_DURATION=2, SPRINT_TASK_COMPOSITION=3`.

- [ ] **Step 4: Create sprint upgrade .tres files**

Create `game_data/upgrades/sprint_duration_15x.tres`:
```
id = "sprint_duration_15x"
display_name = "Agile коуч"
description = "Время спринта ×1.5"
upgrade_type = 2  # SPRINT
stat = 2  # SPRINT_DURATION
multiplier = 1.5
```

Create `game_data/upgrades/sprint_more_features.tres`:
```
id = "sprint_more_features"
display_name = "Product Vision"
description = "Больше фич в спринте"
upgrade_type = 2  # SPRINT
stat = 3  # SPRINT_TASK_COMPOSITION
multiplier = 1.0
```

Note: `SPRINT_TASK_COMPOSITION` upgrades need custom handling in `_generate_sprint_tasks`. The `multiplier` field isn't meaningful here — we'll need a different approach. For now, just track that this upgrade was taken and handle composition logic in PlayerData.

Actually, let's simplify: don't use `SPRINT_TASK_COMPOSITION` as a stat. Instead, just create sprint duration upgrades for now. Task composition tuning can be added later if needed.

Create only `sprint_duration_15x.tres` for now.

- [ ] **Step 5: Rewrite data_registry.gd upgrade pool logic**

Replace the entire contents of `autoloads/data_registry.gd`:

```gdscript
class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_PATH))


func get_level_up_upgrades() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var global_pick: UpgradeData = _pick_random_from(_get_available_by_type(Constants.UpgradeType.GLOBAL))
	if global_pick:
		result.append(global_pick)
	var dev_pick: UpgradeData = _pick_random_from(_get_available_by_type(Constants.UpgradeType.DEV))
	if dev_pick:
		result.append(dev_pick)
	var sprint_pick: UpgradeData = _pick_random_from(_get_available_by_type(Constants.UpgradeType.SPRINT))
	if sprint_pick:
		result.append(sprint_pick)
	var random_pick: UpgradeData = _pick_random_from(_get_all_available())
	if random_pick:
		result.append(random_pick)
	return result


func _get_all_available() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if _is_upgrade_available(upgrade):
			pool.append(upgrade)
	return pool


func _get_available_by_type(type: Constants.UpgradeType) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.upgrade_type != type:
			continue
		pool.append(upgrade)
	return pool


func _pick_random_from(pool: Array[UpgradeData]) -> UpgradeData:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	for req: UpgradeData in upgrade.prerequisites:
		if not _is_taken(req.id):
			return false
	return true


func _is_taken(upgrade_id: String) -> bool:
	for taken: UpgradeData in PD.upgrades_taken:
		if taken.id == upgrade_id:
			return true
	return false
```

Key changes:
- `get_level_up_upgrades` now picks: 1 global, 1 dev-specific, 1 sprint, 1 random
- Removed: `_get_available_backlog()`, stat filter params from `_get_available_by_type`
- Removed: UNLOCK check from `_is_upgrade_available`

- [ ] **Step 6: Commit**

```bash
git add game_data/upgrades/ autoloads/data_registry.gd
git commit -m "feat: rebalance upgrades — 3 categories, remove debt/auto-click"
```

---

## Task 13: Game Over Screen — Company Comparison

**Files:**
- Modify: `components/ui/ui_game_over/ui_game_over.gd`

- [ ] **Step 1: Update ui_game_over.gd**

Replace the entire contents of `components/ui/ui_game_over/ui_game_over.gd`:

```gdscript
class_name UiGameOver
extends CanvasLayer

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var company_label: Label = %CompanyLabel
@onready var restart_button: Button = %RestartButton

const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 50, "name": "Zynga"},
	{"valuation": 200, "name": "Niantic"},
	{"valuation": 500, "name": "Ubisoft"},
	{"valuation": 1500, "name": "EA"},
	{"valuation": 5000, "name": "Valve"},
	{"valuation": 15000, "name": "Epic Games"},
	{"valuation": 50000, "name": "Apple"},
]


func _ready() -> void:
	add_to_group("game_over")
	SB.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_game_over(final_valuation: int) -> void:
	valuation_label.text = "$%d" % final_valuation
	level_label.text = "Уровень: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	_show_company_comparison(final_valuation)
	visible = true


func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in COMPANY_MILESTONES:
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

Key changes:
- Added company comparison label and milestone logic
- Valuation shown as `$N` format
- Company milestones array (same as HUD, duplicated intentionally — different contexts)

**Note:** Add a `%CompanyLabel` (Label) node to `ui_game_over.tscn` in the Godot editor.

- [ ] **Step 2: Update ui_game_over.tscn**

Add `CompanyLabel` node to the scene, mark as unique name `%CompanyLabel`. Position below the team label.

- [ ] **Step 3: Commit**

```bash
git add components/ui/ui_game_over/
git commit -m "feat: add company comparison to game over screen"
```

---

## Task 14: Level Script & Final Cleanup

**Files:**
- Modify: `levels/test_level.gd`
- Modify: `components/task_queue/task_card.gd` (minor)

- [ ] **Step 1: Clean up test_level.gd**

The level script is already minimal. No changes needed — it calls `PD.start_game()` which now starts the sprint cycle. Verify it still works.

- [ ] **Step 2: Clean up task_card.gd**

`task_card.gd` references `PD.task_queue` for drag-and-drop reordering. This still works with the sprint system — tasks in queue can still be reordered. No changes needed.

- [ ] **Step 3: Remove references to deleted signals in any remaining files**

Search the codebase for references to removed signals and constants:
- `backlog_clicked` — should only exist in signal_bus.gd (already removed)
- `backlog_task_spawned` — same
- `resource_tech_debt_changed` — same
- `tech_debt_produced` — same
- `BASE_DEBT_PER_TASK` — should be gone
- `BASE_CLICKS_PER_TASK` — should be gone
- `BUG_SPAWN_MULTIPLIER` — should be gone
- `auto_click` — should be gone from all game code

Run in terminal:
```bash
cd /home/jscom/coding/game-teamlead
grep -rn "backlog_clicked\|backlog_task_spawned\|resource_tech_debt_changed\|tech_debt_produced\|BASE_DEBT\|BASE_CLICKS\|BUG_SPAWN\|auto_click\|AutoClickBar\|TechDebtBar\|BacklogButton\|ClickProgressBar" --include="*.gd" --include="*.tscn"
```

Fix any remaining references found.

- [ ] **Step 4: Run the game and verify**

Launch in Godot:
1. Game starts, sprint begins with 8 tasks
2. Starter vibecoder picks a task and attacks it
3. Tasks have HP bars, flash on hit
4. Sprint timer counts down, green → red
5. CEO comments appear
6. Evaluation grows, XP bar fills
7. Level-up shows upgrade cards (no debt/auto-click cards)
8. Game ends at 10 minutes

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: complete meme viral redesign — sprint system, boost, burnout, YouTube"
```

---

## Summary of Migration

| Phase | Task | What Changes |
|-------|------|-------------|
| Foundation | 1 | Constants & enums |
| Data | 2-3 | TaskData + DeveloperData resources |
| Logic | 4-6 | Balance, SignalBus, PlayerData sprint cycle |
| Gameplay | 7-9 | Developer states, TaskDisplay, scene cleanup |
| UI | 10-11 | HUD rebuild, CEO commentator |
| Systems | 12 | Upgrade rebalance |
| Polish | 13-14 | Game over screen, final cleanup |
