class_name UiUpgradeChoice
extends BaseDialog

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")
const STAT_SUMMARY_ITEM: PackedScene = preload("res://components/ui/ui_upgrade_choice/stat_summary_item.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel
@onready var stats_grid: GridContainer = %StatsGrid

# --- Public ---

func set_data(data: Dictionary) -> void:
	var level: int = data.get("level", 1)
	title_label.text = "Level %d — Pick an Upgrade" % level
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_build_stats_summary()

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.chosen.connect(_on_upgrade_chosen)
		card_container.add_child(card)

func _build_stats_summary() -> void:
	for child: Node in stats_grid.get_children():
		child.queue_free()
	for field: String in Constants.STAT_DISPLAY_NAMES:
		var value: float = PD.total_stats.get(field, 0.0)
		var item: StatSummaryItem = STAT_SUMMARY_ITEM.instantiate()
		item.setup(Constants.STAT_DISPLAY_NAMES[field], value)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_grid.add_child(item)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	close_dialog({"upgrade": upgrade})
