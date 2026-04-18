class_name UiHud
extends CanvasLayer

const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")
const UI_PAUSE: PackedScene = preload("res://components/ui/dialog_pause/dialog_pause.tscn")

const FLY_DURATION: float = 0.4
const FLY_ICON_SIZE: Vector2 = Vector2(64, 64)

# --- @onready ---

@onready var sprint_panel: UiSprintPanel = %UiSprintPanel
@onready var dialog_manager: DialogManager = %DialogManager
@onready var upgrade_button: UiUpgradeButton = %UiUpgradeButton

# --- Lifecycle ---

func _ready() -> void:
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.game_over.connect(_on_game_over)
	SB.task_assigned.connect(_on_task_assigned)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()

# --- Handlers ---

func _on_hire_requested() -> void:
	var result: Dictionary = await dialog_manager.open_dialog(UI_HIRE_CHOICE, {}, true)
	var dev_data: DeveloperData = result.get("dev_data")
	if dev_data:
		SB.developer_chosen.emit(dev_data)

func _on_game_over(final_valuation: int) -> void:
	var result: Dictionary = await dialog_manager.open_dialog(UI_GAME_OVER, {"valuation": final_valuation}, true)
	if result.get("action") == "restart":
		get_tree().reload_current_scene()

func _on_task_assigned(task: TaskData, developer: Developer, task_position: Vector2) -> void:
	_fly_task_to_developer(task, developer, task_position)

func _on_upgrade_button_pressed() -> void:
	while not PD.pending_upgrades.is_empty():
		var upgrade_type: Constants.UpgradeType = PD.pending_upgrades.pop_front()
		SB.pending_upgrades_changed.emit()
		if upgrade_type == Constants.UpgradeType.HIRE:
			var result: Dictionary = await dialog_manager.open_dialog(UI_HIRE_CHOICE, {}, true)
			var dev_data: DeveloperData = result.get("dev_data")
			if dev_data:
				SB.developer_chosen.emit(dev_data)
		elif upgrade_type == Constants.UpgradeType.UPGRADE:
			var result: Dictionary = await dialog_manager.open_dialog(UI_UPGRADE_CHOICE, {"level": PD.level}, true)
			var upgrade: UpgradeData = result.get("upgrade")
			if upgrade:
				SB.upgrade_chosen.emit(upgrade)
		else:
			Log.log_warn(name, "Unknown upgrade type: %d, skipping" % upgrade_type)

# --- Private ---

func _open_pause_menu() -> void:
	var result: Dictionary = await dialog_manager.open_dialog(UI_PAUSE, {}, true)
	if result.get("exit"):
		get_tree().quit()

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
