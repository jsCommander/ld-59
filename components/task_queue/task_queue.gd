class_name TaskQueue
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var drag_layer: Control = %DragLayer


func _ready() -> void:
	drag_layer.add_to_group("drag_layer")
	SB.task_queue_changed.connect(_rebuild_cards)


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for task: TaskData in queue:
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(task)
		card_container.add_child(card)
