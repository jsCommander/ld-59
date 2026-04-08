# Click Backlog — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace auto-backlog with click-to-generate mechanic — player clicks a button to spawn tasks into the queue.

**Architecture:** Single HUD button emits `SB.backlog_clicked`. PlayerData counts clicks, spawns task on threshold. AudioManager plays click sound. Old backlog array, timer, and management UI are deleted.

**Tech Stack:** Godot 4, GDScript

**Spec:** `docs/superpowers/specs/2026-04-08-click-backlog-design.md`

---

## File Structure

### Modify

| File | Changes |
|------|---------|
| `globals/constants.gd` | Add `BASE_CLICKS_PER_TASK`. Remove `BASE_BACKLOG_SIZE`, `BACKLOG_REFRESH_INTERVAL` |
| `autoloads/signal_bus.gd` | Add `backlog_clicked`, `backlog_task_spawned`. Remove `backlog_refreshed`, `task_clicked` |
| `autoloads/player_data.gd` | Remove backlog array/timer/fill/spawn. Add click counting + `_spawn_task_to_queue()` |
| `autoloads/audio_manager.gd` | Add `CLICK` sfx, connect to `backlog_clicked`. Remove `task_clicked` handler |
| `components/hud/hud.gd` | Replace backlog toggle with click emitter + progress bar + tween |
| `components/hud/hud.tscn` | Replace BacklogButton with bigger button + ClickProgressBar above it |
| `levels/test_level.tscn` | Remove UiTaskBacklog node and ext_resource |

### Delete

| File/Folder | Reason |
|-------------|--------|
| `components/ui/ui_task_backlog/` | Entire folder — backlog management UI replaced by click button |

---

## Tasks

### Task 1: Constants + SignalBus

**Files:**
- Modify: `globals/constants.gd`
- Modify: `autoloads/signal_bus.gd`

- [ ] **Step 1: Update constants.gd**

Remove `BASE_BACKLOG_SIZE` and `BACKLOG_REFRESH_INTERVAL`. Add `BASE_CLICKS_PER_TASK`. Full file:

```gdscript
class_name Constants extends Resource

const BUILTIN_SIGNALS: Array[String] = BaseConstants.BUILTIN_SIGNALS

enum DevType { VIBECODER, REGULAR, SENIOR }
enum TaskType { FEATURE, BUG, REFACTOR }
enum Music { FR, FR3, SG, SPB }
enum Sfx { PICKUP, HIT_HURT, EXPLOSION, CLICK }

const BASE_HP: int = 100
const BASE_DAMAGE: int = 10
const BASE_DEBT_PER_HP: float = 0.01
const DEBT_PER_TASK: float = 0.6
const XP_BASE: int = int(BASE_HP * 0.3)
const BASE_CLICKS_PER_TASK: int = 3

const GAME_DURATION: float = 900.0
const HIRE_LEVELS: Array[int] = [3, 6, 9, 12, 15]

const BASE_QUEUE_SIZE: int = 10
const BUG_SPAWN_MULTIPLIER: float = 0.01
const REFACTOR_SPAWN_MULTIPLIER: float = 0.005
```

Note: Added `CLICK` to `Sfx` enum for the click sound.

- [ ] **Step 2: Update signal_bus.gd**

```gdscript
class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared

signal task_queue_changed(tasks: Array[TaskData])

signal developer_attack(developer: Developer)
signal task_hp_changed(task: TaskData, hp: float, max_hp: float)
signal task_destroyed(task: TaskData)

signal developer_hired(dev_data: DeveloperData)
signal developer_fired(dev_data: DeveloperData)

signal resource_tech_debt_changed
signal valuation_changed

signal backlog_clicked
signal backlog_task_spawned

signal game_timer_changed(remaining: float)
signal level_up(level: int)
signal game_over(valuation: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal developer_hire_requested
```

Removed: `backlog_refreshed`, `task_clicked`.
Added: `backlog_clicked`, `backlog_task_spawned`.

- [ ] **Step 3: Commit**

```bash
git add globals/constants.gd autoloads/signal_bus.gd
git commit -m "refactor: add click backlog signals, remove old backlog constants"
```

---

### Task 2: PlayerData — remove backlog, add click counting

**Files:**
- Modify: `autoloads/player_data.gd`

- [ ] **Step 1: Remove backlog state and methods**

Remove these lines/blocks:
- `var backlog: Array[TaskData] = []` (line 15)
- `var _backlog_timer: float = 0.0` (line 17)
- The entire "Backlog refill" section in `_process()` (lines 99-105)
- `func get_backlog_refresh_progress()` (lines 108-109)
- `func _spawn_backlog_task()` (lines 195-200)
- `func fill_backlog()` (lines 203-207)
- `func add_tasks_to_queue()` (lines 230-238)
- In `reset()`: remove `backlog.clear()` (line 65), `_backlog_timer = 0.0` (line 67)
- In `start_game()`: remove `fill_backlog()` (line 53)

- [ ] **Step 2: Add click counting and task spawning**

Add new state variable after `var _awaiting_choice`:
```gdscript
var _click_progress: int = 0
```

In `_ready()`, add signal connection:
```gdscript
SB.backlog_clicked.connect(_on_backlog_clicked)
```

