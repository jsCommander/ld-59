# Attack System Design

## Summary

Replace the current timer-based produce mechanic with an auto-attack system. Developers sit at their desks and periodically attack the first task in the queue. Tasks have HP — when HP reaches 0, the task is completed. Game runs continuously — no sprints.

## Changes

### Data Layer

**DeveloperData** — replace speed stats with damage and attack speed:
- Remove: `feature_speed`, `bug_speed`, `refactor_speed`
- Add: `feature_damage: int`, `bug_damage: int`, `refactor_damage: int`
- Add: `base_attack_speed: float` (interval in seconds)
- Keep: `tech_debt: int`, `salary_multiplier: float`, `texture`, etc.

**TaskData** — add HP:
- Add: `base_hp: float`
- Add: `current_hp: float` (runtime, set when task enters queue)
- Task HP = `base_hp`. Set once when task is added to queue.

### Components

**Developer** — handles attack logic directly:
- Internal timer ticking at `base_attack_speed` interval (from DeveloperData)
- On tick: calculates damage via `get_damage_for_task(task_type)` × `get_damage_multiplier()`
- `get_damage_for_task()` reads from DeveloperData (feature_damage, bug_damage, refactor_damage)
- `get_damage_multiplier()` computed from purchased upgrades
- Emits `SB.developer_attack(developer, damage)`
- Timer runs when there are tasks in the queue. If queue is empty — idle, no attacks.

**PlayerData**:
- Listens to `SB.developer_attack(developer, damage)`
- Gets first task from `task_queue`
- Subtracts damage from task's `current_hp`
- On every hit: increases tech_debt by a small fixed amount
- If `current_hp` <= 0: task completed — apply rewards, remove from queue, emit `task_destroyed`
- Emits `task_hp_changed` on each hit for UI updates
- If queue empty during attack tick — no-op

### Game Flow (replaces sprints)

- Continuous gameplay — no sprint phases, no start/end sprint
- Developers auto-attack whenever there are tasks in the queue
- Player opens backlog UI via button at bottom of screen
- In backlog UI: player drags tasks into the queue
- Tasks flow: backlog → queue → destroyed by developers
- Backlog refills automatically (same generation logic as before)

### Signals

New signals in SignalBus:
```gdscript
signal developer_attack(developer: Developer, damage: float)
signal task_hp_changed(task: TaskData, hp: float, max_hp: float)
signal task_destroyed(task: TaskData)
```

Remove:
- `task_finished` — replaced by `task_destroyed`
- `sprint_started`, `sprint_ended` — no more sprints
- `game_state_changed` — no more PLANNING/WORKING states

### What Gets Removed

- `ProduceTrait` — logic moves into Developer
- `ProduceProgressBar` — repurposed or removed
- Speed stats from DeveloperData and all `.tres` instances
- `get_work_time()`, `get_speed_for_task()` in Developer
- Sprint logic in PlayerData (`start_sprint`, `end_sprint`, `_check_sprint_complete`, `GameState`)
- `Constants.GameState` enum

### Developer Archetypes (updated)

| Archetype | feature_damage | bug_damage | refactor_damage | tech_debt | base_attack_speed |
|-----------|---------------|------------|-----------------|-----------|-------------------|
| Vibecoder | 80 | 20 | 10 | 70 | 2.0 |
| Regular | 50 | 50 | 50 | 30 | 2.0 |
| Senior | 30 | 70 | 80 | 0 | 2.0 |
