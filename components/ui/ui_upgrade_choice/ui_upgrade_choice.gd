class_name UiUpgradeChoice
extends BaseDialog

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Public ---

func set_data(data: Dictionary) -> void:
	var level: int = data.get("level", 1)
	title_label.text = "Level %d — Pick an Upgrade" % level
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.chosen.connect(_on_upgrade_chosen)
		card_container.add_child(card)

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	close_dialog({"upgrade": upgrade})
