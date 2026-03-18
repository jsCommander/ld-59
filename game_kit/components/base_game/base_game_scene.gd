extends Node
class_name BaseGameScene

@export var data: Dictionary = {}

signal finished(_data: Dictionary)
signal reload_requested(data: Dictionary)

func _ready() -> void:
	
	finished.connect(func(_data: Dictionary): Log.log_info(self.name, "scene is finished: %s" % _data))
	reload_requested.connect(func(_data: Dictionary): Log.log_info(self.name, "scene reload requested: %s" % _data))
	
	get_window().grab_focus()

func set_data(_data: Dictionary) -> void:
	data = _data