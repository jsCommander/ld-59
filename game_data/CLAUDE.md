# Game Data

- Resource class definitions (`.gd`) and their instances (`.tres`) live together in the same folder.
- Group by domain: `developer/`, `task/`, `upgrades/`, `cost_function/`. Not by file type.
- One `.gd` defines the schema. Many `.tres` files are variants of that schema with different values.
- New variant = duplicate a `.tres` and change values in the Inspector. Not a new script or scene.

---

## Resource Classes Define the Schema

Each `.gd` file is a `Resource` subclass with `@export` fields. It describes what data a category has.

```gdscript
# developer/developer_data.gd
class_name DeveloperData extends BaseGameData
@export var head_texture: Texture2D
@export var task_mults: Dictionary = {}
@export var base_attack_speed: float = Constants.BASE_ATTACK_SPEED
```

Data resources may contain validation or interchangeable strategy behavior tied to their schema. Broader gameplay calculations belong in `globals/balance.gd`.

---

## .tres Files Are Instances, Not Code

Each `.tres` is a filled-in copy of its Resource class. Edit in the Godot Inspector, not by hand.

```
developer/
  developer_data.gd              # schema
  developer_data_vibecoder.tres   # variant: fast, low damage
  developer_data_developer.tres   # variant: balanced
  developer_data_senior.tres      # variant: slow, high damage
```

Not separate scripts per variant — one schema, many data files.

---

## Subfolder per Domain

Group related `.gd` + `.tres` files in a folder named after the domain. Upgrades subdivide further by rarity.

```
game_data/
  developer/       # DeveloperData + instances
  task/            # TaskData + instances
  upgrades/        # UpgradeData + common/, uncommon/, epic/, legendary/
  cost_function/   # CostFunction + strategy variants
```

Not flat — a folder with 50 `.tres` files is unnavigable.

---

## Strategy Resources for Swappable Logic

Use Resource subclasses when behavior varies by configuration (cost curves, selection algorithms). The base class defines the interface, subclasses implement variants.

```gdscript
# cost_function.gd — base interface
class_name CostFunction extends Resource
func get_cost(base_cost: int, _level: int) -> int:
    return base_cost

# cost_function_exponential.gd — one strategy
class_name CostFunctionExponential extends CostFunction
func get_cost(base_cost: int, level: int) -> int:
    return base_cost * int(pow(2, level - 1))
```

Swap strategies by assigning a different `.tres` in the Inspector. Not `if/else` branches in game code.
