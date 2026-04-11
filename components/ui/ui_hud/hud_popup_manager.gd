class_name HudPopupManager
extends UiPopupManager


func _after_popup_closed() -> void:
	SB.selection_cleared.emit()
