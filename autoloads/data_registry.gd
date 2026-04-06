class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_TREE_PATH: String = "res://game_data/upgrade_tree"
const PHASE_PATH: String = "res://game_data/phase"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeTree] = {}
var phases: Dictionary[String, PhaseData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_upgrades_in_path(UPGRADE_TREE_PATH))
	phases.merge(_find_game_data_in_path(PHASE_PATH))


func _find_upgrades_in_path(path: String) -> Dictionary[String, UpgradeTree]:
	var result: Dictionary[String, UpgradeTree] = {}
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return result
	Log.log_debug(name, "Scanning upgrades: %s" % path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(path.path_join(file_name))
			if res is UpgradeTree:
				var id: String = res.id
				if id.is_empty():
					Log.log_warn(name, "Empty id in %s/%s" % [path, file_name])
				elif id in result:
					Log.log_warn(name, "Duplicate id '%s' in %s/%s" % [id, path, file_name])
				else:
					result[id] = res
		file_name = dir.get_next()
	Log.log_info(name, "Found %d upgrades in %s: %s" % [result.size(), path, ", ".join(result.keys())])
	return result
