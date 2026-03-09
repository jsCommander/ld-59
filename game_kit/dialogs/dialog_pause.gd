extends BaseDialog

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close_dialog({"resume": true})

func _on_resume_button_button_down() -> void:
	close_dialog({"resume": true})

func _on_exit_button_button_down() -> void:
	close_dialog({"exit": true})
