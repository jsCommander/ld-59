class_name PopupManager
extends UiPopupManager

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")


func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)


func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Developer:
		var dev: Developer = target as Developer
		if dev.data == null:
			return
		var popup: PopupDeveloper = POPUP_DEVELOPER.instantiate()
		popup.setup(dev)
		show_popup(target, popup, popup_position)


func _after_popup_closed() -> void:
	SB.selection_cleared.emit()
