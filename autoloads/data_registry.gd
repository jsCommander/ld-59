class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_PATH))


func get_random_upgrades(count: int) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if _is_upgrade_available(upgrade):
			pool.append(upgrade)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


func _is_upgrade_available(upgrade: UpgradeData) -> bool:
	if upgrade.upgrade_type == Constants.UpgradeType.UNLOCK:
		return not _is_taken(upgrade.id)
	for req: UpgradeData in upgrade.prerequisites:
		if not _is_taken(req.id):
			return false
	return true


func _is_taken(upgrade_id: String) -> bool:
	for taken: UpgradeData in PD.upgrades_taken:
		if taken.id == upgrade_id:
			return true
	return false
