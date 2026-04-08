class_name UpgradeCard
extends PanelContainer

signal chosen(upgrade: UpgradeData)

var _upgrade: UpgradeData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var multiplier_label: Label = %MultiplierLabel


func setup(upgrade: UpgradeData) -> void:
	_upgrade = upgrade


func _ready() -> void:
	if not _upgrade:
		return
	if _upgrade.icon:
		icon_rect.texture = _upgrade.icon
	name_label.text = _upgrade.display_name
	description_label.text = _upgrade.description
	multiplier_label.text = "×%.1f" % _upgrade.multiplier


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_upgrade)
