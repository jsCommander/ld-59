# Brotato-Style Stats & Upgrades System

## Overview

Redesign the upgrade system to follow Brotato's item model: many stats, budget-based upgrades with trade-offs, and build diversity through synergies between developer types and task types.

## Stats (10 total)

### Combat Stats
| Stat | Description | Base Value | Cost per 1% |
|---|---|---|---|
| Global Damage | Multiplier on all task damage | 1.0x | 1.5 |
| Feature Damage | Multiplier on FEATURE task damage | 1.0x | 1.0 |
| Bug Damage | Multiplier on BUG task damage | 1.0x | 1.0 |

### Distribution Stats
| Stat | Description | Base Value | Cost per 1% |
|---|---|---|---|
| Feature Chance | Weight for FEATURE tasks in sprint | 50 | 0.5 |
| Bug Chance | Weight for BUG tasks in sprint | 50 | 0.5 |

Feature Chance and Bug Chance are **independent weights**. Task distribution is calculated as a proportion: `feature% = feature_chance / (feature_chance + bug_chance)`. Base 50/50 = 50%. If Feature Chance = 70, Bug Chance = 50, then feature% = 70/120 = 58%.

### Click Stats
| Stat | Description | Base Value | Cost per 1% | Scope |
|---|---|---|---|---|
| Boost Power | Click-boost strength multiplier | 1.0x | 1.0 | Global or Dev-specific |
| Boost Duration | How long boost lasts | 1.0x | 0.8 | Global only |
| Auto Click Speed | Auto-click speed multiplier | 1.0x | 1.2 | Global only |

**Boost Power** can appear in both global and dev-specific upgrades. When dev-specific, it only affects boost strength for that dev type. **Boost Duration** and **Auto Click Speed** are always global.

### Progression Stats
| Stat | Description | Base Value | Cost per 1% |
|---|---|---|---|
| Reward Bonus | Reward (score) from tasks multiplier | 1.0x | 0.7 |

### Meta Stats
| Stat | Description | Base Value | Cost per unit |
|---|---|---|---|
| Upgrade Choices | Number of upgrades offered at level-up | 3 (max 5) | 10.0 per +1 |

### Stat Cost Constants

