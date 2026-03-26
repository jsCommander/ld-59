class_name UpgradeTreeView extends Control

const UPGRADE_NODE_SCENE: PackedScene = preload("res://components/upgrade_tree/upgrade_tree_node.tscn")
const NODE_SIZE: Vector2 = Vector2(140, 80)
const RING_SPACING: float = 160.0
const LINE_COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5)
const LINE_COLOR_UNLOCKED: Color = Color(0.3, 1.0, 0.3)
const LINE_WIDTH: float = 3.0

var _nodes: Dictionary[String, UpgradeTreeNode] = {}
var _upgrades: Dictionary[String, UpgradeTree] = {}


func _ready() -> void:
	_build_tree()


func _build_tree() -> void:
	for id: String in DR.upgrades:
		var res: BaseGameData = DR.upgrades[id]
		if res is UpgradeTree:
			_upgrades[id] = res as UpgradeTree

	var levels: Dictionary[String, int] = _calculate_levels()
	var rings: Dictionary[int, Array] = {}
	for id: String in levels:
		var level: int = levels[id]
		if not rings.has(level):
			rings[level] = []
		rings[level].append(id)

	var center: Vector2 = size / 2.0 if size.length() > 0.0 else Vector2(400, 300)

	for level: int in rings:
		var ids: Array = rings[level]
		if level == 0:
			# Корни — в центре, если один. Если несколько — маленький кружок
			if ids.size() == 1:
				_place_node(ids[0], center - NODE_SIZE / 2.0)
			else:
				var radius: float = RING_SPACING * 0.5
				_place_ring(ids, center, radius)
		else:
			var radius: float = level * RING_SPACING
			_place_ring(ids, center, radius)

	queue_redraw()


func _place_ring(ids: Array, center: Vector2, radius: float) -> void:
	var count: int = ids.size()
	var angle_step: float = TAU / count
	var start_angle: float = -PI / 2.0  # начинаем сверху
	for i: int in count:
		var angle: float = start_angle + i * angle_step
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius - NODE_SIZE / 2.0
		_place_node(ids[i], pos)


func _place_node(id: String, pos: Vector2) -> void:
	var node: UpgradeTreeNode = UPGRADE_NODE_SCENE.instantiate()
	node.setup(_upgrades[id])
	add_child(node)
	node.position = pos
	node.node_clicked.connect(_on_node_clicked)
	_nodes[id] = node


func _draw() -> void:
	for id: String in _nodes:
		var upgrade: UpgradeTree = _upgrades[id]
		var child_node: UpgradeTreeNode = _nodes[id]
		var child_center: Vector2 = child_node.position + NODE_SIZE / 2.0
		for req: UpgradeTree in upgrade.prerequisites:
			if not _nodes.has(req.id):
				continue
			var parent_node: UpgradeTreeNode = _nodes[req.id]
			var parent_center: Vector2 = parent_node.position + NODE_SIZE / 2.0
			var color: Color = _get_line_color(upgrade, req)
			draw_line(parent_center, child_center, color, LINE_WIDTH, true)


func _calculate_levels() -> Dictionary[String, int]:
	var levels: Dictionary[String, int] = {}

	for id: String in _upgrades:
		if _upgrades[id].prerequisites.is_empty():
			levels[id] = 0

	var changed: bool = true
	while changed:
		changed = false
		for id: String in _upgrades:
			if levels.has(id):
				continue
			var upgrade: UpgradeTree = _upgrades[id]
			var all_resolved: bool = true
			var max_level: int = 0
			for req: UpgradeTree in upgrade.prerequisites:
				if not levels.has(req.id):
					all_resolved = false
					break
				max_level = max(max_level, levels[req.id])
			if all_resolved:
				levels[id] = max_level + 1
				changed = true

	return levels


func _get_line_color(child: UpgradeTree, parent: UpgradeTree) -> Color:
	if PD.is_upgrade_unlocked(child) and PD.is_upgrade_unlocked(parent):
		return LINE_COLOR_UNLOCKED
	return LINE_COLOR_LOCKED


func _on_node_clicked(upgrade: UpgradeTree) -> void:
	if PD.can_unlock_upgrade(upgrade):
		SB.upgrade_unlocked.emit(upgrade)
		_update_all_states()
		queue_redraw()


func _update_all_states() -> void:
	for node: UpgradeTreeNode in _nodes.values():
		node.update_state()
