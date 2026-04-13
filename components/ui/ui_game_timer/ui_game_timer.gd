class_name UiGameTimer
extends Label

@onready var game_timer_label: Label = %GameTimerLabel

# --- Lifecycle ---

func _ready() -> void:
	SB.game_timer_changed.connect(_on_game_timer_changed)

# --- Handlers ---

func _on_game_timer_changed(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	game_timer_label.text = "%d:%02d" % [minutes, seconds]
