# Upgrade System Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the upgrade system to support upgrade groups, three trade-off types, stackable upgrades with optional limits, and expanded validation.

**Architecture:** Add `UpgradeGroup` enum and `STAT_TO_GROUP_DICT` mapping to Constants. Extend `UpgradeData` with `group` and `max_count` fields, expand its validation to check trade-off consistency. Modify `PlayerData` to allow stacking with `max_count` limits. Migrate all 80 `.tres` files via a Python script.

**Tech Stack:** GDScript (Godot 4.x), Python (migration script)

---

### Task 1: Update Constants — New Enums and Mappings

**Files:**
- Modify: `globals/constants.gd:6-24` (enums section)
- Modify: `globals/constants.gd:54-98` (upgrades section)

- [ ] **Step 1: Add UpgradeGroup enum and update TradeOffType**

In `globals/constants.gd`, after the `UpgradeRarity` enum (line 23), replace the `TradeOffType` enum and add `UpgradeGroup`:

Replace:
```gdscript
enum TradeOffType {PURE, TRADE_OFF}
```

With:
```gdscript
enum TradeOffType {PURE, TRADE_OFF_INTRA_GROUP, TRADE_OFF_CROSS_GROUP}
enum UpgradeGroup {DPS_DEV, CLICK_BOOST, TASK_TYPE, ECONOMY}
```

- [ ] **Step 2: Add STAT_TO_GROUP_DICT**

In `globals/constants.gd`, after the `NEGATIVE_BUDGET_LIMITS` dict (line 98), add:

```gdscript
const STAT_TO_GROUP_DICT: Dictionary = {
	UpgradeStat.GLOBAL_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.FEATURE_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.BUG_DAMAGE: UpgradeGroup.DPS_DEV,
	UpgradeStat.BOOST_DAMAGE: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.BOOST_DURATION: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.AUTO_CLICK_SPEED: UpgradeGroup.CLICK_BOOST,
	UpgradeStat.FEATURE_CHANCE: UpgradeGroup.TASK_TYPE,
	UpgradeStat.BUG_CHANCE: UpgradeGroup.TASK_TYPE,
	UpgradeStat.REWARD_BONUS: UpgradeGroup.ECONOMY,
	UpgradeStat.RARITY_LUCK: UpgradeGroup.ECONOMY,
}
```

- [ ] **Step 3: Add UPGRADE_LIMITS_DICT**

Right after `STAT_TO_GROUP_DICT`, add:

```gdscript
const UPGRADE_LIMITS_DICT: Dictionary = {
	TradeOffType.PURE: {
		UpgradeRarity.COMMON: 99,
		UpgradeRarity.UNCOMMON: 99,
		UpgradeRarity.EPIC: 99,
		UpgradeRarity.LEGENDARY: 99,
	},
	TradeOffType.TRADE_OFF_INTRA_GROUP: {
		UpgradeRarity.COMMON: 99,
		UpgradeRarity.UNCOMMON: 99,
		UpgradeRarity.EPIC: 99,
		UpgradeRarity.LEGENDARY: 99,
	},
	TradeOffType.TRADE_OFF_CROSS_GROUP: {
		UpgradeRarity.COMMON: 99,
		UpgradeRarity.UNCOMMON: 99,
		UpgradeRarity.EPIC: 99,
		UpgradeRarity.LEGENDARY: 99,
	},
}
```

Note: All limits set to 99 as placeholder — designer fills real values during balancing.

- [ ] **Step 4: Commit**

```bash
git add globals/constants.gd
git commit -m "feat(upgrades): add UpgradeGroup enum, update TradeOffType, add STAT_TO_GROUP_DICT and UPGRADE_LIMITS_DICT"
```

---

### Task 2: Update UpgradeData — New Fields and Expanded Validation

**Files:**
- Modify: `game_data/upgrades/upgrade_data.gd`

- [ ] **Step 1: Add group and max_count exports**

In `game_data/upgrades/upgrade_data.gd`, in the Classification export group (after line 11), add the new fields:

Replace:
```gdscript
@export_group("Classification")
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
```

