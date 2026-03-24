class_name BuildingPopup
extends PanelContainer

var _building: Building

@onready var building_name_label: Label = %BuildingNameLabel
@onready var stats_label: Label = %StatsLabel
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var demolish_button: Button = %DemolishButton


func setup(building: Building) -> void:
	_building = building


func _ready() -> void:
	if not _building or not _building.data:
		Log.log_warn(name, "Invalid building target")
		return
	building_name_label.text = _building.data.building_name
	demolish_button.pressed.connect(_on_demolish_pressed)
	_update_stats()
	_show_upgrades()
	PD.data_changed.connect(_update_upgrade_buttons)


func _show_upgrades() -> void:
	var available: Array[BuildingUpgrade] = _building.get_available_upgrades()
	for upgrade: BuildingUpgrade in available:
		var btn: Button = Button.new()
		btn.set_meta("upgrade", upgrade)
		btn.pressed.connect(_on_upgrade_pressed.bind(upgrade))
		upgrades_container.add_child(btn)
	_update_upgrade_buttons()


func _update_upgrade_buttons() -> void:
	for btn: Node in upgrades_container.get_children():
		var upgrade: BuildingUpgrade = btn.get_meta("upgrade")
		var level: int = _building.get_upgrade_level(upgrade)
		var next_level: int = level + 1
		var scaled_cost: Array[RecipeIngredient] = upgrade.get_scaled_cost(next_level)
		var cost_dict: Dictionary = _cost_to_dict(scaled_cost)
		var cost_text: String = _format_cost(scaled_cost)
		if level > 0:
			btn.text = "%s Lv.%d (%s)" % [upgrade.upgrade_name, next_level, cost_text]
		else:
			btn.text = "%s (%s)" % [upgrade.upgrade_name, cost_text]
		btn.disabled = not PD.can_afford(cost_dict)


func _update_stats() -> void:
	if not _building.data.recipe:
		stats_label.visible = false
		return
	var time: float = _building.produce_trait.produce_time
	var count: int = _building.produce_trait.produce_count
	stats_label.text = "x%d / %.1fs" % [count, time]


func _on_upgrade_pressed(upgrade: BuildingUpgrade) -> void:
	var level: int = _building.get_upgrade_level(upgrade)
	var scaled_cost: Array[RecipeIngredient] = upgrade.get_scaled_cost(level + 1)
	var cost_dict: Dictionary = _cost_to_dict(scaled_cost)
	if not PD.can_afford(cost_dict):
		return
	PD.spend(cost_dict)
	_building.apply_upgrade(upgrade)
	_update_stats()
	_update_upgrade_buttons()
	_hide_maxed_upgrades()


func _hide_maxed_upgrades() -> void:
	for btn: Node in upgrades_container.get_children():
		var u: BuildingUpgrade = btn.get_meta("upgrade")
		btn.visible = u.max_level == 0 or _building.get_upgrade_level(u) < u.max_level


func _on_demolish_pressed() -> void:
	SB.demolish_requested.emit(_building)


func _cost_to_dict(cost: Array[RecipeIngredient]) -> Dictionary:
	var dict: Dictionary = {}
	for ingredient: RecipeIngredient in cost:
		dict[ingredient.product.id] = ingredient.count
	return dict


func _format_cost(cost: Array[RecipeIngredient]) -> String:
	var parts: Array[String] = []
	for ingredient: RecipeIngredient in cost:
		parts.append("%d %s" % [ingredient.count, ingredient.product.product_name])
	return ", ".join(parts)
