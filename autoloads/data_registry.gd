class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_TREE_PATH: String = "res://game_data/upgrade_tree"
const PHASE_PATH: String = "res://game_data/phase"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeTree] = {}
var phases: Dictionary[String, PhaseData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_TREE_PATH))
	phases.merge(_find_game_data_in_path(PHASE_PATH))
