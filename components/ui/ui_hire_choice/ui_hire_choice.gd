class_name UiHireChoice
extends CanvasLayer

const HIRE_CARD: PackedScene = preload("res://components/ui/ui_hire_choice/hire_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Lifecycle ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public ---

func show_hire() -> void:
	title_label.text = "Найми разработчика"
	_build_cards()
	visible = true

# --- Private ---

func _build_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for dev_data: DeveloperData in DR.developers.values():
		var card: HireCard = HIRE_CARD.instantiate()
		card.setup(dev_data)
		card.chosen.connect(_on_dev_chosen)
		card_container.add_child(card)

func _on_dev_chosen(dev_data: DeveloperData) -> void:
	SB.developer_chosen.emit(dev_data.duplicate())
	visible = false