Add new methods (after the level-up section):
```gdscript
# --- Backlog clicks ---

func _on_backlog_clicked() -> void:
	if not _game_active or _awaiting_choice:
		return
	_click_progress += 1
	if _click_progress >= _get_clicks_needed():
		_click_progress = 0
		_spawn_task_to_queue()
		SB.backlog_task_spawned.emit()


func _get_clicks_needed() -> int:
	return Constants.BASE_CLICKS_PER_TASK + level


func _spawn_task_to_queue() -> void:
	var task: TaskData = _create_task_by_debt()
	_scale_task_hp(task)
	task_queue.append(task)
	SB.task_queue_changed.emit(task_queue)
	Log.log_info(name, "Task spawned to queue (total: %d)" % task_queue.size())
```

In `reset()`, add:
```gdscript
_click_progress = 0
```

- [ ] **Step 3: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat: click-based task spawning, remove auto-backlog"
```

---

### Task 3: AudioManager — click sound

**Files:**
- Modify: `autoloads/audio_manager.gd`

- [ ] **Step 1: Update audio_manager.gd**

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
	SB.developer_attack.connect(_on_developer_attack)
	SB.task_destroyed.connect(_on_task_destroyed)


func _on_backlog_clicked() -> void:
	play_sfx(Constants.Sfx.CLICK, 0.3)


func _on_developer_attack(_developer: Developer) -> void:
	play_sfx(Constants.Sfx.HIT_HURT, 0.2)


func _on_task_destroyed(_task: TaskData) -> void:
	play_sfx(Constants.Sfx.EXPLOSION, 0.3)
```

Removed: `task_clicked` connection and `_on_task_clicked` handler.
Added: `CLICK` sfx registration, `backlog_clicked` connection, `_on_backlog_clicked` handler.

- [ ] **Step 2: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat: play click sound on backlog click"
```

---

### Task 4: HUD — click button with progress bar and tween

**Files:**
- Modify: `components/hud/hud.gd`
- Modify: `components/hud/hud.tscn`

- [ ] **Step 1: Update hud.tscn**

Replace the BottomBar section (from `[node name="BottomBar"...]` to end of file) with:

```
[node name="BottomBar" type="VBoxContainer" parent="."]
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -140.0
offset_top = -100.0
offset_right = 140.0
offset_bottom = -12.0
theme_override_constants/separation = 4

[node name="ClickProgressBar" type="ProgressBar" parent="BottomBar"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(250, 12)
max_value = 1.0
show_percentage = false

[node name="BacklogButton" type="Button" parent="BottomBar"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(250, 60)
text = "Бэклог (0/3)"
theme_override_font_sizes/font_size = 26
```

Key changes: BottomBar is now VBoxContainer (was HBoxContainer). Contains ClickProgressBar above BacklogButton. Button is bigger (250×60, font 26).

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
@onready var click_progress_bar: ProgressBar = %ClickProgressBar


func _ready() -> void:
	SB.game_timer_changed.connect(_update_timer)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.task_hp_changed.connect(_on_task_hp_changed)
	SB.backlog_clicked.connect(_update_click_progress)
	SB.backlog_task_spawned.connect(_on_task_spawned)
	backlog_button.pressed.connect(_on_backlog_pressed)
	_update_tech_debt()
	_update_valuation()
	_update_click_label()
	main_layout.visible = true


func _on_backlog_pressed() -> void:
	SB.backlog_clicked.emit()
	_tween_button()


func _tween_button() -> void:
	backlog_button.pivot_offset = backlog_button.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(backlog_button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(backlog_button, "scale", Vector2(1.0, 1.0), 0.05)


func _update_click_progress() -> void:
	var needed: int = PD._get_clicks_needed()
	click_progress_bar.value = float(PD._click_progress) / float(needed)
	_update_click_label()


func _on_task_spawned() -> void:
	click_progress_bar.value = 0.0
	_update_click_label()


func _update_click_label() -> void:
	var needed: int = PD._get_clicks_needed()
	backlog_button.text = "Бэклог (%d/%d)" % [PD._click_progress, needed]


func _update_timer(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	valuation_label.text = "Lv.%d  $%d / $%d" % [PD.level, PD.valuation, next_xp]


func _on_level_up(_level: int) -> void:
	_update_valuation()
	_update_click_label()


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

Note: HUD reads `PD._click_progress` and `PD._get_clicks_needed()` directly for display. The button emits `SB.backlog_clicked` and plays a tween. Progress bar and label update on signal.

- [ ] **Step 3: Commit**

```bash
git add components/hud/hud.gd components/hud/hud.tscn
git commit -m "feat: click backlog button with progress bar and tween"
```

---

### Task 5: Delete old backlog UI + remove from level

**Files:**
- Delete: `components/ui/ui_task_backlog/` (entire folder)
- Modify: `levels/test_level.tscn`

- [ ] **Step 1: Delete backlog UI folder**

```bash
rm -rf components/ui/ui_task_backlog/
```

- [ ] **Step 2: Update test_level.tscn**

Remove the ext_resource line for ui_task_backlog:
```
[ext_resource type="PackedScene" path="res://components/ui/ui_task_backlog/ui_task_backlog.tscn" id="18_task_backlog"]
```

Remove the UiTaskBacklog node:
```
[node name="UiTaskBacklog" parent="." unique_id=702294197 instance=ExtResource("18_task_backlog")]
```

- [ ] **Step 3: Verify**

Run the game in Godot:
- Click "Бэклог" button — hear click sound, button tweens, progress bar fills
- After 3 clicks (level 0) — task appears in queue, bar resets
- Devs attack tasks as normal
- Level up → clicks needed increases

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: delete backlog management UI, remove from level"
```
