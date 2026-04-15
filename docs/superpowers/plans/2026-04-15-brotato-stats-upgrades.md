# Brotato-Style Stats & Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-stat upgrade system with a Brotato-style multi-stat budget system featuring 80 upgrades, 10 stats, trade-offs, and rarity-based appearance rates.

**Architecture:** All breaking API changes happen in a single atomic commit (Task 1) to avoid broken intermediate states. Then infrastructure (recursive scanning, PlayerData logic) is updated, followed by .tres data files.

**Tech Stack:** GDScript (Godot 4.x), .tres Resource files

**Spec:** `docs/superpowers/specs/2026-04-15-brotato-stats-upgrades-design.md`

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `globals/constants.gd` | Modify | New enums (UpgradeStat, TradeOffType), remove RARE rarity, add STAT_COSTS, RARITY_BUDGETS, RARITY_APPEARANCE_RATES |
| `game_data/upgrades/upgrade_data.gd` | Rewrite | Multi-stat resource with 10 stat fields, trade_off_type |
| `globals/balance.gd` | Rewrite | Additive stat summing, new calculate functions for all 10 stats |
| `autoloads/player_data.gd` | Modify | Rarity rolling, dynamic upgrade choices count, reward bonus, feature/bug chance distribution |
| `components/ui/ui_upgrade_choice/upgrade_card.gd` | Modify | Remove RARE from RARITY_VARIATIONS, remove old STAT_MODIFIERS, use new get_stat_effects() |
| `components/ui/stat_modifier/stat_modifier.gd` | Rewrite | Support new percentage format (0.25 not 1.25), green/red coloring |
| `game_kit/autoloads/base_data_registry.gd` | Modify | Add recursive subdirectory scanning |
| `game_data/upgrades/*.tres` | Delete (all old) | Remove old single-stat upgrade files |
| `game_data/upgrades/global/*.tres` | Create (40) | Global upgrade resources |
| `game_data/upgrades/vibecoder/*.tres` | Create (14) | Vibecoder upgrade resources |
| `game_data/upgrades/regular/*.tres` | Create (13) | Regular upgrade resources |
| `game_data/upgrades/senior/*.tres` | Create (13) | Senior upgrade resources |

**Note:** `components/developer/developer.gd` requires NO changes — all Balance function signatures remain the same.

---

### Task 1: Atomic Core System Rewrite

All breaking API changes in one commit. This updates Constants, UpgradeData, Balance, UpgradeCard, StatModifier, and deletes old .tres files together so the project is never in a broken state.

**Files:**
- Modify: `globals/constants.gd`
- Rewrite: `game_data/upgrades/upgrade_data.gd`
- Rewrite: `globals/balance.gd`
- Modify: `components/ui/ui_upgrade_choice/upgrade_card.gd`
- Rewrite: `components/ui/stat_modifier/stat_modifier.gd`
- Delete: all `.tres` files in `game_data/upgrades/` (top level)

- [ ] **Step 1: Update constants.gd — enums**

Replace lines 10-11:
```gdscript
# Old:
enum UpgradeStat {DAMAGE, CLICK_BOOST, AUTO_CLICK}
enum UpgradeRarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

# New:
enum UpgradeStat {
	GLOBAL_DAMAGE,
	FEATURE_DAMAGE,
	BUG_DAMAGE,
	FEATURE_CHANCE,
	BUG_CHANCE,
	BOOST_POWER,
	BOOST_DURATION,
	AUTO_CLICK_SPEED,
	REWARD_BONUS,
	UPGRADE_CHOICES,
}
enum UpgradeRarity {COMMON, UNCOMMON, EPIC, LEGENDARY}
enum TradeOffType {PURE, TRADE_OFF}
```

- [ ] **Step 2: Update constants.gd — add new constants**

