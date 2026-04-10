# Meme Viral Redesign — Game Concept Overhaul

## Overview

Полный редизайн игры в мемный виральный симулятор стартапа для программистов. Игрок управляет командой девелоперов, закрывает спринты за 10 минут, наращивает Evaluation компании. Визуальный стиль — "This is Fine" горящий офис.

## What Changes

### Removed
- Backlog button and manual task spawning (click-to-spawn)
- Tech debt system entirely (mechanic, upgrades, UI bar)
- Auto-click mechanic and related upgrades
- `AttackProgressBar` (dev timer bar)
- Unlock upgrade category

### Reworked
- Game loop: backlog clicks → sprint cycles
- Task types: Feature/Bug → Feature/Bug/Refactor
- Task data: hp_mult/reward_mult → difficulty level as HP multiplier
- Developer combat: add click boost, burnout, YouTube procrastination
- HUD: completely new layout
- Upgrade system: 3 categories instead of current mix
- Game duration: 15 min → 10 min

### Kept
- Developer autonomous task selection (`TaskSelectFunction`)
- Core combat loop (dev picks task, attacks, kills)
- Level-up → upgrade choice flow
- Hire events at specific levels
- game_kit (untouched)

---

## 1. Game Loop & Sprint System

### Core Loop
1. Game starts → 10-minute global timer begins
2. First sprint starts: `MAX_SPRINT_TASKS` tasks of three types generated, sprint timer starts
3. Devs autonomously pick and attack tasks
4. All sprint tasks killed → sprint ends → speed bonus calculated
5. New sprint starts immediately (tasks scale with sprint number)
6. Global timer hits 0 → game over → show final Evaluation

### Sprint Bonus
- Sprint finished before deadline: `bonus = base_bonus * (remaining_time / total_time)` — earlier finish = bigger bonus
- Sprint finished after deadline: bonus = 0, but game continues. Devs finish remaining tasks, just no bonus

### Sprint Timer
- Bar at bottom of screen, color transitions green → red as time decreases
- After deadline: bar is empty/red, visible that sprint is overdue

### Scaling
- Task HP grows with each sprint number (not with elapsed time)
- Formula: `max_hp = BASE_HP * difficulty * sprint_scaling(sprint_number)`

---

## 2. Task Types & Developer Types

### Task Data
Each task has:
- `task_type`: Feature / Bug / Refactor (new enum, replaces Feature/Bug)
- `difficulty`: int — HP multiplier
- `max_hp = BASE_HP * difficulty * sprint_scaling`
- Reward proportional to `max_hp` (same for all task types)

Three `.tres` files, one per type. No `base_hp_mult` or `base_reward_mult` — difficulty handles HP scaling, reward is universal.

### Developer Types

| Dev | Specialization | Strong | Weak |
|-----|---------------|--------|------|
| Vibecoder | Features | ×1.6 vs Feature | ×0.4 vs Bug/Refactor |
| Regular | Generalist | ×1.0 vs all | — |
| Senior | Bug/Refactor | ×1.6 vs Bug/Refactor | ×0.4 vs Feature |

### Task Selection Logic
- Dev looks at sprint queue, picks task with highest damage multiplier (prefers own type)
- If no tasks of preferred type → takes any task, hits it with reduced mult
- Regular picks whatever is available — all ×1.0

Existing `TaskSelectFunction` strategy pattern is reused, just reconfigured with new multipliers.

---

## 3. Developer Interaction Mechanics

### Combat (Reworked)
- Remove `AttackProgressBar`
- Dev attacks task with period ~0.5s (base attack speed)
- On hit: task flashes white (modulate flash)
- Task has HP bar above it, decreases with each hit
- Faster attack speed = faster flashing = power fantasy

### Click Boost
- Click on dev → adds a boost stack
- Visual: dev turns red (modulate shift), boost particles fly
- Each stack reduces attack period (increases speed)
- Stacks decay over time — dev "cools down"
- Exceeds `MAX_BOOST` threshold → burnout

### Burnout
- Dev stops working, fire icon above head
- Lasts `BURNOUT_DURATION` seconds, then self-recovers
- All boost stacks reset to zero

### YouTube Procrastination
- When dev goes to pick a new task: random chance to enter `YOUTUBE` state instead
- Dev shows YouTube icon instead of working
- Player clicks dev → returns to `IDLE`, tries to pick task again
- If player doesn't notice → dev just sits there, wasting sprint time

