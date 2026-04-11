class_name UiSprintPanel
extends VBoxContainer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

# --- @onready ---

@onready var sprint_label: Label = %SprintLabel
@onready var sprint_timer_bar: ProgressBar = %SprintTimerBar
@onready var card_container: HBoxContainer = %CardContainer

# --- Lifecycle ---

func _ready() -> void:
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)
	SB.sprint_timer_changed.connect(_on_sprint_timer_changed)
	SB.task_queue_changed.connect(_rebuild_cards)

# --- Handlers ---

func _on_sprint_started(sprint_num: int) -> void:
	sprint_label.text = "Спринт %d" % sprint_num
	sprint_timer_bar.modulate = Color.GREEN

func _on_sprint_ended(sprint_num: int, bonus: int) -> void:
	if bonus > 0:
		sprint_label.text = "Спринт %d завершён! Бонус: $%d" % [sprint_num, bonus]
	else:
		sprint_label.text = "Спринт %d просрочен" % sprint_num

func _on_sprint_timer_changed(remaining: float, total: float) -> void:
	if total <= 0.0:
		return
	var ratio: float = clampf(remaining / total, 0.0, 1.0)
	sprint_timer_bar.value = ratio
	if ratio > 0.5:
		sprint_timer_bar.modulate = Color.GREEN.lerp(Color.YELLOW, 1.0 - (ratio - 0.5) * 2.0)
	else:
		sprint_timer_bar.modulate = Color.YELLOW.lerp(Color.RED, 1.0 - ratio * 2.0)

func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
