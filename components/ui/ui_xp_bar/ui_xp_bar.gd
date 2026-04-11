class_name UiXpBar
extends ProgressBar

# --- Lifecycle ---

func _ready() -> void:
	SB.valuation_changed.connect(_update)
	SB.level_up.connect(_on_level_up)
	_update()

# --- Handlers ---

func _on_level_up(_level: int) -> void:
	_update()

# --- Private ---

func _update() -> void:
	var next_xp: int = PD.get_xp_for_level(PD.level + 1)
	if next_xp > 0:
		value = float(PD.valuation) / float(next_xp)
	else:
		value = 1.0
