# Autonomous Dev Combat — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each developer autonomously picks tasks from the queue, attacks locally, and reports kills/debt via signals. PD no longer handles combat — only state and rewards.

**Architecture:** Developer selects task via TaskSelectFunction resource, calls PD.take_task() to claim it, attacks locally in _process, shows TaskDisplay overhead. Balance class holds all formulas. PD stores upgrade arrays instead of cached multipliers.

**Tech Stack:** Godot 4, GDScript

**Spec:** `docs/superpowers/specs/2026-04-08-autonomous-dev-combat-design.md`

---

## File Structure

### Create

| File | Purpose |
|------|---------|
| `globals/balance.gd` | Static formula class: damage, debt, attack speed, task mult, HP scaling, XP |
| `game_data/task_select_function.gd` | TaskSelectFunction resource — picks best task from array |
| `game_data/task_select_function_default.tres` | Default instance (by task mult) |
| `components/developer/task_display.gd` | Shows current task icon + HP bar over developer |
| `components/developer/task_display.tscn` | Scene: TextureRect + ProgressBar |

### Modify

| File | Changes |
|------|---------|
| `globals/constants.gd` | Add `BASE_DEBT_PER_TASK`, `DEBT_REDUCTION_PER_REFACTOR`. Remove `BASE_DEBT_PER_HP`, `DEBT_PER_TASK` |
| `autoloads/signal_bus.gd` | Add `tech_debt_produced`. Remove `developer_attack`, `task_hp_changed` |
| `game_data/developer/developer_data.gd` | Add `@export var task_select: TaskSelectFunction` |
| `game_data/developer/*.tres` | Add task_select reference |
| `autoloads/player_data.gd` | Remove cached mults + combat. Add `global_upgrades`, `dev_upgrades`, `take_task()`. Rewrite `_apply_upgrade` |
| `components/developer/developer.gd` | Full rewrite: autonomous pick/attack/kill cycle |
| `components/developer/developer.tscn` | Add TaskDisplay child |
| `autoloads/audio_manager.gd` | Remove `developer_attack` handler, add attack sound on `task_destroyed` or keep existing |
| `components/hud/hud.gd` | Remove `task_hp_changed` handler (devs show their own HP now) |

---

## Tasks

### Task 1: Constants + SignalBus

**Files:**
- Modify: `globals/constants.gd`
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Update constants.gd**

Replace the balance constants section:

```gdscript
const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const BASE_DEBT_PER_TASK: float = 1.0
const DEBT_REDUCTION_PER_REFACTOR: float = 5.0
const XP_BASE: int = int(BASE_HP * 0.3)
const BASE_CLICKS_PER_TASK: int = 1
const BASE_AUTO_CLICK_INTERVAL: float = 2.0
const BASE_AUTO_CLICK_COUNT: int = 1
```

Remove `BASE_DEBT_PER_HP` and `DEBT_PER_TASK`.

- [ ] **Step 2: Update signal_bus.gd**

```gdscript
class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_tech_debt_changed
signal valuation_changed

signal backlog_clicked(count: int)
signal backlog_task_spawned

signal tech_debt_produced(delta: float)

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
```

Removed: `developer_attack`, `task_hp_changed`.
Added: `tech_debt_produced`.

- [ ] **Step 3: Commit**

```bash
git add globals/constants.gd autoloads/signal_bus.gd
git commit -m "refactor: constants and signals for autonomous dev combat"
```

---

### Task 2: Balance class

**Files:**
- Create: `globals/balance.gd`

- [ ] **Step 1: Create balance.gd**

