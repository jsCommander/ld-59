# Progression Rebalance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken sprint-based progression with a continuous task-bag system, tiered upgrades (35 .tres files across 7 chains × 5 rarities), hand-tuned XP/HP curves, and speed cap — targeting 1 trillion capitalization over a 10-minute run with 25 level-ups.

**Architecture:** Constants holds all balance anchors and lookup tables. Balance.gd provides pure static calculations. PlayerData owns the task bag lifecycle (generate bag → feed queue → bag empty → new bag at current time-based level). Upgrade .tres files form prerequisite chains by rarity tier. DataRegistry pools available upgrades filtering by prerequisites/taken. Sprint system is fully removed — signals, state, UI.

**Tech Stack:** Godot 4.x, GDScript

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Modify | `globals/constants.gd` | New enums, balance anchors, lookup tables; remove sprint constants |
| Modify | `game_data/developer/developer_data.gd` | Update `base_attack_speed` default to `2.0` |
| Modify | `game_data/developer/developer_data_vibecoder.tres` | Add `base_attack_speed = 2.0` |
| Modify | `game_data/developer/developer_data_regular.tres` | Add `base_attack_speed = 2.0` |
| Modify | `game_data/developer/developer_data_senior.tres` | Add `base_attack_speed = 2.0` |
| Modify | `game_data/task/task_data.gd` | Add `level: int`, remove `difficulty: int` |
| Modify | `game_data/upgrades/upgrade_data.gd` | Add `rarity: Constants.UpgradeRarity` field |
| Modify | `globals/balance.gd` | New `get_task_hp()`, rewrite `get_xp_for_level()`, add speed cap; remove `scale_task_hp()`, `get_sprint_duration()` |
| Modify | `autoloads/signal_bus.gd` | Remove sprint signals |
| Modify | `autoloads/player_data.gd` | Remove sprint system, add task bag, rewrite level-up flow with hire+upgrade on hire levels |
| Modify | `autoloads/data_registry.gd` | Remove SPRINT pool, show 3 cards, filter taken upgrades from pool |
| Modify | `components/developer/developer.gd` | Apply speed cap |
| Modify | `components/ui/ui_sprint_panel/ui_sprint_panel.gd` | Convert to continuous task panel (no sprint info) |
| Modify | `components/ui/ui_sprint_panel/ui_sprint_panel.tscn` | Remove sprint label and timer bar |
| Modify | `components/ui/ui_upgrade_choice/upgrade_card.gd` | Add rarity border color |
| Modify | `components/ui/ui_ceo_commentator/ui_ceo_commentator.gd` | Remove sprint references |
| Modify | `components/ui/ui_hud/ui_hud.gd` | Adjust popup flow for hire+upgrade on same level |
| Create | `game_data/upgrades/global_damage_common.tres` | Global Damage chain — Common ×3 |
| Create | `game_data/upgrades/global_damage_uncommon.tres` | Global Damage chain — Uncommon ×5 |
| Create | `game_data/upgrades/global_damage_rare.tres` | Global Damage chain — Rare ×9 |
| Create | `game_data/upgrades/global_damage_epic.tres` | Global Damage chain — Epic ×15 |
| Create | `game_data/upgrades/global_damage_legendary.tres` | Global Damage chain — Legendary ×25 |
| Create | `game_data/upgrades/global_speed_common.tres` | Global Speed chain — Common ×1.1 |
| Create | `game_data/upgrades/global_speed_uncommon.tres` | Global Speed chain — Uncommon ×1.2 |
| Create | `game_data/upgrades/global_speed_rare.tres` | Global Speed chain — Rare ×1.3 |
| Create | `game_data/upgrades/global_speed_epic.tres` | Global Speed chain — Epic ×1.4 |
| Create | `game_data/upgrades/global_speed_legendary.tres` | Global Speed chain — Legendary ×1.5 |
| Create | `game_data/upgrades/regular_damage_common.tres` | Regular Damage chain — Common ×3 |
| Create | `game_data/upgrades/regular_damage_uncommon.tres` | Regular Damage chain — Uncommon ×5 |
| Create | `game_data/upgrades/regular_damage_rare.tres` | Regular Damage chain — Rare ×9 |
| Create | `game_data/upgrades/regular_damage_epic.tres` | Regular Damage chain — Epic ×15 |
| Create | `game_data/upgrades/regular_damage_legendary.tres` | Regular Damage chain — Legendary ×25 |
| Create | `game_data/upgrades/regular_speed_common.tres` | Regular Speed chain — Common ×1.1 |
| Create | `game_data/upgrades/regular_speed_uncommon.tres` | Regular Speed chain — Uncommon ×1.2 |
| Create | `game_data/upgrades/regular_speed_rare.tres` | Regular Speed chain — Rare ×1.3 |
| Create | `game_data/upgrades/regular_speed_epic.tres` | Regular Speed chain — Epic ×1.4 |
| Create | `game_data/upgrades/regular_speed_legendary.tres` | Regular Speed chain — Legendary ×1.5 |
| Create | `game_data/upgrades/senior_damage_common.tres` | Senior Damage chain — Common ×3 |
| Create | `game_data/upgrades/senior_damage_uncommon.tres` | Senior Damage chain — Uncommon ×5 |
| Create | `game_data/upgrades/senior_damage_rare.tres` | Senior Damage chain — Rare ×9 |
| Create | `game_data/upgrades/senior_damage_epic.tres` | Senior Damage chain — Epic ×15 |
| Create | `game_data/upgrades/senior_damage_legendary.tres` | Senior Damage chain — Legendary ×25 |
| Create | `game_data/upgrades/vibecoder_damage_common.tres` | Vibecoder Damage chain — Common ×3 |
| Create | `game_data/upgrades/vibecoder_damage_uncommon.tres` | Vibecoder Damage chain — Uncommon ×5 |
| Create | `game_data/upgrades/vibecoder_damage_rare.tres` | Vibecoder Damage chain — Rare ×9 |
| Create | `game_data/upgrades/vibecoder_damage_epic.tres` | Vibecoder Damage chain — Epic ×15 |
| Create | `game_data/upgrades/vibecoder_damage_legendary.tres` | Vibecoder Damage chain — Legendary ×25 |
| Create | `game_data/upgrades/game_duration_common.tres` | Game Duration chain — Common ×3 |
| Create | `game_data/upgrades/game_duration_uncommon.tres` | Game Duration chain — Uncommon ×5 |
| Create | `game_data/upgrades/game_duration_rare.tres` | Game Duration chain — Rare ×9 |
| Create | `game_data/upgrades/game_duration_epic.tres` | Game Duration chain — Epic ×15 |
| Create | `game_data/upgrades/game_duration_legendary.tres` | Game Duration chain — Legendary ×25 |
| Delete | `game_data/upgrades/global_damage_2x.tres` | Old upgrade |
| Delete | `game_data/upgrades/global_speed_15x.tres` | Old upgrade |
| Delete | `game_data/upgrades/regular_damage_3x.tres` | Old upgrade |
| Delete | `game_data/upgrades/regular_speed_2x.tres` | Old upgrade |
| Delete | `game_data/upgrades/senior_damage_3x.tres` | Old upgrade |
| Delete | `game_data/upgrades/vibecoder_damage_3x.tres` | Old upgrade |
| Delete | `game_data/upgrades/sprint_duration_15x.tres` | Old upgrade |

