@tool
extends Control
class_name UiProgressBar

@export var max_value: float:
	set(value):
		current_max_value = value
		_update()
	get:
		return current_max_value

@export var value: float:
	set(value):
		current_value = value
		_update()
	get:
		return current_value

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var label: Label = %Label

var current_value: float = 0.0
var current_max_value: float = 100.0

func _ready() -> void:
	_update()

func _update() -> void:
	if not is_node_ready():
		return

	progress_bar.max_value = current_max_value
	progress_bar.value = current_value
	label.text = "%d / %d" % [current_value, current_max_value]
