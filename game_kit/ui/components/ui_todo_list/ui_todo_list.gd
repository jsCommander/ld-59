@tool
extends Control

const item_scene = preload("res://game_kit/ui/components/ui_todo_list/ui_todo_item.tscn")

@export var title: String = "Todo list"
@export var items: Array[UiTodoItemResource]:
	set = _set_items,
	get = _get_items

var _items: Array[UiTodoItemResource] = []

func _get_items() -> Array[UiTodoItemResource]:
	return _items
	
func _set_items(items: Array[UiTodoItemResource]):
	_items = items
	call_deferred("_update_items")

func _update_items() -> void:
	_clear_items()
	
	for item in _items:
		var item_instance = item_scene.instantiate()
		self.add_child(item_instance)
		item_instance.item = item


func _clear_items() -> void:
	var items = self.get_children()
	for item in items:
		item.queue_free()
