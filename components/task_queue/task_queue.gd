class_name TaskQueue
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")
const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

@onready var card_container: HBoxContainer = %CardContainer
@onready var drag_layer: Control = %DragLayer


func _ready() -> void:
	drag_layer.add_to_group("drag_layer")
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.sprint_ended.connect(_on_sprint_ended)
	PD.task_queue.append(TASK_DATA_FEATURE.duplicate())
	PD.task_queue.append(TASK_DATA_REFACTOR.duplicate())
	_rebuild_cards(PD.task_queue)


func _on_sprint_ended() -> void:
	var expired_bugs: Array[TaskData] = []
	for task: TaskData in PD.task_queue:
		if task.task_type == Constants.TaskType.BUG:
			expired_bugs.append(task)
	for bug: TaskData in expired_bugs:
		PD.expire_task(bug)
	Log.log_info(name, "Sprint ended, expired %d bugs" % expired_bugs.size())


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for task: TaskData in queue:
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(task)
		card_container.add_child(card)
