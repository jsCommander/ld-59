class_name UiHud
extends CanvasLayer

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")
const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")

const FLY_DURATION: float = 0.4
const FLY_ICON_SIZE: Vector2 = Vector2(64, 64)

# --- @onready ---

@onready var popup_manager: UiPopupManager = %UiPopupManager
@onready var sprint_panel: UiSprintPanel = %UiSprintPanel

# --- State ---

var _pending_upgrade_level: int = -1

# --- Lifecycle ---

func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.level_up.connect(_on_level_up)
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.developer_chosen.connect(_on_developer_hired)
	SB.game_over.connect(_on_game_over)
	SB.task_assigned.connect(_on_task_assigned)
	popup_manager.popup_closed.connect(_on_popup_closed)

# --- Handlers ---

func _on_popup_closed() -> void:
	SB.selection_cleared.emit()

func _on_entity_selected(target: Node2D, popup_position: Vector2) -> void:
	if target is Developer:
		var dev: Developer = target as Developer
		if dev.data == null:
			return
		var popup: PopupDeveloper = POPUP_DEVELOPER.instantiate()
		popup.setup(dev)
		popup_manager.show_popup(target, popup, popup_position)

func _on_level_up(level: int) -> void:
	_pending_upgrade_level = level
	# If this is a hire level, wait for hire popup to complete first
	# developer_hire_requested will be emitted by PlayerData if needed
	if level not in Constants.HIRE_LEVELS:
		_show_upgrade_popup(level)

func _on_hire_requested() -> void:
	var popup: UiHireChoice = UI_HIRE_CHOICE.instantiate()
	add_child(popup)
	popup.show_hire()

func _on_developer_hired(_dev_data: DeveloperData) -> void:
	# After hiring, show upgrade choice for the same level
	if _pending_upgrade_level > 0:
		# Small delay to let hire popup close
		await get_tree().process_frame
		_show_upgrade_popup(_pending_upgrade_level)

func _on_game_over(final_valuation: int) -> void:
	var popup: UiGameOver = UI_GAME_OVER.instantiate()
	add_child(popup)
	popup.show_game_over(final_valuation)


func _on_task_assigned(task: TaskData, developer: Developer, task_position: Vector2) -> void:
	_fly_task_to_developer(task, developer, task_position)

# --- Private ---

func _show_upgrade_popup(level: int) -> void:
	var popup: UiUpgradeChoice = UI_UPGRADE_CHOICE.instantiate()
	add_child(popup)
	popup.show_for_level(level)
	_pending_upgrade_level = -1


func _fly_task_to_developer(task: TaskData, developer: Developer, task_position: Vector2) -> void:
	var start_pos: Vector2 = sprint_panel.get_card_position(task)
	var canvas_transform: Transform2D = developer.get_viewport().get_canvas_transform()
	var end_pos: Vector2 = canvas_transform * task_position

	var icon: TextureRect = TextureRect.new()
	icon.texture = task.texture
	icon.custom_minimum_size = FLY_ICON_SIZE
	icon.size = FLY_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = start_pos - FLY_ICON_SIZE * 0.5
	add_child(icon)

	SB.task_fly_started.emit(task, developer)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", end_pos - FLY_ICON_SIZE * 0.5, FLY_DURATION)
	tween.tween_callback(func() -> void:
		icon.queue_free()
		SB.task_fly_ended.emit(task, developer)
	)
