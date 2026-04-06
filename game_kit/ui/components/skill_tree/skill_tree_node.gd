# game_kit/ui/components/skill_tree/skill_tree_node.gd
class_name SkillTreeNode extends Control

signal clicked(upgrade: BaseUpgrade)
signal hovered(upgrade: BaseUpgrade)
signal unhovered(upgrade: BaseUpgrade)

enum NodeState {
	LOCKED,
	AVAILABLE,
	PURCHASED,
}

const COLOR_LOCKED: Color = Color(0.4, 0.4, 0.4)
const COLOR_AVAILABLE: Color = Color(1.0, 1.0, 1.0)
const COLOR_PURCHASED: Color = Color(0.3, 1.0, 0.3)

var upgrade: BaseUpgrade
var state: NodeState = NodeState.LOCKED

@onready var icon_rect: TextureRect = %IconRect


func setup(p_upgrade: BaseUpgrade) -> void:
	upgrade = p_upgrade


func _ready() -> void:
	if not upgrade:
		return
	icon_rect.texture = upgrade.icon
	_apply_state()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_state(new_state: NodeState) -> void:
	state = new_state
	_apply_state()


func _apply_state() -> void:
	match state:
		NodeState.LOCKED:
			modulate = COLOR_LOCKED
		NodeState.AVAILABLE:
			modulate = COLOR_AVAILABLE
		NodeState.PURCHASED:
			modulate = COLOR_PURCHASED


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(upgrade)
			accept_event()


func _on_mouse_entered() -> void:
	hovered.emit(upgrade)


func _on_mouse_exited() -> void:
	unhovered.emit(upgrade)
