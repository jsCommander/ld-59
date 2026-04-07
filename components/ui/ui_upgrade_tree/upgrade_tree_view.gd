class_name UpgradeTreeView extends Control

const UPGRADE_TREE_NODE_SCENE: PackedScene = preload("res://components/ui/ui_upgrade_tree/upgrade_tree_node.tscn")
const UPGRADE_TREE_TOOLTIP_SCENE: PackedScene = preload("res://components/ui/ui_upgrade_tree/upgrade_tree_tooltip.tscn")

const LINE_COLOR_LOCKED: Color = Color(0.3, 0.3, 0.3)
const LINE_COLOR_UNLOCKED: Color = Color(0.0, 0.9, 0.9)
const LINE_WIDTH: float = 3.0

signal purchase_requested(upgrade: UpgradeTree)

@export var layout: SkillTreeLayout

var _nodes: Dictionary[String, UpgradeTreeNode] = {}
var _placements: Dictionary[String, SkillTreeNodePlacement] = {}
var _pan_offset: Vector2 = Vector2.ZERO
var _is_panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _tooltip: UpgradeTreeTooltip
var _nodes_container: Control


func _ready() -> void:
	clip_contents = true
	_nodes_container = Control.new()
	_nodes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nodes_container)
	_tooltip = UPGRADE_TREE_TOOLTIP_SCENE.instantiate()
	_tooltip.buy_pressed.connect(_on_tooltip_buy_pressed)
	add_child(_tooltip)
	SB.upgrade_purchased.connect(_on_upgrade_purchased)
	SB.resource_money_changed.connect(_on_money_changed)
	if layout:
		_build_tree()


func _build_tree() -> void:
	_clear_tree()
	var cell_size: int = layout.cell_size

	for placement: SkillTreeNodePlacement in layout.nodes:
		if not placement.upgrade:
			continue
		var node: UpgradeTreeNode = UPGRADE_TREE_NODE_SCENE.instantiate()
		node.setup(placement.upgrade)
		_nodes_container.add_child(node)
		node.position = Vector2(placement.grid_x * cell_size, placement.grid_y * cell_size)
		node.clicked.connect(_on_node_clicked)
		node.hovered.connect(_on_node_hovered)
		node.unhovered.connect(_on_node_unhovered)
		_nodes[placement.upgrade.id] = node
		_placements[placement.upgrade.id] = placement

	_center_on_root()
	Log.log_info(self.name, "Upgrade tree built: %d nodes" % _nodes.size())
	queue_redraw()


func _clear_tree() -> void:
	for node: UpgradeTreeNode in _nodes.values():
		node.queue_free()
	_nodes.clear()
	_placements.clear()


func _center_on_root() -> void:
	if not layout.root or not layout.root.upgrade:
		return
	var cell_size: int = layout.cell_size
	var root_pos: Vector2 = Vector2(layout.root.grid_x * cell_size, layout.root.grid_y * cell_size)
	_pan_offset = size / 2.0 - root_pos - Vector2(cell_size, cell_size) / 2.0
	_nodes_container.position = _pan_offset


func refresh_states() -> void:
	_center_on_root()
	for id: String in _nodes:
		var node: UpgradeTreeNode = _nodes[id]
		var upgrade: BaseUpgrade = node.upgrade
		if PD.is_upgrade_purchased(id):
			node.set_state(UpgradeTreeNode.NodeState.PURCHASED)
		elif _are_prerequisites_met(upgrade as UpgradeTree):
			node.set_state(UpgradeTreeNode.NodeState.AVAILABLE)
		else:
			node.set_state(UpgradeTreeNode.NodeState.LOCKED)
	queue_redraw()


func _are_prerequisites_met(upgrade: UpgradeTree) -> bool:
	if not upgrade:
		return false
	for prereq: UpgradeTree in upgrade.prerequisites:
		if not PD.is_upgrade_purchased(prereq.id):
			return false
	return true


## Public API

func set_node_state(upgrade_id: String, state: UpgradeTreeNode.NodeState) -> void:
	if _nodes.has(upgrade_id):
		_nodes[upgrade_id].set_state(state)
		Log.log_debug(self.name, "Node state changed: %s -> %s" % [upgrade_id, UpgradeTreeNode.NodeState.keys()[state]])
		queue_redraw()


