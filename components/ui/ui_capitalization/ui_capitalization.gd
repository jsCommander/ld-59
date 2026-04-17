class_name UiCapitalization
extends Control

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var milestone_label: Label = %MilestoneLabel
@onready var current_compare_label: Label = %CurrentCompareLabel
@onready var goal_compare_label: Label = %GoalCompareLabel

# --- State ---

var _last_milestone: String = ""

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update_valuation)
	_update_valuation()

# --- Private ---

func _update_valuation() -> void:
	valuation_label.text = "$" + Utils.format_number(PD.valuation)
	var current_name: String = _get_current_milestone_name()
	current_compare_label.text = current_name if current_name else ""
	_update_next_goal()


func _update_next_goal() -> void:
	var next: Dictionary = _get_next_milestone()
	if next.is_empty():
		milestone_label.visible = false
		goal_compare_label.text = ""
		return
	milestone_label.text = "$" + Utils.format_number(next["valuation"])
	milestone_label.visible = true
	goal_compare_label.text = next["name"]


func _get_current_milestone_name() -> String:
	var result: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			result = milestone["name"]
	return result


func _get_next_milestone() -> Dictionary:
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation < milestone["valuation"]:
			return milestone
	return {}
