class_name UiGameOver
extends BaseDialog

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var level_label: Label = %LevelLabel
@onready var team_label: Label = %TeamLabel
@onready var company_label: Label = %CompanyLabel
@onready var restart_button: Button = %RestartButton

# --- Lifecycle ---

func _ready() -> void:
	restart_button.pressed.connect(_on_restart)

# --- Public ---

func set_data(data: Dictionary) -> void:
	var final_valuation: int = data.get("valuation", 0)
	valuation_label.text = "$%d" % final_valuation
	level_label.text = "Level: %d" % PD.level
	var team_text: String = ""
	for dev: Developer in PD.developers:
		team_text += Constants.DevType.keys()[dev.data.dev_type] + "\n"
	team_label.text = team_text
	_show_company_comparison(final_valuation)

# --- Private ---

func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if val >= milestone["valuation"]:
			best_company = milestone["name"]
	if best_company:
		company_label.text = "Your startup beat %s! 🚀" % best_company
		company_label.visible = true
	else:
		company_label.text = "Keep grinding..."
		company_label.visible = true

func _on_restart() -> void:
	close_dialog({"action": "restart"})
