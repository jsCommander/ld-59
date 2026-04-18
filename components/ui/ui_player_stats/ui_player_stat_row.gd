class_name UiPlayerStatRow
extends Control

# --- @onready ---

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel

# --- Public ---

func setup(row_name: String, value: String, diff_type: Constants.DiffType = Constants.DiffType.NONE) -> void:
	name_label.text = row_name
	value_label.text = value
	match diff_type:
		Constants.DiffType.POSITIVE:
			value_label.add_theme_color_override("font_color", ThemeTokens.STAT_POSITIVE)
		Constants.DiffType.NEGATIVE:
			value_label.add_theme_color_override("font_color", ThemeTokens.STAT_NEGATIVE)
		_:
			value_label.remove_theme_color_override("font_color")