Click on dev has two contexts: if working → boost, if on YouTube → snap out of it.

---

## 4. UI & HUD Layout

### Top of Screen
- Large Evaluation counter — primary metric, prominent placement
- Below it: XP progress bar to next upgrade (company growth stage)
- On level-up: side comparison with real companies ("Bigger than Ubisoft!", "Bigger than EA!")
- Company list sourced from real market cap rankings for meme value

### Center
- Office in "This is Fine" visual style — burning room, devs at desks
- Devs attack tasks, flash, turn red from boost, burn out, watch YouTube

### Bottom of Screen
- Sprint task queue — tasks not yet claimed by devs
- Sprint timer bar — green → red gradient

### Bottom Right Corner
- Circle with CEO silhouette
- Speech bubble with performance commentary
- Fast performance: "Stonks 📈", "To the moon!", "Amazing velocity!"
- Slow performance: "Have you tried working harder?", "Let's circle back", "We need to pivot"

### Removed from HUD
- Backlog button and click progress bar
- Tech debt bar
- Auto-click progress bar

---

## 5. Upgrade System

### When
Evaluation fills XP bar → level-up → card choice (existing flow preserved).

### Three Categories

**1. Dev-Specific Upgrades:**
- Damage boost for specific dev type
- Attack speed boost for specific dev type
- Examples: "Cursor Pro" (Vibecoder ×2 dmg), "Second Monitor" (Regular ×1.5 speed)

**2. Global Dev Upgrades:**
- Damage boost for all devs
- Attack speed boost for all devs
- Examples: "Motivational Speech" (all ×1.5 dmg), "Shorter Standups" (all ×1.3 speed)

**3. Sprint Upgrades:**
- Increase sprint timer duration (more chance for bonus)
- Modify task composition — more Features / more Bugs / more Refactors
- Player tunes sprint to match team composition

### Removed
- All tech debt upgrades
- Auto-click upgrades
- Unlock category

### Hire Events
Preserved as-is: at specific levels, player chooses a new dev from three types.

---

## 6. Meme & Viral Elements

### In-Game Memes
- **CEO commentary**: corporate bullshit phrases reacting to performance
- **Company comparisons**: real company names at each level milestone
- **YouTube icon**: universally recognizable programmer procrastination
- **Burnout**: literal mechanic from real dev life
- **Upgrade names**: IT culture memes ("Cursor Pro", "Stack Overflow Premium", "Pizza Friday", "Removed Standups")
- **"This is Fine" office**: burning room visual style

### Viral Sharing
- Game over screen designed to be shareable:
  - Final Evaluation number
  - Company comparison ("Your startup beat EA!")
  - Team composition summary
  - Share button — saves screenshot/generates shareable image
- Concrete share implementation (platform, format) is out of scope for this spec

---

## 7. Constants & Balance (Starting Point)

```
GAME_DURATION = 600.0          # 10 minutes
BASE_HP = 100
BASE_DAMAGE = 10
BASE_ATTACK_SPEED = 0.5        # seconds between hits
MAX_SPRINT_TASKS = 8           # tasks per sprint (tunable)
SPRINT_DURATION = 60.0         # seconds per sprint timer (tunable)
MAX_BOOST = 10                 # boost stacks before burnout
BOOST_DECAY_RATE = 1.0         # stacks lost per second
BOOST_SPEED_MULT = 0.05        # attack speed reduction per stack
BURNOUT_DURATION = 5.0         # seconds dev is out
YOUTUBE_CHANCE = 0.1           # chance to enter YouTube state when picking task
XP_BASE = 30                   # base XP for first level
HIRE_LEVELS = [3, 6, 9, 12, 15]
```

Sprint scaling: `sprint_hp_mult = 1.0 + (sprint_number * 0.3)` or similar exponential curve. Needs playtesting.

---

## 8. Migration Approach

Phased transformation (Approach C):

1. **Sprint system** — replace backlog with sprint cycle in PlayerData
2. **Tasks** — add Refactor type, replace hp_mult/reward_mult with difficulty, remove tech debt
3. **Developers** — add boost/burnout/YouTube states, remove AttackProgressBar
4. **HUD** — new layout with Evaluation/XP/sprint timer/CEO
5. **Upgrades** — rebalance into 3 categories, remove old ones

Each phase results in a playable game. Incremental and testable.
