class_name TaskQueue
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var drag_layer: Control = %DragLayer


func _ready() -> void:
	drag_layer.add_to_group("drag_layer")
	SB.task_spawned.connect(_on_task_spawned)
	SB.task_drop_consumed.connect(_check_empty)
	SB.sprint_ended.connect(_on_sprint_ended)


func _on_task_spawned(task_data: TaskData) -> void:
	_add_card(task_data)


func _on_sprint_ended(_sprint_number: int) -> void:
	# Penalize unfixed bugs, then clear all remaining cards
	var remaining: int = 0
	for card: TaskCard in card_container.get_children():
		remaining += 1
		if card.task_data.task_type == TaskData.TaskType.BUG:
			SB.task_expired.emit(card.task_data)
		card.queue_free()
	# Also check drag layer for cards mid-drag
	for node: Node in drag_layer.get_children():
		if node is TaskCard:
			remaining += 1
			if node.task_data.task_type == TaskData.TaskType.BUG:
				SB.task_expired.emit(node.task_data)
			node.queue_free()
	Log.log_info(name, "Sprint ended, cleared %d remaining cards" % remaining)


func _check_empty(_task_data: TaskData = null) -> void:
	# Wait a frame for queue_free to process
	await get_tree().process_frame
	if card_container.get_child_count() == 0:
		Log.log_info(name, "Queue empty, requesting more tasks")
		SB.queue_empty.emit()


func _add_card(task_data: TaskData) -> void:
	var card: TaskCard = TASK_CARD.instantiate()
	card.setup(task_data)
	card_container.add_child(card)
	Log.log_debug(name, "Card added: %s" % task_data.task_name)
