class_name UiSprintPanel
extends Control

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer

# --- State ---

var _cards: Array[TaskCard] = []
var _card_positions: Dictionary = {}

# --- Lifecycle ---

func _ready() -> void:
	for child: Node in card_container.get_children():
		if child is TaskCard:
			_cards.append(child as TaskCard)
	SB.task_queue_changed.connect(_update_slots)

# --- Public ---

func get_card_position(task: TaskData) -> Vector2:
	if task in _card_positions:
		return _card_positions[task]
	return card_container.global_position + card_container.size * 0.5

# --- Private ---

func _update_slots(slots: Array) -> void:
	_save_card_positions()
	for i: int in _cards.size():
		if i < slots.size():
			_cards[i].setup(slots[i])
		else:
			_cards[i].setup(null)


func _save_card_positions() -> void:
	_card_positions.clear()
	for card: TaskCard in _cards:
		if card.task_data:
			_card_positions[card.task_data] = card.global_position + card.size * 0.5
