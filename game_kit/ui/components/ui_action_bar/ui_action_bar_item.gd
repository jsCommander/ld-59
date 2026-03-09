@tool
extends Control
class_name UiActionBarItem

@export var item: UiActionBarItemResource:
	set(value):
		_item = value
		_update()
	get:
		return _item

@export var selected: bool:
	set(value):
		_selected = value
		_update()
	get:
		return _selected

signal clicked(item: UiActionBarItemResource)

@onready var texture_rect: TextureRect = %TextureRect

var _item: UiActionBarItemResource
var _selected: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(_item)

func _update():
	if !is_node_ready():
		call_deferred("_update")
		return
		
	texture_rect.texture = item.icon
	self.theme_type_variation = "PanelContainerAccentHover" if _selected else "PanelContainerAccent"

func _on_mouse_entered() -> void:
	self.theme_type_variation = "PanelContainerAccentHover"

func _on_mouse_exited() -> void:
	self.theme_type_variation = "PanelContainerAccent"
