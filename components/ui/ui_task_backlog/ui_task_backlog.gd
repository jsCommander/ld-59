class_name UiTaskBacklog
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var backlog_grid: GridContainer = %BacklogGrid
@onready var queue_grid: GridContainer = %QueueGrid
@onready var queue_label: Label = %QueueLabel
@onready var close_button: Button = %CloseButton

var selected_tasks: Array[TaskData] = []


func _ready() -> void:
	add_to_group("task_backlog")
	close_button.pressed.connect(close)
	visible = false


func open() -> void:
	selected_tasks.clear()
	visible = true
	_rebuild_grids()


func close() -> void:
	if not selected_tasks.is_empty():
		PD.add_tasks_to_queue(selected_tasks)
		selected_tasks.clear()
	visible = false


func _move_to_selected(task: TaskData) -> void:
	PD.backlog.erase(task)
	selected_tasks.append(task)
	SB.task_clicked.emit(task)
	_rebuild_grids()


func _move_to_backlog(task: TaskData) -> void:
	selected_tasks.erase(task)
	PD.backlog.append(task)
	_rebuild_grids()


func _rebuild_grids() -> void:
	_clear_grid(backlog_grid)
	_clear_grid(queue_grid)

	for task: TaskData in PD.backlog:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_backlog_card_input.bind(task))
		backlog_grid.add_child(card)

	for i: int in range(PD.backlog.size(), Constants.BACKLOG_SIZE):
		backlog_grid.add_child(_make_empty_slot())

	for task: TaskData in selected_tasks:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_selected_card_input.bind(task))
		queue_grid.add_child(card)

	queue_label.text = "Очередь (%d)" % selected_tasks.size()


func _on_backlog_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_to_selected(task)


func _on_selected_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_to_backlog(task)


func _make_card(task: TaskData) -> TaskCard:
	var card: TaskCard = TASK_CARD.instantiate()
	card.setup(task)
	card.draggable = false
	return card


func _make_empty_slot() -> PanelContainer:
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.modulate = Color(1, 1, 1, 0.3)
	return slot


func _clear_grid(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		child.queue_free()
