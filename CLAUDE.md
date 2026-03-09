# Godot Game Development Principles

---

## Principle 1: Use the Game Kit

`game_kit/` contains reusable components that are battle-tested across projects. Before building something from scratch, check what's already there.

### What's in the kit

```
game_kit/
  scenes/base_game/     # Scene manager with fade transitions
  scenes/base_rig/      # Character animation rig (walk, hit flash, sprites)
  camera/               # Smooth follow camera with zoom and shake
  dialogs/              # Full dialog system (JSON-driven conversations)
  ui/                   # UI components (health bars, action bars, todo lists, upgrade dialogs)
  effects/              # VFX (hurt effect, slash effect, damage numbers)
  shaders/              # Reusable shaders (color overlay, masks)
  utils/                # Animations (tween factories), Logger, Utils
```

### Rule

The kit never imports from game-specific code. Dependencies flow one way: game code depends on kit, never the reverse.

---

## Principle 2: Project Structure

Game-specific code is organized by role, not by type. Each folder has a clear purpose.

```
scenes/       # Game entities — player, enemies, bullets, interactive objects
levels/       # Level scenes and level-specific scripts
scripts/      # Data type definitions — Resource classes (stats, parts, bullet configs)
resources/    # .tres instances of those data types — the actual values
assets/       # Art, music, sound effects
data/         # External data files (dialog JSON, configs)
```

### Rule

- `scripts/` = shape (class definitions). `resources/` = values (.tres files)
- `scenes/` = autonomous entities you drop on a level. Each works independently
- `levels/` = specific maps that assemble entities from `scenes/` and configure them via `resources/`

---

## Principle 3: Find Everything Through Groups

When one entity needs to know about another, it finds it by group. Not through an autoload, not through a reference passed from the level — it queries the group itself.

### Why

- Entity works standalone — drop an enemy on an empty scene, it just doesn't find a player. No crash, no null, no missing autoload dependency
- Autoload approach (`GameManager.player`) means you can't test the enemy without the whole game running
- Groups scale naturally — works with 1 player, 2 players, or 20
- No manual wiring from the level — enemy finds targets, camera finds its follow target, everything self-connects

### Example: Enemy needs to find the player

**BAD (autoload)** — enemy depends on a global singleton:

```gdscript
# enemy.gd
func _physics_process(_delta):
    var player = GameManager.player  # crash if GameManager not loaded
    move_toward(player.global_position)
    # can't run enemy scene standalone — needs the whole game bootstrapped
```

**BAD (manual wiring)** — level passes player to each enemy:

```gdscript
# level.gd
func _ready():
    for enemy in get_tree().get_nodes_in_group("enemy"):
        enemy.target = player
    # added a new enemy to the scene? forgot to re-run this? silent bug.
    # 2 players? rewrite everything.
```

**GOOD (groups)** — enemy finds the player itself:

```gdscript
# enemy.gd
func _physics_process(_delta):
    if not is_instance_valid(target):
        target = _find_target()
    if not target:
        return  # no player on scene? just idle. no crash, no null.
    move_toward(target.global_position)

func _find_target() -> Node2D:
    var targets = get_tree().get_nodes_in_group("player")
    return Utils.find_closest_target(targets, self)
```

Run the enemy scene alone — it idles. Drop a player on the map — enemy finds it. Drop 2 players — enemy picks the closest. No code changes.

---

## Principle 4: Autonomous Agents

Every entity is an autonomous agent that acts independently. It finds what it needs through the environment (groups, collision layers, component detection), not through explicit wiring from a parent. Drop an entity on the map — it works. No setup, no manual connections.

### Why

- Adding a new entity = drag and drop onto the scene, done
- Entities are reusable across levels without any level-specific code
- The level script stays thin — it handles level logic (win condition, music), not entity wiring

### Example: Hazards damage anything with a Hurtbox

**BAD** — hazard checks for every entity type:

```gdscript
func _on_body_entered(body):
    if body is Player:
        body.apply_damage(10, self, knockback)
    elif body is Enemy:
        body.apply_damage(10, self, knockback)
    # forgot NPCs... they walk through lava unharmed
```

**GOOD** — hazard hits any Hurtbox it overlaps:

```gdscript
func _on_area_entered(area):
    if area is Hurtbox:
        area.take_damage(damage, self, knockback)
```

### The Pattern

Interactions are defined by **component pairs**, not by entity types:

| Component A   | Component B     | Interaction     |
| ------------- | --------------- | --------------- |
| Hurtbox       | Hitbox / Hazard | Damage          |
| PickupCatcher | Pickup          | Item collection |
| Usebox        | Interactable    | Use/activate    |

To give an entity a new capability, add the component node. To remove it, delete the node. No code changes anywhere else.

---

## Principle 4: Composition Over Inheritance

Build complex entities by assembling small, self-contained scenes as children — not by creating deep inheritance trees. Each child component does one thing and knows nothing about its host.

### Why

