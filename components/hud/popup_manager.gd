class_name PopupManager
extends UiPopupManager

const BUILDING_POPUP: PackedScene = preload("res://components/building/building_popup.tscn")
const SLOT_POPUP: PackedScene = preload("res://components/slot/slot_popup.tscn")

var _current_target: Node2D


func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.build_requested.connect(func(_s: Slot, _b: BuildingData) -> void: close_popup())
	SB.demolish_requested.connect(func(_b: Building) -> void: close_popup())


func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	close_popup()
	_current_target = target
	if target is Slot:
		var popup: SlotPopup = SLOT_POPUP.instantiate()
		popup.setup(target as Slot)
		show_popup(popup, popup_position)
	elif target is Building:
		var popup: BuildingPopup = BUILDING_POPUP.instantiate()
		popup.setup(target as Building)
		show_popup(popup, popup_position)


func close_popup() -> void:
	_current_target = null
	super.close_popup()
	SB.selection_cleared.emit()
