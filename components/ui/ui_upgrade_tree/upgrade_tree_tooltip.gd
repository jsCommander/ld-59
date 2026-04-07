class_name UpgradeTreeTooltip extends PanelContainer

signal buy_pressed(upgrade: UpgradeTree)

@onready var name_label: Label = %TooltipName
@onready var description_label: Label = %TooltipDescription
@onready var buy_button: Button = %BuyButton

var _current_upgrade: UpgradeTree


func show_upgrade(upgrade: UpgradeTree) -> void:
	_current_upgrade = upgrade
	name_label.text = upgrade.display_name
	description_label.text = upgrade.description
	buy_button.text = "Купить ($%d)" % upgrade.cost
	buy_button.disabled = not PD.can_afford(upgrade.cost)
	show()


func hide_tooltip() -> void:
	hide()
	_current_upgrade = null


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	visible = false


func _on_buy_pressed() -> void:
	if _current_upgrade:
		buy_pressed.emit(_current_upgrade)
		hide_tooltip()