Stored in `Constants` as:

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
```

## Task Types

Two task types: **FEATURE** and **BUG**. REFACTOR is removed.

Distribution in sprints is controlled by Feature Chance / Bug Chance stats (base 50/50, modified by upgrades).

## Developer Specialization

| Developer | FEATURE mult | BUG mult | Identity |
|---|---|---|---|
| Vibecoder | 1.6x | 0.4x | Fast feature builder, bad at bugs |
| Regular | 1.0x | 1.0x | Jack of all trades |
| Senior | 0.4x | 1.6x | Bug hunter, slow on features |

This creates a strategic triangle:
- **FEATURE build**: Vibecoder team + Feature Damage upgrades + high Feature Chance
- **BUG build**: Senior team + Bug Damage upgrades + high Bug Chance
- **Balanced build**: Regular team + Global Damage upgrades + even distribution

## Upgrade System

### Rarity Tiers (4 levels)

| Rarity | Budget | Trade-off frequency | Color |
|---|---|---|---|
| Common | 10 | ~30% have trade-off | Grey |
| Uncommon | 20 | ~50% have trade-off | Blue |
| Epic | 35 | ~60% have trade-off | Purple |
| Legendary | 50 | ~60% have trade-off | Red |

### Budget System

Each upgrade has a budget based on its rarity. Budget cost = `stat_percentage × stat_cost`.

- Positive effects spend budget
- Negative effects return budget at **0.5x rate** (`penalty% × stat_cost × 0.5`). Trade-off upgrades are stronger overall, but you pay a real cost.

Formula: `sum(positive% × stat_cost) - sum(negative% × stat_cost × 0.5) = budget`

Examples:
- **Common (budget 10), no trade-off**: +10% Feature Damage (10 × 1.0 = 10 ✓)
- **Uncommon (budget 20), with trade-off**: +25% Feature Damage, -10% Bug Damage (25×1.0 − 10×1.0×0.5 = 20 ✓)
- **Epic (budget 35), with trade-off**: +30% Boost Power, +10% Auto Click Speed, -20% Boost Duration (30×1.0 + 10×1.2 − 20×0.8×0.5 = 34 ≈ 35 ✓)
- **Legendary (budget 50), with trade-off**: +30% Global Damage, +20% Feature Damage, -40% Bug Damage (30×1.5 + 20×1.0 − 40×1.0×0.5 = 45+20−20 = 45 ≈ 50 ✓)

Note: Budget is a **guideline** with ±10% tolerance. The stat costs provide a framework for roughly equivalent upgrades — fine-tuning happens during playtesting.

### Upgrade Pool: 80 Total

**Split: 40 global / 40 dev-specific (~13 per dev type)**

| Rarity | Global | Dev-specific | Total |
|---|---|---|---|
| Common | 14 | 14 | 28 |
| Uncommon | 12 | 12 | 24 |
| Epic | 9 | 9 | 18 |
| Legendary | 5 | 5 | 10 |

### Upgrade Types

- **Global upgrades**: Affect all developers equally
- **Dev-specific upgrades**: Only affect one developer type (Vibecoder, Regular, or Senior)
- **Dev-specific upgrades only appear if the player has hired that dev type**
- **Filtering**: When dev-specific upgrades are excluded (dev not hired), re-roll from the remaining pool (global + hired dev types). This prevents a reduced pool from showing repeats.

### Upgrade Choices Meta-Stat

- Base: 3 upgrades offered per level-up
- Max: 5 upgrades offered per level-up
- Two upgrades exist to increase this:
  - "Expanded Shortlist" (Common): +1 upgrade choice
  - "HR Department" (Epic): +1 upgrade choice

## Rarity Appearance Rates

Probability of each rarity appearing, based on player level:

| Player Level | Common | Uncommon | Epic | Legendary |
|---|---|---|---|---|
| 1-10 | 80% | 20% | 0% | 0% |
| 11-20 | 40% | 35% | 20% | 5% |
| 21-30 | 15% | 30% | 35% | 20% |
| 31-40 | 10% | 20% | 40% | 30% |

## Game Progression

- **Game duration**: 10 minutes (600 seconds)
- **Levels**: 40 levels, each level-up offers upgrade choices
- **Sprints**: 10 tasks per sprint, task type distribution based on Feature/Bug Chance stats
- **Developer hiring**: At XP milestones throughout the game

## Build Archetypes (Examples)

### "Feature Factory"
- Stack Vibecoders
- Pump Feature Damage + Feature Chance
- Ignore Bug Damage
- Fast feature throughput, vulnerable to bug-heavy sprints

### "Bug Bounty Hunter"
- Stack Seniors
- Pump Bug Damage + Bug Chance
- Ignore Feature Damage
- Efficient bug clearing, slow on features

### "Balanced Team"
- Mix of all dev types
- Global Damage + Reward Bonus
- No trade-off penalties, but no specialized burst either

### "Click Frenzy"
- Focus on Boost Power + Boost Duration + Auto Click Speed
- Dev type matters less — brute force everything with clicks
- Weaker passive damage

## Full Upgrade List (80 upgrades)

Legend: `+` = positive stat, `−` = negative stat. Budget cost shown in parentheses.

### Global Upgrades (40)

#### Global — Common (14, budget 10)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G1 | Pep Talk | +7% Global Damage | 10.5 |
| G2 | Feature Sprint | +10% Feature Damage | 10 |
| G3 | Bug Bash | +10% Bug Damage | 10 |
| G4 | Shoulder Tap | +10% Boost Power | 10 |
| G5 | Quick Standup | +12% Boost Duration | 9.6 |
| G6 | Coffee Machine | +8% Auto Click Speed | 9.6 |
| G7 | Profit Sharing | +14% Reward Bonus | 9.8 |
| G8 | Expanded Shortlist | +1 Upgrade Choices | 10 |
| G9 | Rubber Duck | +5% Feature Damage, +5% Bug Damage | 10 |
| G10 | Open Floor Plan | +7% Boost Power, +4% Boost Duration | 10.2 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G11 | Hackathon Focus | +15% Feature Damage, −10% Bug Damage | 10 |
| G12 | Debug Marathon | +15% Bug Damage, −10% Feature Damage | 10 |
| G13 | Crunch Time | +15% Boost Power, −12% Boost Duration | 10.2 |
| G14 | Feature Pivot | +15% Feature Damage, +30% Feature Chance, −20% Bug Chance | 10 |

#### Global — Uncommon (12, budget 20)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G15 | Team Lunch | +13% Global Damage | 19.5 |
| G16 | Sprint Planning | +20% Feature Damage | 20 |
| G17 | Code Review | +20% Bug Damage | 20 |
| G18 | Pair Programming | +15% Boost Power, +6% Boost Duration | 19.8 |
| G19 | Task Automation | +17% Auto Click Speed | 20.4 |
| G20 | KPI Dashboard | +28% Reward Bonus | 19.6 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G21 | Feature Factory | +25% Feature Damage, −10% Bug Damage | 20 |
| G22 | Bug Bounty | +25% Bug Damage, −10% Feature Damage | 20 |
| G23 | Overtime Policy | +17% Global Damage, −15% Reward Bonus | 20.25 |
| G24 | Agile Pivot | +20% Feature Damage, +20% Feature Chance, −20% Bug Chance | 20 |
| G25 | Incident Response | +20% Bug Damage, +20% Bug Chance, −20% Feature Chance | 20 |
| G26 | Micromanagement | +20% Boost Power, +10% Boost Duration, −15% Auto Click Speed | 19 |

#### Global — Epic (9, budget 35)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G27 | Strategy Offsite | +23% Global Damage | 34.5 |
| G28 | Automation Suite | +20% Auto Click Speed, +10% Boost Duration | 32 |
| G29 | HR Department | +1 Upgrade Choices, +10% Reward Bonus | 17 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G30 | Feature Blitz | +35% Feature Damage, +20% Feature Chance, −15% Bug Damage | 37.5 |
| G31 | Bug Sweep | +35% Bug Damage, +20% Bug Chance, −15% Feature Damage | 37.5 |
| G32 | Deadline Pressure | +25% Boost Power, +15% Auto Click Speed, −20% Boost Duration | 35 |
| G33 | Growth Hacking | +50% Reward Bonus, −15% Global Damage | 23.75 |
| G34 | All-Hands Meeting | +20% Global Damage, +15% Boost Power, −20% Auto Click Speed | 33 |
| G35 | Product Roadmap | +30% Feature Damage, +50% Feature Chance, −40% Bug Chance | 45 |

#### Global — Legendary (5, budget 50)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G36 | Series A Funding | +25% Global Damage, +30% Reward Bonus | 58.5 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| G37 | IPO | +60% Reward Bonus, +15% Global Damage, −30% Boost Duration | 52.5 |
| G38 | Full Automation | +30% Auto Click Speed, +25% Boost Power, −30% Boost Duration | 49 |
| G39 | Feature Unicorn | +40% Feature Damage, +60% Feature Chance, −50% Bug Damage | 45 |
| G40 | Zero Bug Policy | +40% Bug Damage, +60% Bug Chance, −50% Feature Damage | 45 |

### Dev-Specific Upgrades — Vibecoder (14)

#### Vibecoder — Common (5, budget 10)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V1 | Vibe Check | +10% Feature Damage | 10 |
| V2 | Rapid Prototype | +7% Global Damage | 10.5 |
| V3 | Energy Drink | +10% Boost Power | 10 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V4 | Move Fast | +15% Feature Damage, −10% Bug Damage | 10 |
| V5 | Ship It | +10% Feature Damage, +20% Feature Chance, −20% Bug Chance | 10 |

#### Vibecoder — Uncommon (4, budget 20)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V6 | AI Copilot | +20% Boost Power | 20 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V7 | Prompt Engineering | +25% Feature Damage, −10% Bug Damage | 20 |
| V8 | Demo Day | +20% Feature Damage, +20% Feature Chance, −20% Bug Chance | 20 |
| V9 | Vibe Coding | +20% Boost Power, +10% Feature Damage, −15% Bug Damage | 22.5 |

#### Vibecoder — Epic (3, budget 35)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V10 | 10x Developer | +30% Feature Damage, +20% Boost Power, −25% Bug Damage | 37.5 |
| V11 | Feature Machine | +35% Feature Damage, +40% Feature Chance, −30% Bug Chance | 42.5 |
| V12 | Caffeine Overdose | +35% Boost Power, +15% Feature Damage, −25% Boost Duration | 40 |

#### Vibecoder — Legendary (2, budget 50)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| V13 | Founding Engineer | +30% Global Damage, +30% Feature Damage, −40% Bug Damage | 55 |
| V14 | Ship or Die | +50% Feature Damage, +40% Boost Power, −50% Bug Damage | 65 |

### Dev-Specific Upgrades — Regular (13)

#### Regular — Common (5, budget 10)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| R1 | Daily Standup | +7% Global Damage | 10.5 |
| R2 | Balanced Diet | +5% Feature Damage, +5% Bug Damage | 10 |
| R3 | Process Guide | +14% Reward Bonus | 9.8 |
| R4 | Focus Time | +12% Boost Duration | 9.6 |
| R5 | Steady Pace | +10% Boost Power | 10 |

#### Regular — Uncommon (4, budget 20)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| R6 | Cross-Training | +10% Feature Damage, +10% Bug Damage | 20 |
| R7 | Mentorship | +13% Global Damage | 19.5 |
| R8 | Work-Life Balance | +15% Boost Duration, +8% Boost Power | 20 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| R9 | Versatile Developer | +20% Global Damage, −15% Reward Bonus | 24.75 |

#### Regular — Epic (3, budget 35)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| R10 | Full Stack | +15% Feature Damage, +15% Bug Damage, +15% Reward Bonus, −15% Boost Duration | 34.5 |
| R11 | Reliable Engine | +20% Global Damage, +10% Boost Duration | 38 |
| R12 | Swiss Army Dev | +15% Global Damage, +10% Feature Damage, +10% Bug Damage, −15% Boost Duration | 36.5 |

#### Regular — Legendary (1, budget 50)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| R13 | Tech Lead | +25% Global Damage, +15% Feature Damage, +15% Bug Damage, −20% Boost Duration | 59.5 |

### Dev-Specific Upgrades — Senior (13)

#### Senior — Common (4, budget 10)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S1 | Code Audit | +10% Bug Damage | 10 |
| S2 | Refactor Pass | +7% Global Damage | 10.5 |
| S3 | Deep Focus | +12% Boost Duration | 9.6 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S4 | Bug Priority | +10% Bug Damage, +20% Bug Chance, −20% Feature Chance | 10 |

#### Senior — Uncommon (4, budget 20)

**Pure:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S5 | Monitoring Setup | +20% Boost Power | 20 |

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S6 | Architecture Review | +25% Bug Damage, −10% Feature Damage | 20 |
| S7 | Technical Debt Payoff | +20% Bug Damage, +20% Bug Chance, −20% Feature Chance | 20 |
| S8 | Debugging Mastery | +20% Global Damage, −10% Reward Bonus | 26.5 |

#### Senior — Epic (3, budget 35)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S9 | Post-Mortem Expert | +30% Bug Damage, +20% Boost Power, −25% Feature Damage | 37.5 |
| S10 | Bug Exterminator | +35% Bug Damage, +40% Bug Chance, −30% Feature Chance | 42.5 |
| S11 | System Architect | +25% Global Damage, +20% Bug Damage, −20% Feature Damage | 47.5 |

#### Senior — Legendary (2, budget 50)

**Trade-off:**

| # | Name | Effects | Budget |
|---|---|---|---|
| S12 | Principal Engineer | +30% Global Damage, +30% Bug Damage, −40% Feature Damage | 55 |
| S13 | Bug Whisperer | +50% Bug Damage, +40% Boost Power, −50% Feature Damage | 65 |

## UpgradeData Resource Schema

The current single-stat `UpgradeData` resource is replaced with a multi-stat model:

```gdscript
class_name UpgradeData extends BaseGameData  # BaseGameData adds id: String

