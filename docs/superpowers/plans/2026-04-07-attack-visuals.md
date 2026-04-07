# Attack Visuals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visual feedback to the attack system: progress bar, damage numbers, shake animations, task HP bar, and reduced damage values.

**Architecture:** Developer emits self via signal. PlayerData calculates damage, applies to task, calls `developer.show_damage(damage)` for visual feedback. HUD listens to `task_hp_changed` for card shake and HP bar updates.

**Tech Stack:** Godot 4.x, GDScript

**Spec:** `docs/superpowers/specs/2026-04-07-attack-visuals-design.md`

---

### Task 1: Reduce damage values in .tres files

**Files:**
- Modify: `game_data/developer/developer_data_vibecoder.tres`
- Modify: `game_data/developer/developer_data_regular.tres`
- Modify: `game_data/developer/developer_data_senior.tres`

- [ ] **Step 1: Update Vibecoder damage**

In `game_data/developer/developer_data_vibecoder.tres`, replace:
```
feature_damage = 80
bug_damage = 20
refactor_damage = 10
```
with:
```
feature_damage = 16
bug_damage = 4
refactor_damage = 2
```

- [ ] **Step 2: Update Regular damage**

In `game_data/developer/developer_data_regular.tres`, replace:
```
feature_damage = 50
bug_damage = 50
refactor_damage = 50
```
with:
```
feature_damage = 10
bug_damage = 10
refactor_damage = 10
```

- [ ] **Step 3: Update Senior damage**

In `game_data/developer/developer_data_senior.tres`, replace:
```
feature_damage = 30
bug_damage = 70
refactor_damage = 80
```
with:
```
feature_damage = 6
bug_damage = 14
refactor_damage = 16
```

- [ ] **Step 4: Commit**

```bash
git add game_data/developer/
git commit -m "balance: reduce developer damage values"
```

---

### Task 2: Change signal to emit Developer, add show_damage and shake

**Files:**
- Modify: `autoloads/signal_bus.gd:9`
- Modify: `components/developer/developer.gd`
- Modify: `autoloads/player_data.gd:44-62`

- [ ] **Step 1: Update SignalBus**

In `autoloads/signal_bus.gd`, change line 9:
```gdscript
signal developer_attack(developer: Developer)
```

- [ ] **Step 2: Update Developer — emit self, add show_damage and shake**

In `components/developer/developer.gd`:

Change `_perform_attack()`:
```gdscript
func _perform_attack() -> void:
	SB.developer_attack.emit(self)
	_shake_sprite()
	Log.log_debug(name, "Attack tick")
```

Add `show_damage()` method:
```gdscript
func show_damage(damage: int) -> void:
	damage_number.spawn("-%d" % damage, Vector2.UP, Color.YELLOW)
```

Add `_shake_sprite()` method:
```gdscript
func _shake_sprite() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(dev_sprite, "rotation_degrees", 5.0, 0.05)
	tween.tween_property(dev_sprite, "rotation_degrees", -5.0, 0.05)
	tween.tween_property(dev_sprite, "rotation_degrees", 0.0, 0.1)
```

- [ ] **Step 3: Update PlayerData — receive Developer, call show_damage**

In `autoloads/player_data.gd`, replace `_on_developer_attack` and `_get_damage_for_task`:

```gdscript
func _on_developer_attack(developer: Developer) -> void:
	if task_queue.is_empty():
		return
	var task: TaskData = task_queue[0]
	var damage: int = _get_damage_for_task(developer.data, task.task_type)
	task.current_hp -= damage
	developer.show_damage(damage)
	increase_tech_debt(Constants.TECH_DEBT_PER_HIT)
	SB.task_hp_changed.emit(task, task.current_hp, task.max_hp)
	if task.current_hp <= 0.0:
		task_queue.pop_front()
		_on_task_destroyed(task)
```

`_get_damage_for_task` stays unchanged.

- [ ] **Step 4: Commit**

```bash
git add autoloads/signal_bus.gd components/developer/developer.gd autoloads/player_data.gd
git commit -m "feat: developer emits self, show_damage and shake animation"
```

---

### Task 3: Add attack progress bar to Developer

**Files:**
- Modify: `components/developer/developer.gd`
- Modify: `components/developer/developer.tscn`

- [ ] **Step 1: Add ProgressBar node to developer.tscn**

Add after the DeskSprite node (position below desk). Insert these lines in `components/developer/developer.tscn`:

```
[node name="AttackProgressBar" type="ProgressBar" parent="." unique_id=500]
unique_name_in_owner = true
offset_left = -80.0
offset_top = -25.0
offset_right = 80.0
offset_bottom = -10.0
max_value = 1.0
show_percentage = false
```

- [ ] **Step 2: Update developer.gd — reference and update progress bar**

Add @onready var:
```gdscript
@onready var attack_progress_bar: ProgressBar = %AttackProgressBar
```

Update `_process()` to update the progress bar:
```gdscript
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return
	if PD.task_queue.is_empty():
		_attack_timer = 0.0
		_update_progress_bar()
		return
	_attack_timer += delta
	if _attack_timer >= data.base_attack_speed:
		_attack_timer -= data.base_attack_speed
		_perform_attack()
	_update_progress_bar()
```

Add `_update_progress_bar()`:
```gdscript
func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or PD.task_queue.is_empty():
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / data.base_attack_speed
```

Update `_apply_data()` to hide progress bar when no data:
In the `else` branch (no data), add:
```gdscript
if is_instance_valid(attack_progress_bar):
	attack_progress_bar.visible = false
```

- [ ] **Step 3: Commit**

```bash
git add components/developer/
git commit -m "feat: add attack cooldown progress bar to Developer"
```

---

### Task 4: Add HP bar to TaskCard

**Files:**
- Modify: `components/task_queue/task_card.gd`
- Modify: `components/task_queue/task_card.tscn`

- [ ] **Step 1: Add ProgressBar to task_card.tscn**

Add an HP bar at the bottom of the card. Insert after the MarginContainer/Icon node:

```
[node name="HpBar" type="ProgressBar" parent="." unique_id=300]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 8
custom_minimum_size = Vector2(0, 6)
max_value = 1.0
show_percentage = false
visible = false
```

- [ ] **Step 2: Update task_card.gd — add HP bar support**

Add @onready:
```gdscript
@onready var hp_bar: ProgressBar = %HpBar
```

Add var:
```gdscript
var show_hp: bool = false
```

Add method to update HP:
```gdscript
func update_hp(current: float, max_hp: float) -> void:
	if not is_instance_valid(hp_bar) or max_hp <= 0.0:
		return
	hp_bar.visible = true
	hp_bar.value = maxf(current / max_hp, 0.0)
```

In `_ready()`, after setting icon, add:
```gdscript
if show_hp and task_data.max_hp > 0.0:
	hp_bar.visible = true
	hp_bar.value = task_data.current_hp / task_data.max_hp
```

- [ ] **Step 3: Commit**

```bash
git add components/task_queue/
git commit -m "feat: add HP bar to TaskCard"
```

---

### Task 5: HUD — task HP updates and card shake

**Files:**
- Modify: `components/hud/hud.gd`

- [ ] **Step 1: Update hud.gd**

In `_ready()`, add signal connection:
```gdscript
SB.task_hp_changed.connect(_on_task_hp_changed)
```

Add method:
```gdscript
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
```

Update `_rebuild_cards()` to show HP on first card:
```gdscript
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

- [ ] **Step 2: Commit**

```bash
git add components/hud/hud.gd
git commit -m "feat: HUD shows task HP bar, shakes first card on hit"
```
