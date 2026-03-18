# RTS Unit Architecture Guide

A pattern for building units in RTS games using composition over inheritance.

## Core Concept

Units are assembled from reusable components instead of deep class hierarchies:

```
Unit (identity + data)
├── Traits (permanent capabilities)
└── Action (temporary behavior)
```

**Unit** — who am I (stats, ownership)
**Traits** — what I can do (movement, production, visuals)
**Action** — what I'm doing right now (moving, attacking, gathering)

## Why This Pattern?

### Problem: Inheritance Explosion

```
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

# Need a MovableProducingUnit?
# AttackingGatheringUnit?
# → Class explosion, diamond problem
```

### Solution: Composition

```
Tank       = Unit + Movement + Attack traits
Worker     = Unit + Movement + Gathering traits
Turret     = Unit + Obstacle + Attack traits
Factory    = Unit + Obstacle + Production traits

# New combo? Just add traits:
MobileFactory = Unit + Movement + Production traits
HarvesterTank = Unit + Movement + Attack + Gathering traits
```

## The Three Layers

### Layer 1: Unit (Identity)

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
var sight_range: float

# Ownership
var player:
    get: return get_parent()

# Current behavior (0 or 1 action)
var action: Node = null:
    set = _set_action

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

### Layer 2: Traits (Permanent Capabilities)

Child nodes providing abilities. Always present on the unit.

**Two types:**

| Type    | Base Class | Examples                        |
| ------- | ---------- | ------------------------------- |
| Logical | Node       | Movement, ProductionQueue       |
| Visual  | Node3D     | HealthBar, Selection, Highlight |

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
    var direction = (_unit.global_position.direction_to(next_pos))
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

func produce(unit_scene: PackedScene, build_time: float, cost: Dictionary):
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

#### Visual Trait (HealthBar)

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

### Layer 3: Actions (Temporary Behavior)

Single child node controlling current behavior. Only one active at a time.

#### Base Action

```gdscript
extends Node
class_name Action

# Find parent unit
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

#### Simple Action: Move to Position

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

## Interaction Pattern

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

## Runtime Node Structure

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
    └── MoveToUnitAction
```

## Assigning Actions

Controller decides which action to assign based on context:

```gdscript
# In player input controller
func _on_right_click(unit: Unit, target):
    if target is ResourceNode:
        if GatherResourcesAction.is_applicable(unit, target):
            unit.action = GatherResourcesAction.new(target)
            return

    if target is Unit:
        if AutoAttackAction.is_applicable(unit, target):
            unit.action = AutoAttackAction.new(target)
            return
        if FollowAction.is_applicable(unit, target):
            unit.action = FollowAction.new(target)
            return

    if target is Vector3:
        if MoveAction.is_applicable(unit, target):
            unit.action = MoveAction.new(target)
```

## Best Practices

### DO: Cache trait references

```gdscript
# Once at ready
@onready var _movement = _unit.find_child("Movement")

func _ready():
    _movement.move(target)
    _movement.movement_finished.connect(_on_finished)
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

### DON'T: Tight coupling between actions

```gdscript
# Bad: action knows about specific other action
var other = OtherAction.new()
other.some_internal_method()

# Good: use sub-actions as children
var sub = OtherAction.new(params)
sub.tree_exited.connect(_on_sub_finished)
add_child(sub)
```

### DO: Check applicability before creating

```gdscript
static func is_applicable(source: Unit, target) -> bool:
    return (
        source.find_child("Movement") != null
        and target is ResourceNode
    )
```

### DON'T: Action manipulating unit position directly

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

## Data Management

### Option A: Centralized Dictionary

```gdscript
# All stats in one file
const UNIT_STATS = {
    "tank": {
        "hp": 100,
        "damage": 25,
        "range": 8.0,
    },
    "worker": {
        "hp": 50,
        "gather_speed": 1.0,
    },
}

# Unit loads its stats
func _ready():
    var stats = UNIT_STATS[unit_type]
    for key in stats:
        set(key, stats[key])
```

**Pros:** One file, easy to compare, git-friendly
**Cons:** No type checking, no editor support

### Option B: Resource Files

```gdscript
class_name UnitStats extends Resource

@export var hp: int = 100
@export var hp_max: int = 100
@export var damage: float = 10.0
@export_range(1.0, 20.0) var attack_range: float = 5.0
```

```gdscript
# Unit scene has exported resource
@export var stats: UnitStats

func _ready():
    hp = stats.hp
    attack_damage = stats.damage
```

**Pros:** Type safety, editor support, inheritance
**Cons:** Multiple files, harder to compare

### Recommendation

- Small project (< 20 units): Dictionary
- Large project / team: Resources

## Event Bus vs Local Signals

Use **Event Bus** (global singleton) for system-wide events.
Use **local signals** for direct object-to-object communication.

### Event Bus (Global Signals)

Autoload singleton that decouples systems:

```gdscript
# match_signals.gd — autoload
extends Node

