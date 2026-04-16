class_name UiGameInfo
extends MarginContainer

# --- @onready ---

@onready var timer_label: Label = %TimerLabel
@onready var level_label: Label = %LevelLabel
@onready var sprint_label: Label = %SprintLabel

# --- Lifecycle ---

func _ready() -> void:
	SB.level_up.connect(_on_level_up)
	SB.sprint_number_changed.connect(_on_sprint_number_changed)
	SB.game_timer_changed.connect(_on_game_timer_changed)
	level_label.text = "Level %d" % PD.level
	sprint_label.text = "Sprint %d" % PD.sprint_number

# --- Handlers ---

func _on_level_up(level: int) -> void:
	level_label.text = "Level %d" % level

func _on_sprint_number_changed(sprint_number: int) -> void:
	sprint_label.text = "Sprint %d" % sprint_number

func _on_game_timer_changed(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
