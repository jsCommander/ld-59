# Idle Roguelike Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the game from a sprint-based strategy into an idle roguelike with 15-minute runs, multiplicative upgrades on level-up, and exponential scaling.

**Architecture:** Replace money/purchase/upgrade-tree systems with a timer-based run where valuation acts as both XP and score. Developers auto-attack tasks; on level-up the player picks 1 of 4 random multiplicative upgrades from a pool of 9. At hire levels (3,6,9,12,15) the player also picks a new developer type. Game ends when the 15-minute timer expires and shows a result screen.

**Tech Stack:** Godot 4, GDScript, Resources (.tres), CanvasLayer overlays

**Spec:** `docs/superpowers/specs/2026-04-08-idle-roguelike-redesign-design.md`

---

## File Structure

### Create

| File | Purpose |
|------|---------|
| `game_data/upgrades/upgrade_data.gd` | UpgradeData resource class (id, display_name, description, icon, upgrade_type, target_dev_type, stat, multiplier) |
| `game_data/upgrades/global_damage_2x.tres` | ×2 damage all |
| `game_data/upgrades/global_speed_15x.tres` | ×1.5 speed all |
| `game_data/upgrades/global_debt_07x.tres` | ×0.7 debt all |
| `game_data/upgrades/vibecoder_damage_3x.tres` | ×3 damage vibecoders |
| `game_data/upgrades/vibecoder_debt_05x.tres` | ×0.5 debt vibecoders |
| `game_data/upgrades/regular_damage_3x.tres` | ×3 damage regulars |
| `game_data/upgrades/regular_speed_2x.tres` | ×2 speed regulars |
| `game_data/upgrades/senior_damage_3x.tres` | ×3 damage seniors |
| `game_data/upgrades/senior_debt_0x.tres` | ×0 debt seniors |
| `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd` | Fullscreen overlay: 4 upgrade cards on level-up |
| `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn` | Scene for upgrade choice overlay |
| `components/ui/ui_upgrade_choice/upgrade_card.gd` | Single upgrade card (icon, name, description, multiplier) |
| `components/ui/ui_upgrade_choice/upgrade_card.tscn` | Scene for upgrade card |
| `components/ui/ui_hire_choice/ui_hire_choice.gd` | Fullscreen overlay: 3 developer type cards |
| `components/ui/ui_hire_choice/ui_hire_choice.tscn` | Scene for hire choice overlay |
| `components/ui/ui_hire_choice/hire_card.gd` | Single hire card (texture, name, stats) |
| `components/ui/ui_hire_choice/hire_card.tscn` | Scene for hire card |
| `components/ui/ui_game_over/ui_game_over.gd` | Result screen overlay (valuation, level, team, restart button) |
| `components/ui/ui_game_over/ui_game_over.tscn` | Scene for result screen |

### Modify

| File | Changes |
|------|---------|
| `globals/constants.gd` | Remove: `BASE`, `DEBT_PER_TASK`, `TECH_DEBT_PER_HIT`, `PRIORITY_TIERS`, `MAX_PRIORITY`, `MIN_QUEUE_SIZE`. Add: `GAME_DURATION`, `MAX_LEVEL`, `XP_BASE`, `HIRE_LEVELS`, `MAX_QUEUE_SIZE`, `BASE_DAMAGE`, `BASE_DEBT_PER_HP`. Keep: `BACKLOG_SIZE`, `BACKLOG_REFRESH_INTERVAL`, `BUG_SPAWN_MULTIPLIER`, `REFACTOR_SPAWN_MULTIPLIER`, enums, music/sfx. |
| `game_data/developer/developer_data.gd` | Replace `feature_damage`, `bug_damage`, `refactor_damage`, `tech_debt`, `salary_mult` with `base_feature_mult`, `base_bug_mult`, `base_refactor_mult`, `base_debt_mult`, `base_attack_speed` |
| `game_data/developer/developer_data_vibecoder.tres` | Update field values for new schema |
| `game_data/developer/developer_data_regular.tres` | Update field values for new schema |
| `game_data/developer/developer_data_senior.tres` | Update field values for new schema |
| `autoloads/signal_bus.gd` | Add: `level_up(level: int)`, `game_timer_changed(remaining: float)`, `game_over(valuation: int)`, `upgrade_chosen(upgrade: UpgradeData)`, `developer_hire_requested`. Remove: `upgrade_purchased`, `resource_money_changed` |
| `autoloads/player_data.gd` | Full rewrite: timer, multipliers, level-up logic, new damage formula, remove money |
| `autoloads/data_registry.gd` | Load UpgradeData from `game_data/upgrades/`, remove UpgradeTree and PhaseData loading |
| `components/developer/developer.gd` | New damage/speed formulas using Constants + PD multipliers |
| `components/developer/ui/popup_developer.gd` | Update bar display for new DeveloperData fields |
| `components/hud/hud.gd` | Remove money label + upgrade button. Add timer label. Update valuation to show level progress. |
| `components/hud/hud.tscn` | Remove MoneyLabel, UpgradeButton. Add TimerLabel. |
| `components/hud/popup_manager.gd` | Remove PopupDeveloperEmpty handling (empty desks do nothing) |
| `levels/test_level.gd` | Add game init: auto-hire first vibecoder, wire overlays |
| `levels/test_level.tscn` | Remove UiUpgradeTree. Add UiUpgradeChoice, UiHireChoice, UiGameOver. |

