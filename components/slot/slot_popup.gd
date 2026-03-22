class_name SlotPopup
extends PanelContainer

var _slot: Slot

@onready var button_container: VBoxContainer = %ButtonContainer


func setup(slot: Slot) -> void:
	_slot = slot


func _ready() -> void:
	if not _slot:
		Log.log_warn(name, "No slot target")
		return
	for building_data: BuildingData in DR.buildings.values():
		var button: Button = Button.new()
		button.text = building_data.building_name
		if building_data.icon:
			button.icon = building_data.icon
		button.pressed.connect(_on_building_selected.bind(building_data))
		button_container.add_child(button)


func _on_building_selected(building_data: BuildingData) -> void:
	SB.build_requested.emit(_slot, building_data)
