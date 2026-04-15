class_name StatModifier
extends HBoxContainer

# --- @onready ---
@onready var stat_name_label: Label = %StatNameLabel
@onready var modifier_label: Label = %ModifierLabel

# --- State ---
var _stat_name: String
var _value: float
var _is_integer: bool = false


# --- Public ---
func setup(stat_name: String, value: float, is_integer: bool = false) -> void:
	_stat_name = stat_name
	_value = value
	_is_integer = is_integer


# --- Lifecycle ---
func _ready() -> void:
	stat_name_label.text = _stat_name
	if _is_integer:
		var int_val: int = int(_value)
		modifier_label.text = "+%d" % int_val if int_val > 0 else "%d" % int_val
	else:
		var percent: int = int(_value * 100)
		modifier_label.text = "+%d%%" % percent if percent >= 0 else "%d%%" % percent
	var color: Color = Constants.STAT_POSITIVE_COLOR if _value >= 0 else Constants.STAT_NEGATIVE_COLOR
	modifier_label.add_theme_color_override("font_color", color)
