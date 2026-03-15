# GDScript Code Style Guide

Derived from project CLAUDE.md principles. This is the authoritative reference for code conventions.

## Typing

- Static typing everywhere: variables, arguments, return types, collections
- Use typed collections: `Array[String]`, `Dictionary[PackedScene, PackedScene]`
- Use `as` cast + null check over blind `get_parent()` calls
- `@export` with specific Resource types: `@export var stat: EnemyStat`

## References

- `%NodeName` for intra-scene references (unique names)
- Groups for cross-scene discovery: `get_tree().get_nodes_in_group("player")`
- Never use autoloads for entity references

## Communication

- Signals up: children emit, parents connect
- Calls down: parents call children directly
- No sibling-to-sibling communication
- No `get_parent().get_parent()` chains

## Entity Design

- Composition over inheritance: add component nodes, not subclasses
- Every entity is autonomous: drop on map, it works
- Interactions via component pairs (Hurtbox/Hitbox, PickupCatcher/Pickup)
- Physics layers define "who interacts with whom" — not code

## Data Separation

- `scripts/` = class definitions (Resource subclasses)
- `resources/` = .tres instances (actual values)
- One scene + many .tres variants, not many scenes
- Duplicate mutable resources in `_ready()` to avoid shared state bugs

## Spawning

- Dynamic objects (bullets, drops, VFX) → add to level, not to self
- Find level via group: `get_tree().get_first_node_in_group("level")`

## Logging

- Use `Log.log_debug/info/warn/error(self.name, "message")`
- Log state changes, lifecycle events, decisions
- Never log every frame or obvious things

## Game Kit

- Kit lives in `game_kit/`, game code lives outside
- Kit never imports game-specific code
- Check kit before building something from scratch