### Delete

| File/Folder | Reason |
|-------------|--------|
| `components/ui/ui_upgrade_tree/` | Entire folder — replaced by upgrade choice overlay |
| `game_data/upgrade_tree/*.tres` | Old tree layout and upgrade nodes |
| `game_data/upgrade_tree/upgrade_tree.gd` | Old UpgradeTree resource class |
| `game_data/phase/` | Entire folder — sprint phases removed |
| `components/developer/ui/popup_developer_empty.gd` | Hiring now via overlay, not desk popup |
| `components/developer/ui/popup_developer_empty.tscn` | Hiring now via overlay, not desk popup |

---

## Tasks

### Task 1: Constants — remove old, add new

**Files:**
- Modify: `globals/constants.gd`

- [ ] **Step 1: Replace constants**

```gdscript
class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }

const GAME_DURATION: float = 900.0
const MAX_LEVEL: int = 35
const XP_BASE: int = 30
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const MAX_QUEUE_SIZE: int = 10
const BACKLOG_SIZE: int = 15
const BACKLOG_REFRESH_INTERVAL: float = 10.0
const BUG_SPAWN_MULTIPLIER: float = 0.01
const REFACTOR_SPAWN_MULTIPLIER: float = 0.005

const BASE_DAMAGE: float = 10.0
const BASE_DEBT_PER_HP: float = 0.01
const DEBT_PER_TASK: float = 0.6

enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT, EXPLOSION }
```

Removed: `BASE`, `TECH_DEBT_PER_HIT`, `PRIORITY_TIERS`, `MAX_PRIORITY`, `MIN_QUEUE_SIZE`.
Added: `GAME_DURATION`, `MAX_LEVEL`, `XP_BASE`, `HIRE_LEVELS`, `MAX_QUEUE_SIZE`, `BASE_DAMAGE`, `BASE_DEBT_PER_HP`.
Kept: `DEBT_PER_TASK` (still used for refactor debt reduction).

- [ ] **Step 2: Commit**

```bash
git add globals/constants.gd
git commit -m "refactor: update constants for idle roguelike"
```

---

### Task 2: DeveloperData resource rework

**Files:**
- Modify: `game_data/developer/developer_data.gd`
- Modify: `game_data/developer/developer_data_vibecoder.tres`
- Modify: `game_data/developer/developer_data_regular.tres`
- Modify: `game_data/developer/developer_data_senior.tres`

- [ ] **Step 1: Rewrite developer_data.gd**

Replace the full file with:

```gdscript
class_name DeveloperData extends BaseGameData

@export var dev_type: Constants.DevType = Constants.DevType.REGULAR
@export var texture: Texture2D
@export var base_feature_mult: float = 1.0
@export var base_bug_mult: float = 1.0
@export var base_refactor_mult: float = 1.0
@export var base_debt_mult: float = 1.0
@export var base_attack_speed: float = 2.0
```

- [ ] **Step 2: Update vibecoder .tres**

Open `developer_data_vibecoder.tres` in editor or manually set:
- `base_feature_mult = 1.6`
- `base_bug_mult = 0.4`
- `base_refactor_mult = 0.2`
- `base_debt_mult = 3.0`
- `base_attack_speed = 2.0`

Remove any references to old fields (`feature_damage`, `bug_damage`, `refactor_damage`, `tech_debt`, `salary_mult`).

- [ ] **Step 3: Update regular .tres**

- `base_feature_mult = 1.0`
- `base_bug_mult = 1.0`
- `base_refactor_mult = 1.0`
- `base_debt_mult = 1.0`
- `base_attack_speed = 2.0`

- [ ] **Step 4: Update senior .tres**

- `base_feature_mult = 0.6`
- `base_bug_mult = 1.4`
- `base_refactor_mult = 1.6`
- `base_debt_mult = 0.0`
- `base_attack_speed = 2.0`

- [ ] **Step 5: Commit**

```bash
git add game_data/developer/
git commit -m "refactor: rework DeveloperData to multiplier-based stats"
```

---

### Task 3: UpgradeData resource + 9 .tres files

**Files:**
- Create: `game_data/upgrades/upgrade_data.gd`
- Create: 9 `.tres` files in `game_data/upgrades/`

- [ ] **Step 1: Create upgrade_data.gd**

```gdscript
class_name UpgradeData extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D

enum UpgradeType { GLOBAL, DEV, UNLOCK }
enum Stat { DAMAGE, SPEED, DEBT }

@export var upgrade_type: UpgradeType
@export var target_dev_type: Constants.DevType
@export var stat: Stat
@export var multiplier: float = 1.0
```

Note: `target_dev_type` is only meaningful when `upgrade_type == DEV`. For `GLOBAL` upgrades, its value is ignored.

- [ ] **Step 2: Create 3 global upgrade .tres files**

Create `game_data/upgrades/global_damage_2x.tres`:
```
id = "global_damage_2x"
display_name = "Мотивационная речь"
description = "×2 урон всем"
upgrade_type = 0  # GLOBAL
stat = 0  # DAMAGE
multiplier = 2.0
```