@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: Constants.UpgradeRarity  # COMMON, UNCOMMON, EPIC, LEGENDARY
@export var upgrade_type: Constants.UpgradeType  # GLOBAL, DEV
@export var target_dev_type: Constants.DevType  # only for DEV upgrades
@export var min_game_level: int = 1

## Stat effects — each is a percentage modifier (e.g., 0.25 = +25%, -0.10 = -10%)
## Zero means "not affected by this upgrade"
@export var global_damage: float = 0.0
@export var feature_damage: float = 0.0
@export var bug_damage: float = 0.0
@export var feature_chance: float = 0.0  # adds to feature_chance weight
@export var bug_chance: float = 0.0  # adds to bug_chance weight
@export var boost_power: float = 0.0
@export var boost_duration: float = 0.0
@export var auto_click_speed: float = 0.0
@export var reward_bonus: float = 0.0
@export var upgrade_choices: int = 0  # +1 or +2, not percentage
```

Each upgrade can affect multiple stats. Positive values are bonuses, negative are penalties. This replaces the old single-purpose fields (`multiplier`, `click_boost_power_mult`, etc.).

Stats are applied **additively** across upgrades, then converted to a multiplier: `final_mult = 1.0 + sum_of_all_upgrade_percentages`. For example, two upgrades giving +25% and +10% Global Damage → `1.0 + 0.25 + 0.10 = 1.35x`.

## Attack Speed

Attack speed is **fixed per developer type** via `DeveloperData.base_attack_speed`. It is no longer a stat that can be upgraded. Boost Power and Boost Duration are the levers for increasing effective DPS through clicks.

## Rewards and Currency

Upgrades are **free at level-up** (Brotato style — choose 1 of 3-5). Reward Bonus increases the valuation (score) gained per completed task. There is no shop or currency-based purchasing.

## Rarity Rolling

Each upgrade choice slot rolls rarity **independently** using the appearance rate table. No pity/guarantee system.

## Migration from Current System

All existing `.tres` upgrade files will be deleted and replaced with the new 80-upgrade pool. The `RARE` rarity enum value is removed. Existing upgrade prerequisite chains are removed — upgrades no longer have prerequisites.

## Changes from Current System

1. **Remove REFACTOR task type** — only FEATURE and BUG remain
2. **Remove Rare rarity** — 4 tiers instead of 5 (Common, Uncommon, Epic, Legendary)
3. **Replace single-stat upgrades with budget-based multi-stat upgrades** with trade-offs
4. **Add new stats**: Feature/Bug Damage, Feature/Bug Chance, Reward Bonus, Upgrade Choices
5. **Remove stats**: Attack Speed (removed), Crit (never existed)
6. **Expand upgrade pool** from 35 to 80
7. **Task distribution becomes player-controlled** via Feature/Bug Chance stats
8. **Developer specialization clarified** with explicit FEATURE/BUG multipliers
