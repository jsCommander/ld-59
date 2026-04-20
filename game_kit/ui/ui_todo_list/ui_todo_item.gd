@tool
extends HBoxContainer

@export var item: UiTodoItemResource

@onready var label: RichTextLabel = %Label

func _process(delta: float) -> void:
	if !item or !label:
		return
		
	var format = "- %s" if !item.is_done else "- [s]%s[/s]"
	label.text = format % item.text