```gdscript
class_name Balance


static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var damage_mult: float = _calc_mult(Constants.UpgradeStat.DAMAGE, global_upgrades, dev_upgrades)
	return base * task_mult * damage_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = dev_data.base_attack_speed
	var speed_mult: float = _calc_mult(Constants.UpgradeStat.SPEED, global_upgrades, dev_upgrades)
	return base / speed_mult


static func calculate_debt(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DEBT_PER_TASK
	var debt_mult: float = dev_data.base_debt_mult * _calc_mult(Constants.UpgradeStat.DEBT, global_upgrades, dev_upgrades)
	return base * debt_mult


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	match task_type:
		Constants.TaskType.FEATURE: return dev_data.base_feature_mult
		Constants.TaskType.BUG: return dev_data.base_bug_mult
		Constants.TaskType.REFACTOR: return dev_data.base_refactor_mult
	return 1.0


static func scale_task_hp(base_hp_mult: float, minutes_elapsed: float) -> float:
	return Constants.BASE_HP * base_hp_mult * pow(2.0, minutes_elapsed)


static func get_xp_for_level(level: int) -> int:
	return Constants.XP_BASE * int(pow(2, level - 1))


static func get_clicks_needed() -> int:
	return Constants.BASE_CLICKS_PER_TASK


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

```bash
git add globals/balance.gd
git commit -m "feat: add Balance class with all game formulas"
```

---

### Task 3: TaskSelectFunction + DeveloperData

**Files:**
- Create: `game_data/task_select_function.gd`
- Create: `game_data/task_select_function_default.tres`
- Modify: `game_data/developer/developer_data.gd`
- Modify: `game_data/developer/developer_data_vibecoder.tres`
- Modify: `game_data/developer/developer_data_regular.tres`
- Modify: `game_data/developer/developer_data_senior.tres`

- [ ] **Step 1: Create task_select_function.gd**

```gdscript
class_name TaskSelectFunction extends Resource


func select(dev_data: DeveloperData, tasks: Array[TaskData]) -> TaskData:
	var best_task: TaskData = null
	var best_score: float = -1.0
	for task: TaskData in tasks:
		var score: float = Balance.get_task_mult(dev_data, task.task_type)
		if score > best_score:
			best_score = score
			best_task = task
	return best_task
```

- [ ] **Step 2: Create task_select_function_default.tres**

```
[gd_resource type="Resource" script_class="TaskSelectFunction" load_steps=2 format=3]

[ext_resource type="Script" path="res://game_data/task_select_function.gd" id="1"]

[resource]
script = ExtResource("1")
```

- [ ] **Step 3: Update developer_data.gd**

Add after `base_attack_speed`:

```gdscript
@export var task_select: TaskSelectFunction
```

- [ ] **Step 4: Update all 3 developer .tres files**

Add to each .tres file a reference to the default task select function. Add ext_resource:

```
[ext_resource type="Resource" path="res://game_data/task_select_function_default.tres" id="X_task_select"]
```

And in [resource] section add:

```
task_select = ExtResource("X_task_select")
```

Apply to: `developer_data_vibecoder.tres`, `developer_data_regular.tres`, `developer_data_senior.tres`.

- [ ] **Step 5: Commit**

```bash
git add game_data/task_select_function.gd game_data/task_select_function_default.tres game_data/developer/
git commit -m "feat: add TaskSelectFunction resource and wire to DeveloperData"
```

---

### Task 4: TaskDisplay scene

**Files:**
- Create: `components/developer/task_display.gd`
- Create: `components/developer/task_display.tscn`
- Modify: `components/developer/developer.tscn`

- [ ] **Step 1: Create task_display.gd**

```gdscript
class_name TaskDisplay
extends Control

@onready var icon_rect: TextureRect = %IconRect
@onready var hp_bar: ProgressBar = %HpBar


func show_task(task: TaskData) -> void:
	if task.texture:
		icon_rect.texture = task.texture
	hp_bar.value = 1.0
	visible = true


func update_hp(current_hp: float, max_hp: float) -> void:
	if max_hp > 0.0:
		hp_bar.value = current_hp / max_hp


func hide_task() -> void:
	visible = false
```

- [ ] **Step 2: Create task_display.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://components/developer/task_display.gd" id="1"]

[node name="TaskDisplay" type="Control"]
script = ExtResource("1")
visible = false
layout_mode = 0
offset_left = -30.0
offset_top = -300.0
offset_right = 30.0
offset_bottom = -250.0

[node name="IconRect" type="TextureRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_right = 40.0
offset_bottom = 40.0
expand_mode = 1
stretch_mode = 5

[node name="HpBar" type="ProgressBar" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_top = 42.0
offset_right = 60.0
offset_bottom = 50.0
max_value = 1.0
value = 1.0
show_percentage = false
```

- [ ] **Step 3: Add TaskDisplay to developer.tscn**

Add ext_resource for task_display.tscn and add node instance as child of Developer root:

```
[ext_resource type="PackedScene" path="res://components/developer/task_display.tscn" id="8_task_display"]

[node name="TaskDisplay" parent="." unique_id=600 instance=ExtResource("8_task_display")]
unique_name_in_owner = true
```

- [ ] **Step 4: Commit**

```bash
git add components/developer/task_display.gd components/developer/task_display.tscn components/developer/developer.tscn
git commit -m "feat: add TaskDisplay scene for showing task over developer"
```

