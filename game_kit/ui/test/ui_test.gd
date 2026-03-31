extends Node2D

@onready var last_action: Label = %LastAction


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_ui_action_bar_item_clicked(item: UiActionBarItemResource) -> void:
	last_action.text = "Last item clicked: %s" % item.id