Create `game_data/upgrades/global_speed_15x.tres`:
```
id = "global_speed_15x"
display_name = "Стендапы покороче"
description = "×1.5 скорость атаки всем"
upgrade_type = 0  # GLOBAL
stat = 1  # SPEED
multiplier = 1.5
```

Create `game_data/upgrades/global_debt_07x.tres`:
```
id = "global_debt_07x"
display_name = "Code Review"
description = "×0.7 техдолг всем"
upgrade_type = 0  # GLOBAL
stat = 2  # DEBT
multiplier = 0.7
```

- [ ] **Step 3: Create 6 DEV upgrade .tres files**

Create each in `game_data/upgrades/`:

`vibecoder_damage_3x.tres`: id="vibecoder_damage_3x", display_name="Cursor Pro", description="×3 урон вайбкодеров", upgrade_type=1 (DEV), target_dev_type=0 (VIBECODER), stat=0 (DAMAGE), multiplier=3.0

`vibecoder_debt_05x.tres`: id="vibecoder_debt_05x", display_name="Линтер", description="×0.5 техдолг вайбкодеров", upgrade_type=1 (DEV), target_dev_type=0 (VIBECODER), stat=2 (DEBT), multiplier=0.5

`regular_damage_3x.tres`: id="regular_damage_3x", display_name="IDE плагины", description="×3 урон разработчиков", upgrade_type=1 (DEV), target_dev_type=1 (REGULAR), stat=0 (DAMAGE), multiplier=3.0

`regular_speed_2x.tres`: id="regular_speed_2x", display_name="Второй монитор", description="×2 скорость разработчиков", upgrade_type=1 (DEV), target_dev_type=1 (REGULAR), stat=1 (SPEED), multiplier=2.0

`senior_damage_3x.tres`: id="senior_damage_3x", display_name="Архитектурный паттерн", description="×3 урон сеньоров", upgrade_type=1 (DEV), target_dev_type=2 (SENIOR), stat=0 (DAMAGE), multiplier=3.0

`senior_debt_0x.tres`: id="senior_debt_0x", display_name="Clean Code", description="×0 техдолг сеньоров", upgrade_type=1 (DEV), target_dev_type=2 (SENIOR), stat=2 (DEBT), multiplier=0.0

- [ ] **Step 4: Commit**

```bash
git add game_data/upgrades/
git commit -m "feat: add UpgradeData resource and 9 upgrade definitions"
```

---

### Task 4: SignalBus — new signals

**Files:**
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Update signal_bus.gd**

```gdscript
class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_clicked(task: TaskData)

signal developer_attack(developer: Developer)
signal task_hp_changed(task: TaskData, hp: float, max_hp: float)
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_tech_debt_changed
signal valuation_changed

signal backlog_refreshed

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
```

Removed: `resource_money_changed`, `upgrade_purchased`.
Added: `game_timer_changed`, `level_up`, `game_over`, `upgrade_chosen`, `developer_hire_requested`.

- [ ] **Step 2: Commit**

```bash
git add autoloads/signal_bus.gd
git commit -m "refactor: update SignalBus for idle roguelike signals"
```

---

### Task 5: DataRegistry — load UpgradeData

**Files:**
- Modify: `autoloads/data_registry.gd`

- [ ] **Step 1: Rewrite data_registry.gd**

```gdscript
class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Array[UpgradeData] = []


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades = _find_upgrades_in_path(UPGRADE_PATH)


func _find_upgrades_in_path(path: String) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(path.path_join(file_name))
			if res is UpgradeData:
				result.append(res)
		file_name = dir.get_next()
	Log.log_info(name, "Found %d upgrades" % result.size())
	return result


func get_random_upgrades(count: int) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = upgrades.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))
```

Removed: `UPGRADE_TREE_PATH`, `PHASE_PATH`, `phases` dictionary, `UpgradeTree` references.
Changed: `upgrades` is now `Array[UpgradeData]` (flat pool, not keyed by id).
Added: `get_random_upgrades()` — returns N random upgrades for level-up choice.

- [ ] **Step 2: Commit**

```bash
git add autoloads/data_registry.gd
git commit -m "refactor: DataRegistry loads UpgradeData pool instead of UpgradeTree"
```

---

### Task 6: PlayerData — full rewrite

**Files:**
- Modify: `autoloads/player_data.gd`

This is the biggest change. PlayerData becomes the core game loop controller.

- [ ] **Step 1: Rewrite player_data.gd**

