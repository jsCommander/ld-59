class_name UiGameOver
extends BaseDialog

# --- Constants ---

const FACE_SIZE: Vector2 = Vector2(48, 48)

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var company_label: Label = %CompanyLabel
@onready var sprints_label: Label = %SprintsLabel
@onready var team_grid: GridContainer = %TeamGrid
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var restart_button: Button = %RestartButton

# --- Lifecycle ---

func _ready() -> void:
	restart_button.pressed.connect(_on_restart)

# --- Public ---

func set_data(data: Dictionary) -> void:
	var final_valuation: int = data.get("valuation", 0)
	valuation_label.text = "Your startup grew to a valuation of $%s" % Utils.format_number(final_valuation)
	_show_company_comparison(final_valuation)
	sprints_label.text = "Sprints closed: %d" % PD.sprint_number
	_populate_team_grid()
	_populate_stats()

# --- Private ---

func _show_company_comparison(val: int) -> void:
	var best_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if val >= milestone["valuation"]:
			best_company = milestone["name"]
	if best_company:
		company_label.text = "This is more than %s" % best_company
		company_label.visible = true
	else:
		company_label.visible = false


func _populate_team_grid() -> void:
	for child: Node in team_grid.get_children():
		child.queue_free()
	var dev_count: int = PD.developers.size()
	team_grid.columns = mini(dev_count, 5) if dev_count > 0 else 1
	for dev: Developer in PD.developers:
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.texture = dev.data.head_texture
		tex_rect.custom_minimum_size = FACE_SIZE
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		team_grid.add_child(tex_rect)


func _populate_stats() -> void:
	for child: Node in stats_container.get_children():
		child.queue_free()
	for stat_key: String in Constants.STAT_ORDER:
		if not PD.total_stats.has(stat_key):
			continue
		var value: float = PD.total_stats[stat_key] as float
		if is_zero_approx(value):
			continue
		var display_name: String = Constants.STAT_DISPLAY_NAMES.get(stat_key, stat_key)
		var label: Label = Label.new()
		var sign: String = "+" if value > 0 else ""
		label.text = "%s: %s%d%%" % [display_name, sign, int(value * 100)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(label)


func _on_restart() -> void:
	close_dialog({"action": "restart"})
