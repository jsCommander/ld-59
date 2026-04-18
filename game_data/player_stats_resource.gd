class_name PlayerStatsResource extends Resource

# --- Exports ---

@export_group("Damage")
## Combined damage multiplier for feature tasks: (1 + global_damage) × (1 + feature_damage).
@export var damage_features: float = 1.0
## Combined damage multiplier for refactoring tasks: (1 + global_damage) × (1 + refactoring_damage).
@export var damage_refactor: float = 1.0

@export_group("Click Boost")
## Additive attack-speed bonus per boost stack. Combat: attack_speed /= 1 + stacks × boost_per_stack.
@export var boost_per_stack: float = 0.0
## Seconds between auto-click ticks. 0.0 means auto-click is disabled.
@export var auto_click_interval: float = 0.0

@export_group("Sprint")
## Normalized probability 0..1 that a generated sprint task is a feature.
@export var feature_ratio: float = 0.5
## Normalized probability 0..1 that a generated sprint task is a refactoring. feature_ratio + refactoring_ratio == 1.0.
@export var refactoring_ratio: float = 0.5
