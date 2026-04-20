@tool
extends PanelContainer
class_name UiSelectUpgradeDialogItem

@export var item: UiSelectUpgradeDialogItemResource:
	set(value):
		_item = value
		_update()
	get:
		return _item

@export var button_text: String:
	set(value):
		_button_text = value
		_update()
	get:
		return _button_text

signal clicked

@onready var label: Label = %Label
@onready var button: Button = %Button
@onready var texture_rect: TextureRect = %TextureRect

var _item: UiSelectUpgradeDialogItemResource
var _button_text: String = "Pick"

func _update() -> void:
	if not is_node_ready():
		call_deferred("_update")
		return

	if _item:
		label.text = _item.text
		texture_rect.texture = _item.icon
		
	button.text = _button_text

func _on_button_pressed() -> void:
	clicked.emit()
