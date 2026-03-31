# Manager-Controller-SignalBus Architecture for Godot Incremental Games

## TL;DR

Layered architecture for incremental/idle games with three key principles:
- **Data-Driven Design** — all game content as `.tres` resource files (no hardcoding)
- **Controller-Manager Split** — Controllers handle logic/timers, Managers track state
- **SignalBus Decoupling** — systems communicate through global signals, no direct dependencies
- **SaveFile as Single Source of Truth** — all runtime state in one autoload

---

## What Problems It Solves

### Problem 1: Tight Coupling Between Systems

```gdscript
# Bad: direct dependencies everywhere
class_name WorkerUI

var worker_controller: WorkerController  # Need reference!
var resource_manager: ResourceManager    # Need reference!
var save_system: SaveSystem              # Need reference!

func _on_button_pressed():
    worker_controller.add_worker("lumberjack")  # Direct call
    resource_manager.update_display()           # Direct call
    save_system.save()                          # Direct call

# Problems:
# - Adding new systems = changing multiple files
# - Hard to test individual components
# - Circular dependency nightmares
```

**Solution:** SignalBus — all systems communicate through signals, zero direct references.

### Problem 2: Game Data Hardcoded in Scripts

```gdscript
# Bad: data mixed with code
const WORKERS = {
    "lumberjack": {"produce": "wood", "consume": "food", "rate": 1.0},
    "miner": {"produce": "stone", "consume": "food", "rate": 0.5},
}

# Problems:
# - Adding new worker = editing code
# - No editor support (autocomplete, validation)
# - Designer needs programmer to change values
```

**Solution:** `.tres` resource files — designers edit in Godot Inspector, no code changes.

### Problem 3: State Scattered Across Objects

```gdscript
# Bad: state in multiple places
class WorkerManager:
    var worker_counts = {}  # State here

class UIWorkerPanel:
    var cached_counts = {}  # Duplicate state!

class SaveSystem:
    var saved_workers = {}  # Another copy!

# Problems:
# - State gets out of sync
# - Which one is correct?
# - Bugs when saving/loading
```

**Solution:** SaveFile singleton — single source of truth, all systems read/write there.

### Problem 4: Mixed Responsibilities

```gdscript
# Bad: one class does everything
class ResourceManager:
    func _on_timer_timeout():
        # Logic (controller responsibility)
        var amount = count * efficiency

        # State update (manager responsibility)
        resources[id] += amount

        # UI update (UI responsibility)
        label.text = str(resources[id])

        # Persistence (save responsibility)
        save_to_file()

# Problems:
# - Class grows endlessly
# - Can't change one aspect without touching others
# - Testing requires mocking everything
```

**Solution:** Layer separation — Controllers (when/how), Managers (state), UI (display).

### Problem 5: Adding Content Requires Code Changes

```gdscript
# Bad: new content = new code
func create_worker(type: String):
    match type:
        "lumberjack":
            # ...
        "miner":
            # ...
        "farmer":  # NEW - need to modify code!
            # ...
```

**Solution:** Data-driven — new `.tres` file, unlock condition, done. No core code changes.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GAME DATA (Resources)                    │
│  ResourceGenerator, WorkerRole, EnemyData, SubstanceData    │
│  All game content defined as .tres resource files           │
└──────────────────────────┬──────────────────────────────────┘
                           │ loaded by
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       CONTROLLERS                           │
│  Logic, calculations, timers, validation                    │
│  WorkerController, EnemyController, ProgressButtonController│
└──────────────────────────┬──────────────────────────────────┘
                           │ emits signals via
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       SIGNAL BUS                            │
│  Global event dispatcher (autoload singleton)               │
│  Signals organized by category (UI, Controller, Manager)    │
└──────────────────────────┬──────────────────────────────────┘
                           │ listeners update
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        MANAGERS                             │
│  State tracking, SaveFile updates                           │
│  ResourceManager, WorkerManager, EnemyManager               │
└──────────────────────────┬──────────────────────────────────┘
                           │ emits state change signals
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                          UI                                 │
│  Displays current state, handles user input                 │
│  WorldScreen, ManagerScreen, EnemyScreen                    │
└─────────────────────────────────────────────────────────────┘
```

**Data Flow:**

```
User clicks "Gather Wood" button
        │
        ▼
