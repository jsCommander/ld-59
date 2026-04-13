class_name UiSprintPanel
extends HBoxContainer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer

# --- Lifecycle ---

func _ready() -> void:
	SB.task_queue_changed.connect(_rebuild_cards)

# --- Private ---

func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
