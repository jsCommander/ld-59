class_name PopupDeveloper
extends PanelContainer

var _developer: Developer

@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel
@onready var task_label: Label = %TaskLabel
@onready var upgrades_container: VBoxContainer = %UpgradesContainer


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer or not _developer.data:
		Log.log_warn(name, "Invalid developer target")
		return
	name_label.text = Constants.DevType.keys()[_developer.data.dev_type]
	_update_stats()
	_build_upgrade_buttons()


func _update_stats() -> void:
	var spd_mult: float = _developer.get_speed_multiplier()
	stats_label.text = "Фичи: %d  Баги: %d  Рефактор: %d" % [
		_developer.data.feature_speed,
		_developer.data.bug_speed,
		_developer.data.refactor_speed,
	]
	task_label.text = "Скорость: x%.1f" % spd_mult


func _build_upgrade_buttons() -> void:
	for child: Node in upgrades_container.get_children():
		child.queue_free()

	var available: Array[DeveloperUpgrade] = _developer.get_available_upgrades()
	for upgrade: DeveloperUpgrade in available:
		var btn: Button = Button.new()
		var level: int = _developer.get_upgrade_level(upgrade)
		var cost: int = upgrade.get_scaled_cost(level + 1)
		if level > 0:
			btn.text = "%s Lv.%d → %d ($%d)" % [upgrade.upgrade_name, level, level + 1, cost]
		else:
			btn.text = "%s ($%d)" % [upgrade.upgrade_name, cost]
		btn.disabled = not PD.can_afford(cost)
		btn.pressed.connect(_on_upgrade_pressed.bind(upgrade))
		upgrades_container.add_child(btn)


func _on_upgrade_pressed(upgrade: DeveloperUpgrade) -> void:
	var level: int = _developer.get_upgrade_level(upgrade)
	var cost: int = upgrade.get_scaled_cost(level + 1)
	if not PD.can_afford(cost):
		return
	PD.spend(cost)
	_developer.apply_upgrade(upgrade)
	_update_stats()
	_build_upgrade_buttons()