UI: SignalBus.ui_progress_button_pressed.emit(wood_generator)
        │
        ▼
ProgressButtonController: validates, calculates
        │
        ▼
Controller: SignalBus.resource_generated.emit("wood", 10)
        │
        ▼
ResourceManager: SaveFile.resources["wood"] += 10
        │
        ▼
Manager: SignalBus.resource_updated.emit("wood", new_value)
        │
        ▼
UI: Updates display to show "Wood: 42"
```

**Why This Split:**

```
┌─────────────────────┐     ┌─────────────────────┐
│    CONTROLLERS      │     │      MANAGERS       │
├─────────────────────┤     ├─────────────────────┤
│ WHEN things happen  │     │ WHAT is the state   │
│ Timers              │     │ SaveFile updates    │
│ Validation          │     │ Caps and limits     │
│ Calculations        │     │ State change emit   │
└─────────────────────┘     └─────────────────────┘
         │                           │
         └─────────┬─────────────────┘
                   ▼
         ┌─────────────────┐
         │   SIGNAL BUS    │
         │   (decouples)   │
         └─────────────────┘
```

---

## Components

### 1. Game Data Layer (Resources)

All game content defined as Godot Resources (`.tres` files).

#### ResourceGenerator (Clickable Resources)

```gdscript
class_name ResourceGenerator
extends Resource

@export var id: String                    # "wood", "house"
@export var amount: int                   # Per click
@export var cooldown_seconds: float       # Click cooldown
@export var costs: Array[Cost]            # Resource costs
@export var worker_costs: Array[Cost]     # Worker costs
@export var random_drops: Array[RandomDrop]
@export var max_amount: int               # Cap (0 = unlimited)

func generate() -> int:
    """Calculate amount (with cooldown multipliers)"""

func get_scaled_costs(count: int) -> Array[Cost]:
    """Apply cost scaling (exponential/linear)"""
```

**.tres file example:**

```tres
id = "wood"
amount = 1
cooldown_seconds = 1.0
costs = []  # Free
max_amount = 0  # Unlimited
```

#### WorkerRole (Automated Workers)

```gdscript
class_name WorkerRole
extends Resource

@export var id: String                # "lumberjack"
@export var produce: Array[Cost]      # What generates per cycle
@export var consume: Array[Cost]      # Resources consumed
@export var worker_consume: Array[Cost]

func get_produce_efficiency(resource_id: String, resources: Dictionary) -> float:
    """0.0 to 1.0 based on capacity"""

func get_consume_efficiency(resources: Dictionary) -> float:
    """0.0 to 1.0 based on available resources"""
```

**.tres file example:**

```tres
id = "lumberjack"
produce = [Cost(resource_id="wood", amount=1)]
consume = [Cost(resource_id="food", amount=1)]
```

#### EnemyData (Boss Progression)

```gdscript
class_name EnemyData
extends Resource

@export var id: String
@export var health_points: int
@export var next_enemy_id: String

func is_last() -> bool:
    return next_enemy_id.is_empty()
```

#### SubstanceData (Prestige/Magic Items)

```gdscript
class_name SubstanceData
extends Resource

@export var id: String
@export var costs: Array[Cost]  # Usually hearts
```

---

### 2. Controllers Layer (Logic & Timers)

Controllers handle **when** things happen and **validation**.

#### WorkerController

```gdscript
extends Node

@export var cycle_seconds: float = 5.0

var _timer: Timer

func _ready():
    _timer = Timer.new()
    _timer.timeout.connect(_on_timeout)
    _timer.wait_time = cycle_seconds
    _timer.start()

func _on_timeout():
    _generate_workers()   # Houses produce peasants
    _generate_resources() # Workers produce resources

