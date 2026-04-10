class_name UiHireChoice
extends CanvasLayer

const HIRE_CARD: PackedScene = preload("res://components/ui/ui_hire_choice/hire_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	add_to_group("hire_choice")
	SB.developer_hire_requested.connect(_on_hire_requested)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_hire_requested() -> void:
	title_label.text = "Найми разработчика"
	_build_cards()
	visible = true


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
