class_name UiUpgradeChoice
extends CanvasLayer

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Lifecycle ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public ---

func show_for_level(level: int) -> void:
	title_label.text = "Уровень %d — выбери апгрейд" % level
	var upgrades: Array[UpgradeData] = DR.get_level_up_upgrades()
	_build_cards(upgrades)
	visible = true

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
	visible = false
	SB.upgrade_chosen.emit(upgrade)
