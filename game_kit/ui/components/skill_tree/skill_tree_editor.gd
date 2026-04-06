@tool
class_name SkillTreeEditor extends Control

@export var layout: SkillTreeLayout:
	set(value):
		layout = value
		if is_inside_tree():
			_rebuild()

@export var upgrades_path: String = "":
	set(value):
		upgrades_path = value
		if is_inside_tree():
			_scan_upgrades()
			_rebuild()

var _available_upgrades: Array[BaseUpgrade] = []
var _selected_upgrade: BaseUpgrade  # selected from palette for placement
var _selected_node: SkillTreeNodePlacement  # selected on grid
var _connecting_from: SkillTreeNodePlacement  # first node when creating connection
var _save_timer: Timer
var _needs_save: bool = false

# UI references
@onready var palette_list: ItemList = %PaletteList
@onready var grid_panel: Control = %GridPanel


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_setup_save_timer()
	_scan_upgrades()
	_rebuild()


func _setup_save_timer() -> void:
	_save_timer = Timer.new()
	_save_timer.wait_time = 1.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_do_save)
	add_child(_save_timer)


# --- Upgrade scanning ---

func _scan_upgrades() -> void:
	_available_upgrades.clear()
	if upgrades_path.is_empty():
		return
	_scan_directory(upgrades_path)
	_update_palette()


func _scan_directory(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif file_name.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(full_path)
			if res is BaseUpgrade:
				_available_upgrades.append(res)
		file_name = dir.get_next()


# --- Palette ---

func _update_palette() -> void:
	if not palette_list:
		return
	palette_list.clear()
	var placed_ids: Array[String] = []
	if layout:
		for node: SkillTreeNodePlacement in layout.nodes:
			if node.upgrade:
				placed_ids.append(node.upgrade.id)

	for upgrade: BaseUpgrade in _available_upgrades:
		var idx: int = palette_list.add_item(upgrade.display_name, upgrade.icon)
		if upgrade.id in placed_ids:
			palette_list.set_item_disabled(idx, true)
			palette_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))


# --- Grid drawing ---

func _rebuild() -> void:
	if not is_inside_tree():
		return
	_update_palette()
	if grid_panel:
		grid_panel.queue_redraw()


func _on_grid_draw() -> void:
	if not layout:
		return
	var cell_size: int = layout.cell_size
	var grid_size: Vector2 = grid_panel.size

	# Draw grid
	var grid_color: Color = Color(0.2, 0.2, 0.2, 0.5)
	var cols: int = int(grid_size.x / cell_size) + 1
	var rows: int = int(grid_size.y / cell_size) + 1
	for x: int in range(cols):
		grid_panel.draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, grid_size.y), grid_color)
	for y: int in range(rows):
		grid_panel.draw_line(Vector2(0, y * cell_size), Vector2(grid_size.x, y * cell_size), grid_color)

	# Draw connections
	var node_offset: Vector2 = Vector2(cell_size, cell_size) / 2.0
	for placement: SkillTreeNodePlacement in layout.nodes:
		var from: Vector2 = _grid_to_pixel(placement) + node_offset
		for child: SkillTreeNodePlacement in placement.children:
			var to: Vector2 = _grid_to_pixel(child) + node_offset
			var mid: Vector2 = Vector2(to.x, from.y)
			grid_panel.draw_line(from, mid, Color.CYAN, 2.0, true)
			grid_panel.draw_line(mid, to, Color.CYAN, 2.0, true)

	# Draw placed nodes
	for placement: SkillTreeNodePlacement in layout.nodes:
		var pos: Vector2 = _grid_to_pixel(placement)
		var rect: Rect2 = Rect2(pos + Vector2(4, 4), Vector2(cell_size - 8, cell_size - 8))
		var color: Color = Color.WHITE
		if placement == _selected_node:
			color = Color.YELLOW
		elif placement == _connecting_from:
			color = Color.CYAN
		if placement == layout.root:
			grid_panel.draw_rect(Rect2(pos + Vector2(2, 2), Vector2(cell_size - 4, cell_size - 4)), Color(1, 0.8, 0, 0.3))
		grid_panel.draw_rect(rect, color, false, 2.0)
		if placement.upgrade and placement.upgrade.icon:
			grid_panel.draw_texture_rect(placement.upgrade.icon, rect, false)


func _grid_to_pixel(placement: SkillTreeNodePlacement) -> Vector2:
	return Vector2(placement.grid_x * layout.cell_size, placement.grid_y * layout.cell_size)


# --- Interaction ---

func _on_palette_item_selected(index: int) -> void:
	if index >= 0 and index < _available_upgrades.size():
		_selected_upgrade = _available_upgrades[index]