```gdscript
class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

var valuation: int = 0
var level: int = 0
var tech_debt: float = 0.0
var timer_remaining: float = Constants.GAME_DURATION
var _game_active: bool = false
var _awaiting_choice: bool = false

var task_queue: Array[TaskData] = []
var backlog: Array[TaskData] = []
var developers: Array[Developer] = []
var _backlog_timer: float = 0.0

var upgrades_taken: Array[UpgradeData] = []

# Cached multipliers
var global_damage_mult: float = 1.0
var global_speed_mult: float = 1.0
var global_debt_mult: float = 1.0
var vibecoder_damage_mult: float = 1.0
var vibecoder_debt_mult: float = 1.0
var regular_damage_mult: float = 1.0
var regular_speed_mult: float = 1.0
var senior_damage_mult: float = 1.0
var senior_debt_mult: float = 1.0


func _ready() -> void:
	SB.developer_attack.connect(_on_developer_attack)
	SB.upgrade_chosen.connect(_on_upgrade_chosen)


func start_game() -> void:
	reset()
	_game_active = true
	fill_backlog()


func reset() -> void:
	valuation = 0
	level = 0
	tech_debt = 0.0
	timer_remaining = Constants.GAME_DURATION
	_game_active = false
	_awaiting_choice = false
	task_queue.clear()
	backlog.clear()
	developers.clear()
	_backlog_timer = 0.0
	upgrades_taken.clear()
	global_damage_mult = 1.0
	global_speed_mult = 1.0
	global_debt_mult = 1.0
	vibecoder_damage_mult = 1.0
	vibecoder_debt_mult = 1.0
	regular_damage_mult = 1.0
	regular_speed_mult = 1.0
	senior_damage_mult = 1.0
	senior_debt_mult = 1.0


func _process(delta: float) -> void:
	if not _game_active or _awaiting_choice:
		return

	# Game timer
	timer_remaining -= delta
	SB.game_timer_changed.emit(timer_remaining)
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		get_tree().paused = true
		SB.game_over.emit(valuation)
		return

	# Backlog refill
	if backlog.size() < Constants.BACKLOG_SIZE:
		_backlog_timer += delta
		if _backlog_timer >= Constants.BACKLOG_REFRESH_INTERVAL:
			_backlog_timer = 0.0
			_spawn_backlog_task()
			SB.backlog_refreshed.emit()


func get_backlog_refresh_progress() -> float:
	return _backlog_timer / Constants.BACKLOG_REFRESH_INTERVAL


func get_xp_for_level(lvl: int) -> int:
	return Constants.XP_BASE * int(pow(2, lvl - 1))


# --- Multiplier queries ---

func get_type_damage_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.VIBECODER: return vibecoder_damage_mult
		Constants.DevType.REGULAR: return regular_damage_mult
		Constants.DevType.SENIOR: return senior_damage_mult
	return 1.0


func get_type_speed_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.REGULAR: return regular_speed_mult
	return 1.0


func get_type_debt_mult(dev_type: Constants.DevType) -> float:
	match dev_type:
		Constants.DevType.VIBECODER: return vibecoder_debt_mult
		Constants.DevType.SENIOR: return senior_debt_mult
	return 1.0


# --- Upgrade application ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_check_hire_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == UpgradeData.UpgradeType.GLOBAL:
		match upgrade.stat:
			UpgradeData.Stat.DAMAGE: global_damage_mult *= upgrade.multiplier
			UpgradeData.Stat.SPEED: global_speed_mult *= upgrade.multiplier
			UpgradeData.Stat.DEBT: global_debt_mult *= upgrade.multiplier
	elif upgrade.upgrade_type == UpgradeData.UpgradeType.DEV:
		var dt: Constants.DevType = upgrade.target_dev_type
		match upgrade.stat:
			UpgradeData.Stat.DAMAGE:
				match dt:
					Constants.DevType.VIBECODER: vibecoder_damage_mult *= upgrade.multiplier
					Constants.DevType.REGULAR: regular_damage_mult *= upgrade.multiplier
					Constants.DevType.SENIOR: senior_damage_mult *= upgrade.multiplier
			UpgradeData.Stat.SPEED:
				match dt:
					Constants.DevType.REGULAR: regular_speed_mult *= upgrade.multiplier
			UpgradeData.Stat.DEBT:
				match dt:
					Constants.DevType.VIBECODER: vibecoder_debt_mult *= upgrade.multiplier
					Constants.DevType.SENIOR: senior_debt_mult *= upgrade.multiplier
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


func _check_hire_level() -> void:
	if level in Constants.HIRE_LEVELS:
		_awaiting_choice = true
		SB.developer_hire_requested.emit()
	else:
		get_tree().paused = false


# --- Level-up ---

func _check_level_up() -> void:
	if level >= Constants.MAX_LEVEL:
		return
	if valuation >= get_xp_for_level(level + 1):
		level += 1
		_awaiting_choice = true
		get_tree().paused = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)


# --- Task spawning ---

func _spawn_backlog_task() -> void:
	if backlog.size() >= Constants.BACKLOG_SIZE:
		return
	var task: TaskData = _create_task_by_debt()
	_scale_task_hp(task)
	backlog.append(task)


func fill_backlog() -> void:
	while backlog.size() < Constants.BACKLOG_SIZE:
		var task: TaskData = _create_task_by_debt()
		_scale_task_hp(task)
		backlog.append(task)


func _create_task_by_debt() -> TaskData:
	var bug_chance: float = tech_debt * Constants.BUG_SPAWN_MULTIPLIER
	var refactor_chance: float = tech_debt * Constants.REFACTOR_SPAWN_MULTIPLIER
	var roll: float = randf()
	if roll < bug_chance:
		return TASK_DATA_BUG.duplicate()
	elif roll < bug_chance + refactor_chance:
		return TASK_DATA_REFACTOR.duplicate()
	return TASK_DATA_FEATURE.duplicate()


func _scale_task_hp(task: TaskData) -> void:
	var minutes_elapsed: float = (Constants.GAME_DURATION - timer_remaining) / 60.0
	var hp: float = task.base_hp * pow(2.0, minutes_elapsed)
	task.current_hp = hp
	task.max_hp = hp


# --- Task queue ---

func add_tasks_to_queue(tasks: Array[TaskData]) -> void:
	for task: TaskData in tasks:
		backlog.erase(task)
		if task.current_hp <= 0.0:
			_scale_task_hp(task)
		task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)
	fill_backlog()
	Log.log_info(name, "Added %d tasks to queue (total: %d)" % [tasks.size(), task_queue.size()])


# --- Combat ---

func _on_developer_attack(developer: Developer) -> void:
	if task_queue.is_empty():
		return
	var task: TaskData = task_queue[0]
	var damage: float = _calculate_damage(developer, task.task_type)
	var debt_delta: float = _calculate_debt(developer, damage)
	task.current_hp -= damage
	developer.show_damage(int(damage))
	increase_tech_debt(debt_delta)
	SB.task_hp_changed.emit(task, task.current_hp, task.max_hp)
	if task.current_hp <= 0.0:
		task_queue.pop_front()
		_on_task_destroyed(task)


func _calculate_damage(developer: Developer, task_type: Constants.TaskType) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = _get_task_mult(developer.data, task_type)
	var type_mult: float = get_type_damage_mult(developer.data.dev_type)
	var global_mult: float = global_damage_mult
	return base * task_mult * type_mult * global_mult


func _get_task_mult(data: DeveloperData, task_type: Constants.TaskType) -> float:
	match task_type:
		Constants.TaskType.FEATURE: return data.base_feature_mult
		Constants.TaskType.BUG: return data.base_bug_mult
		Constants.TaskType.REFACTOR: return data.base_refactor_mult
	return 1.0


func _calculate_debt(developer: Developer, damage: float) -> float:
	return Constants.BASE_DEBT_PER_HP * damage * developer.data.base_debt_mult * get_type_debt_mult(developer.data.dev_type) * global_debt_mult


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	SB.task_destroyed.emit(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])


func _apply_task_rewards(task: TaskData) -> void:
	match task.task_type:
		Constants.TaskType.FEATURE:
			valuation += int(task.max_hp)
			SB.valuation_changed.emit()
			_check_level_up()
			Log.log_info(name, "Feature done: +%d valuation (total: %d)" % [int(task.max_hp), valuation])
		Constants.TaskType.BUG:
			Log.log_info(name, "Bug fixed")
		Constants.TaskType.REFACTOR:
			increase_tech_debt(-Constants.DEBT_PER_TASK)
			Log.log_info(name, "Refactor done: -%.1f debt" % Constants.DEBT_PER_TASK)


# --- Developers ---

func hire_developer(developer: Developer) -> void:
	developers.append(developer)
	SB.developer_hired.emit(developer.data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[developer.data.dev_type])
	_awaiting_choice = false
	get_tree().paused = false


func fire_developer(developer: Developer) -> void:
	developers.erase(developer)
	SB.developer_fired.emit(developer.data)


func increase_tech_debt(delta: float) -> void:
	tech_debt = clampf(tech_debt + delta, 0.0, 100.0)
	SB.resource_tech_debt_changed.emit()
```