---

### Task 1: Update Constants — new enums and balance anchors

**Files:**
- Modify: `globals/constants.gd`

Replace sprint-related enums and constants with the new balance system.

- [ ] **Step 1: Update enums**

Replace the `UpgradeType` and `UpgradeStat` enums:

```gdscript
enum UpgradeType { GLOBAL, DEV }
enum UpgradeStat { DAMAGE, SPEED, GAME_DURATION }
enum UpgradeRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
```

- [ ] **Step 2: Replace balance constants**

Remove:
```gdscript
const XP_BASE: int = int(BASE_HP * 0.3)
const MAX_SPRINT_TASKS: int = 8
const SPRINT_DURATION: float = 60.0
```

Add:
```gdscript
const XP_BASE: int = 100
const SPEED_CAP: float = 0.1

const MAX_TASK_QUEUE: int = 8
const TASK_BAG_SIZE: int = 10
const MAX_LEVEL: int = 25
const BASE_TOTAL_GAME_TIME: float = 600.0

const HIRE_LEVELS: Array[int] = [0, 2, 4, 6, 8, 10, 12, 13, 14]

const TASK_LEVEL_THRESHOLDS: Array[float] = [
	BASE_TOTAL_GAME_TIME * 0.0,
	BASE_TOTAL_GAME_TIME * 0.1,
	BASE_TOTAL_GAME_TIME * 0.2,
	BASE_TOTAL_GAME_TIME * 0.3,
	BASE_TOTAL_GAME_TIME * 0.4,
	BASE_TOTAL_GAME_TIME * 0.5,
	BASE_TOTAL_GAME_TIME * 0.6,
	BASE_TOTAL_GAME_TIME * 0.7,
	BASE_TOTAL_GAME_TIME * 0.8,
	BASE_TOTAL_GAME_TIME * 0.9,
]

# Placeholder values — tune during playtesting
# Derived from: expected DPS at minute N × TTK (3 sec)
const TASK_HP_MULTIPLIERS: Array[int] = [
	1,    # level 1: HP = 100 × 1 = 100
	3,    # level 2: HP = 100 × 3 = 300
	6,    # level 3
	30,   # level 4
	60,   # level 5
	600,  # level 6
	1200, # level 7
	30000, # level 8
	60000, # level 9
	150000, # level 10
]

# Placeholder values — tune during playtesting
# Cumulative XP needed to reach each level
const LEVEL_THRESHOLDS: Array[int] = [
	XP_BASE * 0,      # lvl 1
	XP_BASE * 2,      # lvl 2
	XP_BASE * 5,      # lvl 3
	XP_BASE * 10,     # lvl 4
	XP_BASE * 18,     # lvl 5
	XP_BASE * 30,     # lvl 6
	XP_BASE * 50,     # lvl 7
	XP_BASE * 80,     # lvl 8
	XP_BASE * 130,    # lvl 9
	XP_BASE * 200,    # lvl 10
	XP_BASE * 320,    # lvl 11
	XP_BASE * 500,    # lvl 12
	XP_BASE * 800,    # lvl 13
	XP_BASE * 1300,   # lvl 14
	XP_BASE * 2000,   # lvl 15
	XP_BASE * 3200,   # lvl 16
	XP_BASE * 5000,   # lvl 17
	XP_BASE * 8000,   # lvl 18
	XP_BASE * 13000,  # lvl 19
	XP_BASE * 20000,  # lvl 20
	XP_BASE * 32000,  # lvl 21
	XP_BASE * 50000,  # lvl 22
	XP_BASE * 80000,  # lvl 23
	XP_BASE * 130000, # lvl 24
	XP_BASE * 200000, # lvl 25
]

const RARITY_COLORS: Dictionary = {
	UpgradeRarity.COMMON: Color(0.6, 0.6, 0.6),
	UpgradeRarity.UNCOMMON: Color(0.2, 0.8, 0.2),
	UpgradeRarity.RARE: Color(0.2, 0.4, 1.0),
	UpgradeRarity.EPIC: Color(0.6, 0.2, 0.8),
	UpgradeRarity.LEGENDARY: Color(1.0, 0.5, 0.0),
}
```

