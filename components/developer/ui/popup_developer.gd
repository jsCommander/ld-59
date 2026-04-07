class_name PopupDeveloper
extends PanelContainer

var _developer: Developer

@onready var name_label: Label = %NameLabel
@onready var feature_bar: ProgressBar = %FeatureBar
@onready var bug_bar: ProgressBar = %BugBar
@onready var refactor_bar: ProgressBar = %RefactorBar
@onready var speed_bar: ProgressBar = %SpeedBar


func setup(developer: Developer) -> void:
	_developer = developer


func _ready() -> void:
	if not _developer or not _developer.data:
		Log.log_warn(name, "Invalid developer target")
		return
	name_label.text = Constants.DevType.keys()[_developer.data.dev_type]
	_update_bars()


func _update_bars() -> void:
	feature_bar.value = _developer.data.feature_damage
	bug_bar.value = _developer.data.bug_damage
	refactor_bar.value = _developer.data.refactor_damage
	speed_bar.value = 100.0 / _developer.data.base_attack_speed
