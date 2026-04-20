class_name BaseDialog extends Control

signal finished(_data: Dictionary)

func set_data(_data: Dictionary) -> void:
	Log.log_debug(self.name, "Received data: %s" % _data)

func close_dialog(data: Dictionary) -> void:
	Log.log_debug(self.name, "Closing dialog with data: %s" % data)
	finished.emit(data)