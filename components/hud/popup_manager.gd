class_name PopupManager
extends UiPopupManager

const DEVELOPER_POPUP: PackedScene = preload("res://components/developer/developer_popup.tscn")
const SLOT_POPUP: PackedScene = preload("res://components/slot/slot_popup.tscn")


func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.hire_requested.connect(func(_s: Slot, _d: DeveloperData) -> void: close_popup())
	SB.fire_requested.connect(func(_d: Developer) -> void: close_popup())


func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Slot:
		var popup: SlotPopup = SLOT_POPUP.instantiate()
		popup.setup(target as Slot)
		show_popup(target, popup, popup_position)
	elif target is Developer:
		var popup: DeveloperPopup = DEVELOPER_POPUP.instantiate()
		popup.setup(target as Developer)
		show_popup(target, popup, popup_position)


func _after_popup_closed() -> void:
	SB.selection_cleared.emit()