Key changes from current player_data.gd:
- Removed: `money`, `purchased_upgrades`, `can_afford()`, `earn()`, `spend()`, `purchase_upgrade()`, `is_upgrade_purchased()`, `get_bug_priority()`
- Added: `timer_remaining`, `level`, `_game_active`, `_awaiting_choice`, all multiplier vars, `upgrades_taken`
- Added: `start_game()`, `get_xp_for_level()`, `get_type_*_mult()`, `_apply_upgrade()`, `_check_level_up()`, `_check_hire_level()`, `_calculate_damage()`, `_calculate_debt()`, `_scale_task_hp()`
- Changed: `_on_developer_attack()` uses new damage/debt formulas
- Changed: `_apply_task_rewards()` — features add max_hp to valuation, no money
- Changed: `_spawn_backlog_task()` now scales HP based on elapsed time

- [ ] **Step 2: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat: rewrite PlayerData for idle roguelike game loop"
```

---

### Task 7: Developer — new attack speed formula

**Files:**
- Modify: `components/developer/developer.gd`

- [ ] **Step 1: Update developer.gd attack speed**

The developer's `_process` currently uses `data.base_attack_speed` directly. It needs to use the multiplied attack speed from PD.

Replace the `_process` method:

```gdscript
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return
	if PD.task_queue.is_empty():
		_attack_timer = 0.0
		_stop_idle_sway()
		_update_progress_bar()
		return
	_start_idle_sway()
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()
	_update_progress_bar()
```

Replace `_update_progress_bar`:

```gdscript
func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or PD.task_queue.is_empty():
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / _get_attack_speed()
```

Add `_get_attack_speed`:

```gdscript
func _get_attack_speed() -> float:
	var base: float = data.base_attack_speed
	var type_mult: float = PD.get_type_speed_mult(data.dev_type)
	var global_mult: float = PD.global_speed_mult
	return base / (type_mult * global_mult)
```

- [ ] **Step 2: Commit**

```bash
git add components/developer/developer.gd
git commit -m "feat: developer uses multiplied attack speed"
```

---

### Task 8: PopupDeveloper — update for new stats

**Files:**
- Modify: `components/developer/ui/popup_developer.gd`

- [ ] **Step 1: Update bar display**

```gdscript
class_name PopupDeveloper
extends PanelContainer

