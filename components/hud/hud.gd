extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var timer_label: Label = %TimerLabel
@onready var valuation_label: Label = %ValuationLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var sprint_label: Label = %SprintLabel
@onready var sprint_timer_bar: ProgressBar = %SprintTimerBar
@onready var company_label: Label = %CompanyLabel

const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 50, "name": "Zynga"},
	{"valuation": 200, "name": "Niantic"},
	{"valuation": 500, "name": "Ubisoft"},
	{"valuation": 1500, "name": "EA"},
	{"valuation": 5000, "name": "Valve"},
	{"valuation": 15000, "name": "Epic Games"},
	{"valuation": 50000, "name": "Apple"},
]


func _ready() -> void:
	SB.game_timer_changed.connect(_update_timer)
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_ended.connect(_on_sprint_ended)
	SB.sprint_timer_changed.connect(_on_sprint_timer_changed)
	_update_valuation()
	company_label.visible = false


func _update_timer(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_valuation() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	valuation_label.text = "$%d" % PD.valuation
	if next_xp > 0:
		xp_bar.value = float(PD.valuation) / float(next_xp)
	_update_company_comparison()


func _update_company_comparison() -> void:
	var current_company: String = ""
	for milestone: Dictionary in COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company:
		company_label.text = "Больше чем у %s!" % current_company
		company_label.visible = true
	else:
		company_label.visible = false


func _on_level_up(_level: int) -> void:
	_update_valuation()


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