Add after the enums block:
```gdscript
const STAT_COSTS: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: 1.5,
	UpgradeStat.FEATURE_DAMAGE: 1.0,
	UpgradeStat.BUG_DAMAGE: 1.0,
	UpgradeStat.FEATURE_CHANCE: 0.5,
	UpgradeStat.BUG_CHANCE: 0.5,
	UpgradeStat.BOOST_POWER: 1.0,
	UpgradeStat.BOOST_DURATION: 0.8,
	UpgradeStat.AUTO_CLICK_SPEED: 1.2,
	UpgradeStat.REWARD_BONUS: 0.7,
	UpgradeStat.UPGRADE_CHOICES: 10.0,
}

const RARITY_BUDGETS: Dictionary = {
	UpgradeRarity.COMMON: 10,
	UpgradeRarity.UNCOMMON: 20,
	UpgradeRarity.EPIC: 35,
	UpgradeRarity.LEGENDARY: 50,
}

const TRADE_OFF_RETURN_RATE: float = 0.5

const BASE_FEATURE_CHANCE: float = 50.0
const BASE_BUG_CHANCE: float = 50.0
const BASE_UPGRADE_CHOICES: int = 3
const MAX_UPGRADE_CHOICES: int = 5

# game level ranges -> rarity weights for rolling upgrade rarity
const RARITY_APPEARANCE_RATES: Array[Dictionary] = [
	# levels 1-10
	{UpgradeRarity.COMMON: 0.80, UpgradeRarity.UNCOMMON: 0.20, UpgradeRarity.EPIC: 0.0, UpgradeRarity.LEGENDARY: 0.0},
	# levels 11-20
	{UpgradeRarity.COMMON: 0.40, UpgradeRarity.UNCOMMON: 0.35, UpgradeRarity.EPIC: 0.20, UpgradeRarity.LEGENDARY: 0.05},
	# levels 21-30
	{UpgradeRarity.COMMON: 0.15, UpgradeRarity.UNCOMMON: 0.30, UpgradeRarity.EPIC: 0.35, UpgradeRarity.LEGENDARY: 0.20},
	# levels 31-40
	{UpgradeRarity.COMMON: 0.10, UpgradeRarity.UNCOMMON: 0.20, UpgradeRarity.EPIC: 0.40, UpgradeRarity.LEGENDARY: 0.30},
]
```

- [ ] **Step 3: Update constants.gd — update RARITY_COLORS, remove TASK_TYPE_WEIGHTS**

Replace RARITY_COLORS (lines 109-115) — remove RARE, Legendary = Red per spec:
```gdscript
const RARITY_COLORS: Dictionary = {
	UpgradeRarity.COMMON: Color(0.6, 0.6, 0.6),
	UpgradeRarity.UNCOMMON: Color(0.2, 0.4, 1.0),
	UpgradeRarity.EPIC: Color(0.6, 0.2, 0.8),
	UpgradeRarity.LEGENDARY: Color(0.9, 0.2, 0.2),
}
```

Delete TASK_TYPE_WEIGHTS (lines 59-62):
```gdscript
# DELETE these lines:
const TASK_TYPE_WEIGHTS: Dictionary[int, Dictionary] = {
	1: {TaskType.FEATURE: 0.5, TaskType.BUG: 0.5},
}
```

- [ ] **Step 4: Rewrite upgrade_data.gd**

