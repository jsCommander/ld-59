extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var valuation_label: Label = %ValuationLabel
@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var main_layout: VBoxContainer = %MainLayout


func _ready() -> void:
	SB.resource_money_changed.connect(_update_money)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.game_state_changed.connect(_on_game_state_changed)
	_update_money()
	_update_tech_debt()
	_update_valuation()
	_on_game_state_changed(PD.game_state)


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	valuation_label.text = "Оценка: $%d" % PD.valuation


func _on_game_state_changed(state: Constants.GameState) -> void:
	main_layout.visible = state == Constants.GameState.WORKING


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for task: TaskData in queue:
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(task)
		card_container.add_child(card)
