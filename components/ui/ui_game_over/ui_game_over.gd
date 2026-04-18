class_name UiGameOver
extends BaseDialog

# --- Constants ---

const DEV_FACE: PackedScene = preload("res://components/ui/ui_game_over/dev_face.tscn")

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var company_label: Label = %CompanyLabel
@onready var team_grid: GridContainer = %TeamGrid
@onready var player_stats_view: UiPlayerStats = %UiPlayerStats
@onready var restart_button: Button = %RestartButton

# --- Lifecycle ---

func _ready() -> void:
	restart_button.pressed.connect(_on_restart)

# --- Public ---

func set_data(data: Dictionary) -> void:
	var final_valuation: int = data.get("valuation", 0)
	valuation_label.text = "$%s" % Utils.format_number(final_valuation)
	_show_company_comparison(final_valuation)
	_populate_team_grid()
	player_stats_view.stats = PD.player_stats

# --- Private ---

func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if val >= milestone["valuation"]:
			best_company = milestone["name"]
	if best_company:
		company_label.text = best_company
		company_label.get_parent().visible = true
	else:
		company_label.get_parent().visible = false


func _populate_team_grid() -> void:
	for child: Node in team_grid.get_children():
		child.queue_free()
	var dev_count: int = PD.developers.size()
	team_grid.columns = mini(dev_count, 5) if dev_count > 0 else 1
	for dev: Developer in PD.developers:
		if not dev.data:
			continue
		var face: DevFace = DEV_FACE.instantiate()
		face.dev_data = dev.data
		team_grid.add_child(face)


func _on_restart() -> void:
	close_dialog({"action": "restart"})
