class_name UiGameOver
extends CanvasLayer

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var company_label: Label = %CompanyLabel
@onready var restart_button: Button = %RestartButton

const COMPANY_MILESTONES: Array[Dictionary] = [
	{"valuation": 50, "name": "Zynga"},
	{"valuation": 200, "name": "Niantic"},
	{"valuation": 500, "name": "Ubisoft"},
	{"valuation": 1500, "name": "EA"},
	{"valuation": 5000, "name": "Valve"},
	{"valuation": 15000, "name": "Epic Games"},
	{"valuation": 50000, "name": "Apple"},
]


func _ready() -> void:
	add_to_group("game_over")
	SB.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_game_over(final_valuation: int) -> void:
	valuation_label.text = "$%d" % final_valuation
	level_label.text = "Уровень: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	_show_company_comparison(final_valuation)
	visible = true


func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in COMPANY_MILESTONES:
		if val >= milestone["valuation"]:
			best_company = milestone["name"]
	if best_company:
		company_label.text = "Your startup beat %s! 🚀" % best_company
		company_label.visible = true
	else:
		company_label.text = "Keep grinding..."
		company_label.visible = true


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
