class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_PATH))
	_validate_upgrade_budgets()


func _validate_upgrade_budgets() -> void:
	var lines: PackedStringArray = []
	for upgrade: UpgradeData in upgrades.values():
		var warning: String = upgrade.validate_budget()
		if warning:
			lines.append(warning)
	if lines.is_empty():
		return
	lines.sort()
	var path: String = "res://logs/balance_warnings.txt"
	DirAccess.make_dir_recursive_absolute("res://logs")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines) + "\n")
		file.close()
		Log.log_warn(name, "%d budget warnings written to %s" % [lines.size(), path])
