# Unit-Trait-Action Architecture for RTS Games in Godot

## TL;DR

Composition-based unit architecture with three key principles:
- **Unit** — identity and core data (hp, damage, ownership)
- **Traits** — permanent capabilities as child nodes (Movement, Production, HealthBar)
- **Actions** — temporary behavior, single active at a time (MoveAction, AttackAction)
- **SignalBus** — decouples input detection from action assignment

---

## What Problems It Solves

### Problem 1: Inheritance Explosion

```
# Bad: deep hierarchy with diamond problem
Unit
├── MovableUnit
│   ├── AttackingMovableUnit
│   │   ├── Tank
│   │   └── Helicopter
│   └── GatheringMovableUnit
│       └── Worker
└── StaticUnit
    ├── AttackingStaticUnit
    │   └── Turret
    └── ProducingStaticUnit
        └── Factory

# Need MovableProducingUnit?
# AttackingGatheringUnit?
# → Class explosion, diamond problem
```

**Solution:** Composition — mix traits freely:

```
Tank       = Unit + Movement + Attack traits
Worker     = Unit + Movement + Gathering traits
Turret     = Unit + Obstacle + Attack traits
Factory    = Unit + Obstacle + Production traits

# New combo? Just add traits:
MobileFactory = Unit + Movement + Production traits
HarvesterTank = Unit + Movement + Attack + Gathering traits
```

### Problem 2: Mixed Behavior Logic

```gdscript
# Bad: all logic in one giant class
class_name Unit

func _process(delta):
    if is_moving:
        _do_movement(delta)
    if is_attacking:
        _do_attack(delta)
    if is_gathering:
        _do_gathering(delta)
    if is_building:
        _do_building(delta)
    # ... grows endlessly

# Problems:
# - Can't have "move while gathering" without complex state
# - Hard to add new behaviors
# - Single file becomes huge
```

**Solution:** Actions — one active behavior at a time, actions can have sub-actions for complex flows.

### Problem 3: Tight Coupling Between Input and Logic

```gdscript
# Bad: input handler knows all action types
func _on_right_click(position):
    if selected_unit.has_trait("movement"):
        selected_unit.move_to(position)  # Direct call
    elif selected_unit.has_trait("attack"):
        selected_unit.attack(position)   # Direct call

# Problems:
# - Input handler coupled to unit implementation
# - Hard to add new actions
# - No priority system
```

**Solution:** Event Bus + Controller pattern — distributed detection, centralized decision making.

### Problem 4: State Synchronization

```gdscript
# Bad: multiple places track same state
class Unit:
    var is_moving = false
    var is_attacking = false
    var current_target = null

class MovementSystem:
    var units_moving = {}  # Duplicate!

class UI:
    var unit_states = {}   # Another duplicate!

# Problems:
# - State gets out of sync
# - Which one is correct?
```

**Solution:** Single action reference — `unit.action` is the only source of truth for current behavior.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Unit (identity + data)                   │
│  hp, damage, range, player ownership                        │
│  action: Node = null (0 or 1 active action)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ children
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────────┐
    │  Traits  │    │  Traits  │    │    Action    │
    │(permanent)│    │ (visual) │    │ (temporary)  │
    ├──────────┤    ├──────────┤    ├──────────────┤
    │ Movement │    │HealthBar │    │ MoveAction   │
    │Production│    │Selection │    │ AttackAction │
    │ Attack   │    │Highlight │    │ GatherAction │
    └──────────┘    └──────────┘    └──────────────┘
```

**Data Flow (user input to action):**

```
User right-clicks on terrain
        │
        ▼
Terrain (StaticBody3D): detects input_event
        │
        ▼
MatchSignals.terrain_targeted.emit(position)
        │
        ▼
UnitActionsController: listens to signal
        │
        ├── MoveAction.is_applicable(unit)? → Yes
        │
        ▼
unit.action = MoveAction.new(position)
        │
        ▼
MoveAction finds Movement trait
        │
        ▼
movement.move(position)
        │
        ▼
movement.movement_finished.emit()
        │
        ▼
MoveAction.queue_free()
```

**Runtime Node Structure:**

```
Tank (Unit)
├── Movement (Trait)              ← permanent
├── Selection (Trait)             ← permanent
├── HealthBar (Trait)             ← permanent
├── Geometry                      ← 3D model
└── AutoAttackAction              ← temporary
    └── AttackWhileInRangeAction  ← sub-action

Worker (Unit)
├── Movement (Trait)
├── Selection (Trait)
├── HealthBar (Trait)
├── Geometry
└── GatherResourcesAction
    └── MoveToUnitAction          ← sub-action
