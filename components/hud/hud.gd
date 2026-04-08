extends CanvasLayer

const TASK_CARD: PackedScene = preload("res://components/task_queue/task_card.tscn")

@onready var timer_label: Label = %TimerLabel
@onready var valuation_label: Label = %ValuationLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var card_container: HBoxContainer = %CardContainer
@onready var main_layout: VBoxContainer = %MainLayout
@onready var backlog_button: Button = %BacklogButton
@onready var click_progress_bar: ProgressBar = %ClickProgressBar
@onready var auto_click_bar: ProgressBar = %AutoClickBar


func _ready() -> void:
	SB.game_timer_changed.connect(_update_timer)
	SB.resource_tech_debt_changed.connect(_update_tech_debt)
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	SB.task_queue_changed.connect(_rebuild_cards)
	SB.backlog_clicked.connect(_update_click_progress)
	SB.backlog_task_spawned.connect(_on_task_spawned)
	backlog_button.pressed.connect(_on_backlog_pressed)
	_update_tech_debt()
	_update_valuation()
	_update_click_label()
	main_layout.visible = true


func _process(_delta: float) -> void:
	if not PD.auto_click_unlocked or not PD._auto_click_timer:
		return
	if not auto_click_bar.visible:
		auto_click_bar.visible = true
	auto_click_bar.value = 1.0 - (PD._auto_click_timer.time_left / PD._auto_click_timer.wait_time)


func _on_backlog_pressed() -> void:
	SB.backlog_clicked.emit(1)
	_tween_button()


func _tween_button() -> void:
	backlog_button.pivot_offset = backlog_button.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(backlog_button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(backlog_button, "scale", Vector2(1.0, 1.0), 0.05)


func _update_click_progress(_count: int) -> void:
	var needed: int = PD._get_clicks_needed()
	click_progress_bar.value = float(PD._click_progress) / float(needed)
	_update_click_label()


func _on_task_spawned() -> void:
	click_progress_bar.value = 0.0
	_update_click_label()


func _update_click_label() -> void:
	var needed: int = PD._get_clicks_needed()
	backlog_button.text = "Бэклог (%d/%d)" % [PD._click_progress, needed]


func _update_timer(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _update_valuation() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	valuation_label.text = "Lv.%d  $%d / $%d" % [PD.level, PD.valuation, next_xp]


func _on_level_up(_level: int) -> void:
	_update_valuation()
	_update_click_label()


func _rebuild_cards(queue: Array[TaskData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for i: int in queue.size():
		var card: TaskCard = TASK_CARD.instantiate()
		card.setup(queue[i])
		card_container.add_child(card)