With:
```gdscript
@export_group("Classification")
@export var rarity: Constants.UpgradeRarity = Constants.UpgradeRarity.COMMON
@export var group: Constants.UpgradeGroup = Constants.UpgradeGroup.DPS_DEV
@export var trade_off_type: Constants.TradeOffType = Constants.TradeOffType.PURE
@export var max_count: int = 0
```

- [ ] **Step 2: Add trade-off validation to validate_budget()**

Replace the entire `validate_budget()` method with:

```gdscript
func validate_budget() -> String:
	var budget: float = calculate_budget()
	var target: float = Constants.RARITY_BUDGETS[rarity] as float
	if is_zero_approx(target):
		return ""
	var warnings: Array[String] = []
	var diff: float = absf(budget - target) / target
	if diff > Constants.BUDGET_TOLERANCE:
		warnings.append("%s: budget %.1f, target %d (%.0f%% off)" % [id, budget, int(target), diff * 100])
	var neg_total: float = _calculate_negative_budget()
	var neg_limit: float = Constants.NEGATIVE_BUDGET_LIMITS[rarity] as float
	if neg_total > neg_limit:
		warnings.append("%s: negative budget %.1f exceeds limit %d" % [id, neg_total, int(neg_limit)])
	warnings.append_array(_validate_trade_off())
	return "\n".join(warnings)
```

- [ ] **Step 3: Add _validate_trade_off() method**

After `_calculate_negative_budget()`, add:

```gdscript
func _validate_trade_off() -> Array[String]:
	var warnings: Array[String] = []
	var positive_groups: Array[Constants.UpgradeGroup] = []
	var negative_groups: Array[Constants.UpgradeGroup] = []
	for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
		var field: String = Constants.STAT_FIELDS[stat]
		var value: float = get(field) as float
		var stat_group: Constants.UpgradeGroup = Constants.STAT_TO_GROUP_DICT[stat] as Constants.UpgradeGroup
		if value > 0.0 and stat_group not in positive_groups:
			positive_groups.append(stat_group)
		elif value < 0.0 and stat_group not in negative_groups:
			negative_groups.append(stat_group)

	# Check 1: PURE with negative stats
	if trade_off_type == Constants.TradeOffType.PURE and not negative_groups.is_empty():
		warnings.append("%s: marked as PURE but has negative stats" % id)

	# Check 2: INTRA_GROUP with cross-group negative
	if trade_off_type == Constants.TradeOffType.TRADE_OFF_INTRA_GROUP:
		for neg_group: Constants.UpgradeGroup in negative_groups:
			if neg_group != group:
				warnings.append("%s: TRADE_OFF_INTRA_GROUP but has negative stat from group %s (upgrade group: %s)" % [
					id,
					Constants.UpgradeGroup.keys()[neg_group],
					Constants.UpgradeGroup.keys()[group],
				])

	# Check 3: CROSS_GROUP with same-group negative
	if trade_off_type == Constants.TradeOffType.TRADE_OFF_CROSS_GROUP:
		for neg_group: Constants.UpgradeGroup in negative_groups:
			if neg_group == group:
				warnings.append("%s: TRADE_OFF_CROSS_GROUP but has negative stat from same group %s" % [
					id,
					Constants.UpgradeGroup.keys()[group],
				])

	# Check 4: Group mismatch — all positive stats from one group, but group field differs
	if positive_groups.size() == 1 and positive_groups[0] != group:
		warnings.append("%s: group is %s but all positive stats are in %s" % [
			id,
			Constants.UpgradeGroup.keys()[group],
			Constants.UpgradeGroup.keys()[positive_groups[0]],
		])

	return warnings
```

- [ ] **Step 4: Commit**

```bash
git add game_data/upgrades/upgrade_data.gd
git commit -m "feat(upgrades): add group, max_count fields and trade-off validation to UpgradeData"
```

---

### Task 3: Update DataRegistry — Pool-Level Validation

**Files:**
- Modify: `autoloads/data_registry.gd`

- [ ] **Step 1: Add pool-level count validation**