Also update `HIRE_LEVELS` from `[3, 6, 9, 12, 15]` to the new value above, and rename `GAME_DURATION` to `BASE_TOTAL_GAME_TIME`.

Update `BASE_ATTACK_SPEED` from `0.5` to `2.0` (the spec's entire DPS math is based on `base_attack_speed = 2.0`, starting DPS = 10/2.0 = 5):

```gdscript
const BASE_ATTACK_SPEED: float = 2.0
```

- [ ] **Step 3: Update DeveloperData default and .tres files**

In `game_data/developer/developer_data.gd`, change the default:

```gdscript
@export var base_attack_speed: float = 2.0
```

In each developer .tres file (`developer_data_vibecoder.tres`, `developer_data_regular.tres`, `developer_data_senior.tres`), add or update:

```
base_attack_speed = 2.0
```

- [ ] **Step 4: Commit**

```
refactor: update Constants with new balance anchors, enums, and lookup tables
```

---

### Task 2: Update TaskData — add level, remove difficulty

**Files:**
- Modify: `game_data/task/task_data.gd`

- [ ] **Step 1: Replace difficulty with level**

Replace:
```gdscript
@export var difficulty: int = 1
```

With:
```gdscript
@export var level: int = 1
```

- [ ] **Step 2: Update the three task .tres templates**

In `game_data/task/task_data_feature.tres`, `task_data_bug.tres`, `task_data_refactor.tres`:
- Remove any `difficulty = ...` line (replace with `level = 1` or omit for default)

- [ ] **Step 3: Commit**

```
refactor: replace task difficulty with level in TaskData
```

---

### Task 3: Update UpgradeData — add rarity field

**Files:**
- Modify: `game_data/upgrades/upgrade_data.gd`

- [ ] **Step 1: Add rarity export**

Add after the `multiplier` line:

```gdscript
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
```

- [ ] **Step 2: Commit**

```
feat: add rarity field to UpgradeData
```

---

### Task 4: Rewrite Balance.gd

**Files:**
- Modify: `globals/balance.gd`

- [ ] **Step 1: Replace the entire file**

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
	var interval: float = base / (speed_mult * boost_mult)
	return maxf(interval, Constants.SPEED_CAP)


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func get_task_hp(task_level: int) -> float:
	var index: int = clampi(task_level - 1, 0, Constants.TASK_HP_MULTIPLIERS.size() - 1)
	return float(Constants.BASE_HP * Constants.TASK_HP_MULTIPLIERS[index])


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.LEVEL_THRESHOLDS.size():
		return 0
	return Constants.LEVEL_THRESHOLDS[level - 1]


static func get_task_level(elapsed_time: float) -> int:
	var level: int = 1
	for i: int in Constants.TASK_LEVEL_THRESHOLDS.size():
		if elapsed_time >= Constants.TASK_LEVEL_THRESHOLDS[i]:
			level = i + 1
	return level


static func get_game_duration(global_upgrades: Array[UpgradeData]) -> float:
	var mult: float = _calc_mult(Constants.UpgradeStat.GAME_DURATION, global_upgrades, [])
	return Constants.BASE_TOTAL_GAME_TIME * mult


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

- [ ] **Step 2: Commit**

```
refactor: rewrite Balance with task levels, XP lookup, speed cap, game duration
```

---

### Task 5: Update SignalBus — remove sprint signals

**Files:**
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Remove sprint signals**

Remove:
```gdscript
signal sprint_started(sprint_number: int)
signal sprint_ended(sprint_number: int, bonus: int)
signal sprint_timer_changed(remaining: float, total: float)
```

The remaining signals stay as-is: `task_queue_changed`, `task_destroyed`, `valuation_changed`, `game_timer_changed`, `level_up`, `game_over`, `upgrade_chosen`, `developer_hire_requested`, `developer_chosen`, `entity_selected`, `selection_cleared`.

- [ ] **Step 2: Commit**

```
refactor: remove sprint signals from SignalBus
```

---

### Task 6: Rewrite PlayerData — remove sprints, add task bag

**Files:**
- Modify: `autoloads/player_data.gd`

This is the largest change. Sprint system is fully removed. Task bag replaces sprint-based generation. Level-up gives both hire and upgrade on hire levels.

- [ ] **Step 1: Replace the entire file**

```gdscript
class_name PlayerData extends Node

const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_BUG: TaskData = preload("res://game_data/task/task_data_bug.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

# --- State ---

var valuation: int = 0
var level: int = 0
var timer_remaining: float = Constants.BASE_TOTAL_GAME_TIME
var _game_active: bool = false
var _awaiting_choice: bool = false

var task_queue: Array[TaskData] = []
var _task_bag: Array[TaskData] = []

var developers: Array[Developer] = []
var hired_data: Array[DeveloperData] = []

var upgrades_taken: Array[UpgradeData] = []
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
var _empty_upgrades: Array[UpgradeData] = []

var _tick_timer: Timer

# --- Public ---

func get_dev_upgrades(dev_type: Constants.DevType) -> Array[UpgradeData]:
	if dev_type in dev_upgrades:
		return dev_upgrades[dev_type] as Array[UpgradeData]
	return _empty_upgrades


func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)


func get_elapsed_time() -> float:
	var game_duration: float = Balance.get_game_duration(global_upgrades)
	return game_duration - timer_remaining


func start_game() -> void:
	reset()
	developers.assign(Groups.get_all_of_type(get_tree(), "developer", Developer))
	_game_active = true
	_tick_timer.start()
	_generate_task_bag()
	_fill_queue_from_bag()


func reset() -> void:
	valuation = 0
	level = 0
	timer_remaining = Constants.BASE_TOTAL_GAME_TIME
	_game_active = false
	_awaiting_choice = false
	task_queue.clear()
	_task_bag.clear()
	developers.clear()
	hired_data.clear()
	upgrades_taken.clear()
	global_upgrades.clear()
	dev_upgrades.clear()
	_tick_timer.stop()


func take_task(task: TaskData) -> TaskData:
	if task not in task_queue:
		return null
	task_queue.erase(task)
	SB.task_queue_changed.emit(task_queue)
	_fill_queue_from_bag()
	return task


func hire_developer(dev_data: DeveloperData) -> void:
	var desk: Developer = Groups.get_first_filtered(get_tree(), "developer", func(d: Developer) -> bool: return not d.data) as Developer
	if not desk:
		Log.log_warn(name, "No empty desks available")
		return
	desk.data = dev_data
	developers.append(desk)
	hired_data.append(dev_data)
	Log.log_info(name, "Hired %s" % Constants.DevType.keys()[dev_data.dev_type])

# --- Lifecycle ---

func _ready() -> void:
	SB.upgrade_chosen.connect(_on_upgrade_chosen)
	SB.task_destroyed.connect(_on_task_destroyed)
	SB.developer_chosen.connect(_on_developer_chosen)
	_tick_timer = _create_tick_timer()


func _process(delta: float) -> void:
	if not _game_active or _awaiting_choice:
		return

	timer_remaining -= delta
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_game_active = false
		_tick_timer.stop()
		get_tree().paused = true
		SB.game_over.emit(valuation)
		return

# --- Handlers ---

func _on_tick() -> void:
	SB.game_timer_changed.emit(timer_remaining)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	upgrades_taken.append(upgrade)
	_apply_upgrade(upgrade)
	_awaiting_choice = false
	_resume_after_choice()


func _on_developer_chosen(dev_data: DeveloperData) -> void:
	hire_developer(dev_data)
	_awaiting_choice = false
	# After hiring, show upgrade choice on the same level
	_show_upgrade_choice()


func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s (level %d)" % [Constants.TaskType.keys()[task.task_type], task.level])

# --- Private ---

func _create_tick_timer() -> Timer:
	var timer: Timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	add_child(timer)
	return timer


# --- Task bag system ---

func _generate_task_bag() -> void:
	var task_templates: Array[TaskData] = [TASK_DATA_FEATURE, TASK_DATA_BUG, TASK_DATA_REFACTOR]
	var task_level: int = Balance.get_task_level(get_elapsed_time())
	_task_bag.clear()
	for i: int in Constants.TASK_BAG_SIZE:
		var template: TaskData = task_templates[randi() % task_templates.size()]
		var task: TaskData = template.duplicate()
		task.level = task_level
		var hp: float = Balance.get_task_hp(task_level)
		task.current_hp = hp
		task.max_hp = hp
		_task_bag.append(task)
	Log.log_info(name, "Generated task bag: %d tasks at level %d" % [_task_bag.size(), task_level])


func _fill_queue_from_bag() -> void:
	while task_queue.size() < Constants.MAX_TASK_QUEUE and not _task_bag.is_empty():
		task_queue.append(_task_bag.pop_front())
	SB.task_queue_changed.emit(task_queue)
	if _task_bag.is_empty():
		_generate_task_bag()


# --- Upgrade application ---

func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


# --- Level-up ---

func _check_level_up() -> void:
	var next_threshold: int = get_xp_for_level(level + 1)
	if next_threshold <= 0:
		return  # max level reached
	if valuation >= next_threshold:
		level += 1
		_awaiting_choice = true
		get_tree().paused = true
		SB.level_up.emit(level)
		Log.log_info(name, "Level up! Level %d" % level)
		if level in Constants.HIRE_LEVELS:
			SB.developer_hire_requested.emit()
		else:
			_show_upgrade_choice()


func _show_upgrade_choice() -> void:
	_awaiting_choice = true
	# UiHud listens to level_up and shows upgrade choice popup.
	# The upgrade_chosen signal triggers _on_upgrade_chosen which calls _resume_after_choice.


func _resume_after_choice() -> void:
	get_tree().paused = false
	# Check if we leveled up again while paused (from accumulated rewards)
	_check_level_up()


func _apply_task_rewards(task: TaskData) -> void:
	var reward: int = int(task.max_hp)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		if not _awaiting_choice:
			_check_level_up()
```

- [ ] **Step 2: Verify the level-up + hire flow**

The new flow on hire levels:
1. `_check_level_up()` → detects level-up → emits `level_up` + `developer_hire_requested`
2. UiHud shows hire popup first
3. Player picks dev → `_on_developer_chosen()` → hires dev → calls `_show_upgrade_choice()`
4. UiHud shows upgrade popup (it already listens to `level_up` and stored the level)
5. Player picks upgrade → `_on_upgrade_chosen()` → applies → `_resume_after_choice()`

**Important:** UiHud needs to be updated (Task 10) to handle the sequence: hire first, then upgrade on the same level-up.

- [ ] **Step 3: Commit**

```
refactor: rewrite PlayerData — remove sprints, add task bag, new level-up flow
```

---

### Task 7: Update UiHud — hire + upgrade sequence on same level

**Files:**
- Modify: `components/ui/ui_hud/ui_hud.gd`

On hire levels, the player sees hire popup first, then upgrade popup. UiHud needs to track the pending level for showing upgrade after hire completes.

- [ ] **Step 1: Update ui_hud.gd**

```gdscript
class_name UiHud
extends CanvasLayer

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")
const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")

# --- @onready ---

@onready var popup_manager: UiPopupManager = %UiPopupManager

# --- State ---

var _pending_upgrade_level: int = -1

# --- Lifecycle ---

func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.level_up.connect(_on_level_up)
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.developer_chosen.connect(_on_developer_hired)
	SB.game_over.connect(_on_game_over)
	popup_manager.popup_closed.connect(_on_popup_closed)

# --- Handlers ---

func _on_popup_closed() -> void:
	SB.selection_cleared.emit()

func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Developer:
		var dev: Developer = target as Developer
		if dev.data == null:
			return
		var popup: PopupDeveloper = POPUP_DEVELOPER.instantiate()
		popup.setup(dev)
		popup_manager.show_popup(target, popup, popup_position)

func _on_level_up(level: int) -> void:
	_pending_upgrade_level = level
	# If this is a hire level, wait for hire popup to complete first
	# developer_hire_requested will be emitted by PlayerData if needed
	if level not in Constants.HIRE_LEVELS:
		_show_upgrade_popup(level)

func _on_hire_requested() -> void:
	var popup: UiHireChoice = UI_HIRE_CHOICE.instantiate()
	add_child(popup)
	popup.show_hire()

func _on_developer_hired(_dev_data: DeveloperData) -> void:
	# After hiring, show upgrade choice for the same level
	if _pending_upgrade_level > 0:
		# Small delay to let hire popup close
		await get_tree().process_frame
		_show_upgrade_popup(_pending_upgrade_level)

func _on_game_over(final_valuation: int) -> void:
	var popup: UiGameOver = UI_GAME_OVER.instantiate()
	add_child(popup)
	popup.show_game_over(final_valuation)

# --- Private ---

func _show_upgrade_popup(level: int) -> void:
	var popup: UiUpgradeChoice = UI_UPGRADE_CHOICE.instantiate()
	add_child(popup)
	popup.show_for_level(level)
	_pending_upgrade_level = -1
```

- [ ] **Step 2: Commit**

```
feat: update UiHud to handle hire + upgrade sequence on same level
```

---

### Task 8: Delete old upgrade .tres files

**Files:**
- Delete: all 7 files in `game_data/upgrades/*.tres`

- [ ] **Step 1: Delete old .tres files**

```bash
rm game_data/upgrades/global_damage_2x.tres
rm game_data/upgrades/global_speed_15x.tres
rm game_data/upgrades/regular_damage_3x.tres
rm game_data/upgrades/regular_speed_2x.tres
rm game_data/upgrades/senior_damage_3x.tres
rm game_data/upgrades/vibecoder_damage_3x.tres
rm game_data/upgrades/sprint_duration_15x.tres
```

- [ ] **Step 2: Commit**

```
chore: delete old upgrade .tres files
```

---

### Task 9: Create 35 new upgrade .tres files

**Files:**
- Create: 35 `.tres` files in `game_data/upgrades/`

Each `.tres` file follows this template (values vary per chain/tier):

```
[gd_resource type="Resource" script_class="UpgradeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://game_data/upgrades/upgrade_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = "<chain>_<rarity>"
display_name = "<unique name>"
description = "<unique description>"
upgrade_type = <0=GLOBAL, 1=DEV>
target_dev_type = <0=VIBECODER, 1=REGULAR, 2=SENIOR>  (only for DEV type)
stat = <0=DAMAGE, 1=SPEED, 2=GAME_DURATION>
multiplier = <value>
rarity = <0=COMMON, 1=UNCOMMON, 2=RARE, 3=EPIC, 4=LEGENDARY>
prerequisites = []  (or reference to previous tier)
```

Prerequisites are tricky in .tres format — they reference other .tres by `ExtResource`. Each non-common tier needs a `load_steps` increment and an additional `ext_resource` for the prerequisite.

**Example — uncommon with prerequisite:**

```
[gd_resource type="Resource" script_class="UpgradeData" load_steps=3 format=3]

[ext_resource type="Script" path="res://game_data/upgrades/upgrade_data.gd" id="1"]
[ext_resource type="Resource" path="res://game_data/upgrades/global_damage_common.tres" id="2_prereq"]

[resource]
script = ExtResource("1")
id = "global_damage_uncommon"
display_name = "Пивот стратегии"
description = "×5 урон всем"
upgrade_type = 0
stat = 0
multiplier = 5.0
rarity = 1
prerequisites = [ExtResource("2_prereq")]
```

- [ ] **Step 1: Create Global Damage chain (5 files)**

`global_damage_common.tres`:
- id: `global_damage_common`, display_name: `"Мотивационная речь"`, description: `"×3 урон всем"`, upgrade_type: 0, stat: 0, multiplier: 3.0, rarity: 0, prerequisites: []

`global_damage_uncommon.tres`:
- id: `global_damage_uncommon`, display_name: `"Пивот стратегии"`, description: `"×5 урон всем"`, upgrade_type: 0, stat: 0, multiplier: 5.0, rarity: 1, prerequisites: [global_damage_common]

`global_damage_rare.tres`:
- id: `global_damage_rare`, display_name: `"Аджайл-трансформация"`, description: `"×9 урон всем"`, upgrade_type: 0, stat: 0, multiplier: 9.0, rarity: 2, prerequisites: [global_damage_uncommon]

`global_damage_epic.tres`:
- id: `global_damage_epic`, display_name: `"Серия A"`, description: `"×15 урон всем"`, upgrade_type: 0, stat: 0, multiplier: 15.0, rarity: 3, prerequisites: [global_damage_rare]

`global_damage_legendary.tres`:
- id: `global_damage_legendary`, display_name: `"IPO"`, description: `"×25 урон всем"`, upgrade_type: 0, stat: 0, multiplier: 25.0, rarity: 4, prerequisites: [global_damage_epic]

- [ ] **Step 2: Create Global Speed chain (5 files)**

`global_speed_common.tres`:
- id: `global_speed_common`, display_name: `"Дейлик в 9 утра"`, description: `"×1.1 скорость всем"`, upgrade_type: 0, stat: 1, multiplier: 1.1, rarity: 0, prerequisites: []

`global_speed_uncommon.tres`:
- id: `global_speed_uncommon`, display_name: `"Канбан-доска"`, description: `"×1.2 скорость всем"`, upgrade_type: 0, stat: 1, multiplier: 1.2, rarity: 1, prerequisites: [global_speed_common]

`global_speed_rare.tres`:
- id: `global_speed_rare`, display_name: `"CI/CD пайплайн"`, description: `"×1.3 скорость всем"`, upgrade_type: 0, stat: 1, multiplier: 1.3, rarity: 2, prerequisites: [global_speed_uncommon]

`global_speed_epic.tres`:
- id: `global_speed_epic`, display_name: `"Автоматизация тестов"`, description: `"×1.4 скорость всем"`, upgrade_type: 0, stat: 1, multiplier: 1.4, rarity: 3, prerequisites: [global_speed_rare]

`global_speed_legendary.tres`:
- id: `global_speed_legendary`, display_name: `"Бесконечный стакан кофе"`, description: `"×1.5 скорость всем"`, upgrade_type: 0, stat: 1, multiplier: 1.5, rarity: 4, prerequisites: [global_speed_epic]

- [ ] **Step 3: Create Regular Damage chain (5 files)**

`regular_damage_common.tres`:
- id: `regular_damage_common`, display_name: `"Код-ревью ботом"`, description: `"×3 урон regular"`, upgrade_type: 1, target_dev_type: 1, stat: 0, multiplier: 3.0, rarity: 0, prerequisites: []

`regular_damage_uncommon.tres`:
- id: `regular_damage_uncommon`, display_name: `"Stack Overflow Premium"`, description: `"×5 урон regular"`, upgrade_type: 1, target_dev_type: 1, stat: 0, multiplier: 5.0, rarity: 1, prerequisites: [regular_damage_common]

`regular_damage_rare.tres`:
- id: `regular_damage_rare`, display_name: `"Второй монитор"`, description: `"×9 урон regular"`, upgrade_type: 1, target_dev_type: 1, stat: 0, multiplier: 9.0, rarity: 2, prerequisites: [regular_damage_uncommon]

`regular_damage_epic.tres`:
- id: `regular_damage_epic`, display_name: `"Механическая клавиатура"`, description: `"×15 урон regular"`, upgrade_type: 1, target_dev_type: 1, stat: 0, multiplier: 15.0, rarity: 3, prerequisites: [regular_damage_rare]

`regular_damage_legendary.tres`:
- id: `regular_damage_legendary`, display_name: `"Полное погружение"`, description: `"×25 урон regular"`, upgrade_type: 1, target_dev_type: 1, stat: 0, multiplier: 25.0, rarity: 4, prerequisites: [regular_damage_epic]

- [ ] **Step 4: Create Regular Speed chain (5 files)**

`regular_speed_common.tres`:
- id: `regular_speed_common`, display_name: `"Тихий офис"`, description: `"×1.1 скорость regular"`, upgrade_type: 1, target_dev_type: 1, stat: 1, multiplier: 1.1, rarity: 0, prerequisites: []

`regular_speed_uncommon.tres`:
- id: `regular_speed_uncommon`, display_name: `"Выделенная переговорка"`, description: `"×1.2 скорость regular"`, upgrade_type: 1, target_dev_type: 1, stat: 1, multiplier: 1.2, rarity: 1, prerequisites: [regular_speed_common]

`regular_speed_rare.tres`:
- id: `regular_speed_rare`, display_name: `"Noise-cancelling наушники"`, description: `"×1.3 скорость regular"`, upgrade_type: 1, target_dev_type: 1, stat: 1, multiplier: 1.3, rarity: 2, prerequisites: [regular_speed_uncommon]

`regular_speed_epic.tres`:
- id: `regular_speed_epic`, display_name: `"Удалёнка навсегда"`, description: `"×1.4 скорость regular"`, upgrade_type: 1, target_dev_type: 1, stat: 1, multiplier: 1.4, rarity: 3, prerequisites: [regular_speed_rare]

`regular_speed_legendary.tres`:
- id: `regular_speed_legendary`, display_name: `"Копия сознания в облаке"`, description: `"×1.5 скорость regular"`, upgrade_type: 1, target_dev_type: 1, stat: 1, multiplier: 1.5, rarity: 4, prerequisites: [regular_speed_epic]

- [ ] **Step 5: Create Senior Damage chain (5 files)**

`senior_damage_common.tres`:
- id: `senior_damage_common`, display_name: `"Lint правила"`, description: `"×3 урон senior"`, upgrade_type: 1, target_dev_type: 2, stat: 0, multiplier: 3.0, rarity: 0, prerequisites: []

`senior_damage_uncommon.tres`:
- id: `senior_damage_uncommon`, display_name: `"Архитектурный RFC"`, description: `"×5 урон senior"`, upgrade_type: 1, target_dev_type: 2, stat: 0, multiplier: 5.0, rarity: 1, prerequisites: [senior_damage_common]

`senior_damage_rare.tres`:
- id: `senior_damage_rare`, display_name: `"Система мониторинга"`, description: `"×9 урон senior"`, upgrade_type: 1, target_dev_type: 2, stat: 0, multiplier: 9.0, rarity: 2, prerequisites: [senior_damage_uncommon]

`senior_damage_epic.tres`:
- id: `senior_damage_epic`, display_name: `"Incident playbook"`, description: `"×15 урон senior"`, upgrade_type: 1, target_dev_type: 2, stat: 0, multiplier: 15.0, rarity: 3, prerequisites: [senior_damage_rare]

`senior_damage_legendary.tres`:
- id: `senior_damage_legendary`, display_name: `"10x инженер"`, description: `"×25 урон senior"`, upgrade_type: 1, target_dev_type: 2, stat: 0, multiplier: 25.0, rarity: 4, prerequisites: [senior_damage_epic]

- [ ] **Step 6: Create Vibecoder Damage chain (5 files)**

`vibecoder_damage_common.tres`:
- id: `vibecoder_damage_common`, display_name: `"ChatGPT подписка"`, description: `"×3 урон vibecoder"`, upgrade_type: 1, target_dev_type: 0, stat: 0, multiplier: 3.0, rarity: 0, prerequisites: []

`vibecoder_damage_uncommon.tres`:
- id: `vibecoder_damage_uncommon`, display_name: `"Cursor Pro"`, description: `"×5 урон vibecoder"`, upgrade_type: 1, target_dev_type: 0, stat: 0, multiplier: 5.0, rarity: 1, prerequisites: [vibecoder_damage_common]

`vibecoder_damage_rare.tres`:
- id: `vibecoder_damage_rare`, display_name: `"Prompt engineering курс"`, description: `"×9 урон vibecoder"`, upgrade_type: 1, target_dev_type: 0, stat: 0, multiplier: 9.0, rarity: 2, prerequisites: [vibecoder_damage_uncommon]

`vibecoder_damage_epic.tres`:
- id: `vibecoder_damage_epic`, display_name: `"Fine-tuned модель"`, description: `"×15 урон vibecoder"`, upgrade_type: 1, target_dev_type: 0, stat: 0, multiplier: 15.0, rarity: 3, prerequisites: [vibecoder_damage_rare]

`vibecoder_damage_legendary.tres`:
- id: `vibecoder_damage_legendary`, display_name: `"AGI в продакшене"`, description: `"×25 урон vibecoder"`, upgrade_type: 1, target_dev_type: 0, stat: 0, multiplier: 25.0, rarity: 4, prerequisites: [vibecoder_damage_epic]

- [ ] **Step 7: Create Game Duration chain (5 files)**

`game_duration_common.tres`:
- id: `game_duration_common`, display_name: `"Овертайм"`, description: `"×3 время игры"`, upgrade_type: 0, stat: 2, multiplier: 3.0, rarity: 0, prerequisites: []

`game_duration_uncommon.tres`:
- id: `game_duration_uncommon`, display_name: `"Ночная смена"`, description: `"×5 время игры"`, upgrade_type: 0, stat: 2, multiplier: 5.0, rarity: 1, prerequisites: [game_duration_common]

`game_duration_rare.tres`:
- id: `game_duration_rare`, display_name: `"Кранч перед релизом"`, description: `"×9 время игры"`, upgrade_type: 0, stat: 2, multiplier: 9.0, rarity: 2, prerequisites: [game_duration_uncommon]

`game_duration_epic.tres`:
- id: `game_duration_epic`, display_name: `"Бессонная неделя"`, description: `"×15 время игры"`, upgrade_type: 0, stat: 2, multiplier: 15.0, rarity: 3, prerequisites: [game_duration_rare]

`game_duration_legendary.tres`:
- id: `game_duration_legendary`, display_name: `"Вечный стартап"`, description: `"×25 время игры"`, upgrade_type: 0, stat: 2, multiplier: 25.0, rarity: 4, prerequisites: [game_duration_epic]

- [ ] **Step 8: Commit**

```
feat: create 35 tiered upgrade .tres files (7 chains × 5 rarities)
```

---

### Task 10: Update DataRegistry — new upgrade pool logic

**Files:**
- Modify: `autoloads/data_registry.gd`

Remove SPRINT pool category. Show 3 cards: 1 GLOBAL, 1 DEV, 1 random. Filter out already-taken upgrades.

- [ ] **Step 1: Rewrite get_level_up_upgrades and filtering**

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
	var all_available: Array[UpgradeData] = _get_all_available()
	# Third card: random from remaining pool (not already picked)
	var remaining: Array[UpgradeData] = []
	for u: UpgradeData in all_available:
		if u not in result:
			remaining.append(u)
	var random_pick: UpgradeData = _pick_random_from(remaining)
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
	# Already taken
	if _is_taken(upgrade.id):
		return false
	# Prerequisites not met
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

- [ ] **Step 2: Commit**

```
refactor: update DataRegistry — 3 cards, no SPRINT pool, filter taken upgrades
```

---

### Task 11: Update UpgradeCard — rarity border color

**Files:**
- Modify: `components/ui/ui_upgrade_choice/upgrade_card.gd`

- [ ] **Step 1: Add rarity border coloring in _ready**

Add after the existing `multiplier_label.text` line in `_ready()`:

```gdscript
	if _upgrade.rarity in Constants.RARITY_COLORS:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.border_color = Constants.RARITY_COLORS[_upgrade.rarity]
		style.set_border_width_all(3)
		style.set_corner_radius_all(4)
		style.bg_color = Color(0.1, 0.1, 0.12)
		style.set_content_margin_all(8)
		add_theme_stylebox_override("panel", style)
```

- [ ] **Step 2: Commit**

```
feat: add rarity border color to upgrade cards
```

---

### Task 12: Convert UiSprintPanel to continuous task panel

**Files:**
- Modify: `components/ui/ui_sprint_panel/ui_sprint_panel.gd`
- Modify: `components/ui/ui_sprint_panel/ui_sprint_panel.tscn`

Remove sprint label, sprint timer bar, and all sprint signal subscriptions. Keep only the task card container.

- [ ] **Step 1: Simplify ui_sprint_panel.gd**

```gdscript
class_name UiSprintPanel
extends HBoxContainer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer

# --- Lifecycle ---

func _ready() -> void:
	SB.task_queue_changed.connect(_rebuild_cards)

# --- Private ---

func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
```

- [ ] **Step 2: Update ui_sprint_panel.tscn**

Remove the `SprintLabel` and `SprintTimerBar` nodes. Root becomes `HBoxContainer` (was `VBoxContainer`). Keep only `CardContainer`. Scene tree:

```
UiSprintPanel (HBoxContainer) [ui_sprint_panel.gd]
  └── CardContainer (HBoxContainer) [unique name]
      alignment = CENTER
      theme_override_constants/separation = 8
```

- [ ] **Step 3: Commit**

```
refactor: convert UiSprintPanel to continuous task panel — remove sprint UI
```

---

### Task 13: Update UiCeoCommentator — remove sprint references

**Files:**
- Modify: `components/ui/ui_ceo_commentator/ui_ceo_commentator.gd`

- [ ] **Step 1: Remove sprint_ended connection and PD._sprint_active access**

Replace the file:

```gdscript
class_name UiCeoCommentator
extends Control

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
	speech_bubble.text = ""


func _process(delta: float) -> void:
	_comment_timer += delta
	if _comment_timer >= COMMENT_INTERVAL:
		_comment_timer -= COMMENT_INTERVAL
		_show_random_comment()


func _show_random_comment() -> void:
	if not PD._game_active:
		return
	var comments: Array[String] = GOOD_COMMENTS + BAD_COMMENTS
	speech_bubble.text = comments[randi() % comments.size()]
```

- [ ] **Step 2: Commit**

```
refactor: remove sprint references from UiCeoCommentator
```

---

### Task 14: Update game duration in PlayerData

**Files:**
- Modify: `autoloads/player_data.gd`

The game timer should respect `GAME_DURATION` upgrades. Currently `timer_remaining` is set to `Constants.BASE_TOTAL_GAME_TIME` in `reset()`. When a `GAME_DURATION` upgrade is taken, the remaining time should increase proportionally.

- [ ] **Step 1: Add game duration update to _apply_upgrade**

In `_apply_upgrade()`, after appending a GAME_DURATION upgrade to global_upgrades, recalculate remaining time. The key insight: `Balance.get_game_duration()` multiplies ALL GAME_DURATION upgrades, so after appending the new one it returns the new total. Dividing by the just-applied multiplier gives the old total.

```gdscript
func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
		if upgrade.stat == Constants.UpgradeStat.GAME_DURATION:
			_recalculate_game_duration()
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			var arr: Array[UpgradeData] = []
			dev_upgrades[upgrade.target_dev_type] = arr
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])


func _recalculate_game_duration() -> void:
	var new_total: float = Balance.get_game_duration(global_upgrades)
	# The upgrade was just appended, so dividing by its multiplier gives old total
	var just_applied: UpgradeData = global_upgrades.back()
	var old_total: float = new_total / just_applied.multiplier
	var elapsed: float = old_total - timer_remaining
	timer_remaining = new_total - elapsed
	Log.log_info(name, "Game duration: %.0f → %.0f sec (%.0f remaining)" % [old_total, new_total, timer_remaining])
```

- [ ] **Step 2: Commit**

```
feat: game duration upgrades extend remaining time
```

---

### Task 15: Verify and playtest

**Files:** None (verification only)

- [ ] **Step 0: Update COMPANY_MILESTONES in constants.gd**

The current milestones cap at 50,000 but the new system targets 1 trillion. Rescale them to remain meaningful throughout the run:

```gdscript
const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 500, "name": "Zynga"},
	{"valuation": 5000, "name": "Niantic"},
	{"valuation": 50000, "name": "Ubisoft"},
	{"valuation": 500000, "name": "EA"},
	{"valuation": 5000000, "name": "Valve"},
	{"valuation": 50000000, "name": "Epic Games"},
	{"valuation": 500000000, "name": "Apple"},
	{"valuation": 5000000000, "name": "Microsoft"},
	{"valuation": 100000000000, "name": "US GDP"},
	{"valuation": 1000000000000, "name": "Мировое господство"},
]
```

- [ ] **Step 1: Search for stale references**

Grep the entire project for:
- `sprint_number` — should only be in git history, not code
- `sprint_timer` — same
- `_sprint_active` — same
- `SPRINT_DURATION` — should be gone from constants
- `SPRINT_TASK_COMPOSITION` — should be gone
- `UpgradeType.SPRINT` — should be gone
- `scale_task_hp` — should be gone
- `difficulty` in task-related files — should be replaced with `level`

- [ ] **Step 2: Run the game**

Test checklist:
- Game starts, tasks appear in queue
- Devs pick tasks and work on them
- As tasks are completed, new ones fill from bag
- Task level increases over time (check task HP at minute 0 vs minute 3)
- Level-up triggers upgrade choice (3 cards with rarity borders)
- On hire levels (0, 2, 4, 6, 8, 10, 12, 13, 14): hire popup first, then upgrade popup
- Game duration upgrade extends remaining time
- Speed cap works (attack speed never goes below 0.1)
- XP bar progresses correctly toward next threshold
- CEO commentator works without sprint references
- Game over triggers at timer end
- Company milestones still flash

- [ ] **Step 3: Commit any fixes found during playtest**

```
fix: playtest fixes for progression rebalance
```
