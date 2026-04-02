class_name ProduceTrait
extends Node

signal started
signal stopped

var produce_time: float = 5.0

var _elapsed: float = 0.0
var _is_producing: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_DISABLED


func setup_simple(time: float) -> void:
	produce_time = time
	process_mode = PROCESS_MODE_INHERIT
	Log.log_debug(name, "Setup simple timer: %.1fs" % produce_time)


func start() -> void:
	_elapsed = 0.0
	_is_producing = true
	started.emit()
	Log.log_debug(name, "Production started (%.1fs)" % produce_time)


func stop() -> void:
	_is_producing = false
	_elapsed = 0.0
	stopped.emit()


func cancel() -> void:
	_is_producing = false
	_elapsed = 0.0


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
	pass
