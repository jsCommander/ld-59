class_name HireCard
extends Control

# --- Signals ---
signal chosen(dev_data: DeveloperData)

# --- State ---
var _dev_data: DeveloperData

# --- @onready ---
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var feature_damage_row: UiPlayerStatRow = %FeatureDamageRow
@onready var refactor_damage_row: UiPlayerStatRow = %RefactorDamageRow


func setup(dev_data: DeveloperData) -> void:
	_dev_data = dev_data


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not _dev_data:
		return
	if _dev_data.head_texture:
		icon_rect.texture = _dev_data.head_texture
	name_label.text = Constants.DEV_TYPE_DISPLAY_NAMES[_dev_data.dev_type]
	description_label.text = _dev_data.description
	_populate_stats()


# --- Private ---
func _populate_stats() -> void:
	var stats: PlayerStatsResource = PD.player_stats
	var feature_total: float = _dev_data.task_mults.get(Constants.TaskType.FEATURE, 1.0) * stats.damage_features
	var refactor_total: float = _dev_data.task_mults.get(Constants.TaskType.REFACTORING, 1.0) * stats.damage_refactor
	feature_damage_row.setup("Feature damage", Utils.format_mult(feature_total), _diff_vs_baseline(feature_total))
	refactor_damage_row.setup("Refactor damage", Utils.format_mult(refactor_total), _diff_vs_baseline(refactor_total))


func _diff_vs_baseline(value: float) -> Constants.DiffType:
	if is_equal_approx(value, 1.0):
		return Constants.DiffType.NONE
	return Constants.DiffType.POSITIVE if value > 1.0 else Constants.DiffType.NEGATIVE


# --- Handlers ---

func _on_mouse_entered() -> void:
	modulate = Color(0.75, 0.75, 0.75)


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_dev_data)