Replace entire file:
```gdscript
class_name UpgradeData extends BaseGameData

# --- Exports ---
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var upgrade_type: Constants.UpgradeType = Constants.UpgradeType.GLOBAL
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
@export var target_dev_type: Constants.DevType
@export var min_game_level: int = 1

@export_group("Stat Effects")
@export var global_damage: float = 0.0
@export var feature_damage: float = 0.0
@export var bug_damage: float = 0.0
@export var feature_chance: float = 0.0
@export var bug_chance: float = 0.0
@export var boost_power: float = 0.0
@export var boost_duration: float = 0.0
@export var auto_click_speed: float = 0.0
@export var reward_bonus: float = 0.0
@export var upgrade_choices: int = 0


# --- Public ---

## Returns all non-zero stat effects as [{name, value}] for UI display
func get_stat_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var fields: Array[Array] = [
		["Global Damage", global_damage],
		["Feature Damage", feature_damage],
		["Bug Damage", bug_damage],
		["Feature Chance", feature_chance],
		["Bug Chance", bug_chance],
		["Boost Power", boost_power],
		["Boost Duration", boost_duration],
		["Auto Click Speed", auto_click_speed],
		["Reward Bonus", reward_bonus],
	]
	for f: Array in fields:
		if not is_zero_approx(f[1] as float):
			effects.append({"name": f[0] as String, "value": f[1] as float})
	if upgrade_choices != 0:
		effects.append({"name": "Upgrade Choices", "value": float(upgrade_choices)})
	return effects
```

- [ ] **Step 5: Rewrite balance.gd**

Replace entire file. Key changes from old system:
- Additive stacking (`1.0 + sum`) instead of multiplicative (`mult *= value`)
- `_sum_stat(field, ...)` reads named fields instead of checking `upgrade.stat` enum
- `calculate_task_type_weights` accepts ALL upgrades (global + all dev) so dev-specific Feature/Bug Chance stats work
- `calculate_reward_multiplier` accepts ALL upgrades so dev-specific Reward Bonus stats work
- New functions: `calculate_reward_multiplier`, `calculate_task_type_weights`, `calculate_upgrade_choices`, `roll_rarity`
- Removed: `get_task_type_weights`, `_calc_mult`

