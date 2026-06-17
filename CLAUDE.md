# Godot Game Development Rules

- Check `game_kit/` before building anything from scratch. Game code depends on kit, never the reverse.
- Find other entities through groups. Not autoload-held references, not manual wiring — entities self-connect or gracefully idle.
- Build entities by composing child scenes. Not inheritance trees — add/remove components as nodes.
- Emit signals up, call methods down. Siblings never talk directly — a common ancestor mediates.
- Separate logic from data: one scene + many `.tres` Resource variants. Not a scene-per-type.
- Type everything: variables, arguments, return values, collections. No untyped code.
- Spawn dynamic objects to the level node. Not to the spawner — children die with parents.

---

## Use the Game Kit

Check `game_kit/` before building from scratch — it has scene management, character rigs, camera, dialogs, UI components, effects, shaders, and utilities.

Dependencies flow one way: game code imports from kit. Not the reverse — kit stays game-agnostic.

---

## Find Everything Through Groups

Query groups to discover other entities at runtime. Entities self-connect or gracefully idle when no target exists.

```gdscript
func _physics_process(_delta: float) -> void:
    if not is_instance_valid(target):
        target = _find_target()
    if not target:
        return  # no player? just idle. no crash.
    move_toward(target.global_position)

func _find_target() -> Node2D:
    var targets: Array[Node] = get_tree().get_nodes_in_group("player")
    return Utils.find_closest_target(targets, self)
```

Not `GameManager.player` (autoload) — can't test standalone, crashes without the whole game running.
Not level-wired references (`enemy.target = player`) — silent bugs when new entities are added.

Autoloads are fine for cross-cutting services (`Log`, `BaseSignalBus`, `BaseConstants`) — just never for holding entity references.

---

## Autonomous Entities

Every entity acts independently. It finds what it needs through the environment (groups, collision layers, component detection). Drop it on a map — it works.

```gdscript
func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox:
        area.take_damage(damage, self, knockback)
```

Not type-checking each entity (`if body is Player... elif body is Enemy`) — misses new types silently.

Interactions are defined by component pairs (Hurtbox/Hitbox, PickupCatcher/Pickup, Usebox/Interactable). Add a component node to grant a capability. Remove it to revoke. No code changes elsewhere.

---

## Composition Over Inheritance

Assemble entities from small, self-contained child scenes. Each component does one thing and knows nothing about its host.

```
Entity (CharacterBody2D)
  +-- CharacterRig    # visual rig, walk animation, hit flash
  +-- HealthBar       # HP display
  +-- Hurtbox         # can receive damage
  +-- Hitbox          # can deal melee damage (optional)
  +-- BulletSpawn     # can shoot (optional)
```

Boss needs melee AND ranged? It has both Hitbox and BulletSpawn. Not an inheritance tree that breaks at `BossEnemy extends MeleeEnemy AND RangedEnemy`.

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
class_name EnemyStat extends Resource
@export var texture: Texture2D
@export var hurt_sound: AudioStream
@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 100.0
```

New enemy type = duplicate a `.tres`, change values. Not a new scene + new script per variant.

**Shared instance gotcha:** multiple nodes referencing the same `.tres` share ONE instance. Duplicate mutable state in `_ready()`:

```gdscript
func _ready() -> void:
    stat = stat.duplicate()
```

---

## Spawn to Level, Not to Self

Add dynamic objects (bullets, drops, effects) as children of the level. Find it by group.

```gdscript
func _shoot(target_pos: Vector2) -> void:
    var bullet: Bullet = BULLET.instantiate()
    var level: Node = get_tree().get_first_node_in_group("level")
    level.add_child(bullet)
    bullet.init(global_position, target_pos)
```

Not `add_child(bullet)` on the spawner — bullet moves with shooter, dies when shooter dies.

---

## Use Unique Names for References

Use `%NodeName` for intra-scene references. Not `$Path/To/Deep/Node` — breaks on tree reorganization.

```gdscript
@onready var health_bar: ProgressBar = %HealthBar
```

`%Name` only works within the scene that defines it. For cross-scene access, use groups or signals.

---

## Physics Layers as a Contract

Collision layers define who interacts with whom. Name them, assign them systematically. The layer setup IS the interaction rulebook.

```gdscript
func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox:
        area.take_damage(stat.damage, self, stat.knockback_force)
    kill()
```

Not branching on entity type in code (`if type == PLAYER and body is Enemy`) — add a new layer and set masks instead.

---

## Type Everything

Use static typing on all variables, arguments, return values, and collections.

```gdscript
var current_health: int = 0
@onready var health_bar: ProgressBar = %HealthBar
@export var stat: BaseEnemyStat

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

Every GDScript file follows this section order, separated by `# --- Section Name ---` comments. Omit empty sections. Every present section ALWAYS has the comment header.

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
  dialogs/              # Full dialog system (JSON-driven conversations)
  ui/                   # UI components (health bars, action bars, todo lists, upgrade dialogs)
  effects/              # VFX (hurt effect, slash effect, damage numbers)
  shaders/              # Reusable shaders (color overlay, masks)
  globals/              # Logger
  autoloads/            # BaseSignalBus, BaseConstants
  utils/                # Animations (tween factories), Utils
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
