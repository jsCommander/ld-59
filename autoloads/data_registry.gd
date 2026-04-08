class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_PATH))


func get_level_up_upgrades() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var global_pick: UpgradeData = _pick_random_from(_get_available_by_type(Constants.UpgradeType.GLOBAL, Constants.UpgradeStat.DAMAGE, Constants.UpgradeStat.SPEED, Constants.UpgradeStat.DEBT))
	if global_pick:
		result.append(global_pick)
	var backlog_pick: UpgradeData = _pick_random_from(_get_available_backlog())
	if backlog_pick:
		result.append(backlog_pick)
	var dev_pick: UpgradeData = _pick_random_from(_get_available_by_type(Constants.UpgradeType.DEV))
	if dev_pick:
		result.append(dev_pick)
	var random_pick: UpgradeData = _pick_random_from(_get_all_available())
	if random_pick:
		result.append(random_pick)
	return result


func _get_all_available() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if _is_upgrade_available(upgrade):
			pool.append(upgrade)
	return pool


func _get_available_by_type(type: Constants.UpgradeType, stat_filter_1: Constants.UpgradeStat = -1, stat_filter_2: Constants.UpgradeStat = -1, stat_filter_3: Constants.UpgradeStat = -1) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.upgrade_type != type:
			continue
		if stat_filter_1 != -1:
			if upgrade.stat != stat_filter_1 and upgrade.stat != stat_filter_2 and upgrade.stat != stat_filter_3:
				continue
		pool.append(upgrade)
	return pool


func _get_available_backlog() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrades.values():
		if not _is_upgrade_available(upgrade):
			continue
		if upgrade.stat == Constants.UpgradeStat.AUTO_CLICK or upgrade.stat == Constants.UpgradeStat.AUTO_CLICK_COUNT or upgrade.stat == Constants.UpgradeStat.AUTO_CLICK_SPEED:
			pool.append(upgrade)
	return pool


func _pick_random_from(pool: Array[UpgradeData]) -> UpgradeData:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


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