- Components are reusable: a health bar works on a player, enemy, NPC, boss, a destructible barrel
- Easy to recombine: need a shooting enemy? Add a bullet spawner. Need one that talks? Add a dialog trigger
- No diamond inheritance problems — a boss can have both melee and ranged just by having both components

### Example

**BAD** — inheritance chain:

```
BaseCharacter
  +-- Player
  +-- BaseEnemy
       +-- MeleeEnemy
       +-- RangedEnemy
       +-- BossEnemy  # needs both melee AND ranged — inheritance breaks
```

**GOOD** — flat composition:

```
Entity (CharacterBody2D)
  +-- CharacterRig    # visual rig, walk animation, hit flash
  +-- HealthBar       # HP display
  +-- DamageNumber    # floating damage text
  +-- Hurtbox         # can receive damage
  +-- Hitbox          # can deal melee damage (optional)
  +-- BulletSpawn     # can shoot (optional)
```

Boss needs melee AND ranged? It has both Hitbox and BulletSpawn. No inheritance gymnastics.

---

## Principle 5: Emit Up, Call Down

Children emit signals. Parents connect and react. Siblings never talk to each other directly — a common ancestor mediates.

### Why

- Children don't know who listens — fully decoupled
- Swapping a child scene doesn't break sibling code
- Signal connections are visible in the parent, making data flow traceable

### Example 1: Node communication

**BAD** — child reaches up and calls parent:

```gdscript
func _on_body_entered(body):
    get_parent().get_parent().load_next_level()  # fragile path, coupled to tree structure
```

**GOOD** — child emits, parent decides:

```gdscript
# finish_trigger.gd
signal triggered

func _on_body_entered(body):
    triggered.emit()  # don't know or care what happens next

# level.gd
func _ready():
    $FinishTrigger.triggered.connect(_on_level_complete)

func _on_level_complete():
    finished.emit({})  # scene manager decides what's next
```

### Example 2: Scene flow

Same principle at a higher level — a scene (level, menu, cutscene) doesn't know what comes after it. It emits `finished`, the scene manager routes.

**BAD** — level knows what's next:

```gdscript
func _on_level_complete():
    get_tree().change_scene_to_file("res://levels/Level2.tscn")
    # reorder levels? edit every level script
```

**GOOD** — level just says "I'm done", manager routes:

```gdscript
# scene_manager.gd
const FLOW: Dictionary[PackedScene, PackedScene] = {
    START: LEVEL_1,
    LEVEL_1: LEVEL_2,
    LEVEL_2: LEVEL_3,
    LEVEL_3: END,
    END: START,
}

func handle_scene_finished(_data: Dictionary):
    load_scene(FLOW[current_scene])
```

---

## Principle 6: Separate Logic from Data

One scene, many variants. Don't create separate scenes for skeleton, orc, zombie — create one `enemy` scene and feed it different `.tres` Resource files with different textures, sounds, and stats.

### Why

- New enemy type = duplicate a `.tres`, change texture and numbers. No new scenes, no new scripts
- Balance tweaking in the Inspector without touching code
- Logic fixes apply to ALL variants at once — fix the enemy script, every enemy type gets the fix

### Example

**BAD** — separate scene per enemy type:

```
scenes/
  skeleton.tscn + skeleton.gd   # copy-pasted movement logic
  orc.tscn + orc.gd             # copy-pasted movement logic with small tweaks
  zombie.tscn + zombie.gd       # copy-pasted movement logic with other tweaks
  # fix a bug? fix it in 3 files. add a feature? add it in 3 files.
```

**GOOD** — one scene, data in Resources:

```gdscript
# enemy_stat.gd
class_name EnemyStat extends Resource
@export var texture: Texture2D
@export var hurt_sound: AudioStream
@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 100.0

# enemy.gd — one script for all enemy types
@export var stat: EnemyStat  # drag-and-drop in Inspector
```

```
resources/enemy/
  skeleton.tres  -> {texture: skeleton.png, speed: 80, health: 50}
  orc.tres       -> {texture: orc.png, speed: 120, health: 150}
  zombie.tres    -> {texture: zombie.png, speed: 40, health: 300}
```

### Gotcha: Shared Instance Mutation

Multiple nodes referencing the same `.tres` share ONE instance. Mutating runtime state on one entity mutates it for all. For mutable state, duplicate in `_ready()`:

```gdscript
func _ready():
    stat = stat.duplicate()  # this entity now has its own copy
```

---

## Principle 7: Unique Names for Stable References

Use `%NodeName` instead of `$Path/To/Deep/Node` for intra-scene references.

### Why

- Move a node anywhere within the scene — `%HealthBar` still finds it
- Cleaner than long relative paths

### Example

**BAD** — fragile path:

```gdscript
@onready var health_bar = $Rig/AnimationRig/UI/HealthBar
# reorganize tree? script breaks.
```

**GOOD** — unique name:

```gdscript
@onready var health_bar: ProgressBar = %HealthBar
# move it anywhere within this scene — still works
```

