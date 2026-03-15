# Plan: Base Game Entities

## Phase 1: Resource Classes

Define the data shape for each entity.

- [x] Task: Create `scripts/slot_stat.gd` — `class_name SlotStat extends Resource`
  - [x] @export var texture: Texture2D
  - [x] @export var occupied_texture: Texture2D

- [x] Task: Create `scripts/building_stat.gd` — `class_name BuildingStat extends Resource`
  - [x] @export var texture: Texture2D
  - [x] @export var building_name: String
  - [x] @export var icon: Texture2D

- [x] Task: Create `scripts/plant_stat.gd` — `class_name PlantStat extends Resource`
  - [x] @export var texture: Texture2D
  - [x] @export var plant_name: String

- [x] Task: Create `scripts/unit_stat.gd` — `class_name UnitStat extends Resource`
  - [x] @export var texture: Texture2D
  - [x] @export var unit_name: String
  - [x] @export var speed: float

- [x] Task: Conductor - User Manual Verification 'Phase 1' (skipped per user request)

## Phase 2: Entity Scenes

Create scenes with scripts that read data from their resource. All visuals are Sprite2D, no animations.

- [x] Task: Create `scenes/slot/slot.tscn` + `slot.gd`
  - [x] Node2D base with Area2D for detection
  - [x] Sprite2D reads texture from SlotStat
  - [x] `is_occupied: bool` property
  - [x] Visual swap between empty/occupied texture
  - [x] Group: "slot"

- [x] Task: Create `scenes/building/building.tscn` + `building.gd`
  - [x] Node2D base
  - [x] Sprite2D reads texture from BuildingStat
  - [x] @export var stat: BuildingStat
  - [x] Group: "building"

- [x] Task: Create `scenes/plant/plant.tscn` + `plant.gd`
  - [x] Node2D base
  - [x] Sprite2D reads texture from PlantStat
  - [x] @export var stat: PlantStat
  - [x] Group: "plant"

- [x] Task: Create `scenes/unit/unit.tscn` + `unit.gd`
  - [x] CharacterBody2D base
  - [x] Sprite2D reads texture from UnitStat
  - [x] @export var stat: UnitStat
  - [x] Simple horizontal movement at stat.speed
  - [x] Group: "unit"

- [x] Task: Conductor - User Manual Verification 'Phase 2' (skipped per user request)

## Phase 3: Resource Instances

Create .tres files with placeholder data using game_kit assets.

- [x] Task: Create `resources/slot/default_slot.tres`
  - [x] texture: `prop_coin_@0.5x.png`
  - [x] occupied_texture: `prop_star_@0.5x.png`

- [x] Task: Create `resources/building/drill.tres`
  - [x] texture: `prop_bomb_@0.5x.png`
  - [x] building_name: "Drill"

- [x] Task: Create `resources/plant/basic_plant.tres`
  - [x] texture: `prop_cake_@0.5x.png`
  - [x] plant_name: "Basic Plant"

- [x] Task: Create `resources/unit/worker.tres`
  - [x] texture: `char_robot_smile_@0.5x.png`
  - [x] unit_name: "Worker"
  - [x] speed: 100.0

- [x] Task: Conductor - User Manual Verification 'Phase 3' (skipped per user request)
