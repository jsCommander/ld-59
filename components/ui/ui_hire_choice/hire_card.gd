class_name HireCard
extends Control

# --- Constants ---
const STAT_MODIFIER: PackedScene = preload("res://components/ui/ui_sprint_panel/stat_modifier.tscn")

# --- Signals ---
signal chosen(dev_data: DeveloperData)

# --- State ---
var _dev_data: DeveloperData

# --- @onready ---
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var stats_container: VBoxContainer = %Stats
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
	description_label.text = _dev_data.description
	_populate_stats()


# --- Private ---
func _populate_stats() -> void:
	var rows: Array[Array] = [
		[Constants.TaskType.FEATURE, Constants.STAT_DISPLAY_NAMES[Constants.STAT_FEATURE_DAMAGE]],
		[Constants.TaskType.REFACTORING, Constants.STAT_DISPLAY_NAMES[Constants.STAT_REFACTORING_DAMAGE]],
	]
	for row: Array in rows:
		var task_type: Constants.TaskType = row[0]
		var label: String = row[1]
		var mult: float = _dev_data.task_mults.get(task_type, 1.0)
		var bonus: float = mult - 1.0
		var stat_row: StatModifier = STAT_MODIFIER.instantiate()
		stat_row.setup(label, bonus)
		stats_container.add_child(stat_row)


# --- Handlers ---

func _on_mouse_entered() -> void:
	modulate = Color(0.75, 0.75, 0.75)


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_dev_data)