func _generate_resources():
    for worker_role in all_worker_roles:
        var count = SaveFile.workers.get(worker_role.id, 0)
        if count == 0:
            continue

        var consume_eff = worker_role.get_consume_efficiency(SaveFile.resources)

        for produce_cost in worker_role.produce:
            var produce_eff = worker_role.get_produce_efficiency(
                produce_cost.resource_id,
                SaveFile.resources
            )
            var efficiency = min(consume_eff, produce_eff)
            var amount = count * produce_cost.amount * efficiency

            SignalBus.resource_generated.emit(produce_cost.resource_id, amount)
```

**Efficiency Calculation:**

```
5 lumberjacks, 3 food available, need 1 food each

consume_efficiency = min(3/5, 1.0) = 0.6
produce_efficiency = 1.0 (no cap)
final_efficiency = min(0.6, 1.0) = 0.6

Output: 5 × 1 × 0.6 = 3 wood
Consumed: 3 food (all available)
```

#### ProgressButtonController

```gdscript
extends Node

func _ready():
    SignalBus.ui_progress_button_pressed.connect(_on_button_pressed)

func _on_button_pressed(resource_generator: ResourceGenerator):
    if not _can_pay(resource_generator):
        return

    var amount = resource_generator.generate()
    _pay_costs(resource_generator)
    SignalBus.resource_generated.emit(resource_generator.id, amount)

    # Random drops
    for drop in resource_generator.random_drops:
        if randf() < drop.chance:
            SignalBus.resource_generated.emit(drop.resource_id, drop.amount)

func _can_pay(rg: ResourceGenerator) -> bool:
    for cost in rg.get_scaled_costs(1):
        if SaveFile.resources.get(cost.resource_id, 0) < cost.amount:
            return false
    return true
```

#### EnemyController

```gdscript
extends Node

@export var cycle_seconds: float = 10.0

func _on_timeout():
    var damage = _calculate_damage()
    SignalBus.enemy_damaged.emit(damage)

func _calculate_damage() -> int:
    var base = SaveFile.workers.get("swordsman", 0)
    var multiplier = _get_substance_multipliers()
    return base * multiplier
```

#### UnlockController

```gdscript
extends Node

func _ready():
    SignalBus.resource_generated.connect(_on_resource_generated)

func _on_resource_generated(resource_id: String, _amount: int):
    match resource_id:
        "land":
            _unlock_tab("world")
            _unlock_resource_generator("house")
        "house":
            _unlock_worker_role("peasant")
        "brick":
            _unlock_tab("manager")
            _unlock_worker_role("lumberjack")

func _unlock_resource_generator(id: String):
    if not SaveFile.resource_generator_unlocks.has(id):
        SaveFile.resource_generator_unlocks.append(id)
        SignalBus.resource_generator_unlocked.emit(id)
```

---

### 3. SignalBus (Global Event Dispatcher)

```gdscript
extends Node

# === UI → Controllers ===
signal ui_progress_button_pressed(resource_generator: ResourceGenerator)
signal ui_manager_button_plus_pressed(worker_role: WorkerRole)
signal ui_tab_pressed(tab_data: TabData)

# === Controllers → Managers ===
signal resource_generated(resource_id: String, amount: int)
signal worker_generated(worker_id: String, amount: int)
signal enemy_damaged(damage: int)
signal substance_crafted(substance_id: String)

# === Managers → UI ===
signal resource_updated(resource_id: String, new_amount: int)
signal worker_updated(worker_id: String, new_amount: int)
signal enemy_updated(enemy_id: String, hp: int)
signal enemy_defeated(enemy_id: String)

# === Progression ===
signal resource_generator_unlocked(resource_id: String)
signal worker_role_unlocked(worker_id: String)
signal tab_unlocked(tab_id: String)

# === Game Flow ===
signal prestige_triggered
signal game_saved
signal offline_progress_applied(seconds_passed: float)
```

---

### 4. Managers Layer (State Tracking)

Managers listen to signals and update SaveFile.

#### ResourceManager

```gdscript
extends Node

func _ready():
    SignalBus.resource_generated.connect(_on_resource_generated)

