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
		connect(sig_name, _make_logger(sig_name, arg_count))
		Log.log_debug(name, "Subscribed to signal: %s (args: %d)" % [sig_name, arg_count])


func _make_logger(sig_name: String, arg_count: int) -> Callable:
	match arg_count:
		0: return func() -> void: Log.log_info(name, "Emitted '%s' with args: []" % sig_name)
		1: return func(a1: Variant) -> void: Log.log_info(name, "Emitted '%s' with args: %s" % [sig_name, [a1]])
		2: return func(a1: Variant, a2: Variant) -> void: Log.log_info(name, "Emitted '%s' with args: %s" % [sig_name, [a1, a2]])
		3: return func(a1: Variant, a2: Variant, a3: Variant) -> void: Log.log_info(name, "Emitted '%s' with args: %s" % [sig_name, [a1, a2, a3]])
		_: return func(a1: Variant, a2: Variant, a3: Variant, a4: Variant) -> void: Log.log_info(name, "Emitted '%s' with args: %s" % [sig_name, [a1, a2, a3, a4]])


func _is_builtin_signal(sig_name: String) -> bool:
	return sig_name in BaseConstants.BUILTIN_SIGNALS