### Limitation

`%Name` only works within the scene that defines it. For cross-scene access, use groups or signals.

---

## Principle 8: Physics Layers as a Contract

Collision layers define who can interact with whom. Name them, assign them systematically. The layer setup IS the interaction rulebook.

### Why

- Self-documenting: layer 13 mask 8 = "player projectile hits enemy hurtboxes"
- New entity types = assign layers, interactions work automatically
- No code needed to define "who can hit whom"

### Example

**BAD** — collision logic in code:

```gdscript
func _on_area_entered(area):
    var body = area.get_parent()
    if type == Type.PLAYER and body is Enemy:
        body.apply_damage(stat.damage)
    elif type == Type.ENEMY and body is Player:
        body.apply_damage(stat.damage)
    # new faction? more branches.
```

**GOOD** — layers handle it, code is generic:

```gdscript
# bullet doesn't care about entity types
func _on_area_entered(area):
    if area is Hurtbox:
        area.take_damage(stat.damage, self, stat.knockback_force)
    kill()
```

Want ally projectiles? Add a new layer, set masks. Zero code changes.

---

## Principle 9: Spawn to Level, Not to Self

Dynamic objects (bullets, drops, effects) are added as children of the **level**, not the spawner. Find the level by group.

### Why

- Bullets shouldn't follow the shooter
- Loot shouldn't disappear when the enemy that dropped it dies
- Effects at a world position stay at that position

### Example

**BAD** — bullet is child of the shooter:

```gdscript
func _shoot(target_pos: Vector2):
    var bullet = BULLET.instantiate()
    add_child(bullet)  # moves with shooter, dies when shooter dies
```

**GOOD** — bullet is added to the level:

```gdscript
func _shoot(target_pos: Vector2):
    var bullet = BULLET.instantiate()
    var level = get_tree().get_first_node_in_group("level")
    level.add_child(bullet)  # lives independently in the level
    bullet.init(global_position, target_pos)
```

---

## Principle 10: Log Everything Important

Use `Log` (from `game_kit/utils/logger.gd`) to log state changes, lifecycle events, and decisions. When something breaks, logs tell you what happened without attaching a debugger.

### API

```gdscript
Log.log_debug(self.name, "message")  # verbose, disabled with Log.show_debug = false
Log.log_info(self.name, "message")   # key events — scene loaded, dialog finished
Log.log_warn(self.name, "message")   # something unexpected but recoverable
Log.log_error(self.name, "message")  # something broke
```

Output format: `[timestamp] [LEVEL] (NodeName) message`

### What to log

- **Scene lifecycle** — scene loaded, scene removed, scene finished:
  ```gdscript
  Log.log_info(self.name, "Starting to load level: %s" % scene_name)
  Log.log_info(self.name, "Scene is active: %s" % scene_name)
  ```

- **State changes** — enemy AI transitions, player actions:
  ```gdscript
  Log.log_debug(self.name, "Changing state from %s to %s" % [old_state, new_state])
  ```

- **Decisions and edge cases** — why something did or didn't happen:
  ```gdscript
  Log.log_debug(self.name, "Can't spawn bullet, no bullet stat")
  ```

### What NOT to log

- Every frame of `_physics_process` — floods the output, hides useful logs
- Obvious things — "entered _ready()" on every node adds noise, not signal

---

## Principle 11: Type Everything

Use static typing everywhere in GDScript. Type all variables, function arguments, return values, and collections. The compiler catches bugs before runtime, and the editor gives autocomplete.

### Where to type

**Variables and @onready:**

```gdscript
var current_health: int = 0
var is_dead: bool = false
var current_state: State = State.IDLE
var player: Player

@onready var health_bar: ProgressBar = %HealthBar
@onready var base_rig: BaseRig = $BaseRig
@onready var hit_sfx: AudioStreamPlayer2D = %HitSfx
```

**Function signatures — arguments AND return type:**

```gdscript
func apply_damage(damage: int, attacker: Node2D, knockback_force: int = 0) -> void:
func _find_player() -> Player:
func find_closest_target(targets: Array, node: Node2D) -> Node2D:
func is_player_has_full_set(set_type: Types.SetType) -> bool:
```

**@export with custom Resource types:**

```gdscript
@export var stat: BaseEnemyStat
@export var drop_part: BasePart
@export var head: PartHead
@export var torso: PartTorso
```

**Typed collections (Godot 4.x):**

```gdscript
const SCENE_TRANSITIONS: Dictionary[PackedScene, PackedScene] = { ... }
var visited_dialog_zones: Array[String] = []
```

**Typed instantiation:**

```gdscript
var drop: PartDrop = PART_DROP.instantiate()
var dialog_zone = node as DialogZone
```

### Why

- Compiler catches type mismatches before you run the game
- Editor autocomplete works — `stat.` shows all EnemyStat fields
- Refactoring is safer — rename a field, compiler shows every broken reference
- `as` cast + null check is safer than blind `get_parent()` calls
