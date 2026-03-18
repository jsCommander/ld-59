class_name BaseSignalBus extends Node

var is_debug_mode: bool = OS.is_debug_build()


func _ready() -> void:
	if is_debug_mode:
		_subscribe_to_all_signals()


func _subscribe_to_all_signals() -> void:
	for sig_info in get_signal_list():
		var sig_name: String = sig_info.name
		if _is_builtin_signal(sig_name):
			continue
		var arg_count: int = sig_info.args.size()
		connect(sig_name, _log_signal.bind(arg_count, sig_name))
		Log.log_debug(name, "Subscribed to signal: %s (args: %d)" % [sig_name, arg_count])


func _log_signal(
	a1 = null, a2 = null, a3 = null, a4 = null, a5 = null,
	arg_count: int = 0, sig_name: String = ""
) -> void:
	var args: Array = [a1, a2, a3, a4, a5].slice(0, arg_count)
	Log.log_info(name, "Emitted '%s' with args: %s" % [sig_name, args])


func _is_builtin_signal(sig_name: String) -> bool:
	return sig_name in BaseConstants.BUILTIN_SIGNALS
