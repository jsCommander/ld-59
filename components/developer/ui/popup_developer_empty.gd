class_name PopupDeveloperEmpty
extends PanelContainer

var _developer: Developer

@onready var button_container: VBoxContainer = %ButtonContainer


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer:
		Log.log_warn(name, "No developer target")
		return
	for dev_data: DeveloperData in DR.developers.values():
		var button: Button = Button.new()
		button.text = Constants.DevType.keys()[dev_data.dev_type]
		button.pressed.connect(_on_developer_selected.bind(dev_data))
		button_container.add_child(button)


func _on_developer_selected(dev_data: DeveloperData) -> void:
	_developer.hire(dev_data)
	queue_free()
