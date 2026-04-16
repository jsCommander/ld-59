# Upgrade System Rework

## Summary

Rework the upgrade system to support upgrade groups, three trade-off types, stackable upgrades with optional limits, and expanded validation.

## Current State

- 80 hand-crafted `.tres` upgrades across 4 rarities (28 common, 24 uncommon, 18 epic, 10 legendary)
- 10 stats: `global_damage`, `feature_damage`, `bug_damage`, `feature_chance`, `bug_chance`, `boost_damage`, `boost_duration`, `auto_click_speed`, `reward_bonus`, `rarity_luck`
- Each upgrade can only be taken once (checked via `upgrades_taken` by id)
- Classification: `rarity` (COMMON/UNCOMMON/EPIC/LEGENDARY) and `trade_off_type` (PURE/TRADE_OFF)
- Budget validation exists: ±15% tolerance, negative budget limits per rarity
- No upgrade groups/categories beyond rarity

## Changes

### 1. New Enums

In `Constants`:

```gdscript
enum UpgradeGroup { DPS_DEV, CLICK_BOOST, TASK_TYPE, ECONOMY }

# Replaces current: enum TradeOffType { PURE, TRADE_OFF }
enum TradeOffType { PURE, TRADE_OFF_INTRA_GROUP, TRADE_OFF_CROSS_GROUP }
```

### 2. Stat-to-Group Mapping

In `Constants`:

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

### 3. UpgradeData Changes

New fields:

```gdscript
@export var group: Constants.UpgradeGroup = Constants.UpgradeGroup.DPS_DEV
@export var max_count: int = 0  # 0 = unlimited
```

The `trade_off_type` field is updated to use the new 3-value enum (was 2-value).

### 4. Stackable Upgrades

- Remove the uniqueness check in `PlayerData._pick_upgrade_by_rarity()` — no longer filter out upgrades already in `upgrades_taken`
- Add `max_count` check: if `max_count > 0`, count how many times this upgrade is already in `upgrades_taken`. If count >= `max_count`, exclude from pool
- Keep the per-offer uniqueness check — same upgrade won't appear twice in a single level-up roll, but can appear in subsequent rolls
- `upgrades_taken` array stays as-is, same upgrade can appear multiple times
- `_recalculate_total_stats()` already sums all upgrades additively — stacking works automatically

### 5. Expanded Validation

#### 5a. Per-Upgrade Validation (in UpgradeData)

Existing checks (kept as-is):
- Budget ±15% tolerance from rarity target
- Negative budget total vs `NEGATIVE_BUDGET_LIMITS`

New checks:
1. **PURE with negative stats**: Upgrade marked as PURE but has negative stat values
2. **TRADE_OFF_INTRA_GROUP with cross-group negative**: Negative stat belongs to a different group than `group` field
3. **TRADE_OFF_CROSS_GROUP with same-group negative**: Negative stat belongs to the same group as `group` field
4. **Group mismatch**: All positive stats belong to one group, but `group` field points to a different group. Only warns when all positive stats are from a single group — if positive stats span multiple groups, no warning (designer's choice)

#### 5b. Pool-Level Validation (in DataRegistry)

New constant in `Constants`:

```gdscript
const UPGRADE_LIMITS_DICT: Dictionary = {
    TradeOffType.PURE: {
        UpgradeRarity.COMMON: ...,
        UpgradeRarity.UNCOMMON: ...,
        UpgradeRarity.EPIC: ...,
        UpgradeRarity.LEGENDARY: ...,
    },
    TradeOffType.TRADE_OFF_INTRA_GROUP: {
        UpgradeRarity.COMMON: ...,
        UpgradeRarity.UNCOMMON: ...,
        UpgradeRarity.EPIC: ...,
        UpgradeRarity.LEGENDARY: ...,
    },
    TradeOffType.TRADE_OFF_CROSS_GROUP: {
        UpgradeRarity.COMMON: ...,
        UpgradeRarity.UNCOMMON: ...,
        UpgradeRarity.EPIC: ...,
        UpgradeRarity.LEGENDARY: ...,
    },
}
```

Concrete numbers TBD — filled in during balancing. Validation warns if the count of upgrades for any `trade_off_type × rarity` combination exceeds the limit.

All warnings written to `res://logs/balance_warnings.txt`. Nothing blocks gameplay.

### 6. Existing .tres Updates

All 80 existing `.tres` files need to be updated:
- Set `group` field based on the upgrade's primary positive stats
- Migrate `trade_off_type` from old 2-value enum to new 3-value enum:
  - `PURE` stays `PURE`
  - `TRADE_OFF` becomes either `TRADE_OFF_INTRA_GROUP` or `TRADE_OFF_CROSS_GROUP` based on which groups the positive and negative stats belong to

### 7. UI

No UI changes. Stats summary already shows cumulative totals which reflect stacking naturally.

## Files Affected

| File | Change |
|------|--------|
| `globals/constants.gd` | New `UpgradeGroup` enum, updated `TradeOffType` enum, `STAT_TO_GROUP_DICT`, `UPGRADE_LIMITS_DICT` |
| `game_data/upgrades/upgrade_data.gd` | New `group`, `max_count` fields; expanded validation |
| `autoloads/player_data.gd` | Remove uniqueness check, add `max_count` check |
| `autoloads/data_registry.gd` | Add pool-level validation (count per type × rarity) |
| `game_data/upgrades/**/*.tres` (80 files) | Add `group`, update `trade_off_type` |
