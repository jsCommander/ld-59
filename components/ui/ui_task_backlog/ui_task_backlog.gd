class_name UiTaskBacklog
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var backlog_grid: GridContainer = %BacklogGrid
@onready var queue_grid: GridContainer = %QueueGrid
@onready var queue_label: Label = %QueueLabel
@onready var close_button: Button = %CloseButton
@onready var refresh_bar: ProgressBar = %RefreshBar


func _ready() -> void:
	add_to_group("task_backlog")
	close_button.pressed.connect(close)
	SB.backlog_refreshed.connect(_on_backlog_refreshed)
	visible = false


func _process(_delta: float) -> void:
	if is_instance_valid(refresh_bar):
		refresh_bar.value = PD.get_backlog_refresh_progress()


func _on_backlog_refreshed() -> void:
	if visible:
		_rebuild_grids()


func open() -> void:
	visible = true
	_rebuild_grids()


func close() -> void:
	visible = false


func _add_to_queue(task: TaskData) -> void:
	PD.backlog.erase(task)
	task.current_hp = task.base_hp
	task.max_hp = task.base_hp
	PD.task_queue.append(task)
	SB.task_clicked.emit(task)
	SB.task_queue_changed.emit(PD.task_queue)
	_rebuild_grids()


func _remove_from_queue(task: TaskData) -> void:
	PD.task_queue.erase(task)
	PD.backlog.append(task)
	SB.task_queue_changed.emit(PD.task_queue)
	_rebuild_grids()


func _rebuild_grids() -> void:
	_clear_grid(backlog_grid)
	_clear_grid(queue_grid)

	for task: TaskData in PD.task_queue:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_queue_card_input.bind(task))
		queue_grid.add_child(card)

	queue_label.text = "Очередь (%d)" % PD.task_queue.size()

	for task: TaskData in PD.backlog:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_backlog_card_input.bind(task))
		backlog_grid.add_child(card)

	for i: int in range(PD.backlog.size(), Constants.BACKLOG_SIZE):
		backlog_grid.add_child(_make_empty_slot())


func _on_backlog_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_add_to_queue(task)


func _on_queue_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_remove_from_queue(task)


func _make_card(task: TaskData) -> TaskCard:
	var card: TaskCard = TASK_CARD.instantiate()
	card.setup(task)
	card.draggable = false
	return card


func _make_empty_slot() -> PanelContainer:
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(120, 120)
	slot.modulate = Color(1, 1, 1, 0.3)
	return slot


func _clear_grid(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		child.queue_free()
