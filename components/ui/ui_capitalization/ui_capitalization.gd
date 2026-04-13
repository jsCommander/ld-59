class_name UiCapitalization
extends Control

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel
@onready var company_label: Label = %CompanyLabel

# --- State ---

var _flash_tween: Tween

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update_valuation)
	SB.level_up.connect(_on_level_up)
	company_label.modulate.a = 0.0
	_update_valuation()

# --- Handlers ---

func _on_level_up(_level: int) -> void:
	_update_valuation()

# --- Private ---

func _update_valuation() -> void:
	valuation_label.text = "$%d" % PD.valuation
	_update_company_comparison()

func _update_company_comparison() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company:
		company_label.text = "Bigger than %s!" % current_company
		_flash_company_label()

func _flash_company_label() -> void:
	if _flash_tween:
		_flash_tween.kill()
	company_label.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(2.0)
	_flash_tween.tween_property(company_label, "modulate:a", 0.0, 0.5)
