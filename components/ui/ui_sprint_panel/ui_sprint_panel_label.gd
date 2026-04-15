class_name UiSprintPanelLabel
extends PanelContainer

# --- @onready ---
@onready var sprint_label: Label = %SprintLabel

# --- Lifecycle ---
func _ready() -> void:
	SB.sprint_number_changed.connect(_on_sprint_number_changed)

# --- Handlers ---
func _on_sprint_number_changed(sprint_number: int) -> void:
	sprint_label.text = "Sprint %d" % sprint_number
