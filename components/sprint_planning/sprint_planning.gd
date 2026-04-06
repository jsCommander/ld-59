class_name SprintPlanning
extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var backlog_grid: GridContainer = %BacklogGrid
@onready var sprint_grid: GridContainer = %SprintGrid
@onready var sprint_label: Label = %SprintLabel
@onready var start_button: Button = %StartButton

var sprint_tasks: Array[TaskData] = []


func _ready() -> void:
	SB.game_state_changed.connect(_on_game_state_changed)
	start_button.pressed.connect(_on_start_pressed)
	_on_game_state_changed(PD.game_state)


func _on_game_state_changed(state: Constants.GameState) -> void:
	if state == Constants.GameState.PLANNING:
		_open()
	else:
		_close()


func _open() -> void:
	visible = true
	sprint_tasks.clear()
	_rebuild_grids()


func _close() -> void:
	visible = false


func _on_start_pressed() -> void:
	if sprint_tasks.is_empty():
		return
	PD.start_sprint(sprint_tasks)


func _move_to_sprint(task: TaskData) -> void:
	if sprint_tasks.size() >= Constants.SPRINT_SIZE:
		return
	PD.backlog.erase(task)
	sprint_tasks.append(task)
	SB.task_clicked.emit(task)
	_rebuild_grids()


func _move_to_backlog(task: TaskData) -> void:
	sprint_tasks.erase(task)
	PD.backlog.append(task)
	_rebuild_grids()


func _rebuild_grids() -> void:
	_clear_grid(backlog_grid)
	_clear_grid(sprint_grid)

	for task: TaskData in PD.backlog:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_backlog_card_input.bind(task))
		backlog_grid.add_child(card)

	for i: int in range(PD.backlog.size(), Constants.BACKLOG_SIZE):
		backlog_grid.add_child(_make_empty_slot())

	for task: TaskData in sprint_tasks:
		var card: TaskCard = _make_card(task)
		card.gui_input.connect(_on_sprint_card_input.bind(task))
		sprint_grid.add_child(card)

	for i: int in range(sprint_tasks.size(), Constants.SPRINT_SIZE):
		sprint_grid.add_child(_make_empty_slot())

	sprint_label.text = "Спринт (%d/%d)" % [sprint_tasks.size(), Constants.SPRINT_SIZE]
	start_button.disabled = sprint_tasks.is_empty()


func _on_backlog_card_input(event: InputEvent, task: TaskData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_to_sprint(task)


func _on_sprint_card_input(event: InputEvent, task: TaskData) -> void:
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