```

---

## Components

### 1. Unit (Identity Layer)

Base entity holding core data. All units inherit from this.

```gdscript
extends Area3D
class_name Unit

# Core stats
var hp: float
var hp_max: float
var attack_damage: float
var attack_range: float
var attack_interval: float

# Ownership
var player:
    get: return get_parent()

# Current behavior (0 or 1 action)
var action: Node = null:
    set = _set_action

signal action_changed(action)

func _set_action(new_action: Node):
    # Remove old action
    if action != null and action.is_inside_tree():
        action.queue_free()
        remove_child(action)

    # Add new action as child
    action = new_action
    if action != null:
        action.tree_exited.connect(_on_action_finished.bind(action))
        add_child(action)

    action_changed.emit(action)

func _on_action_finished(finished_action: Node):
    if finished_action == action:
        action = null
```

**Key points:**
- Simple data stays here (hp, damage, range)
- Player ownership via parent node
- Single action at a time, managed as child node

---

### 2. Traits (Permanent Capabilities)

Child nodes providing abilities. Always present on the unit.

| Type | Base Class | Examples |
|------|------------|----------|
| Logical | Node | Movement, ProductionQueue |
| Visual | Node3D | HealthBar, Selection, Highlight |

#### Movement Trait

```gdscript
extends NavigationAgent3D
class_name MovementTrait

signal movement_finished

@export var speed: float = 4.0

@onready var _unit: Unit = get_parent()

func _physics_process(delta):
    if is_navigation_finished():
        return

    var next_pos = get_next_path_position()
    var direction = _unit.global_position.direction_to(next_pos)
    var velocity = direction * speed * delta

    _unit.global_position += velocity
    _unit.look_at(next_pos)

func move(target: Vector3):
    target_position = target

func stop():
    target_position = _unit.global_position

func _on_navigation_finished():
    movement_finished.emit()
```

#### Production Trait

```gdscript
extends Node
class_name ProductionQueueTrait

signal unit_produced(unit_scene: PackedScene)

@export var queue_limit: int = 5

var _queue: Array[Dictionary] = []

@onready var _unit: Unit = get_parent()

func _process(delta):
    if _queue.is_empty():
        return

    _queue[0].time_left -= delta
    if _queue[0].time_left <= 0:
        _finish_production(_queue.pop_front())

func produce(unit_scene: PackedScene, build_time: float, cost: Dictionary) -> bool:
    if _queue.size() >= queue_limit:
        return false
    if not _has_resources(cost):
        return false

    _spend_resources(cost)
    _queue.append({
        "scene": unit_scene,
        "time_left": build_time,
        "time_total": build_time,
    })
    return true

func _finish_production(item: Dictionary):
    unit_produced.emit(item.scene)
```

#### HealthBar Trait (Visual)

```gdscript
extends Node3D
class_name HealthBarTrait

@onready var _unit: Unit = get_parent()
@onready var _bar: Sprite3D = $Bar

func _ready():
    _unit.hp_changed.connect(_update_bar)
    _update_bar()

func _update_bar():
    var ratio = _unit.hp / _unit.hp_max
    _bar.scale.x = ratio
```

---

### 3. Actions (Temporary Behavior)

Single child node controlling current behavior. Only one active at a time.

#### Base Action

```gdscript
extends Node
class_name Action

@onready var _unit: Unit = _find_parent_unit()

func _find_parent_unit() -> Unit:
    var node = get_parent()
    while node != null:
        if node is Unit:
            return node
        node = node.get_parent()
    return null

# Override in subclasses
static func is_applicable(source: Unit, target) -> bool:
    return false
```

#### Simple Action: Move

```gdscript
extends Action
class_name MoveAction

var _target_position: Vector3

@onready var _movement: MovementTrait = _unit.find_child("Movement")

func _init(target: Vector3):
    _target_position = target

static func is_applicable(source: Unit, _target) -> bool:
    return source.find_child("Movement") != null

func _ready():
    _movement.movement_finished.connect(_on_finished)
    _movement.move(_target_position)

func _exit_tree():
    if is_inside_tree():
        _movement.stop()

func _on_finished():
    queue_free()
```

#### Composite Action: Auto-Attack

Actions can have sub-actions for complex behaviors.

```gdscript
extends Action
class_name AutoAttackAction

var _target_unit: Unit
var _sub_action: Action

@onready var _movement: MovementTrait = _unit.find_child("Movement")

func _init(target: Unit):
    _target_unit = target