# Requests (commands)
signal deselect_all_units
signal setup_and_spawn_unit(unit, transform, player)
signal place_structure(structure_prototype)
signal navigate_unit_to_rally_point(unit, rally_point)

# Notifications (events)
signal match_started
signal match_finished_with_victory
signal match_finished_with_defeat
signal unit_spawned(unit)
signal unit_died(unit)
signal unit_damaged(unit)
signal unit_selected(unit)
signal unit_deselected(unit)
signal terrain_targeted(position)
signal unit_targeted(unit)
signal unit_production_started(unit_prototype, producer)
signal unit_production_finished(unit, producer)
signal not_enough_resources_for_production(player)
```

### Local Signals

Defined on objects, for direct 1-to-1 or 1-to-few relationships:

```gdscript
# Unit.gd
signal selected
signal deselected
signal hp_changed
signal action_changed(new_action)

# Player.gd
signal changed  # resources changed

# Movement trait
signal movement_finished

# ProductionQueue trait
signal element_enqueued(element)
signal element_removed(element)
```

### When to Use What

| Scenario                | Use          | Why                                              |
| ----------------------- | ------------ | ------------------------------------------------ |
| Unit dies               | Event Bus    | Many listeners: AI, HUD, sounds, match end check |
| Unit HP changes         | Local signal | Few listeners: HealthBar, DamageFlash            |
| Unit selected           | Both         | Local for Selection trait, global for HUD        |
| Player resources change | Local signal | Only ResourcesBar listens                        |
| Unit spawned            | Event Bus    | Minimap, FogOfWar, handlers need to know         |
| Movement finished       | Local signal | Only parent Action listens                       |
| Production finished     | Event Bus    | Rally point, sounds, AI need to know             |

### Decision Flowchart

```
Does the event affect multiple unrelated systems?
    │
    ├── YES → Event Bus
    │         (unit_died, unit_spawned, match_started)
    │
    └── NO → Does the listener have direct reference to emitter?
              │
              ├── YES → Local signal
              │         (hp_changed → HealthBar, movement_finished → Action)
              │
              └── NO → Event Bus
                        (need to find emitter by searching = use event bus)
```

### Event Bus Patterns

**Request pattern** — asking a system to do something:

```gdscript
# Anyone can request
MatchSignals.setup_and_spawn_unit.emit(unit, transform, player)

# Match system handles
func _ready():
    MatchSignals.setup_and_spawn_unit.connect(_on_setup_and_spawn_unit)

func _on_setup_and_spawn_unit(unit, transform, player):
    # actual spawning logic
```

**Notification pattern** — informing about something that happened:

```gdscript
# Unit notifies when it dies
func _handle_unit_death():
    MatchSignals.unit_died.emit(self)
    queue_free()

# Multiple systems react
# AI:
MatchSignals.unit_died.connect(_on_unit_died)
# Sound:
MatchSignals.unit_died.connect(_play_death_sound)
# Match end checker:
MatchSignals.unit_died.connect(_check_victory_condition)
```

### Local Signal Patterns

**Direct subscription** — listener knows the source:

```gdscript
# HealthBar knows its unit
@onready var _unit = get_parent()

func _ready():
    _unit.hp_changed.connect(_update_bar)
```

**Passed reference** — listener receives source:

```gdscript
# Action receives trait reference
@onready var _movement = _unit.find_child("Movement")

func _ready():
    _movement.movement_finished.connect(_on_movement_finished)
```

### Multiple Event Buses

For large projects, split by scope:

```gdscript
# Global (always exists) — e.g. global_signals.gd
GlobalSignals
├── settings_changed
└── debug_mode_toggled

# Match-scoped (exists during gameplay) — e.g. match_signals.gd
MatchSignals
├── unit_died
├── unit_spawned
└── terrain_targeted

# UI-scoped (optional) — e.g. ui_signals.gd
UISignals
├── menu_opened
└── tooltip_requested
```

### Anti-patterns

**DON'T: Event bus for direct communication**

```gdscript
# Bad: HealthBar subscribes to global signal, filters by unit
MatchSignals.unit_hp_changed.connect(func(unit):
    if unit == _my_unit:
        _update_bar()
)

# Good: Direct subscription
_unit.hp_changed.connect(_update_bar)
```

**DON'T: Local signal when many unrelated listeners**

```gdscript
# Bad: Everyone needs reference to unit to listen
unit.died.connect(...)  # AI needs reference
unit.died.connect(...)  # Sound needs reference
unit.died.connect(...)  # HUD needs reference

