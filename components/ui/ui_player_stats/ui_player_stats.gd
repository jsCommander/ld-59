class_name UiPlayerStats
extends Control

# --- Exports ---

## Current stats to display. When `stats_for_diff` is null, rendered plain.
@export var stats: PlayerStatsResource:
	set(value):
		stats = value
		_refresh()

## Optional preview stats. When set, each row shows the preview value coloured by direction.
@export var stats_for_diff: PlayerStatsResource:
	set(value):
		stats_for_diff = value
		_refresh()

# --- @onready ---

@onready var row_damage_features: UiPlayerStatRow = %RowDamageFeatures
@onready var row_damage_refactor: UiPlayerStatRow = %RowDamageRefactor
@onready var row_click_per_stack: UiPlayerStatRow = %RowClickPerStack
@onready var row_click_auto: UiPlayerStatRow = %RowClickAuto
@onready var row_sprint_features: UiPlayerStatRow = %RowSprintFeatures
@onready var row_sprint_refactor: UiPlayerStatRow = %RowSprintRefactor

# --- Lifecycle ---

func _ready() -> void:
	_refresh()

# --- Private ---

func _refresh() -> void:
	if not is_node_ready() or stats == null:
		return
	var shown: PlayerStatsResource = stats_for_diff if stats_for_diff != null else stats
	row_damage_features.setup("Features:", Utils.format_mult(shown.damage_features), _diff(stats.damage_features, shown.damage_features))
	row_damage_refactor.setup("Refactor:", Utils.format_mult(shown.damage_refactor), _diff(stats.damage_refactor, shown.damage_refactor))
	row_click_per_stack.setup("Dev Speed Per Stack:", Utils.format_mult(1.0 + shown.boost_per_stack), _diff(stats.boost_per_stack, shown.boost_per_stack))
	row_click_auto.setup("Auto click:", _fmt_interval(shown.auto_click_interval), _diff_interval(stats.auto_click_interval, shown.auto_click_interval))
	row_sprint_features.setup("Features:", _fmt_ratio(shown.feature_ratio), _diff(stats.feature_ratio, shown.feature_ratio))
	row_sprint_refactor.setup("Refactoring:", _fmt_ratio(shown.refactoring_ratio), _diff(stats.refactoring_ratio, shown.refactoring_ratio))


func _diff(current: float, preview: float) -> Constants.DiffType:
	if is_equal_approx(current, preview):
		return Constants.DiffType.NONE
	return Constants.DiffType.POSITIVE if preview > current else Constants.DiffType.NEGATIVE


## Inverted: smaller interval is better. "Off" (0.0) → any > 0 is positive (unlock).
func _diff_interval(current: float, preview: float) -> Constants.DiffType:
	if is_equal_approx(current, preview):
		return Constants.DiffType.NONE
	if is_zero_approx(current):
		return Constants.DiffType.POSITIVE
	if is_zero_approx(preview):
		return Constants.DiffType.NEGATIVE
	return Constants.DiffType.POSITIVE if preview < current else Constants.DiffType.NEGATIVE


func _fmt_interval(seconds: float) -> String:
	if is_zero_approx(seconds):
		return "Off"
	return "%.1fs" % seconds


func _fmt_ratio(ratio: float) -> String:
	var size: int = Balance.get_sprint_size(PD.level)
	return "%.1f/%d" % [ratio * size, size]
