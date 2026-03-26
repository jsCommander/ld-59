class_name DataRegistry extends BaseDataRegistry

const PRODUCT_PATH: String = "res://game_data/product"
const BUILDING_PATH: String = "res://game_data/building"
const UPGRADE_TREE_PATH: String = "res://game_data/upgrade_tree"

var products: Dictionary[String, ProductData] = {}
var buildings: Dictionary[String, BuildingData] = {}
var upgrades: Dictionary[String, UpgradeTree] = {}

func _ready() -> void:
	products.merge(_find_game_data_in_path(PRODUCT_PATH))
	buildings.merge(_find_game_data_in_path(BUILDING_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_TREE_PATH))