var _developer: Developer

@onready var name_label: Label = %NameLabel
@onready var feature_bar: ProgressBar = %FeatureBar
@onready var bug_bar: ProgressBar = %BugBar
@onready var refactor_bar: ProgressBar = %RefactorBar
@onready var speed_bar: ProgressBar = %SpeedBar


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer or not _developer.data:
		Log.log_warn(name, "Invalid developer target")
		return
	name_label.text = Constants.DevType.keys()[_developer.data.dev_type]
	_update_bars()


func _update_bars() -> void:
	feature_bar.value = _developer.data.base_feature_mult * 50.0
	bug_bar.value = _developer.data.base_bug_mult * 50.0
	refactor_bar.value = _developer.data.base_refactor_mult * 50.0
	speed_bar.value = 100.0 / _developer.data.base_attack_speed
```

Bar values are scaled so that 1.0 mult = 50% bar, 2.0 = 100%. Speed bar stays the same logic.

- [ ] **Step 2: Commit**

```bash
git add components/developer/ui/popup_developer.gd
git commit -m "refactor: popup_developer displays multiplier-based stats"
```

---

### Task 9: HUD — remove money, add timer, update valuation

**Files:**
- Modify: `components/hud/hud.gd`
- Modify: `components/hud/hud.tscn`

- [ ] **Step 1: Update hud.tscn**

In the .tscn file:
1. Delete the `MoneyLabel` node (under StatsPanel/MarginContainer/VBoxContainer).
2. Delete the `UpgradeButton` node (under BottomBar).
3. Add a `TimerLabel` node (Label) as first child of `StatsPanel/MarginContainer/VBoxContainer`, with `unique_name_in_owner = true`, text = "15:00".
4. Update `ValuationLabel` text to "Lv.0  $0 / $30".

- [ ] **Step 2: Rewrite hud.gd**

```gdscript
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var timer_label: Label = %TimerLabel
@onready var valuation_label: Label = %ValuationLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var main_layout: VBoxContainer = %MainLayout
@onready var backlog_button: Button = %BacklogButton


func _ready() -> void:
	SB.game_timer_changed.connect(_update_timer)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.task_hp_changed.connect(_on_task_hp_changed)
	backlog_button.pressed.connect(_on_backlog_pressed)
	_update_tech_debt()
	_update_valuation()
	main_layout.visible = true


func _update_timer(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1) if PD.level < Constants.MAX_LEVEL else 0
	if PD.level >= Constants.MAX_LEVEL:
		valuation_label.text = "Lv.%d  $%d (MAX)" % [PD.level, PD.valuation]
	else:
		valuation_label.text = "Lv.%d  $%d / $%d" % [PD.level, PD.valuation, next_xp]


func _on_level_up(_level: int) -> void:
	_update_valuation()


func _on_backlog_pressed() -> void:
	var backlog: UiTaskBacklog = get_tree().get_first_node_in_group("task_backlog")
	if backlog:
		if backlog.visible:
			backlog.close()
		else:
			backlog.open()


func _on_task_hp_changed(task: TaskData, hp: float, max_hp: float) -> void:
	if card_container.get_child_count() == 0:
		return
	var first_card: TaskCard = card_container.get_child(0) as TaskCard
	if not first_card:
		return
	first_card.update_hp(hp, max_hp)
	_shake_card(first_card)


func _shake_card(card: Control) -> void:
	var tween: Tween = create_tween()
	var original_x: float = card.position.x
	tween.tween_property(card, "position:x", original_x + 5.0, 0.04)
	tween.tween_property(card, "position:x", original_x - 5.0, 0.04)
	tween.tween_property(card, "position:x", original_x, 0.07)


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		if i == 0:
			card.show_hp = true
		card_container.add_child(card)
```

Removed: `money_label`, `upgrade_button`, `_update_money()`, `_on_upgrade_pressed()`.
Added: `timer_label`, `_update_timer()`, `_on_level_up()`.
Changed: `_update_valuation()` shows level + XP progress.

- [ ] **Step 3: Commit**

```bash
git add components/hud/hud.gd components/hud/hud.tscn
git commit -m "feat: HUD shows timer and level progress, removes money"
```

---

### Task 10: Upgrade Choice overlay

**Files:**
- Create: `components/ui/ui_upgrade_choice/upgrade_card.gd`
- Create: `components/ui/ui_upgrade_choice/upgrade_card.tscn`
- Create: `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd`
- Create: `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn`

- [ ] **Step 1: Create upgrade_card.gd**

```gdscript
class_name UpgradeCard
extends PanelContainer

signal chosen(upgrade: UpgradeData)

var _upgrade: UpgradeData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var multiplier_label: Label = %MultiplierLabel


func setup(upgrade: UpgradeData) -> void:
	_upgrade = upgrade


