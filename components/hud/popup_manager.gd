class_name PopupManager
extends UiPopupManager

const BUILDING_POPUP: PackedScene = preload("res://components/building/building_popup.tscn")

var _current_target: Node2D


func _ready() -> void:
	SB.building_selected.connect(_on_building_selected)


func _on_building_selected(target: Node2D, popup_position: Vector2) -> void:
	close_popup()
	_current_target = target
	var popup: BuildingPopup = BUILDING_POPUP.instantiate()
	popup.setup(target as Building)
	show_popup(popup, popup_position)


func close_popup() -> void:
	_current_target = null
	super.close_popup()
	SB.selection_cleared.emit()