```gdscript
class_name Balance


## Damage = BASE_DAMAGE × task_mult × (1 + sum global_damage) × (1 + sum type_damage)
static func calculate_damage(dev_data: DeveloperData, task_type: Constants.TaskType, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var base: float = Constants.BASE_DAMAGE
	var task_mult: float = get_task_mult(dev_data, task_type)
	var global_dmg_mult: float = 1.0 + _sum_stat("global_damage", global_upgrades, dev_upgrades)
	var type_field: String = "feature_damage" if task_type == Constants.TaskType.FEATURE else "bug_damage"
	var type_dmg_mult: float = 1.0 + _sum_stat(type_field, global_upgrades, dev_upgrades)
	return base * task_mult * global_dmg_mult * type_dmg_mult


static func calculate_attack_speed(dev_data: DeveloperData, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData], boost_stacks: int = 0) -> float:
	var base: float = dev_data.base_attack_speed
	var boost_power: float = calculate_boost_power(global_upgrades, dev_upgrades)
	var boost_mult: float = 1.0 + boost_stacks * boost_power
	var interval: float = base / boost_mult
	return maxf(interval, Constants.SPEED_CAP)


## Boost power = BOOST_SPEED_MULT × (1 + sum boost_power)
static func calculate_boost_power(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0 + _sum_stat("boost_power", global_upgrades, dev_upgrades)
	return Constants.BOOST_SPEED_MULT * mult


## Boost decay interval = (1/DECAY_RATE) × (1 + sum boost_duration)
static func calculate_boost_decay_interval(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var mult: float = 1.0 + _sum_stat("boost_duration", global_upgrades, dev_upgrades)
	return (1.0 / Constants.BOOST_DECAY_RATE) * mult


## Auto click interval = BASE_INTERVAL / (1 + sum auto_click_speed). Returns 0 if no upgrade.
static func calculate_auto_click_interval(global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var sum_val: float = _sum_stat("auto_click_speed", global_upgrades, dev_upgrades)
	if is_zero_approx(sum_val):
		return 0.0
	return Constants.AUTO_CLICK_BASE_INTERVAL / (1.0 + sum_val)


## Reward multiplier = 1 + sum reward_bonus (across ALL upgrades, global + all devs)
static func calculate_reward_multiplier(all_upgrades: Array[UpgradeData]) -> float:
	var total: float = 0.0
	for upgrade: UpgradeData in all_upgrades:
		total += upgrade.reward_bonus
	return 1.0 + total


## Task type weights based on Feature/Bug Chance stats (across ALL upgrades, global + all devs)
static func calculate_task_type_weights(all_upgrades: Array[UpgradeData]) -> Dictionary:
	var feature_w: float = Constants.BASE_FEATURE_CHANCE
	var bug_w: float = Constants.BASE_BUG_CHANCE
	for upgrade: UpgradeData in all_upgrades:
		feature_w += upgrade.feature_chance
		bug_w += upgrade.bug_chance
	feature_w = maxf(feature_w, 1.0)
	bug_w = maxf(bug_w, 1.0)
	var total: float = feature_w + bug_w
	return {
		Constants.TaskType.FEATURE: feature_w / total,
		Constants.TaskType.BUG: bug_w / total,
	}


## How many upgrade choices the player gets at level-up
static func calculate_upgrade_choices(all_upgrades: Array[UpgradeData]) -> int:
	var bonus: int = 0
	for upgrade: UpgradeData in all_upgrades:
		bonus += upgrade.upgrade_choices
	return mini(Constants.BASE_UPGRADE_CHOICES + bonus, Constants.MAX_UPGRADE_CHOICES)


## Roll a rarity based on current player level
static func roll_rarity(player_level: int) -> Constants.UpgradeRarity:
	var bracket: int = clampi((player_level - 1) / 10, 0, Constants.RARITY_APPEARANCE_RATES.size() - 1)
	var weights: Dictionary = Constants.RARITY_APPEARANCE_RATES[bracket]
	var roll: float = randf()
	var cumulative: float = 0.0
	for rarity: Constants.UpgradeRarity in weights:
		cumulative += weights[rarity] as float
		if roll <= cumulative:
			return rarity
	return Constants.UpgradeRarity.COMMON


static func get_task_mult(dev_data: DeveloperData, task_type: Constants.TaskType) -> float:
	if task_type in dev_data.task_mults:
		return dev_data.task_mults[task_type]
	return 1.0


static func get_game_level(elapsed_time: float) -> int:
	var lvl: int = 1
	for i: int in Constants.GAME_LEVEL_THRESHOLDS.size():
		if elapsed_time >= Constants.GAME_LEVEL_THRESHOLDS[i]:
			lvl = i + 1
	return lvl


static func get_task_hp(game_level: int) -> float:
	var clamped: int = clampi(game_level, 1, Constants.TASK_HP_BY_LEVEL.size())
	return float(Constants.TASK_HP_BY_LEVEL[clamped])


static func get_xp_for_level(level: int) -> int:
	if level < 1 or level > Constants.LEVEL_THRESHOLDS.size():
		return 0
	return Constants.LEVEL_THRESHOLDS[level - 1]


static func get_game_duration() -> float:
	return Constants.BASE_TOTAL_GAME_TIME


## Sum a stat field across all upgrades (additive stacking)
static func _sum_stat(field: String, global_upgrades: Array[UpgradeData], dev_upgrades: Array[UpgradeData]) -> float:
	var total: float = 0.0
	for upgrade: UpgradeData in global_upgrades:
		total += upgrade.get(field) as float
	for upgrade: UpgradeData in dev_upgrades:
		total += upgrade.get(field) as float
	return total
```

- [ ] **Step 6: Update upgrade_card.gd**

Remove RARE from RARITY_VARIATIONS (lines 7-13):
```gdscript
const RARITY_VARIATIONS: Dictionary = {
	Constants.UpgradeRarity.COMMON: &"PanelContainerRarityCommon",
	Constants.UpgradeRarity.UNCOMMON: &"PanelContainerRarityUncommon",
	Constants.UpgradeRarity.EPIC: &"PanelContainerRarityEpic",
	Constants.UpgradeRarity.LEGENDARY: &"PanelContainerRarityLegendary",
}
```

