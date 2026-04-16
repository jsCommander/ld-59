@tool
extends EditorScript

## Run via Script > Run in Godot Editor.
## Extracts all Color constants from ThemeTokens and checks each one exists
## somewhere in ui_game_theme.tres.

func _run() -> void:
	var theme: Theme = load("res://resources/ui_game_theme.tres")
	if not theme:
		printerr("ERROR: Could not load ui_game_theme.tres")
		return

	var theme_colors: Array[Color] = _collect_theme_colors(theme)
	var token_colors: Dictionary = _collect_token_colors()
	var missing: int = 0

	for token_name: String in token_colors:
		var color: Color = token_colors[token_name]
		if not _color_in_list(color, theme_colors):
			printerr("  MISSING in theme: ThemeTokens.%s = %s" % [token_name, color.to_html()])
			missing += 1

	if missing == 0:
		print("✓ All %d ThemeTokens colors found in theme" % token_colors.size())
	else:
		printerr("✗ %d / %d token colors missing from theme" % [missing, token_colors.size()])


func _collect_theme_colors(theme: Theme) -> Array[Color]:
	var colors: Array[Color] = []
	for type_name: String in theme.get_type_list():
		for color_name: String in theme.get_color_list(type_name):
			colors.append(theme.get_color(color_name, type_name))
		for style_name: String in theme.get_stylebox_list(type_name):
			var sb: StyleBox = theme.get_stylebox(style_name, type_name)
			if sb is StyleBoxFlat:
				colors.append((sb as StyleBoxFlat).bg_color)
				colors.append((sb as StyleBoxFlat).border_color)
	return colors


func _collect_token_colors() -> Dictionary:
	var result: Dictionary = {}
	var script: GDScript = ThemeTokens
	var constants: Dictionary = {}
	for prop: Dictionary in script.get_script_constant_map():
		constants = script.get_script_constant_map()
		break
	for key: String in constants:
		var value: Variant = constants[key]
		if value is Color:
			result[key] = value
	return result


func _color_in_list(color: Color, list: Array[Color]) -> bool:
	for c: Color in list:
		if c.is_equal_approx(color):
			return true
	return false
