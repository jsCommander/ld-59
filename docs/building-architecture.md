# Building Architecture

One scene, one script, many variants via `.tres` Resources. Buildings differ by data, not by code.

## Core Structure

```
building.tscn (building.gd)
  ├── Sprite2D
  ├── Hurtbox
  ├── HealthBar
  └── ProductionQueue
```

All buildings share the same scene. Behavior is defined by `BuildingStat` resource attached via `@export`.

## BuildingStat Resource

```gdscript
# building_stat.gd
class_name BuildingStat
extends Resource

@export var name: String
@export var icon: Texture2D
@export var max_health: int = 100
@export var products: Array[ProductionItem] = []  # what it can produce
@export var resource_drain: float = 0.0           # consumption per second
@export var resource_output: float = 0.0          # production per second
```

Empty `products` array means the building doesn't produce anything — the production queue sits idle, UI shows no buttons. Zero `resource_drain` means no upkeep. Each field is effectively optional.

### Building Variants

```
resources/buildings/
  robot_platform.tres  → { products: [robot_collector.tres], drain: 5.0 }
  generator.tres       → { output: 10.0 }
  drill.tres           → { drain: 2.0 }
  lab.tres             → { products: [upgrade_speed.tres, upgrade_capacity.tres] }
```

50 buildings = 50 `.tres` files. Zero new scenes, zero new scripts.

## ProductionQueue Component

A generic queue that knows nothing about resources, biofuel, or the player. It receives items, waits, emits signals.

```gdscript
# production_queue.gd
class_name ProductionQueue
extends Node

signal production_started(item: ProductionItem)
signal production_completed(scene: PackedScene)
signal queue_changed

@export var max_queue_size: int = 5

var _queue: Array[ProductionItem] = []
var _current: ProductionItem = null
var _time_left: float = 0.0

func _process(delta: float) -> void:
    if not _current:
        _try_start_next()
        return
    _time_left -= delta
    if _time_left <= 0.0:
        var scene: PackedScene = _current.scene
        _current = null
        production_completed.emit(scene)
        _try_start_next()

func enqueue(item: ProductionItem) -> bool:
    if _queue.size() >= max_queue_size:
        return false
    _queue.append(item)
    queue_changed.emit()
    return true

func cancel(index: int) -> ProductionItem:
    if index < 0 or index >= _queue.size():
        return null
    var item: ProductionItem = _queue[index]
    _queue.remove_at(index)
    queue_changed.emit()
    return item  # caller decides refund policy

func get_progress() -> float:
    if not _current:
        return 0.0
    return 1.0 - (_time_left / _current.production_time)

func get_queue_size() -> int:
    return _queue.size() + (1 if _current else 0)

func _try_start_next() -> void:
    if _queue.is_empty():
        return
    _current = _queue.pop_front()
    _time_left = _current.production_time
    production_started.emit(_current)
```

## ProductionItem Resource

Describes what can be produced — the unit scene, time, cost, and UI data.

```gdscript
# production_item.gd
class_name ProductionItem
extends Resource

@export var scene: PackedScene
@export var production_time: float = 3.0
@export var cost: float = 10.0
@export var icon: Texture2D
@export var name: String = ""
```

### Production Item Variants

```
resources/production/
  robot_collector.tres  → { scene: robot.tscn, time: 3.0, cost: 10.0 }
  upgrade_speed.tres    → { scene: null, time: 5.0, cost: 25.0 }
```

## Building Script

The building is a mediator. Children emit signals up, the building listens and coordinates.

```gdscript
# building.gd
class_name Building
extends Node2D

signal destroyed

@export var stat: BuildingStat

@onready var production_queue: ProductionQueue = %ProductionQueue
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var health_bar: ProgressBar = %HealthBar

var current_health: int

func _ready() -> void:
    stat = stat.duplicate()
    current_health = stat.max_health
    production_queue.production_completed.connect(_on_production_completed)
    hurtbox.damage_taken.connect(_on_damage_taken)

func request_production(item: ProductionItem, player: Player) -> void:
    if not player.has_resources(item.cost):
        return
    if production_queue.enqueue(item):
        player.spend(item.cost)

func _on_production_completed(scene: PackedScene) -> void:
    var unit: Node2D = scene.instantiate()
    var level: Node2D = get_tree().get_first_node_in_group("level")
    level.add_child(unit)
    unit.global_position = global_position

func _on_damage_taken(damage: int) -> void:
    current_health -= damage
    health_bar.value = float(current_health) / stat.max_health
    if current_health <= 0:
        destroyed.emit()
        queue_free()
```

## Signal Flow

```
ProductionQueue  ──(production_completed)──►  Building  ──(call down)──►  spawns unit to level
Hurtbox          ──(damage_taken)──────────►  Building  ──(call down)──►  HealthBar.update()
Building         ──(destroyed)─────────────►  Level     ──────────────►  handles cleanup
```

Children emit signals. Building connects and reacts. Siblings never talk directly.

## Economy

Player resources (biofuel) are centralized in a single node. Buildings don't subtract from the pool independently — a centralized economy tick handles income and drain to avoid frame-order race conditions.

```gdscript
# economy tick (centralized)
func _process(delta: float) -> void:
    var total_drain: float = 0.0
    for building in get_tree().get_nodes_in_group("building"):
        total_drain += building.stat.resource_drain
    total_drain *= storm_multiplier
    biofuel += (total_income - total_drain) * delta
```

Buildings find each other and external entities via groups, not singletons or manual wiring.