Delete the old STAT_MODIFIERS constant (lines 15-20).

Replace `_populate_stats()` method (lines 61-68):
```gdscript
func _populate_stats() -> void:
	var effects: Array[Dictionary] = _upgrade.get_stat_effects()
	for effect: Dictionary in effects:
		var stat_row: StatModifier = STAT_MODIFIER.instantiate()
		var is_integer: bool = effect["name"] == "Upgrade Choices"
		stat_row.setup(effect["name"] as String, effect["value"] as float, is_integer)
		stats_container.add_child(stat_row)
```

- [ ] **Step 7: Rewrite stat_modifier.gd**

Replace entire file. New format: values are raw percentages (0.25 = +25%, not 1.25). Green for positive, red for negative.
```gdscript
class_name StatModifier
extends HBoxContainer

# --- @onready ---
@onready var stat_name_label: Label = %StatNameLabel
@onready var modifier_label: Label = %ModifierLabel

# --- State ---
var _stat_name: String
var _value: float
var _is_integer: bool = false


# --- Public ---
func setup(stat_name: String, value: float, is_integer: bool = false) -> void:
	_stat_name = stat_name
	_value = value
	_is_integer = is_integer


# --- Lifecycle ---
func _ready() -> void:
	stat_name_label.text = _stat_name
	if _is_integer:
		var int_val: int = int(_value)
		modifier_label.text = "+%d" % int_val if int_val > 0 else "%d" % int_val
	else:
		var percent: int = int(_value * 100)
		modifier_label.text = "+%d%%" % percent if percent >= 0 else "%d%%" % percent
	if _value >= 0:
		modifier_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	else:
		modifier_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
```

- [ ] **Step 8: Delete old .tres files**

```bash
find game_data/upgrades -maxdepth 1 -name "*.tres" -type f -delete
```

- [ ] **Step 9: Commit**

```bash
git add globals/constants.gd game_data/upgrades/upgrade_data.gd globals/balance.gd components/ui/ui_upgrade_choice/upgrade_card.gd components/ui/stat_modifier/stat_modifier.gd
git add -A game_data/upgrades/
git commit -m "refactor: atomic rewrite of upgrade system to Brotato-style multi-stat budget model"
```

---

### Task 2: Add Recursive Directory Scanning to BaseDataRegistry

**Files:**
- Modify: `game_kit/autoloads/base_data_registry.gd`

- [ ] **Step 1: Add recursive scanning**

Replace entire file:
```gdscript
class_name BaseDataRegistry extends Node


func _find_game_data_in_path(path: String) -> Dictionary[String, BaseGameData]:
	var result: Dictionary[String, BaseGameData] = {}
	_scan_directory(path, result)
	Log.log_info(name, "Found %d entries in %s: %s" % [result.size(), path, ", ".join(result.keys())])
	return result


func _scan_directory(path: String, result: Dictionary[String, BaseGameData]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return
	Log.log_debug(name, "Scanning: %s" % path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(full_path, result)
		elif file_name.ends_with(".tres"):
			var res: Resource = load(full_path)
			if res is BaseGameData:
				var id: String = res.id
				if id.is_empty():
					Log.log_warn(name, "Empty id in %s" % full_path)
				elif id in result:
					Log.log_warn(name, "Duplicate id '%s' in %s" % [id, full_path])
				else:
					result[id] = res
		file_name = dir.get_next()
```

- [ ] **Step 2: Commit**

```
git add game_kit/autoloads/base_data_registry.gd
git commit -m "feat: add recursive subdirectory scanning to BaseDataRegistry"
```

---

### Task 3: Update PlayerData — Rarity Rolling, Upgrade Choices, Reward Bonus

**Files:**
- Modify: `autoloads/player_data.gd`

- [ ] **Step 1: Add _get_all_upgrades_flat helper**