func set_all_states(states: Dictionary) -> void:
	for upgrade_id: String in states:
		set_node_state(upgrade_id, states[upgrade_id])


# --- Drawing ---

func _draw() -> void:
	var cell_size: int = layout.cell_size if layout else 80
	var node_center_offset: Vector2 = Vector2(cell_size, cell_size) / 2.0

	for id: String in _placements:
		var placement: SkillTreeNodePlacement = _placements[id]
		var from_pos: Vector2 = Vector2(placement.grid_x * cell_size, placement.grid_y * cell_size) + node_center_offset + _pan_offset

		for child: SkillTreeNodePlacement in placement.children:
			if not child.upgrade:
				continue
			var to_pos: Vector2 = Vector2(child.grid_x * cell_size, child.grid_y * cell_size) + node_center_offset + _pan_offset
			var color: Color = _get_line_color(placement, child)
			var mid: Vector2 = Vector2(to_pos.x, from_pos.y)
			draw_line(from_pos, mid, color, LINE_WIDTH, true)
			draw_line(mid, to_pos, color, LINE_WIDTH, true)


func _get_line_color(parent: SkillTreeNodePlacement, child: SkillTreeNodePlacement) -> Color:
	var parent_node: UpgradeTreeNode = _nodes.get(parent.upgrade.id)
	var child_node: UpgradeTreeNode = _nodes.get(child.upgrade.id)
	if parent_node and child_node:
		if parent_node.state == UpgradeTreeNode.NodeState.PURCHASED and child_node.state == UpgradeTreeNode.NodeState.PURCHASED:
			return LINE_COLOR_UNLOCKED
	return LINE_COLOR_LOCKED


# --- Pan ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_is_panning = true
				_pan_start = mb.position
			else:
				_is_panning = false
			accept_event()
	elif event is InputEventMouseMotion and _is_panning:
		var motion: InputEventMouseMotion = event
		_pan_offset += motion.relative
		_nodes_container.position = _pan_offset
		queue_redraw()
		accept_event()


# --- Tooltip ---

func _on_node_clicked(upgrade: BaseUpgrade) -> void:
	var node: UpgradeTreeNode = _nodes.get(upgrade.id)
	if not node:
		return
	if node.state != UpgradeTreeNode.NodeState.AVAILABLE:
		return
	Log.log_debug(self.name, "Node clicked: %s" % upgrade.display_name)
	_show_tooltip(upgrade)


func _on_node_hovered(_upgrade: BaseUpgrade) -> void:
	pass


func _on_node_unhovered(_upgrade: BaseUpgrade) -> void:
	pass


func _show_tooltip(upgrade: BaseUpgrade) -> void:
	if not _nodes.has(upgrade.id):
		return
	var node: UpgradeTreeNode = _nodes[upgrade.id]
	_tooltip.show_upgrade(upgrade as UpgradeTree)

	await get_tree().process_frame
	var node_global_pos: Vector2 = node.global_position
	var tooltip_pos: Vector2 = Vector2(
		node_global_pos.x - _tooltip.size.x / 2.0 + node.size.x / 2.0,
		node_global_pos.y - _tooltip.size.y - 8.0
	)
	var viewport_size: Vector2 = get_viewport_rect().size
	tooltip_pos.x = clampf(tooltip_pos.x, 0.0, viewport_size.x - _tooltip.size.x)
	if tooltip_pos.y < 0.0:
		tooltip_pos.y = node_global_pos.y + node.size.y + 8.0
	_tooltip.global_position = tooltip_pos


func _on_tooltip_buy_pressed(upgrade: UpgradeTree) -> void:
	purchase_requested.emit(upgrade)


func _on_upgrade_purchased(_upgrade_id: String) -> void:
	refresh_states()


func _on_money_changed() -> void:
	if _tooltip.visible and _tooltip._current_upgrade:
		_tooltip.buy_button.disabled = not PD.can_afford(_tooltip._current_upgrade.cost)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_tooltip.hide_tooltip()
