class_name UiGameOver
extends CanvasLayer

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	add_to_group("game_over")
	SB.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_game_over(final_valuation: int) -> void:
	valuation_label.text = "Стоимость компании: $%d" % final_valuation
	level_label.text = "Уровень: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	visible = true


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
