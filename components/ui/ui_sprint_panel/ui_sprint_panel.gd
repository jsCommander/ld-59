class_name UiSprintPanel
extends Control

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer

# --- State ---

var _card_positions: Dictionary = {}

# --- Lifecycle ---

func _ready() -> void:
	SB.task_queue_changed.connect(_rebuild_cards)

# --- Public ---

func get_card_position(task: TaskData) -> Vector2:
	if task in _card_positions:
		return _card_positions[task]
	return card_container.global_position + card_container.size * 0.5

# --- Private ---

func _rebuild_cards(queue: Array[TaskData]) -> void:
	_save_card_positions()
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)


func _save_card_positions() -> void:
	_card_positions.clear()
	for child: Node in card_container.get_children():
		if child is TaskCard:
			var card: TaskCard = child as TaskCard
			_card_positions[card.task_data] = card.global_position + card.size * 0.5
