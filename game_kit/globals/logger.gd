class_name Log extends RefCounted

static var show_debug: bool = true

static func get_log_message(type: String, component_name: String, message: String) -> String:
	var timestamp = Log.get_timestamp()
	return "[%s] [%s] (%s) %s" % [timestamp, type, component_name, message]

static func log_debug(component_name: String, message: String):
	if not show_debug:
		return

	var log_message = Log.get_log_message("DEBUG", component_name, message)
	print(log_message)

static func log_info(component_name: String, message: String):
	var log_message = Log.get_log_message("INFO", component_name, message)
	print(log_message)

static func log_warn(component_name: String, message: String):
	var log_message = Log.get_log_message("WARN", component_name, message)
	print(log_message)
	push_warning(log_message)

static func log_error(component_name: String, message: String):
	var log_message = Log.get_log_message("ERROR", component_name, message)
	print(log_message)
	push_error(log_message)

static func get_timestamp() -> String:
	return Time.get_datetime_string_from_system(true)
