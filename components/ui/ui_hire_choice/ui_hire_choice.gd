class_name UiHireChoice
extends BaseDialog

const HIRE_CARD: PackedScene = preload("res://components/ui/ui_hire_choice/hire_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel

# --- Public ---

func set_data(_data: Dictionary) -> void:
	title_label.text = "Hire a Developer"
	_build_cards()

# --- Private ---

func _build_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for dev_data: DeveloperData in DR.developers.values():
		var card: Control = HIRE_CARD.instantiate()
		card.setup(dev_data)
		card.chosen.connect(_on_dev_chosen)
		card_container.add_child(card)

func _on_dev_chosen(dev_data: DeveloperData) -> void:
	close_dialog({"dev_data": dev_data.duplicate()})
