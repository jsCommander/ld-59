class_name UiCapitalization
extends Control

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var milestone_label: Label = %MilestoneLabel
@onready var next_level_label: Label = %NextLevel

# --- State ---

var _last_milestone: String = ""

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	_update_valuation()
	_update_next_level()

# --- Handlers ---

func _on_level_up(_level: int) -> void:
	_update_next_level()

# --- Private ---

func _update_valuation() -> void:
	valuation_label.text = "$%d" % PD.valuation
	_update_milestone()
	_update_next_level()

func _update_milestone() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company != _last_milestone:
		_last_milestone = current_company
		if _last_milestone:
			milestone_label.text = _last_milestone
			milestone_label.visible = true
		else:
			milestone_label.visible = false

func _update_next_level() -> void:
	var target: int = PD.get_xp_for_level(PD.level + 1)
	if target > 0:
		next_level_label.text = "$%d / $%d" % [PD.valuation, target]
	else:
		next_level_label.text = "MAX"
