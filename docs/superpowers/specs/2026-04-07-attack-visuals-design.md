# Attack Visuals Design

## Summary

Visual polish for the attack system: progress bar between attacks, damage numbers, tween shake animations, task HP bar, and reduced damage values for longer fights.

## Changes

### 1. Attack Progress Bar

ProgressBar node under developer (child of Developer scene). Shows attack cooldown.

- Fills from 0% to 100% between attacks: `value = _attack_timer / data.base_attack_speed * 100`
- Resets to 0 on attack
- Hidden when queue is empty or no data assigned
- Position: below desk sprite, small and unobtrusive

### 2. Damage Numbers

Developer has a `show_damage(damage: int)` method that spawns a damage number via existing DamageNumber component.

**Signal flow:**
1. Developer emits `SB.developer_attack.emit(self)` — sends itself
2. PlayerData receives Developer, reads `developer.data`, calculates damage, applies to task HP
3. PlayerData calls `developer.show_damage(damage)` to display the number

**Signal change:** `signal developer_attack(developer: Developer)` — no damage param, no dev_data.

### 3. Tween Shake Animations

**Developer shake:** On attack, dev_sprite does a quick rotation tween: 0° → 5° → -5° → 0° over ~0.2s.

**Task card shake:** First card in HUD card_container shakes on hit. HUD listens to `SB.task_hp_changed`, gets first child of card_container, applies a position shake tween (x offset ±5px, ~0.15s).

### 4. Task HP Bar

First task card in HUD shows a ProgressBar at the bottom displaying current_hp / max_hp. Updates on `SB.task_hp_changed`. When task is destroyed, next card becomes the active one.

Implementation: TaskCard gets an optional HP bar that is shown when the card is in the HUD queue (not in backlog UI).

### 5. Reduced Damage Values

Divide all damage stats by 5:

| Archetype | feature_damage | bug_damage | refactor_damage |
|-----------|---------------|------------|-----------------|
| Vibecoder | 16 | 4 | 2 |
| Regular | 10 | 10 | 10 |
| Senior | 6 | 14 | 16 |

With HP=100 and damage=10, one Regular kills a feature in 10 hits (20 seconds).

### Files to Modify

- `autoloads/signal_bus.gd` — change `developer_attack` signature
- `components/developer/developer.gd` — add `show_damage()`, attack bar logic, shake tween, emit self
- `components/developer/developer.tscn` — add AttackProgressBar node
- `autoloads/player_data.gd` — receive Developer, calculate damage, call `show_damage()`
- `components/hud/hud.gd` — listen to `task_hp_changed`, shake first card
- `components/task_queue/task_card.gd` — add optional HP bar
- `game_data/developer/developer_data_vibecoder.tres` — reduce damage
- `game_data/developer/developer_data_regular.tres` — reduce damage
- `game_data/developer/developer_data_senior.tres` — reduce damage
