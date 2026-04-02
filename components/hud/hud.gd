extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")
const TASK_DATA_FEATURE: TaskData = preload("res://game_data/task/task_data_feature.tres")
const TASK_DATA_REFACTOR: TaskData = preload("res://game_data/task/task_data_refactor.tres")

@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var queue_label: Label = %QueueLabel
@onready var card_container: HBoxContainer = %CardContainer
@onready var drag_layer: Control = %DragLayer
@onready var start_sprint_button: Button = %StartSprintButton


func _ready() -> void:
	SB.resource_money_changed.connect(_update_money)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)
	SB.task_queue_changed.connect(_rebuild_cards)
	start_sprint_button.pressed.connect(_on_start_sprint_pressed)
	drag_layer.add_to_group("drag_layer")
	_update_money()
	_update_tech_debt()
	PD.task_queue.append(TASK_DATA_FEATURE.duplicate())
	PD.task_queue.append(TASK_DATA_REFACTOR.duplicate())
	_rebuild_cards(PD.task_queue)
	_update_queue_label()


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_queue_label() -> void:
	queue_label.text = "Sprint %d" % PD.sprint_number


func _on_start_sprint_pressed() -> void:
	SB.sprint_execute_requested.emit()


func _on_sprint_started() -> void:
	_update_queue_label()
	start_sprint_button.visible = false


func _on_sprint_ended() -> void:
	start_sprint_button.visible = true
	_expire_bugs()


func _expire_bugs() -> void:
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