---

### Task 5: PlayerData — remove combat, add upgrade arrays + take_task

**Files:**
- Modify: `autoloads/player_data.gd`

This is the biggest refactor. Read the current file, then:

### Remove:
- All cached multipliers (lines 22-34): `global_damage_mult`, `global_speed_mult`, `global_debt_mult`, `vibecoder_*`, `regular_*`, `senior_*`, `auto_click_count_mult`, `auto_click_speed_mult`
- `_on_developer_attack()` connection in `_ready()` (line 41)
- All multiplier query methods: `get_type_damage_mult()`, `get_type_speed_mult()`, `get_type_debt_mult()`
- All combat methods: `_on_developer_attack()`, `_calculate_damage()`, `_get_task_mult()`, `_calculate_debt()`
- In `_on_task_destroyed()`: remove `SB.task_queue_changed.emit(task_queue)` (dev already removed task)
- In `reset()`: remove all multiplier resets (lines 73-84)

### Add:
After `upgrades_taken`:
```gdscript
var global_upgrades: Array[UpgradeData] = []
var dev_upgrades: Dictionary = {}
```

### Replace `_apply_upgrade`:
```gdscript
func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == Constants.UpgradeType.GLOBAL:
		global_upgrades.append(upgrade)
		if upgrade.stat == Constants.UpgradeStat.AUTO_CLICK_SPEED:
			_update_auto_click_timer()
	elif upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if upgrade.target_dev_type not in dev_upgrades:
			dev_upgrades[upgrade.target_dev_type] = []
		dev_upgrades[upgrade.target_dev_type].append(upgrade)
	elif upgrade.upgrade_type == Constants.UpgradeType.UNLOCK:
		match upgrade.stat:
			Constants.UpgradeStat.AUTO_CLICK: _unlock_auto_click()
	Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])
```

### Add `take_task`:
```gdscript
func take_task(task: TaskData) -> TaskData:
	if task not in task_queue:
		return null
	task_queue.erase(task)
	SB.task_queue_changed.emit(task_queue)
	return task
```

### Add signal connection in `_ready`:
```gdscript
SB.tech_debt_produced.connect(_on_tech_debt_produced)
```

### Add handler:
```gdscript
func _on_tech_debt_produced(delta: float) -> void:
	increase_tech_debt(delta)
```

### Replace `_apply_task_rewards`:
```gdscript
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
			increase_tech_debt(-Constants.DEBT_REDUCTION_PER_REFACTOR)
			Log.log_info(name, "Refactor done: -%.1f debt" % Constants.DEBT_REDUCTION_PER_REFACTOR)
```

### Replace `_on_task_destroyed`:
```gdscript
func _on_task_destroyed(task: TaskData) -> void:
	_apply_task_rewards(task)
	Log.log_info(name, "Task destroyed: %s" % Constants.TaskType.keys()[task.task_type])
```

### Update `reset()`:
Replace multiplier resets with:
```gdscript
global_upgrades.clear()
dev_upgrades.clear()
auto_click_unlocked = false
```

### Update auto-click timer:
```gdscript
func _update_auto_click_timer() -> void:
	if _auto_click_timer:
		var speed_mult: float = Balance._calc_mult(Constants.UpgradeStat.AUTO_CLICK_SPEED, global_upgrades, [])
		_auto_click_timer.wait_time = Constants.BASE_AUTO_CLICK_INTERVAL / speed_mult
```

### Update auto-click count:
```gdscript
func _on_auto_click_tick() -> void:
	var count_mult: float = Balance._calc_mult(Constants.UpgradeStat.AUTO_CLICK_COUNT, global_upgrades, [])
	var count: int = int(Constants.BASE_AUTO_CLICK_COUNT * count_mult)
	SB.backlog_clicked.emit(count)
```

### Update `_scale_task_hp` to use Balance:
```gdscript
func _scale_task_hp(task: TaskData) -> void:
	var minutes_elapsed: float = (Constants.GAME_DURATION - timer_remaining) / 60.0
	var hp: float = Balance.scale_task_hp(task.base_hp_mult, minutes_elapsed)
	task.current_hp = hp
	task.max_hp = hp
```

### Update `get_xp_for_level` to delegate to Balance:
```gdscript
func get_xp_for_level(lvl: int) -> int:
	return Balance.get_xp_for_level(lvl)
```

### Update `_get_clicks_needed`:
```gdscript
func _get_clicks_needed() -> int:
	return Balance.get_clicks_needed()
```