static func is_applicable(source: Unit, target) -> bool:
    return (
        source.attack_range != null
        and target is Unit
        and source.player != target.player
    )

func _ready():
    _target_unit.tree_exited.connect(queue_free)
    _attack_or_chase()

func _attack_or_chase():
    var distance = _unit.global_position.distance_to(_target_unit.global_position)

    if distance <= _unit.attack_range:
        _sub_action = AttackWhileInRangeAction.new(_target_unit)
    else:
        _sub_action = ChaseUntilInRangeAction.new(_target_unit, _unit.attack_range)

    _sub_action.tree_exited.connect(_on_sub_action_finished)
    add_child(_sub_action)

func _on_sub_action_finished():
    if not is_inside_tree() or not _target_unit.is_inside_tree():
        return
    _attack_or_chase()  # Loop: chase → attack → chase...
```

#### State Machine Action: Resource Gathering

```gdscript
extends Action
class_name GatherResourcesAction

enum State { MOVING_TO_RESOURCE, GATHERING, MOVING_TO_BASE }

var _state: State
var _resource_node: Node
var _base_node: Node
var _sub_action: Action

func _init(resource: Node):
    _resource_node = resource

func _ready():
    _change_state(State.MOVING_TO_RESOURCE)

func _change_state(new_state: State):
    _state = new_state

    match _state:
        State.MOVING_TO_RESOURCE:
            _sub_action = MoveToUnitAction.new(_resource_node)
        State.GATHERING:
            _sub_action = GatherWhileInRangeAction.new(_resource_node)
        State.MOVING_TO_BASE:
            _sub_action = MoveToUnitAction.new(_base_node)

    _sub_action.tree_exited.connect(_on_sub_action_finished)
    add_child(_sub_action)

func _on_sub_action_finished():
    match _state:
        State.MOVING_TO_RESOURCE:
            _change_state(State.GATHERING)
        State.GATHERING:
            _base_node = _find_nearest_base()
            _change_state(State.MOVING_TO_BASE)
        State.MOVING_TO_BASE:
            _deposit_resources()
            _change_state(State.MOVING_TO_RESOURCE)
```

---

### 4. SignalBus (Event Decoupling)

Global signals for system-wide events, local signals for direct communication.

```gdscript
# match_signals.gd — autoload singleton
extends Node

# Input events
signal terrain_targeted(position: Vector3)
signal unit_targeted(unit: Unit)

# Unit lifecycle
signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)

# Selection
signal unit_selected(unit: Unit)
signal unit_deselected(unit: Unit)
signal deselect_all_units

# Production
signal unit_production_started(unit_prototype, producer)
signal unit_production_finished(unit, producer)
```

**When to use what:**

| Scenario | Use | Why |
|----------|-----|-----|
| Unit dies | Event Bus | Many listeners: AI, HUD, sounds |
| Unit HP changes | Local signal | Few listeners: HealthBar only |
| Movement finished | Local signal | Only parent Action listens |
| Unit spawned | Event Bus | Minimap, FogOfWar need to know |

---

### 5. Input Controller (Centralized Logic)

```gdscript
# unit_actions_controller.gd
extends Node

func _ready():
    MatchSignals.terrain_targeted.connect(_on_terrain_targeted)
    MatchSignals.unit_targeted.connect(_on_unit_targeted)

func _on_terrain_targeted(position: Vector3):
    for unit in get_tree().get_nodes_in_group("selected_units"):
        if MoveAction.is_applicable(unit, position):
            unit.action = MoveAction.new(position)

func _on_unit_targeted(target_unit: Unit):
    for unit in get_tree().get_nodes_in_group("selected_units"):
        _assign_appropriate_action(unit, target_unit)

func _assign_appropriate_action(unit: Unit, target: Unit):
    # Priority order — first applicable wins
    if GatherAction.is_applicable(unit, target):
        unit.action = GatherAction.new(target)
    elif AutoAttackAction.is_applicable(unit, target):
        unit.action = AutoAttackAction.new(target)
    elif FollowAction.is_applicable(unit, target):
        unit.action = FollowAction.new(target)
```

---

## Usage

### Interaction Pattern

Actions command traits. Never manipulate unit directly.

```
GatherResourcesAction (what to do)
         │
         ▼
    MoveToUnitAction (sub-action)
         │
         ▼ finds trait
    movement = _unit.find_child("Movement")
         │
         ▼ commands trait
    movement.move(target_position)
         │
         ▼ trait does the work
    NavigationAgent3D pathfinding
         │
         ▼ trait signals completion
    movement_finished.emit()
         │
         ▼ action reacts
    queue_free() or change state
