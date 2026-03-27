extends CanvasLayer

@onready var money_label: Label = %MoneyLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar


func _ready() -> void:
	SB.money_changed.connect(_update_money)
	SB.tech_debt_changed.connect(_update_tech_debt)
	_update_money()
	_update_tech_debt()


func _update_money() -> void:
	money_label.text = "$%d" % PD.money


func _update_tech_debt() -> void:
	tech_debt_bar.value = PD.tech_debt
