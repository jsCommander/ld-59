@tool
extends BaseDialog

@onready var label: Label = %Label
@onready var button: Button = %Button

func set_data(data) -> void:
	label.text = data.text
	button.text = data.button_text

func _on_button_pressed() -> void:
	finished.emit("ok")