Add in the Public section (after `get_dev_upgrades`):
```gdscript
## Returns all taken upgrades (global + all dev) in a single flat array
func get_all_upgrades_flat() -> Array[UpgradeData]:
	var all: Array[UpgradeData] = []
	all.append_array(global_upgrades)
	for arr: Variant in dev_upgrades.values():
		all.append_array(arr as Array[UpgradeData])
	return all
```

- [ ] **Step 2: Rewrite get_level_up_upgrades() with rarity rolling and dynamic choices**

Replace lines 40-56:
```gdscript
func get_level_up_upgrades() -> Array[UpgradeData]:
	var all: Array[UpgradeData] = get_all_upgrades_flat()
	var count: int = Balance.calculate_upgrade_choices(all)
	var result: Array[UpgradeData] = []
	var used_ids: Array[String] = []
	for i: int in count:
		var rarity: Constants.UpgradeRarity = Balance.roll_rarity(level)
		var pick: UpgradeData = _pick_upgrade_by_rarity(rarity, used_ids)
		if pick:
			result.append(pick)
			used_ids.append(pick.id)
	return result
```

- [ ] **Step 3: Update _is_upgrade_available — remove prerequisites check**

Replace lines 284-295:
```gdscript
func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	if _is_taken(upgrade.id):
		return false
	if upgrade.min_game_level > 0 and game_level < upgrade.min_game_level:
		return false
	if upgrade.upgrade_type == Constants.UpgradeType.DEV:
		if not _has_hired_dev_type(upgrade.target_dev_type):
			return false
	return true
```

- [ ] **Step 4: Add _pick_upgrade_by_rarity helper**

Add in the Private section (after `_has_hired_dev_type`):
```gdscript
func _pick_upgrade_by_rarity(target_rarity: Constants.UpgradeRarity, exclude_ids: Array[String]) -> UpgradeData:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in DR.upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.id in exclude_ids:
			continue
		if upgrade.rarity == target_rarity:
			pool.append(upgrade)
	if pool.is_empty():
		# Fallback: try any rarity
		for upgrade: UpgradeData in DR.upgrades.values():
			if not _is_upgrade_available(upgrade):
				continue
			if upgrade.id in exclude_ids:
				continue
			pool.append(upgrade)
	return _pick_random_from(pool)
```

- [ ] **Step 5: Update _apply_upgrade log message**

Replace line 230:
```gdscript
# Old:
Log.log_info(name, "Applied upgrade: %s (×%.1f)" % [upgrade.id, upgrade.multiplier])

# New:
Log.log_info(name, "Applied upgrade: %s (%s)" % [upgrade.id, upgrade.display_name])
```

- [ ] **Step 6: Update _apply_task_rewards to use reward bonus**

Replace lines 248-254. Uses `get_all_upgrades_flat()` so dev-specific reward_bonus upgrades (R3, R10) also apply:
```gdscript
func _apply_task_rewards(task: TaskData) -> void:
	var base_reward: int = int(task.max_hp)
	var all: Array[UpgradeData] = get_all_upgrades_flat()
	var reward_mult: float = Balance.calculate_reward_multiplier(all)
	var reward: int = int(base_reward * reward_mult)
	if reward > 0:
		valuation += reward
		SB.valuation_changed.emit()
		if not _awaiting_choice:
			_check_level_up()
```

- [ ] **Step 7: Update _generate_sprint to use player-controlled task weights**

Replace line 183. Uses `get_all_upgrades_flat()` so dev-specific feature/bug chance upgrades (V5, V8, S4, S7 etc.) also apply:
```gdscript
# Old:
var weights: Dictionary = Balance.get_task_type_weights(task_level)

# New:
var all: Array[UpgradeData] = get_all_upgrades_flat()
var weights: Dictionary = Balance.calculate_task_type_weights(all)
```

- [ ] **Step 8: Remove unused methods**

Delete `_get_all_available()` (lines 259-264) and `_get_available_by_type()` (lines 267-275) — no longer used since `get_level_up_upgrades` was rewritten.

