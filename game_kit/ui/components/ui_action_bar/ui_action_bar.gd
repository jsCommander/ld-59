@tool
extends Control
class_name UiActionBar

const item_scene = preload("res://game_kit/ui/components/ui_action_bar/ui_action_bar_item.tscn")

@export var items: Array[UiActionBarItemResource]:
	set(value):
		_items = value
		_update()
	get:
		return _items
		
@export var selected_item: String

signal item_clicked(item: UiActionBarItemResource)

@onready var h_box_container: HBoxContainer = %HBoxContainer

var _items: Array[UiActionBarItemResource] = []

func _update():
	if !is_node_ready():
		call_deferred("_update")
		return
	
	var childs:=get_items_nodes()
	
	for child in childs:
		child.queue_free()
		
	for item in _items:
		var scene = item_scene.instantiate()
		scene.item = item
		scene.clicked.connect(_handle_item_clicked)
		h_box_container.add_child(scene)
		
func _handle_item_clicked(item: UiActionBarItemResource):
	Log.log_debug(self.name, "item %s was clicked" % item.id)
	selected_item = item.id
	
	var childs:= get_items_nodes()
	
	for child in childs:
		child.selected = true if item.id == child.item.id else false
	
	item_clicked.emit(item)
	
func get_items_nodes() -> Array[UiActionBarItem]:
	var items: Array[UiActionBarItem] = []
	for child in h_box_container.get_children():
		if child is UiActionBarItem:
			items.append(child)
			
	return items
