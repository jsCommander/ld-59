class_name UiCapitalization
extends Control

# --- @onready ---

@onready var valuation_label: Label = %ValuationLabel

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update_valuation)
	_update_valuation()

# --- Private ---

func _update_valuation() -> void:
	valuation_label.text = "$%d" % PD.valuation
