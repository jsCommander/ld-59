class_name StatSummaryItem
extends PanelContainer

# --- @onready ---
@onready var stat_name_label: Label = %StatNameLabel
@onready var stat_value_label: Label = %StatValueLabel

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
	var percent: int = int(_value * 100)
	if percent > 0:
		stat_value_label.text = "+%d%%" % percent
		stat_value_label.add_theme_color_override("font_color", ThemeTokens.STAT_POSITIVE)
	elif percent < 0:
		stat_value_label.text = "%d%%" % percent
		stat_value_label.add_theme_color_override("font_color", ThemeTokens.STAT_NEGATIVE)
	else:
		stat_value_label.text = "0%"