func _on_grid_gui_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() or not layout:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return

		var grid_pos: Vector2i = _pixel_to_grid(mb.position)

		if mb.button_index == MOUSE_BUTTON_LEFT:
			var existing: SkillTreeNodePlacement = _find_placement_at(grid_pos)

			if existing:
				# If we're in connection mode, create/toggle connection
				if _connecting_from:
					_toggle_connection(_connecting_from, existing)
					_connecting_from = null
				else:
					_selected_node = existing
					_connecting_from = null
			elif _selected_upgrade:
				# Place new node
				_place_node(_selected_upgrade, grid_pos)
				_selected_upgrade = null
				if palette_list:
					palette_list.deselect_all()

		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			# Start connection mode
			var existing: SkillTreeNodePlacement = _find_placement_at(grid_pos)
			if existing:
				if _connecting_from:
					_connecting_from = null  # cancel
				else:
					_connecting_from = existing

		_rebuild()


func _unhandled_key_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		return
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and key.keycode == KEY_DELETE and _selected_node:
			_remove_node(_selected_node)
			_selected_node = null
			_rebuild()


# --- Layout operations ---

func _place_node(upgrade: BaseUpgrade, grid_pos: Vector2i) -> void:
	if _find_placement_at(grid_pos):
		return  # cell occupied
	var placement: SkillTreeNodePlacement = SkillTreeNodePlacement.new()
	placement.upgrade = upgrade
	placement.grid_x = grid_pos.x
	placement.grid_y = grid_pos.y
	layout.nodes.append(placement)
	if layout.nodes.size() == 1:
		layout.root = placement  # first node is root
	Log.log_debug("SkillTreeEditor", "Placed node: %s at (%d, %d)" % [upgrade.display_name, grid_pos.x, grid_pos.y])
	_schedule_save()


func _remove_node(placement: SkillTreeNodePlacement) -> void:
	var node_name: String = placement.upgrade.display_name if placement.upgrade else "unknown"
	# Remove from all children arrays
	for node: SkillTreeNodePlacement in layout.nodes:
		node.children.erase(placement)
	layout.nodes.erase(placement)
	if layout.root == placement:
		layout.root = layout.nodes[0] if layout.nodes.size() > 0 else null
	Log.log_debug("SkillTreeEditor", "Removed node: %s" % node_name)
	_schedule_save()


func _toggle_connection(from: SkillTreeNodePlacement, to: SkillTreeNodePlacement) -> void:
	if from == to:
		return
	var from_name: String = from.upgrade.display_name if from.upgrade else "?"
	var to_name: String = to.upgrade.display_name if to.upgrade else "?"
	if to in from.children:
		from.children.erase(to)
		Log.log_debug("SkillTreeEditor", "Removed connection: %s -> %s" % [from_name, to_name])
	else:
		from.children.append(to)
		Log.log_debug("SkillTreeEditor", "Added connection: %s -> %s" % [from_name, to_name])
	_schedule_save()


func _find_placement_at(grid_pos: Vector2i) -> SkillTreeNodePlacement:
	for placement: SkillTreeNodePlacement in layout.nodes:
		if placement.grid_x == grid_pos.x and placement.grid_y == grid_pos.y:
			return placement
	return null


func _pixel_to_grid(pixel: Vector2) -> Vector2i:
	var cell_size: int = layout.cell_size
	return Vector2i(floori(pixel.x / cell_size), floori(pixel.y / cell_size))


# --- Validation ---

func _validate_layout() -> Array[String]:
	var warnings: Array[String] = []
	if not layout:
		return warnings

	# Check for duplicate positions
	var positions: Dictionary = {}
	for placement: SkillTreeNodePlacement in layout.nodes:
		var key: String = "%d,%d" % [placement.grid_x, placement.grid_y]
		if key in positions:
			warnings.append("Duplicate position: %s" % key)
		positions[key] = true

	# Check all nodes reachable from root
	if layout.root:
		var visited: Array[SkillTreeNodePlacement] = []
		_visit(layout.root, visited)
		for placement: SkillTreeNodePlacement in layout.nodes:
			if placement not in visited:
				var uname: String = placement.upgrade.display_name if placement.upgrade else "unknown"
				warnings.append("Node not reachable from root: %s" % uname)

	return warnings


func _visit(node: SkillTreeNodePlacement, visited: Array[SkillTreeNodePlacement]) -> void:
	if node in visited:
		return
	visited.append(node)
	for child: SkillTreeNodePlacement in node.children:
		_visit(child, visited)


# --- Save ---

func _schedule_save() -> void:
	_needs_save = true
	if _save_timer:
		_save_timer.start()


func _do_save() -> void:
	if not _needs_save or not layout:
		return
	ResourceSaver.save(layout)
	_needs_save = false
	Log.log_info("SkillTreeEditor", "Layout saved: %d nodes" % layout.nodes.size())
