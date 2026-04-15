class_name ClickableTrait
extends Area2D

# --- Signals ---

signal clicked

# --- Lifecycle ---

func _ready() -> void:
	input_event.connect(_on_input_event)

# --- Handlers ---

func _on_input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		viewport.set_input_as_handled()
		clicked.emit()
