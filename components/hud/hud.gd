extends CanvasLayer

@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var sprint_label: Label = %SprintLabel
@onready var sprint_timer_label: Label = %SprintTimerLabel


func _ready() -> void:
	SB.money_changed.connect(_update_money)
	SB.tech_debt_changed.connect(_update_tech_debt)
	SB.sprint_started.connect(_on_sprint_started)
	SB.sprint_tick.connect(_on_sprint_tick)
	_update_money()
	_update_tech_debt()


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt


func _on_sprint_started(sprint_number: int, _duration: float) -> void:
	sprint_label.text = "Sprint %d" % sprint_number


func _on_sprint_tick(time_remaining: float) -> void:
	var seconds: int = maxi(0, ceili(time_remaining))
	sprint_timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
