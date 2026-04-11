class_name HireCard
extends PanelContainer

signal chosen(dev_data: DeveloperData)

var _dev_data: DeveloperData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel


func setup(dev_data: DeveloperData) -> void:
	_dev_data = dev_data


func _ready() -> void:
	if not _dev_data:
		return
	if _dev_data.head_texture:
		icon_rect.texture = _dev_data.head_texture
	name_label.text = Constants.DevType.keys()[_dev_data.dev_type]
	stats_label.text = "Фичи: %.1f\nБаги: %.1f\nРефактор: %.1f\nСкорость: %.1f" % [
		_dev_data.task_mults.get(Constants.TaskType.FEATURE, 1.0),
		_dev_data.task_mults.get(Constants.TaskType.BUG, 1.0),
		_dev_data.task_mults.get(Constants.TaskType.REFACTOR, 1.0),
		_dev_data.base_attack_speed,
	]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_dev_data)
