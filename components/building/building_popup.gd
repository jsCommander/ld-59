class_name BuildingPopup
extends PanelContainer

var _building: Building

@onready var building_name_label: Label = %BuildingNameLabel
@onready var demolish_button: Button = %DemolishButton


func setup(building: Building) -> void:
	_building = building


func _ready() -> void:
	if not _building or not _building.data:
		Log.log_warn(name, "Invalid building target")
		return
	building_name_label.text = _building.data.building_name
	demolish_button.pressed.connect(_on_demolish_pressed)


func _on_demolish_pressed() -> void:
	SB.demolish_requested.emit(_building)