func _on_resource_generated(resource_id: String, amount: int):
    var current = SaveFile.resources.get(resource_id, 0)
    var new_value = current + amount

    # Clamp to max
    var rg = Resources.resource_generators.get(resource_id)
    if rg and rg.max_amount > 0:
        new_value = min(new_value, rg.max_amount)

    SaveFile.resources[resource_id] = new_value
    SignalBus.resource_updated.emit(resource_id, new_value)
```

#### WorkerManager

```gdscript
extends Node

func _ready():
    SignalBus.worker_generated.connect(_on_worker_generated)

func _on_worker_generated(worker_id: String, amount: int):
    var current = SaveFile.workers.get(worker_id, 0)
    var new_value = current + amount

    # Check capacity (peasants capped by houses)
    var max_amount = _get_max_workers(worker_id)
    if max_amount > 0:
        new_value = min(new_value, max_amount)

    SaveFile.workers[worker_id] = new_value
    SignalBus.worker_updated.emit(worker_id, new_value)

func _get_max_workers(worker_id: String) -> int:
    if worker_id == "peasant":
        return SaveFile.resources.get("house", 0) * 10
    return 0
```

#### EnemyManager

```gdscript
extends Node

func _ready():
    SignalBus.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(damage: int):
    var current_hp = SaveFile.current_enemy_hp
    current_hp -= damage

    if current_hp <= 0:
        _defeat_enemy()
    else:
        SaveFile.current_enemy_hp = current_hp
        SignalBus.enemy_hp_updated.emit(current_hp)

func _defeat_enemy():
    var current = Resources.enemy_datas[SaveFile.current_enemy_id]

    if current.is_last():
        _trigger_endgame()
        return

    var next = Resources.enemy_datas[current.next_enemy_id]
    SaveFile.current_enemy_id = next.id
    SaveFile.current_enemy_hp = next.health_points

    SignalBus.enemy_defeated.emit(current.id)
    SignalBus.enemy_updated.emit(next.id, next.health_points)
```

---

### 5. SaveFile (Single Source of Truth)

```gdscript
extends Node

# === Game State ===
var resources: Dictionary = {}
var workers: Dictionary = {}
var substances: Dictionary = {}

# === Progression ===
var resource_generator_unlocks: Array[String] = []
var worker_role_unlocks: Array[String] = []
var tab_unlocks: Array[String] = []

# === Enemy ===
var current_enemy_id: String = "rabbit"
var current_enemy_hp: int = 10

# === Meta ===
var metadata: Dictionary = {}
```

---

## Usage

### Signal Flow Example 1: Player Clicks Button

```
1. UI (ProgressButton.pressed)
   │
   ▼
   SignalBus.ui_progress_button_pressed.emit(wood_generator)
   │
2. ProgressButtonController
   │ validates, calculates
   ▼
   SignalBus.resource_generated.emit("wood", 1)
   │
3. ResourceManager
   │ SaveFile.resources["wood"] = 42
   ▼
   SignalBus.resource_updated.emit("wood", 42)
   │
4. UI (ProgressButton)
   │ Updates display: "Wood: 42"
```

### Signal Flow Example 2: Worker Production Cycle

```
1. WorkerController (Timer every 5s)
   │
   │ 3 lumberjacks × 0.6 efficiency = ~2 wood
   ▼
   SignalBus.resource_generated.emit("wood", 2)
   SignalBus.resource_generated.emit("food", -2)
   │
2. ResourceManager
   │ SaveFile updates
   ▼
   SignalBus.resource_updated.emit("wood", 44)
   SignalBus.resource_updated.emit("food", 8)
   │
3. UI updates all displays
```

### Signal Flow Example 3: Unlocking Content

```
1. Player generates first "brick"
   SignalBus.resource_generated.emit("brick", 1)
   │
2. UnlockController
   │ detects milestone
   ▼
   SignalBus.tab_unlocked.emit("manager")
   SignalBus.worker_role_unlocked.emit("lumberjack")
   │
3. Managers update SaveFile
   │
4. UI shows new tab, new worker
```

---

## Adding New Content

### New Resource (5 minutes)

**1. Create .tres file:**
```tres
# resources/game_data/resource_generator/iron.tres
id = "iron"
amount = 1
cooldown_seconds = 2.0
costs = [Cost(resource_id="stone", amount=5)]
```

**2. Add unlock condition:**
```gdscript
# unlock_controller.gd
"stone":
    if SaveFile.resources["stone"] >= 100:
        _unlock_resource_generator("iron")
