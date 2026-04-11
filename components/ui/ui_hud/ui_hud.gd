class_name UiHud
extends CanvasLayer

const POPUP_DEVELOPER: PackedScene = preload("res://components/developer/ui/popup_developer.tscn")
const UI_UPGRADE_CHOICE: PackedScene = preload("res://components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn")
const UI_HIRE_CHOICE: PackedScene = preload("res://components/ui/ui_hire_choice/ui_hire_choice.tscn")
const UI_GAME_OVER: PackedScene = preload("res://components/ui/ui_game_over/ui_game_over.tscn")

# --- @onready ---

@onready var popup_manager: UiPopupManager = %UiPopupManager

# --- Lifecycle ---

func _ready() -> void:
	SB.entity_selected.connect(_on_entity_selected)
	SB.level_up.connect(_on_level_up)
	SB.developer_hire_requested.connect(_on_hire_requested)
	SB.game_over.connect(_on_game_over)
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
	var popup: UiUpgradeChoice = UI_UPGRADE_CHOICE.instantiate()
	add_child(popup)
	popup.show_for_level(level)

func _on_hire_requested() -> void:
	var popup: UiHireChoice = UI_HIRE_CHOICE.instantiate()
	add_child(popup)
	popup.show_hire()

func _on_game_over(final_valuation: int) -> void:
	var popup: UiGameOver = UI_GAME_OVER.instantiate()
	add_child(popup)
	popup.show_game_over(final_valuation)