```

### Adding New Unit Type

**1. Create scene with traits as children:**

```
MobileFactory.tscn
├── MobileFactory (Unit script)
├── Movement (MovementTrait)
├── ProductionQueue (ProductionQueueTrait)
├── HealthBar (HealthBarTrait)
├── Selection (SelectionTrait)
└── Geometry (3D model)
```

**2. No code changes needed.** Controller checks `is_applicable()` for each action.

### Adding New Action

**1. Create action script:**

```gdscript
extends Action
class_name RepairAction

var _target_building: Unit

func _init(building: Unit):
    _target_building = building

static func is_applicable(source: Unit, target) -> bool:
    return (
        source.find_child("Repair") != null
        and target.has_trait("Repairable")
    )

func _ready():
    # ... implementation
```

**2. Add to controller priority list:**

```gdscript
func _assign_appropriate_action(unit: Unit, target: Unit):
    if RepairAction.is_applicable(unit, target):  # NEW
        unit.action = RepairAction.new(target)
    elif GatherAction.is_applicable(unit, target):
        # ...
```

---

## Best Practices

### DO: Cache trait references

```gdscript
@onready var _movement = _unit.find_child("Movement")

func _ready():
    _movement.move(target)
```

### DON'T: Search every frame

```gdscript
# Bad: 60 searches per second
func _physics_process(delta):
    var movement = _unit.find_child("Movement")
    movement.move(target)
```

### DO: Use signals for communication

```gdscript
# Trait signals when done
movement_finished.emit()

# Action listens
_movement.movement_finished.connect(_on_finished)
```

### DON'T: Action manipulating unit directly

```gdscript
# Bad
func _physics_process(delta):
    _unit.global_position += velocity * delta

# Good
func _ready():
    _movement.move(target)
```

### DO: Clean up on exit

```gdscript
func _exit_tree():
    if is_inside_tree():
        _movement.stop()
```

### DON'T: Multiple simultaneous actions

```gdscript
# This replaces, doesn't add
unit.action = MoveAction.new(pos)
unit.action = AttackAction.new(enemy)  # MoveAction gone

# For parallel behavior, use composite action
unit.action = MoveAndShootAction.new(pos, enemy)
```

---

## File Structure

```
units/
├── unit.gd                 # Base Unit class
├── traits/
│   ├── movement.gd
│   ├── production_queue.gd
│   ├── health_bar.gd
│   └── selection.gd
├── actions/
│   ├── action.gd           # Base Action class
│   ├── move.gd
│   ├── auto_attack.gd
│   ├── gather_resources.gd
│   └── ...
├── tank/
│   ├── tank.tscn           # Scene with traits
│   └── tank.gd             # Optional unit-specific
└── worker/
    ├── worker.tscn
    └── worker.gd

signals/
└── match_signals.gd        # Event bus autoload

controllers/
└── unit_actions_controller.gd
```

---

## Pros and Cons

### Pros

| Feature | Benefit |
|---------|---------|
| Composition | Mix traits freely, no diamond problem |
| Single action | Clear current behavior, no state sync |
| Sub-actions | Complex flows via composition |
| is_applicable() | Self-documenting requirements |
| Event bus | Decoupled input from logic |

### Cons

| Issue | When Critical |
|-------|---------------|
| find_child() overhead | Cache references to mitigate |
| Many small files | Use folders to organize |
| Action priority in controller | Can grow large |
| No parallel actions | Need composite action pattern |

---

## Summary

| Layer | Lifetime | Count per Unit | Responsibility |
|-------|----------|----------------|----------------|
| Unit | Permanent | 1 | Identity, stats, ownership |
| Trait | Permanent | 0-N | Capability (movement, production) |
| Action | Temporary | 0-1 | Current behavior (moving, attacking) |

| Problem | Solution |
|---------|----------|
| Inheritance explosion | Composition via traits |
| Mixed behavior logic | Single action, sub-actions |
| Tight input coupling | Event bus + controller |
| State synchronization | unit.action is source of truth |
| Adding new unit types | Just combine traits in scene |
| Adding new behaviors | Create action + add to controller |

**Key Flow:**
```
Input → EventBus → Controller → unit.action = Action.new()
Action → finds Trait → commands Trait → Trait signals → Action reacts
```

**Golden Rules:**
1. Unit = **who** (identity, stats)
2. Traits = **can do** (permanent capabilities)
3. Actions = **doing** (temporary behavior)
4. Actions command Traits, never Unit directly
5. One action at a time, use sub-actions for complexity
