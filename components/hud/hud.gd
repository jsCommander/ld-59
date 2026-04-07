extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var valuation_label: Label = %ValuationLabel
@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var main_layout: VBoxContainer = %MainLayout
@onready var backlog_button: Button = %BacklogButton


func _ready() -> void:
	SB.resource_money_changed.connect(_update_money)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.task_hp_changed.connect(_on_task_hp_changed)
	backlog_button.pressed.connect(_on_backlog_pressed)
	_update_money()
	_update_tech_debt()
	_update_valuation()
	main_layout.visible = true


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	valuation_label.text = "Оценка: $%d" % PD.valuation


func _on_backlog_pressed() -> void:
	var backlog: UiTaskBacklog = get_tree().get_first_node_in_group("task_backlog")
	if backlog:
		if backlog.visible:
			backlog.close()
		else:
			backlog.open()


func _on_task_hp_changed(task: TaskData, hp: float, max_hp: float) -> void:
	if card_container.get_child_count() == 0:
		return
	var first_card: TaskCard = card_container.get_child(0) as TaskCard
	if not first_card:
		return
	first_card.update_hp(hp, max_hp)
	_shake_card(first_card)


func _shake_card(card: Control) -> void:
	var tween: Tween = create_tween()
	var original_x: float = card.position.x
	tween.tween_property(card, "position:x", original_x + 5.0, 0.04)
	tween.tween_property(card, "position:x", original_x - 5.0, 0.04)
	tween.tween_property(card, "position:x", original_x, 0.07)


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		if i == 0:
			card.show_hp = true
		card_container.add_child(card)