Replace the entire `_validate_upgrade_budgets()` method with:

```gdscript
func _validate_upgrade_budgets() -> void:
	var lines: PackedStringArray = []
	for upgrade: UpgradeData in upgrades.values():
		var warning: String = upgrade.validate_budget()
		if warning:
			lines.append(warning)
	lines.append_array(_validate_upgrade_pool_limits())
	if lines.is_empty():
		return
	lines.sort()
	var path: String = "res://logs/balance_warnings.txt"
	DirAccess.make_dir_recursive_absolute("res://logs")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines) + "\n")
		file.close()
		Log.log_warn(name, "%d budget warnings written to %s" % [lines.size(), path])
```

- [ ] **Step 2: Add _validate_upgrade_pool_limits() method**

After `_validate_upgrade_budgets()`, add:

```gdscript
func _validate_upgrade_pool_limits() -> PackedStringArray:
	var lines: PackedStringArray = []
	# Count upgrades per trade_off_type x rarity
	var counts: Dictionary = {}
	for trade_off_type: Constants.TradeOffType in Constants.UPGRADE_LIMITS_DICT:
		counts[trade_off_type] = {}
		for rarity: Constants.UpgradeRarity in Constants.UPGRADE_LIMITS_DICT[trade_off_type]:
			counts[trade_off_type][rarity] = 0
	for upgrade: UpgradeData in upgrades.values():
		if upgrade.trade_off_type in counts and upgrade.rarity in counts[upgrade.trade_off_type]:
			counts[upgrade.trade_off_type][upgrade.rarity] += 1
	# Check against limits
	for trade_off_type: Constants.TradeOffType in Constants.UPGRADE_LIMITS_DICT:
		var limits: Dictionary = Constants.UPGRADE_LIMITS_DICT[trade_off_type]
		for rarity: Constants.UpgradeRarity in limits:
			var count: int = counts[trade_off_type][rarity]
			var limit: int = limits[rarity] as int
			if count > limit:
				lines.append("Pool: %s x %s has %d upgrades (limit %d)" % [
					Constants.TradeOffType.keys()[trade_off_type],
					Constants.UpgradeRarity.keys()[rarity],
					count,
					limit,
				])
	return lines
```

- [ ] **Step 3: Commit**

```bash
git add autoloads/data_registry.gd
git commit -m "feat(upgrades): add pool-level upgrade count validation in DataRegistry"
```

---

### Task 4: Update PlayerData — Stackable Upgrades with max_count

**Files:**
- Modify: `autoloads/player_data.gd:258-309` (upgrade selection section)

- [ ] **Step 1: Replace _is_upgrade_available() and remove _is_taken()**

In `autoloads/player_data.gd`, replace these two methods:

```gdscript
func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	return not _is_taken(upgrade.id)


func _is_taken(upgrade_id: String) -> bool:
	for taken: UpgradeData in upgrades_taken:
		if taken.id == upgrade_id:
			return true
	return false
```

With:

```gdscript
func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	if upgrade.max_count <= 0:
		return true
	var count: int = 0
	for taken: UpgradeData in upgrades_taken:
		if taken.id == upgrade.id:
			count += 1
	return count < upgrade.max_count
```

- [ ] **Step 2: Update _pick_boost_upgrade() to use same availability check**

The `_pick_boost_upgrade()` method at line 300 already calls `_is_upgrade_available(upgrade)` — no changes needed. Verify this is the case by reading the method.

- [ ] **Step 3: Commit**

```bash
git add autoloads/player_data.gd
git commit -m "feat(upgrades): allow stacking upgrades with max_count limit"
```

---

### Task 5: Migrate All 80 .tres Files

**Files:**
- Create: `scripts/migrate_upgrades.py` (temporary migration script)
- Modify: `game_data/upgrades/**/*.tres` (all 80 files)

- [ ] **Step 1: Create the migration script**

Create `scripts/migrate_upgrades.py`:

