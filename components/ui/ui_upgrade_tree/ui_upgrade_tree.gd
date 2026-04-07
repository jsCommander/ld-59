class_name UiUpgradeTree extends CanvasLayer

const LAYOUT: SkillTreeLayout = preload("res://game_data/upgrade_tree/tree.tres")

@onready var close_button: Button = %CloseButton
@onready var upgrade_tree_view: UpgradeTreeView = %UpgradeTreeView


func _ready() -> void:
	add_to_group("upgrade_tree")
	close_button.pressed.connect(close)
	upgrade_tree_view.layout = LAYOUT
	upgrade_tree_view.purchase_requested.connect(_on_purchase_requested)
	visible = false


func open() -> void:
	visible = true
	upgrade_tree_view.refresh_states()


func close() -> void:
	visible = false


func _on_purchase_requested(upgrade: UpgradeTree) -> void:
	PD.purchase_upgrade(upgrade)
