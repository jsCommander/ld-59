class_name DataRegistry extends BaseDataRegistry

const DEVELOPER_PATH: String = "res://game_data/developer"
const UPGRADE_PATH: String = "res://game_data/upgrades"

var developers: Dictionary[String, DeveloperData] = {}
var upgrades: Dictionary[String, UpgradeData] = {}


func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_game_data_in_path(UPGRADE_PATH))
	if OS.has_feature("editor"):
		_write_upgrade_data_log()
		_validate_upgrades()


func _write_upgrade_data_log() -> void:
	var lines: PackedStringArray = []

	# Summary table: count per trade_off_type x rarity
	lines.append("=== UPGRADE POOL SUMMARY ===")
	lines.append("")
	var type_keys: PackedStringArray = PackedStringArray(Constants.TradeOffType.keys())
	var rarity_keys: PackedStringArray = PackedStringArray(Constants.UpgradeRarity.keys())

	# Header
	var header: String = "%-30s" % "TYPE \\ RARITY"
	for rarity_name: String in rarity_keys:
		header += "  %-10s" % rarity_name
	header += "  TOTAL"
	lines.append(header)
	lines.append("-".repeat(header.length()))

	# Rows per trade_off_type
	for trade_off_type: Constants.TradeOffType in Constants.TradeOffType.values():
		var row: String = "%-30s" % type_keys[trade_off_type]
		var row_total: int = 0
		for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
			var count: int = 0
			for upgrade: UpgradeData in upgrades.values():
				if upgrade.trade_off_type == trade_off_type and upgrade.rarity == rarity:
					count += 1
			row += "  %-10d" % count
			row_total += count
		row += "  %d" % row_total
		lines.append(row)

	# Rows per group
	lines.append("")
	header = "%-30s" % "GROUP \\ RARITY"
	for rarity_name: String in rarity_keys:
		header += "  %-10s" % rarity_name
	header += "  TOTAL"
	lines.append(header)
	lines.append("-".repeat(header.length()))

	var group_keys: PackedStringArray = PackedStringArray(Constants.UpgradeGroup.keys())
	for grp: Constants.UpgradeGroup in Constants.UpgradeGroup.values():
		var row: String = "%-30s" % group_keys[grp]
		var row_total: int = 0
		for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
			var count: int = 0
			for upgrade: UpgradeData in upgrades.values():
				if upgrade.group == grp and upgrade.rarity == rarity:
					count += 1
			row += "  %-10d" % count
			row_total += count
		row += "  %d" % row_total
		lines.append(row)

	# Full upgrade list grouped by rarity, then group, then type
	lines.append("")
	lines.append("=== FULL UPGRADE LIST ===")
	for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
		var rarity_upgrades: Array[UpgradeData] = []
		for upgrade: UpgradeData in upgrades.values():
			if upgrade.rarity == rarity:
				rarity_upgrades.append(upgrade)
		if rarity_upgrades.is_empty():
			continue
		rarity_upgrades.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool:
			if a.group != b.group:
				return a.group < b.group
			if a.trade_off_type != b.trade_off_type:
				return a.trade_off_type < b.trade_off_type
			return a.id < b.id
		)
		lines.append("")
		lines.append("--- %s (%d) ---" % [rarity_keys[rarity], rarity_upgrades.size()])
		for upgrade: UpgradeData in rarity_upgrades:
			var stats_parts: PackedStringArray = []
			for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
				var field: String = Constants.STAT_FIELDS[stat]
				var value: float = upgrade.get(field) as float
				if not is_zero_approx(value):
					stats_parts.append("%s=%+.0f%%" % [field, value * 100.0])
			lines.append("  %-30s %-12s %-28s budget:%.1f  %s" % [
				upgrade.id,
				group_keys[upgrade.group],
				type_keys[upgrade.trade_off_type],
				upgrade.calculate_budget(),
				", ".join(stats_parts),
			])

	var path: String = "res://logs/upgrade_data.log"
	DirAccess.make_dir_recursive_absolute("res://logs")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines) + "\n")
		file.close()
		Log.log_info(name, "Upgrade data log written to %s" % path)


func _validate_upgrades() -> void:
	var warnings: PackedStringArray = []
	_validate_upgrade_budgets(warnings)
	_validate_upgrade_pool_counts(warnings)
	_validate_upgrade_stat_coverage(warnings)
	_validate_upgrade_duplicates(warnings)
	_validate_upgrade_step(warnings)
	if warnings.is_empty():
		return
	warnings.sort()
	var path: String = "res://logs/balance_warnings.txt"
	DirAccess.make_dir_recursive_absolute("res://logs")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(warnings) + "\n")
		file.close()
		Log.log_warn(name, "%d balance warnings written to %s" % [warnings.size(), path])