```python
#!/usr/bin/env python3
"""
Migrate upgrade .tres files:
1. Add 'group = N' field based on positive stats
2. Update trade_off_type from old 2-value to new 3-value enum
   Old: 0=PURE, 1=TRADE_OFF
   New: 0=PURE, 1=TRADE_OFF_INTRA_GROUP, 2=TRADE_OFF_CROSS_GROUP
"""

import os
import re
import sys

# Stat -> group enum value
STAT_TO_GROUP = {
    "global_damage": 0,   # DPS_DEV
    "feature_damage": 0,  # DPS_DEV
    "bug_damage": 0,      # DPS_DEV
    "boost_damage": 1,    # CLICK_BOOST
    "boost_duration": 1,  # CLICK_BOOST
    "auto_click_speed": 1,# CLICK_BOOST
    "feature_chance": 2,  # TASK_TYPE
    "bug_chance": 2,      # TASK_TYPE
    "reward_bonus": 3,    # ECONOMY
    "rarity_luck": 3,     # ECONOMY
}

GROUP_NAMES = {0: "DPS_DEV", 1: "CLICK_BOOST", 2: "TASK_TYPE", 3: "ECONOMY"}
TRADE_OFF_NAMES = {0: "PURE", 1: "TRADE_OFF_INTRA_GROUP", 2: "TRADE_OFF_CROSS_GROUP"}

STAT_PATTERN = re.compile(
    r"^(global_damage|feature_damage|bug_damage|feature_chance|bug_chance|"
    r"boost_damage|boost_duration|auto_click_speed|reward_bonus|rarity_luck)"
    r"\s*=\s*(-?[\d.]+)"
)


def parse_stats(lines):
    """Extract stat name -> float value from .tres lines."""
    stats = {}
    for line in lines:
        m = STAT_PATTERN.match(line)
        if m:
            stats[m.group(1)] = float(m.group(2))
    return stats


def determine_group(stats):
    """Determine upgrade group from highest-value positive stat."""
    positive_stats = {k: v for k, v in stats.items() if v > 0}
    if not positive_stats:
        return 0  # default DPS_DEV

    # Group with most positive budget contribution
    group_budgets = {}
    for stat, value in positive_stats.items():
        g = STAT_TO_GROUP[stat]
        group_budgets[g] = group_budgets.get(g, 0) + value
    return max(group_budgets, key=group_budgets.get)


def determine_trade_off_type(old_type, stats, group):
    """
    Convert old trade_off_type (0=PURE, 1=TRADE_OFF) to new enum.
    0 = PURE (no change)
    1 = check if negative stats are in same group (INTRA=1) or different (CROSS=2)
    """
    if old_type == 0:
        return 0  # PURE stays PURE

    negative_groups = set()
    for stat, value in stats.items():
        if value < 0:
            negative_groups.add(STAT_TO_GROUP[stat])

    if not negative_groups:
        return 0  # no negatives, should be PURE (validation will warn)

    # If ANY negative is from a different group -> CROSS_GROUP
    # If ALL negatives are from the same group -> INTRA_GROUP
    if all(g == group for g in negative_groups):
        return 1  # TRADE_OFF_INTRA_GROUP
    else:
        return 2  # TRADE_OFF_CROSS_GROUP


def migrate_file(filepath):
    """Migrate a single .tres file."""
    with open(filepath, "r") as f:
        content = f.read()
    lines = content.split("\n")

    stats = parse_stats(lines)
    if not stats:
        print(f"  SKIP (no stats): {filepath}")
        return False

    # Parse current trade_off_type
    old_trade_off = 0
    for line in lines:
        m = re.match(r"^trade_off_type\s*=\s*(\d+)", line)
        if m:
            old_trade_off = int(m.group(1))
            break

    group = determine_group(stats)
    new_trade_off = determine_trade_off_type(old_trade_off, stats, group)

    # Build new content
    new_lines = []
    trade_off_written = False
    group_written = False

    for line in lines:
        # Update trade_off_type value
        if re.match(r"^trade_off_type\s*=", line):
            new_lines.append(f"trade_off_type = {new_trade_off}")
            trade_off_written = True
            # Add group right after trade_off_type if non-default
            if group != 0:
                new_lines.append(f"group = {group}")
                group_written = True
            continue

        # If there was no trade_off_type line, add group after rarity
        if not trade_off_written and re.match(r"^rarity\s*=", line):
            new_lines.append(line)
            # trade_off_type was default (0=PURE), so not in file
            # Add group if non-default
            if group != 0 and not group_written:
                new_lines.append(f"group = {group}")
                group_written = True
            continue

        new_lines.append(line)

    new_content = "\n".join(new_lines)
    if new_content != content:
        with open(filepath, "w") as f:
            f.write(new_content)
        print(f"  MIGRATED: {filepath} -> group={GROUP_NAMES[group]}, trade_off={TRADE_OFF_NAMES[new_trade_off]}")
        return True
    else:
        print(f"  NO CHANGE: {filepath} (group={GROUP_NAMES[group]}, trade_off={TRADE_OFF_NAMES[new_trade_off]})")
        return False


def main():
    base = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game_data", "upgrades")
    if not os.path.isdir(base):
        print(f"ERROR: directory not found: {base}")
        sys.exit(1)

    changed = 0
    total = 0
    for root, dirs, files in os.walk(base):
        for fname in sorted(files):
            if fname.endswith(".tres"):
                total += 1
                if migrate_file(os.path.join(root, fname)):
                    changed += 1

    print(f"\nDone: {changed}/{total} files migrated")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the migration script**

Run: `cd /home/jscom/coding/game-teamlead && python3 scripts/migrate_upgrades.py`

Expected: output showing each file's migration result. Approximately 36 files should change (the ones with non-DPS_DEV groups and/or TRADE_OFF type needing split).

- [ ] **Step 3: Spot-check a few migrated files**

Verify these specific files:

1. `game_data/upgrades/common/upgrade_coffee_machine.tres` — should have `group = 1` (CLICK_BOOST), `trade_off_type = 0` (PURE)
2. `game_data/upgrades/common/upgrade_crunch_time.tres` — should have `group = 1` (CLICK_BOOST), `trade_off_type = 1` (TRADE_OFF_INTRA_GROUP, negative boost_duration is same group)
3. `game_data/upgrades/epic/upgrade_growth_hacking.tres` — should have `group = 3` (ECONOMY), `trade_off_type = 2` (TRADE_OFF_CROSS_GROUP, negative global_damage is DPS_DEV)
4. `game_data/upgrades/common/upgrade_bug_priority.tres` — should have `group = 2` (TASK_TYPE), `trade_off_type = 1` (TRADE_OFF_INTRA_GROUP, negative feature_chance is same TASK_TYPE group)
5. `game_data/upgrades/legendary/upgrade_ipo.tres` — should have `group = 3` (ECONOMY), `trade_off_type = 2` (TRADE_OFF_CROSS_GROUP, negative boost_duration is CLICK_BOOST)

- [ ] **Step 4: Commit the migration**

```bash
git add game_data/upgrades/
git commit -m "feat(upgrades): migrate 80 .tres files — add group field and split trade-off types"
```

- [ ] **Step 5: Delete the migration script**

```bash
rm scripts/migrate_upgrades.py
rmdir scripts/ 2>/dev/null  # remove if empty
git add -A scripts/
git commit -m "chore: remove upgrade migration script"
```

---

### Task 6: Verify — Run Game and Check Validation Output

- [ ] **Step 1: Open the project in Godot and run**

Open the project in Godot editor and run the game (F5). The game should start without errors.

- [ ] **Step 2: Check balance_warnings.txt**

Read `logs/balance_warnings.txt` after the game starts. Verify:
- No warnings about trade-off type mismatches (PURE with negatives, INTRA with cross-group negatives, etc.)
- Existing budget warnings may still appear — that's fine, they're about balance numbers, not the new validation
- Pool limit warnings should not appear (all limits are 99)

- [ ] **Step 3: Test upgrade stacking**

Play through a few level-ups. After taking an upgrade, verify that the same upgrade can appear in a subsequent level-up offer. Take it again and verify that `total_stats` correctly shows the cumulative value (should be doubled).