func _ready() -> void:
	if not _upgrade:
		return
	if _upgrade.icon:
		icon_rect.texture = _upgrade.icon
	name_label.text = _upgrade.display_name
	description_label.text = _upgrade.description
	multiplier_label.text = "×%.1f" % _upgrade.multiplier


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_upgrade)
```

- [ ] **Step 2: Create upgrade_card.tscn**

Build in editor or write .tscn manually:
- Root: PanelContainer (UpgradeCard script, custom_minimum_size = 200×280)
- MarginContainer (margins 12)
  - VBoxContainer (separation 8)
    - IconRect (TextureRect, unique, custom_minimum_size 64×64, expand_mode=KEEP_SIZE, stretch_mode=KEEP_ASPECT_CENTERED)
    - NameLabel (Label, unique, horizontal_alignment=CENTER, autowrap)
    - DescriptionLabel (Label, unique, horizontal_alignment=CENTER, autowrap, size_flags_vertical=EXPAND_FILL)
    - MultiplierLabel (Label, unique, horizontal_alignment=CENTER, font_size=28)

- [ ] **Step 3: Create ui_upgrade_choice.gd**

```gdscript
class_name UiUpgradeChoice
extends CanvasLayer

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	add_to_group("upgrade_choice")
	SB.level_up.connect(_on_level_up)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_level_up(level: int) -> void:
	title_label.text = "Уровень %d — выбери апгрейд" % level
	var upgrades: Array[UpgradeData] = DR.get_random_upgrades(4)
	_build_cards(upgrades)
	visible = true


func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.chosen.connect(_on_upgrade_chosen)
		card_container.add_child(card)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	SB.upgrade_chosen.emit(upgrade)
	visible = false
```

- [ ] **Step 4: Create ui_upgrade_choice.tscn**

Build in editor or write .tscn manually:
- Root: CanvasLayer (layer=20, UiUpgradeChoice script)
- ColorRect (full screen, color 0.05, 0.05, 0.1, 0.9, mouse_filter=STOP)
- CenterContainer (full screen anchors)
  - VBoxContainer (separation 24)
    - TitleLabel (Label, unique, horizontal_alignment=CENTER, font_size=32)
    - CardContainer (HBoxContainer, unique, separation=16, alignment=CENTER)

- [ ] **Step 5: Verify**

Run: Open the game, ensure level-up triggers the overlay. Click a card → overlay closes, multiplier applied.

- [ ] **Step 6: Commit**

```bash
git add components/ui/ui_upgrade_choice/
git commit -m "feat: add upgrade choice overlay for level-up"
```

---

### Task 11: Hire Choice overlay

**Files:**
- Create: `components/ui/ui_hire_choice/hire_card.gd`
- Create: `components/ui/ui_hire_choice/hire_card.tscn`
- Create: `components/ui/ui_hire_choice/ui_hire_choice.gd`
- Create: `components/ui/ui_hire_choice/ui_hire_choice.tscn`

- [ ] **Step 1: Create hire_card.gd**

```gdscript
class_name HireCard
extends PanelContainer

signal chosen(dev_data: DeveloperData)

var _dev_data: DeveloperData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel


func setup(dev_data: DeveloperData) -> void:
	_dev_data = dev_data


func _ready() -> void:
	if not _dev_data:
		return
	if _dev_data.texture:
		icon_rect.texture = _dev_data.texture
	name_label.text = Constants.DevType.keys()[_dev_data.dev_type]
	stats_label.text = "Фичи: %.1f\nБаги: %.1f\nРефактор: %.1f\nДолг: %.1f\nСкорость: %.1f" % [
		_dev_data.base_feature_mult,
		_dev_data.base_bug_mult,
		_dev_data.base_refactor_mult,
		_dev_data.base_debt_mult,
		_dev_data.base_attack_speed,
	]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_dev_data)
```

- [ ] **Step 2: Create hire_card.tscn**

Similar to upgrade_card.tscn:
- Root: PanelContainer (HireCard script, custom_minimum_size = 200×300)
- MarginContainer (margins 12)
  - VBoxContainer (separation 8)
    - IconRect (TextureRect, unique, custom_minimum_size 80×80)
    - NameLabel (Label, unique, horizontal_alignment=CENTER, font_size=22)
    - StatsLabel (Label, unique, autowrap)

- [ ] **Step 3: Create ui_hire_choice.gd**

```gdscript
class_name UiHireChoice
extends CanvasLayer

