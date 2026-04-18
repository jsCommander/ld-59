class_name UiGameInfo
extends MarginContainer

# --- @onready ---

@onready var timer_label: Label = %TimerLabel
@onready var level_label: Label = %LevelLabel
@onready var valuation_label: Label = %ValuationLabel

# --- Lifecycle ---

func _ready() -> void:
	SB.level_up.connect(_on_level_up)
	SB.game_timer_changed.connect(_on_game_timer_changed)
	SB.valuation_changed.connect(_on_valuation_changed)
	level_label.text = "%d" % PD.level
	_on_valuation_changed()

# --- Handlers ---

func _on_level_up(level: int) -> void:
	level_label.text = "%d" % level

func _on_game_timer_changed(remaining: float) -> void:
	@warning_ignore("integer_division")
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

func _on_valuation_changed() -> void:
	valuation_label.text = "$" + Utils.format_number(PD.valuation)
