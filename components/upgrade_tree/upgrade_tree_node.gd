class_name UpgradeTreeNode extends PanelContainer

signal node_clicked(upgrade: UpgradeTree)

var upgrade: UpgradeTree

@onready var name_label: Label = %NameLabel
@onready var button: Button = %Button


func setup(u: UpgradeTree) -> void:
	upgrade = u


func _ready() -> void:
	if not upgrade:
		return
	name_label.text = upgrade.display_name
	button.pressed.connect(_on_pressed)
	update_state()


func update_state() -> void:
	if PD.is_upgrade_unlocked(upgrade):
		modulate = Color(0.3, 1.0, 0.3)
		button.disabled = true
		button.text = "Unlocked"
	elif PD.can_unlock_upgrade(upgrade):
		modulate = Color(1.0, 1.0, 1.0)
		button.disabled = false
		button.text = "Unlock"
	else:
		modulate = Color(0.4, 0.4, 0.4)
		button.disabled = true
		button.text = "Locked"


func _on_pressed() -> void:
	node_clicked.emit(upgrade)