const HIRE_CARD: PackedScene = preload("res://components/ui/ui_hire_choice/hire_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	add_to_group("hire_choice")
	SB.developer_hire_requested.connect(_on_hire_requested)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_hire_requested() -> void:
	title_label.text = "Найми разработчика"
	_build_cards()
	visible = true


func _build_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for dev_data: DeveloperData in DR.developers.values():
		var card: HireCard = HIRE_CARD.instantiate()
		card.setup(dev_data)
		card.chosen.connect(_on_dev_chosen)
		card_container.add_child(card)


func _on_dev_chosen(dev_data: DeveloperData) -> void:
	var desks: Array[Node] = get_tree().get_nodes_in_group("desk")
	if desks.is_empty():
		Log.log_warn(name, "No empty desks available")
		visible = false
		return
	var desk: Developer = desks[0] as Developer
	desk.hire(dev_data.duplicate())
	visible = false
```

Note: `dev_data.duplicate()` ensures each developer has its own DeveloperData instance.

- [ ] **Step 4: Create ui_hire_choice.tscn**

Same structure as ui_upgrade_choice.tscn:
- Root: CanvasLayer (layer=20, UiHireChoice script)
- ColorRect (full screen background)
- CenterContainer (full screen)
  - VBoxContainer
    - TitleLabel (unique)
    - CardContainer (HBoxContainer, unique)

- [ ] **Step 5: Commit**

```bash
git add components/ui/ui_hire_choice/
git commit -m "feat: add hire choice overlay for hire levels"
```

---

### Task 12: Game Over overlay

**Files:**
- Create: `components/ui/ui_game_over/ui_game_over.gd`
- Create: `components/ui/ui_game_over/ui_game_over.tscn`

- [ ] **Step 1: Create ui_game_over.gd**

```gdscript
class_name UiGameOver
extends CanvasLayer

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	add_to_group("game_over")
	SB.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_game_over(final_valuation: int) -> void:
	valuation_label.text = "Стоимость компании: $%d" % final_valuation
	level_label.text = "Уровень: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	visible = true


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
```

- [ ] **Step 2: Create ui_game_over.tscn**

- Root: CanvasLayer (layer=20, UiGameOver script)
- ColorRect (full screen, dark overlay)
- CenterContainer (full screen)
  - PanelContainer
    - MarginContainer (margins 24)
      - VBoxContainer (separation 16)
        - TitleLabel (text "Время вышло!", font_size=36, horizontal_alignment=CENTER)
        - ValuationLabel (Label, unique, font_size=28, horizontal_alignment=CENTER)
        - LevelLabel (Label, unique, font_size=22, horizontal_alignment=CENTER)
        - TeamLabel (Label, unique, horizontal_alignment=CENTER)
        - RestartButton (Button, unique, text "Заново", font_size=22, custom_minimum_size=200×50)

- [ ] **Step 3: Commit**

```bash
git add components/ui/ui_game_over/
git commit -m "feat: add game over result screen"
```

---

### Task 13: PopupManager — remove empty desk hiring

**Files:**
- Modify: `components/hud/popup_manager.gd`

- [ ] **Step 1: Update popup_manager.gd**

Remove the PopupDeveloperEmpty branch. Empty desks now do nothing (hiring is via overlay).

```gdscript
class_name PopupManager
extends UiPopupManager

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")


func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)


func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Developer:
		var dev: Developer = target as Developer
		if dev.data == null:
			return
		var popup: PopupDeveloper = POPUP_DEVELOPER.instantiate()
		popup.setup(dev)
		show_popup(target, popup, popup_position)


func _after_popup_closed() -> void:
	SB.selection_cleared.emit()
```

- [ ] **Step 2: Commit**

```bash
git add components/hud/popup_manager.gd
git commit -m "refactor: popup_manager ignores empty desks"
```

---

### Task 14: Level scene — wire everything

**Files:**
- Modify: `levels/test_level.gd`
- Modify: `levels/test_level.tscn`

- [ ] **Step 1: Update test_level.tscn**

1. Remove the `UiUpgradeTree` node.
2. Add 3 new instances as children of TestLevel:
   - `UiUpgradeChoice` (from `res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn`)
   - `UiHireChoice` (from `res://components/ui/ui_hire_choice/ui_hire_choice.tscn`)
   - `UiGameOver` (from `res://components/ui/ui_game_over/ui_game_over.tscn`)

- [ ] **Step 2: Update test_level.gd**

```gdscript
extends Node2D

const STARTER_DEV: DeveloperData = preload("res://game_data/developer/developer_data_vibecoder.tres")


func _ready() -> void:
	add_to_group("level")
	AM.play_playlist([Constants.Music.FR, Constants.Music.FR3, Constants.Music.SG, Constants.Music.SPB])
	_auto_hire_starter()
	PD.start_game()


func _auto_hire_starter() -> void:
	var desks: Array[Node] = get_tree().get_nodes_in_group("desk")
	if desks.is_empty():
		Log.log_warn(name, "No desks found for starter dev")
		return
	var desk: Developer = desks[0] as Developer
	desk.hire(STARTER_DEV.duplicate())
```

- [ ] **Step 3: Commit**

```bash
git add levels/test_level.gd levels/test_level.tscn
git commit -m "feat: wire level for idle roguelike with auto-hire and overlays"
```

---

### Task 15: Delete old files

**Files:**
- Delete: `components/ui/ui_upgrade_tree/` (entire folder)
- Delete: `game_data/upgrade_tree/` (entire folder)
- Delete: `game_data/phase/` (entire folder)
- Delete: `components/developer/ui/popup_developer_empty.gd`
- Delete: `components/developer/ui/popup_developer_empty.tscn`

- [ ] **Step 1: Delete upgrade tree UI**

```bash
rm -rf components/ui/ui_upgrade_tree/
```

- [ ] **Step 2: Delete old upgrade tree data**

```bash
rm -rf game_data/upgrade_tree/
```

- [ ] **Step 3: Delete phase data**

```bash
rm -rf game_data/phase/
```

- [ ] **Step 4: Delete popup_developer_empty**

```bash
rm components/developer/ui/popup_developer_empty.gd
rm components/developer/ui/popup_developer_empty.tscn
```

- [ ] **Step 5: Verify — run the game**

Run: Open the project in Godot. Ensure no errors about missing files. Run the game:
- Timer counts down in HUD
- One vibecoder auto-hired and attacking
- Tasks spawn with scaled HP
- Level-up shows upgrade choice (4 cards)
- At hire levels, hire overlay appears after upgrade pick
- Timer hits 0 → result screen shows → "Заново" reloads

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: delete old upgrade tree, phase data, and empty desk popup"
```
