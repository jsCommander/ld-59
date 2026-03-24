class_name ProduceTrait
extends Node

signal started
signal stopped

var recipe: Recipe
var produce_time: float = 5.0
var produce_count: int = 1

var _elapsed: float = 0.0
var _is_producing: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_DISABLED


func setup(r: Recipe, time_override: float = 0.0, count_override: int = 0) -> void:
	recipe = r
	produce_time = time_override if time_override > 0.0 else r.produce_time
	produce_count = count_override if count_override > 0 else 1
	process_mode = PROCESS_MODE_INHERIT
	Log.log_debug(name, "Setup: %s (x%d / %.1fs)" % [r.output.product_name, produce_count, produce_time])


func start() -> void:
	_elapsed = 0.0
	_is_producing = true
	started.emit()
	Log.log_debug(name, "Production started (%.1fs)" % produce_time)


func stop() -> void:
	_is_producing = false
	_elapsed = 0.0
	stopped.emit()


func _process(delta: float) -> void:
	if not _is_producing:
		return
	_elapsed += delta
	if _elapsed >= produce_time:
		_is_producing = false
		_elapsed = 0.0
		stopped.emit()
		_produce()


func _produce() -> void:
	if not recipe:
		Log.log_warn(name, "No recipe set")
		return
	Log.log_debug(name, "Produced %s" % recipe.output.product_name)
	SB.product_produced.emit(recipe.output.id, produce_count)
