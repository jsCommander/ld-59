class_name BaseDataRegistry extends Node


func _find_game_data_in_path(path: String) -> Dictionary[String, BaseGameData]:
	var result: Dictionary[String, BaseGameData] = {}
	_scan_directory(path, result)
	Log.log_info(name, "Found %d entries in %s: %s" % [result.size(), path, ", ".join(result.keys())])
	return result


func _scan_directory(path: String, result: Dictionary[String, BaseGameData]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return
	Log.log_debug(name, "Scanning: %s" % path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(full_path, result)
		elif file_name.ends_with(".tres"):
			var res: Resource = load(full_path)
			if res is BaseGameData:
				var id: String = res.id
				if id.is_empty():
					Log.log_warn(name, "Empty id in %s" % full_path)
				elif id in result:
					Log.log_warn(name, "Duplicate id '%s' in %s" % [id, full_path])
				else:
					result[id] = res
		file_name = dir.get_next()