- [ ] **Step 9: Commit**

```
git add autoloads/player_data.gd
git commit -m "feat: rarity rolling, dynamic upgrade choices, reward bonus in PlayerData"
```

---

### Task 4: Create Upgrade Subdirectories and .tres Files

**Files:**
- Create: `game_data/upgrades/global/*.tres` (40 files)
- Create: `game_data/upgrades/vibecoder/*.tres` (14 files)
- Create: `game_data/upgrades/regular/*.tres` (13 files)
- Create: `game_data/upgrades/senior/*.tres` (13 files)

- [ ] **Step 1: Create subdirectories**

```bash
mkdir -p game_data/upgrades/global
mkdir -p game_data/upgrades/vibecoder
mkdir -p game_data/upgrades/regular
mkdir -p game_data/upgrades/senior
```

- [ ] **Step 2: Create all 80 .tres files**

Each file follows this pattern. Example for G1 (Pep Talk):
```tres
[gd_resource type="Resource" script_class="UpgradeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://game_data/upgrades/upgrade_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = "pep_talk"
display_name = "Pep Talk"
description = "\"You're doing great, team!\" *narrator: they weren't*"
rarity = 0
upgrade_type = 0
trade_off_type = 0
min_game_level = 1
global_damage = 0.07
```

**Key field mappings:**
- `rarity`: 0=COMMON, 1=UNCOMMON, 2=EPIC, 3=LEGENDARY
- `upgrade_type`: 0=GLOBAL, 1=DEV
- `trade_off_type`: 0=PURE, 1=TRADE_OFF
- `target_dev_type`: 0=VIBECODER, 1=DEVELOPER (for Regular), 2=SENIOR
- Stat values use decimal: +7% = `0.07`, −10% = `-0.10`
- `upgrade_choices` is int, not percentage: +1 = `1`
- File naming: snake_case of display_name (e.g., `pep_talk.tres`, `hackathon_focus.tres`)
- Only include non-zero stat fields in .tres (zero is the default)

Create all files per the spec's Full Upgrade List:
- **Global (40):** G1-G40 in `game_data/upgrades/global/`
- **Vibecoder (14):** V1-V14 in `game_data/upgrades/vibecoder/` — `upgrade_type = 1`, `target_dev_type = 0`
- **Regular (13):** R1-R13 in `game_data/upgrades/regular/` — `upgrade_type = 1`, `target_dev_type = 1`
- **Senior (13):** S1-S13 in `game_data/upgrades/senior/` — `upgrade_type = 1`, `target_dev_type = 2`

- [ ] **Step 3: Commit**

```
git add game_data/upgrades/
git commit -m "feat: create 80 upgrade .tres files organized in subdirectories"
```

---

### Task 5: Smoke Test

**Files:** None (manual verification)

- [ ] **Step 1: Launch the game in Godot editor**

Verify:
1. Game starts without errors in the console
2. First developer hire prompt appears
3. After hiring, tasks spawn with correct FEATURE/BUG distribution (~50/50)
4. Level-up triggers upgrade choice dialog
5. Upgrade cards show multi-stat effects with green/red coloring
6. After choosing an upgrade, stats apply correctly (damage changes, etc.)
7. Higher levels show higher-rarity upgrades
8. Dev-specific upgrades only appear for hired dev types

- [ ] **Step 2: Test edge cases**

1. Take "Expanded Shortlist" upgrade → next level-up should show 4 choices
2. Take a trade-off upgrade → verify negative stat applies (red text in UI)
3. Reach level 30+ → verify Epic/Legendary upgrades appear frequently
4. Stack Feature Chance upgrades → verify sprint task distribution shifts toward FEATURE
5. Take dev-specific Reward Bonus upgrade (R3 Process Guide) → verify increased rewards

- [ ] **Step 3: Fix any issues found and commit**

```
git add -A
git commit -m "fix: address issues found during smoke testing"
```
