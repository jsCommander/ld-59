class_name BaseDataRegistry extends Node


func _find_game_data_in_path(path: String) -> Dictionary[String, BaseGameData]:
	var result: Dictionary[String, BaseGameData] = {}
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return result
	Log.log_debug(name, "Scanning: %s" % path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(path.path_join(file_name))
			if res is BaseGameData:
				var id: String = res.id
				if id.is_empty():
					Log.log_warn(name, "Empty id in %s/%s" % [path, file_name])
				elif id in result:
					Log.log_warn(name, "Duplicate id '%s' in %s/%s" % [id, path, file_name])
				else:
					result[id] = res
		file_name = dir.get_next()
	Log.log_info(name, "Found %d entries in %s: %s" % [result.size(), path, ", ".join(result.keys())])
	return result
