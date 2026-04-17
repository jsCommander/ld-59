class_name HireCard
extends Control

signal chosen(dev_data: DeveloperData)

var _dev_data: DeveloperData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var feature_bar: ProgressBar = %FeatureBar
@onready var bug_bar: ProgressBar = %BugBar
@onready var description_label: Label = %DescriptionLabel


func setup(dev_data: DeveloperData) -> void:
	_dev_data = dev_data


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not _dev_data:
		return
	if _dev_data.head_texture:
		icon_rect.texture = _dev_data.head_texture
	name_label.text = Constants.DEV_TYPE_DISPLAY_NAMES[_dev_data.dev_type]
	feature_bar.value = _dev_data.task_mults.get(Constants.TaskType.FEATURE, 1.0) / Constants.MAX_DEV_STAT_MULTIPLIER
	bug_bar.value = _dev_data.task_mults.get(Constants.TaskType.BUG, 1.0) / Constants.MAX_DEV_STAT_MULTIPLIER
	description_label.text = _dev_data.description


# --- Handlers ---

func _on_mouse_entered() -> void:
	modulate = Color(0.75, 0.75, 0.75)


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_dev_data)
