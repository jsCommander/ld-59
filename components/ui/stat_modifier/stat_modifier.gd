class_name StatModifier
extends HBoxContainer

# --- @onready ---
@onready var stat_name_label: Label = %StatNameLabel
@onready var modifier_label: Label = %ModifierLabel

# --- State ---
var _stat_name: String
var _value: float


# --- Public ---
func setup(stat_name: String, value: float) -> void:
	_stat_name = stat_name
	_value = value


# --- Lifecycle ---
func _ready() -> void:
	stat_name_label.text = _stat_name
	var percent: int = int((_value - 1.0) * 100)
	if percent >= 0:
		modifier_label.text = "+%d%%" % percent
	else:
		modifier_label.text = "%d%%" % percent
