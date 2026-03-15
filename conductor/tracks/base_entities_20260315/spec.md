# Spec: Base Game Entities

## Overview

Create the foundational abstract entities for the game: Slot, Building, Plant, and Unit.
Each entity follows the data-driven pattern: behavior lives in scenes/scripts,
data (textures, stats) lives in Resource (.tres) files. Entities are minimal —
they exist on a level, have visuals, and expose their data through resources.
No inter-entity interactions in this track.

## Entities

### Slot
- A position on the surface where a Building or Plant can be placed
- Has a visual representation (empty vs occupied state)
- Knows whether it is occupied or free
- Resource: `SlotStat` — texture, occupied texture

### Building
- A static structure placed in a Slot
- Has a sprite defined by its resource
- Resource: `BuildingStat` — texture, name, icon

### Plant
- A growable entity placed in a Slot
- Has a sprite defined by its resource
- Resource: `PlantStat` — texture, name

### Unit
- A mobile entity that exists on the level (not in a slot)
- Simple Sprite2D, no animations
- Moves horizontally along the ground
- Resource: `UnitStat` — texture, speed, name

## Architecture

- Each entity is a scene (`.tscn`) with an attached script (`.gd`)
- Each entity has a corresponding Resource class in `scripts/`
- Example .tres instances go in `resources/`
- Entities are autonomous — drop on a level, they work (or idle gracefully)
- Visuals use existing game_kit assets as placeholders:
  - Unit: `char_robot_smile_@0.5x.png`
  - Building: `prop_bomb_@0.5x.png`
  - Plant: `prop_cake_@0.5x.png`
  - Slot: `prop_coin_@0.5x.png` (empty), `prop_star_@0.5x.png` (occupied)

## File Structure

```
scripts/
  slot_stat.gd          # class SlotStat extends Resource
  building_stat.gd      # class BuildingStat extends Resource
  plant_stat.gd         # class PlantStat extends Resource
  unit_stat.gd          # class UnitStat extends Resource

scenes/
  slot/
    slot.tscn + slot.gd
  building/
    building.tscn + building.gd
  plant/
    plant.tscn + plant.gd
  unit/
    unit.tscn + unit.gd

resources/
  slot/
    default_slot.tres
  building/
    drill.tres
  plant/
    basic_plant.tres
  unit/
    worker.tres
```

## Acceptance Criteria

- [ ] Each entity scene can be dropped onto an empty level and runs without errors
- [ ] Each entity reads its visual/stat data from an @export Resource
- [ ] Resource classes have typed @export fields
- [ ] At least one .tres instance exists per entity type
- [ ] Slot visually indicates empty vs occupied state
- [ ] All scripts use full static typing

## Out of Scope

- Animations (BaseRig, walk cycles)
- Inter-entity interactions (unit collecting from plant, delivering to building)
- Economy system (biofuel, production chain)
- Level/grid system
- Storm mechanics
- UI panels
- Sound effects
- Meta-progression