- [ ] **Step 2: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "refactor: PlayerData delegates combat to devs, stores upgrade arrays"
```

---

### Task 6: Developer — autonomous combat

**Files:**
- Modify: `components/developer/developer.gd`

- [ ] **Step 1: Rewrite developer.gd**

```gdscript
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
@onready var attack_progress_bar: ProgressBar = %AttackProgressBar
@onready var task_display: TaskDisplay = %TaskDisplay

var _attack_timer: float = 0.0
var _idle_tween: Tween = null
var _current_task: TaskData = null


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	if not _current_task:
		_pick_task()
		if not _current_task:
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


func _pick_task() -> void:
	if PD.task_queue.is_empty():
		return
	var task: TaskData = data.task_select.select(data, PD.task_queue)
	if task:
		_current_task = PD.take_task(task)
		if _current_task:
			task_display.show_task(_current_task)


func _perform_attack() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, dev_upgrades)
	_current_task.current_hp -= damage
	show_damage(int(damage))
	task_display.update_hp(_current_task.current_hp, _current_task.max_hp)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _on_task_killed() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	var debt: float = Balance.calculate_debt(data, PD.global_upgrades, dev_upgrades)
	SB.task_destroyed.emit(_current_task)
	SB.tech_debt_produced.emit(debt)
	task_display.hide_task()
	_current_task = null


func _get_attack_speed() -> float:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	return Balance.calculate_attack_speed(data, PD.global_upgrades, dev_upgrades)


func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or not _current_task:
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / _get_attack_speed()


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
		if is_instance_valid(attack_progress_bar):
			attack_progress_bar.visible = false
		if not Engine.is_editor_hint():
			add_to_group("desk")
			if is_in_group("developer"):
				remove_from_group("developer")
```

- [ ] **Step 2: Commit**

```bash
git add components/developer/developer.gd
git commit -m "feat: developer autonomously picks and attacks tasks"
```

---

### Task 7: AudioManager + HUD cleanup

**Files:**
- Modify: `autoloads/audio_manager.gd`
- Modify: `components/hud/hud.gd`

- [ ] **Step 1: Update audio_manager.gd**

Remove `developer_attack` connection. Add attack sound on `task_destroyed` instead (reuse HIT_HURT for each kill):

```gdscript
class_name AudioManager extends BaseAudioManager


func _ready() -> void:
	super._ready()
	_register_music()
	_register_sfx()
	_connect_signals()


func _register_music() -> void:
	register_music(Constants.Music.FR, preload("res://assets/music/fr.mp3"))
	register_music(Constants.Music.FR3, preload("res://assets/music/fr3.mp3"))
	register_music(Constants.Music.SG, preload("res://assets/music/sg.mp3"))
	register_music(Constants.Music.SPB, preload("res://assets/music/spb.mp3"))


func _register_sfx() -> void:
	register_sfx(Constants.Sfx.PICKUP, preload("res://assets/sfx/pickupCoin.wav"))
	register_sfx(Constants.Sfx.HIT_HURT, preload("res://assets/sfx/hitHurt.wav"))
	register_sfx(Constants.Sfx.EXPLOSION, preload("res://assets/sfx/explosion.wav"))
	register_sfx(Constants.Sfx.CLICK, preload("res://assets/sfx/click.wav"))


func _connect_signals() -> void:
	SB.backlog_clicked.connect(_on_backlog_clicked)
	SB.task_destroyed.connect(_on_task_destroyed)


func _on_backlog_clicked(_count: int) -> void:
	play_sfx(Constants.Sfx.CLICK, 0.3)


func _on_task_destroyed(_task: TaskData) -> void:
	play_sfx(Constants.Sfx.EXPLOSION, 0.3)
```

- [ ] **Step 2: Update hud.gd**

Remove `task_hp_changed` connection and handler. The HUD no longer tracks individual task HP — each developer's TaskDisplay handles that.

In `_ready()`: remove `SB.task_hp_changed.connect(_on_task_hp_changed)`.

Remove methods: `_on_task_hp_changed()`, `_shake_card()`.

Also remove `show_hp = true` from `_rebuild_cards` since cards in HUD no longer show HP (devs show it):

```gdscript
func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
```

- [ ] **Step 3: Commit**

```bash
git add autoloads/audio_manager.gd components/hud/hud.gd
git commit -m "refactor: cleanup AudioManager and HUD for autonomous dev combat"
```
