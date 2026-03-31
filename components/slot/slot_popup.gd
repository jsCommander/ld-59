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
	for dev_data: DeveloperData in DR.developers.values():
		var button: Button = Button.new()
		button.text = dev_data.dev_name
		button.pressed.connect(_on_developer_selected.bind(dev_data))
		button_container.add_child(button)


func _on_developer_selected(dev_data: DeveloperData) -> void:
	SB.hire_requested.emit(_slot, dev_data)
