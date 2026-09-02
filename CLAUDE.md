# Godot Game Development Rules

- Check `game_kit/` before building anything from scratch. Game code depends on kit, never the reverse.
- Use `SB` signals for cross-system coordination; use groups only for dynamic scene discovery.
- Build entities by composing child scenes. Not inheritance trees — add/remove components as nodes.
- Emit signals up, call methods down. Siblings never talk directly — a common ancestor mediates.
- Separate logic from data: one scene + many `.tres` Resource variants. Not a scene-per-type.
- Prefer explicit types for variables, arguments, return values, and collections in game code.
- Spawn dynamic objects to the level node. Not to the spawner — children die with parents.

---

## Use the Game Kit

Check `game_kit/` before building from scratch — it has scene management, character rigs, camera, dialogs, UI components, effects, shaders, and utilities.

Dependencies flow one way: game code imports from kit. Not the reverse — kit stays game-agnostic.

---

## Coordinate Entities Through Signals

Entities subscribe to `SB` events and ignore events addressed to another instance. This keeps task assignment independent of scene-tree paths.

```gdscript
func _ready() -> void:
    SB.task_assigned.connect(_on_task_assigned)

func _on_task_assigned(task: TaskData, developer: Developer, _position: Vector2) -> void:
    if developer != self:
        return
    _current_task = task
```

Not level-wired references (`developer.task = task`) or hardcoded scene paths between systems.

---

## Composition Over Inheritance

Assemble entities from small, self-contained child scenes. Each component does one thing and knows nothing about its host.

```
Developer (Node2D)
  +-- DevRig           # visuals and animation
  +-- TaskCard         # current task display
  +-- ClickableTrait   # click input
  +-- UiBoostStack     # boost state display
```

Add or remove a trait node to change an entity's capability instead of growing an inheritance tree.

---

## Emit Up, Call Down

Children emit signals. Parents connect and react. Siblings never talk directly. This governs nodes *within one entity's tree* — interactions *between* entities go through component pairs and collision layers (see Autonomous Entities), not direct sibling calls.

```gdscript
# finish_trigger.gd
signal triggered

func _on_body_entered(body: Node2D) -> void:
    triggered.emit()  # don't know or care what happens next

# level.gd
func _ready() -> void:
    %FinishTrigger.triggered.connect(_on_level_complete)
```

Not `get_parent().get_parent().load_next_level()`

---

## Separate Logic from Data

One scene, many variants. Feed different `.tres` Resource files for different textures, sounds, and stats.

```gdscript
class_name DeveloperData extends BaseGameData
@export var head_texture: Texture2D
@export var head_offset: Vector2 = Vector2.ZERO
@export var task_mults: Dictionary = {}
@export var base_attack_speed: float = Constants.BASE_ATTACK_SPEED
```

New developer type = duplicate a `.tres` and change its values. Not a new scene and script per variant.

**Shared instance gotcha:** multiple nodes referencing the same `.tres` share one instance. Duplicate a shared resource before mutating its runtime fields; use `duplicate(true)` when nested resources must also be independent:

```gdscript
func _ready() -> void:
    stat = stat.duplicate(true)
```

---

## Keep Dynamic Scene Objects Alive

Add dynamic scene objects that must outlive their creator as children of the level. Find it by group.

```gdscript
func _spawn_effect(effect_scene: PackedScene, target_pos: Vector2) -> void:
    var effect: Node2D = effect_scene.instantiate()
    var level: Node = get_tree().get_first_node_in_group("level")
    level.add_child(effect)
    effect.global_position = target_pos
```

Not `add_child(effect)` on a short-lived creator when the effect must continue after that creator is freed.

---

## Use Unique Names for References

Use `%NodeName` for intra-scene references. Not `$Path/To/Deep/Node` — breaks on tree reorganization.

```gdscript
@onready var health_bar: ProgressBar = %HealthBar
```

`%Name` only works within the scene that defines it. For cross-scene access, use groups or signals.

---

## Input Through Traits

Reusable trait nodes own generic interaction mechanics and emit signals to their parent entity.

```gdscript
signal clicked

func _on_input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed:
        viewport.set_input_as_handled()
        clicked.emit()
```

Not duplicating mouse-input handling in every clickable entity.

---

## Type Everything

Prefer explicit static typing for variables, arguments, return values, and collections in game code. Existing game-kit utilities are only partially typed.

```gdscript
var current_health: int = 0
@onready var health_bar: ProgressBar = %HealthBar
@export var data: DeveloperData

func apply_damage(damage: int, attacker: Node2D, knockback_force: int = 0) -> void:

const SCENE_TRANSITIONS: Dictionary[PackedScene, PackedScene] = { ... }
var visited_zones: Array[String] = []
var drop: PartDrop = PART_DROP.instantiate()
```

---

## Log Important Events

Use `Log` for state changes, lifecycle events, and decisions. Not every-frame logging — that floods output and hides signal.

```gdscript
Log.log_info(self.name, "Starting to load level: %s" % scene_name)
Log.log_debug(self.name, "Changing state from %s to %s" % [old_state, new_state])
Log.log_warn(self.name, "Can't spawn bullet, no bullet stat")
```

---

## Reference: Script Section Order

New or substantially edited gameplay scripts should follow this section order, separated by `# --- Section Name ---` comments. Omit empty sections.

```gdscript
# --- Enums ---
# --- Constants ---
# --- Signals ---
# --- Exports ---
# --- @onready ---
# --- State ---          # private vars
# --- Lifecycle ---      # _ready, _process, _physics_process, _enter_tree, _exit_tree
# --- Handlers ---       # _on_* callbacks, signal handlers
# --- Public ---         # methods callable from outside
# --- Private ---        # internal methods
```

---

## Reference: Project Structure

```
game_kit/     # Reusable kit — scene manager, rigs, camera, dialogs, UI, effects, shaders, utils
components/   # Game entities — player, enemies, bullets, interactive objects
levels/       # Level scenes and level-specific scripts
game_data/    # Resource classes (.gd) and their instances (.tres) together
assets/       # Art, music, sound effects
data/         # External data files (dialog JSON, configs)
```

---

## Reference: Game Kit Contents

```
game_kit/
  components/base_game/ # Scene manager with fade transitions
  components/base_rig/  # Character animation rig (walk, hit flash, sprites)
  camera/               # Smooth follow camera with zoom and shake
  components/dialog_manager/      # Dialog orchestration
  components/dialog_conversation/ # JSON-driven conversations
  ui/                   # UI components (health bars, action bars, todo lists, upgrade dialogs)
  components/floating_text/       # Floating text effects
  autoloads/            # BaseSignalBus, BaseConstants
  globals/              # Animations, Groups, Growth, Log, Utils
```

---

## Reference: Log API

```gdscript
Log.log_debug(self.name, "message")  # verbose, disabled with Log.show_debug = false
Log.log_info(self.name, "message")   # key events
Log.log_warn(self.name, "message")   # unexpected but recoverable
Log.log_error(self.name, "message")  # something broke
```

Output format: `[timestamp] [LEVEL] (NodeName) message`