func _validate_upgrade_budgets(warnings: PackedStringArray) -> void:
	for upgrade: UpgradeData in upgrades.values():
		var warning: String = upgrade.validate_budget()
		if warning:
			warnings.append(warning)


func _validate_upgrade_pool_counts(warnings: PackedStringArray) -> void:
	var counts: Dictionary = {}
	for trade_off_type: Constants.TradeOffType in Constants.TradeOffType.values():
		counts[trade_off_type] = {}
		for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
			counts[trade_off_type][rarity] = 0
	for upgrade: UpgradeData in upgrades.values():
		if upgrade.trade_off_type in counts and upgrade.rarity in counts[upgrade.trade_off_type]:
			counts[upgrade.trade_off_type][upgrade.rarity] += 1
	for trade_off_type: Constants.TradeOffType in Constants.TradeOffType.values():
		var min_limits: Dictionary = Constants.UPGRADE_MIN_COUNT_DICT[trade_off_type]
		var max_limits: Dictionary = Constants.UPGRADE_MAX_COUNT_DICT[trade_off_type]
		for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
			var count: int = counts[trade_off_type][rarity]
			var min_limit: int = min_limits[rarity] as int
			var max_limit: int = max_limits[rarity] as int
			if count < min_limit:
				warnings.append("Pool: %s x %s has %d upgrades (min %d)" % [
					Constants.TradeOffType.keys()[trade_off_type],
					Constants.UpgradeRarity.keys()[rarity],
					count,
					min_limit,
				])
			if count > max_limit:
				warnings.append("Pool: %s x %s has %d upgrades (max %d)" % [
					Constants.TradeOffType.keys()[trade_off_type],
					Constants.UpgradeRarity.keys()[rarity],
					count,
					max_limit,
				])


func _validate_upgrade_duplicates(warnings: PackedStringArray) -> void:
	var seen: Dictionary = {}
	for upgrade: UpgradeData in upgrades.values():
		var parts: PackedStringArray = []
		for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
			var field: String = Constants.STAT_FIELDS[stat]
			var value: float = upgrade.get(field) as float
			if value > 0.0:
				parts.append("+%s" % field)
			elif value < 0.0:
				parts.append("-%s" % field)
		parts.sort()
		var fingerprint: String = ",".join(parts)
		if not seen.has(upgrade.rarity):
			seen[upgrade.rarity] = {}
		if not seen[upgrade.rarity].has(fingerprint):
			seen[upgrade.rarity][fingerprint] = [] as Array[String]
		(seen[upgrade.rarity][fingerprint] as Array).append(upgrade.id)
	for rarity: Constants.UpgradeRarity in seen:
		for fingerprint: String in seen[rarity]:
			var ids: Array = seen[rarity][fingerprint]
			if ids.size() > 1:
				warnings.append("Duplicate stats in %s: [%s] share pattern [%s]" % [
					Constants.UpgradeRarity.keys()[rarity],
					", ".join(ids),
					fingerprint,
				])


func _validate_upgrade_step(warnings: PackedStringArray) -> void:
	const STEP: float = 0.025
	for upgrade: UpgradeData in upgrades.values():
		for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
			var field: String = Constants.STAT_FIELDS[stat]
			var value: float = upgrade.get(field) as float
			if is_zero_approx(value):
				continue
			var ratio: float = value / STEP
			if not is_equal_approx(ratio, roundf(ratio)):
				warnings.append("%s: %s=%+.3f is not a multiple of %.2f" % [
					upgrade.id, field, value, STEP,
				])


func _validate_upgrade_stat_coverage(warnings: PackedStringArray) -> void:
	for grp: Constants.UpgradeGroup in Constants.UpgradeGroup.values():
		for stat: Constants.UpgradeStat in Constants.STAT_FIELDS:
			if Constants.STAT_TO_GROUP_DICT[stat] != grp:
				continue
			var field: String = Constants.STAT_FIELDS[stat]
			for rarity: Constants.UpgradeRarity in Constants.UpgradeRarity.values():
				var found: bool = false
				for upgrade: UpgradeData in upgrades.values():
					if upgrade.rarity == rarity and upgrade.get(field) as float > 0.0:
						found = true
						break
				if not found:
					warnings.append("Pool: no %s upgrade with positive %s in %s" % [
						Constants.UpgradeRarity.keys()[rarity],
						field,
						Constants.UpgradeGroup.keys()[grp],
					])