# Good: Event bus, no references needed
MatchSignals.unit_died.connect(...)  # anyone can listen
```

**DON'T: Circular event chains**

```gdscript
# Bad: A emits → B reacts → B emits → A reacts → loop
MatchSignals.foo.connect(func(): MatchSignals.bar.emit())
MatchSignals.bar.connect(func(): MatchSignals.foo.emit())
```

## User Input Handling

Input is handled using **distributed detection + centralized control** pattern.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INPUT DETECTION                          │
│                                                             │
│  Clickable nodes detect interactions via Godot signals      │
│  and emit global events                                     │
│                                                             │
│  Terrain (StaticBody3D)  ──► terrain_targeted(position)     │
│  Unit (Area3D)           ──► unit_targeted(unit)            │
│  Minimap (Control)       ──► terrain_targeted(position)     │
│                                                             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    EVENT BUS                                │
│                                                             │
│  Global signals decouple input from logic                   │
│                                                             │
│  MatchSignals.terrain_targeted(position)                    │
│  MatchSignals.unit_targeted(unit)                           │
│                                                             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    CONTROLLER                               │
│                                                             │
│  Listens to events, decides which action to assign          │
│                                                             │
│  UnitActionsController:                                     │
│    - Checks is_applicable() for each action type            │
│    - Assigns: unit.action = AppropriateAction.new(target)   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Input Detection (distributed)

Use Godot's built-in `input_event` signal on physics bodies:

```gdscript
# Terrain.gd — detects clicks on ground
extends StaticBody3D

func _ready():
    input_event.connect(_on_input_event)

func _on_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
    if (
        event is InputEventMouseButton
        and event.button_index == MOUSE_BUTTON_RIGHT
        and event.pressed
    ):
        var target = get_viewport().get_camera_3d().get_ray_intersection(event.position)
        MatchSignals.terrain_targeted.emit(target)
```

```gdscript
# Targetability.gd — trait that detects clicks on units
extends Node3D

@onready var _unit: Unit = get_parent()

func _ready():
    _unit.input_event.connect(_on_input_event)

func _on_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
    if (
        event is InputEventMouseButton
        and event.button_index == MOUSE_BUTTON_RIGHT
        and event.pressed
    ):
        MatchSignals.unit_targeted.emit(_unit)
```

### Event Bus (global signals)

```gdscript
# match_signals.gd — autoload singleton
extends Node

signal terrain_targeted(position: Vector3)
signal unit_targeted(unit: Unit)
signal unit_selected(unit: Unit)
signal unit_deselected(unit: Unit)
signal deselect_all_units
```

### Controller (centralized logic)

```gdscript
# unit_actions_controller.gd — child of Human player
extends Node

func _ready():
    MatchSignals.terrain_targeted.connect(_on_terrain_targeted)
    MatchSignals.unit_targeted.connect(_on_unit_targeted)


func _on_terrain_targeted(position: Vector3):
    for unit in get_tree().get_nodes_in_group("selected_units"):
        if MoveAction.is_applicable(unit):
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

### Why This Pattern?

| Approach                  | Pros                                  | Cons                              |
| ------------------------- | ------------------------------------- | --------------------------------- |
| **Distributed detection** | Uses Godot physics, no manual raycast | Logic spread across files         |
| **Centralized control**   | All decision logic in one place       | Controller knows all action types |
| **Event bus**             | Decouples input from logic            | Extra indirection                 |

### Adding New Input Types

**1. New clickable object:**

```gdscript
# building_site.gd
extends Area3D

func _ready():
    input_event.connect(_on_input_event)

func _on_input_event(_camera, event, ...):
    if right_click(event):
        MatchSignals.building_site_targeted.emit(self)
```

**2. Add signal to event bus:**

```gdscript
# match_signals.gd
signal building_site_targeted(site)
```

**3. Handle in controller:**

```gdscript
# unit_actions_controller.gd
func _ready():
    MatchSignals.building_site_targeted.connect(_on_building_site_targeted)

func _on_building_site_targeted(site):
    for unit in selected_units:
        if BuildAction.is_applicable(unit, site):
            unit.action = BuildAction.new(site)
```

### Keyboard Input

For hotkeys, use `_unhandled_input` in a dedicated handler:

```gdscript
# hotkey_handler.gd
extends Node

func _unhandled_input(event: InputEvent):
    if event.is_action_pressed("stop"):
        _stop_selected_units()
    elif event.is_action_pressed("attack_move"):
        _enable_attack_move_mode()


func _stop_selected_units():
    for unit in get_tree().get_nodes_in_group("selected_units"):
        unit.action = null  # clear action
```

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
│   ├── move_to_unit.gd
│   ├── auto_attack.gd
│   ├── attack_while_in_range.gd
│   ├── gather_resources.gd
│   └── gather_while_in_range.gd
├── tank/
│   ├── tank.tscn           # Scene with traits as children
│   └── tank.gd             # Optional unit-specific code
└── worker/
    ├── worker.tscn
    └── worker.gd
```

## Summary

| Layer  | Lifetime  | Count per Unit | Responsibility                       |
| ------ | --------- | -------------- | ------------------------------------ |
| Unit   | Permanent | 1              | Identity, stats, ownership           |
| Trait  | Permanent | 0-N            | Capability (movement, production)    |
| Action | Temporary | 0-1            | Current behavior (moving, attacking) |

**Flow:**

1. Controller assigns action to unit
2. Action finds required traits
3. Action commands traits via methods
4. Traits signal completion
5. Action transitions or finishes
6. Unit.action becomes null or new action

This pattern scales from simple RTS to complex games with many unit types and behaviors.
