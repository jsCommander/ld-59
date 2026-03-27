class_name TaskQueue
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var card_container: HBoxContainer = %CardContainer
@onready var drag_layer: Control = %DragLayer


func _ready() -> void:
	drag_layer.add_to_group("drag_layer")
	SB.task_spawned.connect(_on_task_spawned)
	SB.bug_generated.connect(_on_bug_generated)


func _on_task_spawned(task_data: TaskData) -> void:
	_add_card(task_data)


func _on_bug_generated(task_data: TaskData) -> void:
	_add_card(task_data)


func _add_card(task_data: TaskData) -> void:
	var card: TaskCard = TASK_CARD.instantiate()
	card.setup(task_data)
	card_container.add_child(card)
	Log.log_debug(name, "Card added: %s" % task_data.task_name)