```

**3. Add translation:**
```csv
# assets/i18n/en.csv
iron,Iron
```

**Done!** UI auto-displays when unlocked.

### New Worker (5 minutes)

**1. Create .tres file:**
```tres
# resources/game_data/worker_role/miner.tres
id = "miner"
produce = [Cost(resource_id="iron", amount=1)]
consume = [Cost(resource_id="food", amount=2)]
```

**2. Add unlock:**
```gdscript
"iron":
    _unlock_worker_role("miner")
```

**3. Translation. Done!**

### New Substance/Power (10 minutes)

**1. Create .tres file:**
```tres
id = "the_tower"
costs = [Cost(resource_id="heart", amount=50)]
```

**2. Implement effect in relevant controller:**
```gdscript
# worker_controller.gd
func _get_substance_multiplier() -> float:
    var mult = 1.0
    if SaveFile.substances.has("the_tower"):
        mult *= 3.0
    return mult
```

**3. Translation. Done!**

---

## Special Systems

### Prestige System

```gdscript
func _do_prestige():
    var hearts = _count_maxed_resources()

    # Reset
    SaveFile.resources.clear()
    SaveFile.workers.clear()
    SaveFile.unlocks.clear()

    # Keep prestige currency
    SaveFile.substances["heart"] += hearts

    SignalBus.prestige_triggered.emit()
```

### Offline Progress

```gdscript
func _apply_offline_progress(seconds: float):
    var cycles = int(seconds / 5.0)

    for i in range(cycles):
        _run_worker_cycle()

    SignalBus.offline_progress_applied.emit(seconds)
```

---

## File Structure

```
project/
├── global/
│   ├── autoload/
│   │   ├── signal_bus/signal_bus.gd
│   │   ├── save_file/save_file.gd
│   │   ├── resources/resources.gd
│   │   └── audio/audio.gd
│   └── const/
│       └── constants.gd
│
├── resources/
│   └── game_data/
│       ├── resource_generator/
│       │   ├── resource_generator.gd
│       │   └── *.tres
│       ├── worker_role/
│       │   ├── worker_role.gd
│       │   └── *.tres
│       └── enemy_data/
│           ├── enemy_data.gd
│           └── *.tres
│
├── scenes/
│   ├── controller/
│   │   ├── worker_controller/
│   │   ├── progress_button_controller/
│   │   └── enemy_controller/
│   ├── manager/
│   │   ├── resource_manager/
│   │   ├── worker_manager/
│   │   └── enemy_manager/
│   └── screen/
│       ├── world_screen/
│       └── manager_screen/
```

---

## Pros and Cons

### Pros

| Feature | Benefit |
|---------|---------|
| Data-driven | Add content without code changes |
| SignalBus | Zero coupling between systems |
| Single source of truth | No state sync bugs |
| Layer separation | Easy to test, modify, extend |
| Efficiency system | Workers auto-balance production |

### Cons

| Issue | When Critical |
|-------|---------------|
| Indirection | Harder to trace signal flow |
| Boilerplate | Many small files |
| Global state | SaveFile is technically global |
| Learning curve | Need to understand architecture first |

---

## Summary

| Problem | Solution |
|---------|----------|
| Tight coupling | SignalBus decouples all systems |
| Hardcoded data | .tres resource files |
| State scattered | SaveFile single source of truth |
| Mixed responsibilities | Controller/Manager/UI split |
| Content requires code | Data-driven design |
| Testing difficulty | Signal-based, mockable |

**Key Flow:**
```
User Input → UI → SignalBus → Controller → SignalBus → Manager → SignalBus → UI
```

**Golden Rules:**
1. Controllers = **when** (timers, validation, calculations)
2. Managers = **what** (state updates, SaveFile sync)
3. UI = **display** (no business logic)
4. SignalBus = **glue** (no direct references)
5. SaveFile = **truth** (read from here, write through managers)
