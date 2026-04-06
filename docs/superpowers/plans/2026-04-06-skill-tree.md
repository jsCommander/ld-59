# Skill Tree Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable skill tree component for `game_kit/` with a `@tool` editor for laying out nodes on a grid and a runtime viewer with pan, tooltips, and signals.

**Architecture:** Three resource types (`BaseUpgrade`, `SkillTreeNodePlacement`, `SkillTreeLayout`) define the data. A `@tool` editor lets designers drag-and-drop upgrades onto a grid and wire connections. A runtime `SkillTreeView` renders the tree with pan, tooltips, and state management via external API. The component lives entirely in `game_kit/` and has no game-specific dependencies.

**Tech Stack:** Godot 4.x, GDScript, `@tool` scripts, Resource-based data

**Spec:** `docs/superpowers/specs/2026-04-06-skill-tree-design.md`

---

## File Map

### New files (game_kit)

| File | Responsibility |
|------|---------------|
| `game_kit/ui/components/skill_tree/base_upgrade.gd` | Base Resource: id, display_name, description, icon |
| `game_kit/ui/components/skill_tree/skill_tree_node_placement.gd` | Resource: upgrade ref + grid position + children |
| `game_kit/ui/components/skill_tree/skill_tree_layout.gd` | Resource: array of placements + root + cell_size |
| `game_kit/ui/components/skill_tree/skill_tree_node.gd` | Runtime: single node Control (diamond + icon + states) |
| `game_kit/ui/components/skill_tree/skill_tree_node.tscn` | Scene for SkillTreeNode |
| `game_kit/ui/components/skill_tree/skill_tree_tooltip.gd` | Tooltip PanelContainer (name, desc, icon) |
| `game_kit/ui/components/skill_tree/skill_tree_tooltip.tscn` | Scene for tooltip |
| `game_kit/ui/components/skill_tree/skill_tree_view.gd` | Runtime: renders tree, pan, manages nodes, emits signals |
| `game_kit/ui/components/skill_tree/skill_tree_view.tscn` | Scene for SkillTreeView |
| `game_kit/ui/components/skill_tree/skill_tree_editor.gd` | @tool: palette + grid editor, saves to layout resource |
| `game_kit/ui/components/skill_tree/skill_tree_editor.tscn` | Scene for editor |

### Modified files

| File | Change |
|------|--------|
| `game_data/upgrade_tree/upgrade_tree.gd` | Change `extends BaseGameData` → `extends BaseUpgrade`, remove duplicated fields |

### Files to delete after migration

| File | Reason |
|------|--------|
| `components/upgrade_tree/upgrade_tree_view.gd` | Replaced by `skill_tree_view.gd` |
| `components/upgrade_tree/upgrade_tree_view.tscn` | Replaced by `skill_tree_view.tscn` |
| `components/upgrade_tree/upgrade_tree_node.gd` | Replaced by `skill_tree_node.gd` |
| `components/upgrade_tree/upgrade_tree_node.tscn` | Replaced by `skill_tree_node.tscn` |

---

## Task 1: Resource layer — BaseUpgrade, SkillTreeNodePlacement, SkillTreeLayout

**Files:**
- Create: `game_kit/ui/components/skill_tree/base_upgrade.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_node_placement.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_layout.gd`

- [ ] **Step 1: Create BaseUpgrade resource**

```gdscript
# game_kit/ui/components/skill_tree/base_upgrade.gd
class_name BaseUpgrade extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
```

- [ ] **Step 2: Create SkillTreeNodePlacement resource**

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_node_placement.gd
class_name SkillTreeNodePlacement extends Resource

@export var upgrade: BaseUpgrade
@export var grid_x: int = 0
@export var grid_y: int = 0
@export var children: Array[SkillTreeNodePlacement] = []
```

- [ ] **Step 3: Create SkillTreeLayout resource**

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_layout.gd
class_name SkillTreeLayout extends Resource

@export var nodes: Array[SkillTreeNodePlacement] = []
@export var root: SkillTreeNodePlacement
@export var cell_size: int = 80
```

- [ ] **Step 4: Commit**

```bash
git add game_kit/ui/components/skill_tree/base_upgrade.gd \
       game_kit/ui/components/skill_tree/skill_tree_node_placement.gd \
       game_kit/ui/components/skill_tree/skill_tree_layout.gd
git commit -m "feat: add skill tree resource types (BaseUpgrade, NodePlacement, Layout)"
```

---

## Task 2: Migrate UpgradeTree to extend BaseUpgrade

**Files:**
- Modify: `game_data/upgrade_tree/upgrade_tree.gd`

**Context:** Current `UpgradeTree` extends `BaseGameData` which only has `id: String`. It also declares its own `display_name`, `description`, `icon`. After migration it extends `BaseUpgrade` which already has all four fields.

- [ ] **Step 1: Update UpgradeTree**

Change `game_data/upgrade_tree/upgrade_tree.gd` from:

```gdscript
class_name UpgradeTree extends BaseGameData

@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var prerequisites: Array[UpgradeTree] = []
```

To:

```gdscript
class_name UpgradeTree extends BaseUpgrade

@export var prerequisites: Array[UpgradeTree] = []
```

Fields `id`, `display_name`, `description`, `icon` are now inherited from `BaseUpgrade`.

- [ ] **Step 2: Verify DataRegistry compatibility**

`DataRegistry._find_game_data_in_path()` filters by `is BaseGameData`. Since `BaseUpgrade extends Resource` (not `BaseGameData`), `UpgradeTree` will no longer pass this check.

Update `autoloads/data_registry.gd`:

1. **Replace** the old upgrades line in `_ready()`. The full `_ready()` after edit:

```gdscript
func _ready() -> void:
	developers.merge(_find_game_data_in_path(DEVELOPER_PATH))
	upgrades.merge(_find_upgrades_in_path(UPGRADE_TREE_PATH))
	phases.merge(_find_game_data_in_path(PHASE_PATH))
```

Note: the old `upgrades.merge(_find_game_data_in_path(UPGRADE_TREE_PATH))` is **replaced**, not augmented.

2. Add new method to `data_registry.gd`:

```gdscript
func _find_upgrades_in_path(path: String) -> Dictionary[String, UpgradeTree]:
	var result: Dictionary[String, UpgradeTree] = {}
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		Log.log_warn(name, "Cannot open directory: %s" % path)
		return result
	Log.log_debug(name, "Scanning upgrades: %s" % path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(path.path_join(file_name))
			if res is UpgradeTree:
				var id: String = res.id
				if id.is_empty():
					Log.log_warn(name, "Empty id in %s/%s" % [path, file_name])
				elif id in result:
					Log.log_warn(name, "Duplicate id '%s' in %s/%s" % [id, path, file_name])
				else:
					result[id] = res
		file_name = dir.get_next()
	Log.log_info(name, "Found %d upgrades in %s: %s" % [result.size(), path, ", ".join(result.keys())])
	return result
```

- [ ] **Step 3: Run the project in Godot to verify no errors**

Open the project in Godot editor. Check Output panel for errors. `DataRegistry` should still load upgrades (currently 0 `.tres` files, so just verifying no crashes).

- [ ] **Step 4: Commit**

```bash
git add game_data/upgrade_tree/upgrade_tree.gd autoloads/data_registry.gd
git commit -m "refactor: migrate UpgradeTree to extend BaseUpgrade"
```

---

## Task 3: SkillTreeNode — single node visual (diamond + icon + states)

**Files:**
- Create: `game_kit/ui/components/skill_tree/skill_tree_node.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_node.tscn`

- [ ] **Step 1: Create SkillTreeNode script**

`NodeState` enum is defined in `SkillTreeNode` because `SkillTreeView` preloads the node scene (circular dependency if enum lived in View). Game code accesses it as `SkillTreeNode.NodeState` or through the `SkillTreeView` API which accepts `SkillTreeNode.NodeState` values.

```gdscript
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
```

- [ ] **Step 2: Create SkillTreeNode scene**

Create `skill_tree_node.tscn` with this structure:

```
SkillTreeNode (Control) [script: skill_tree_node.gd]
  custom_minimum_size = Vector2(64, 64)
  └── Diamond (Control) [rotation = 45 degrees, anchors centered]
       └── ColorRect [anchors full rect, color for background]
            └── IconRect (TextureRect) [unique name, anchors full rect, stretch_mode = keep_aspect_centered, rotation = -45 degrees to counter-rotate]
```

The diamond effect: a `Control` node rotated 45 degrees with a `ColorRect` background. The `IconRect` inside is counter-rotated -45 degrees so the icon stays upright.

Scene tree in `.tscn` format — create manually in Godot editor or write:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://game_kit/ui/components/skill_tree/skill_tree_node.gd" id="1_script"]

[node name="SkillTreeNode" type="Control"]
custom_minimum_size = Vector2(64, 64)
script = ExtResource("1_script")

[node name="Diamond" type="Control" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -24.0
offset_top = -24.0
offset_right = 24.0
offset_bottom = 24.0
rotation = 0.785398
pivot_offset = Vector2(24, 24)

[node name="Background" type="ColorRect" parent="Diamond"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.15, 0.15, 0.2, 1)

[node name="IconRect" type="TextureRect" parent="Diamond"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 4.0
offset_top = 4.0
offset_right = -4.0
offset_bottom = -4.0
rotation = -0.785398
pivot_offset = Vector2(20, 20)
expand_mode = 1
stretch_mode = 5
```

- [ ] **Step 3: Verify node renders in Godot**

Open `skill_tree_node.tscn` in Godot, assign a test texture to `IconRect` via inspector, verify diamond shape renders correctly with icon upright inside.

- [ ] **Step 4: Commit**

```bash
git add game_kit/ui/components/skill_tree/skill_tree_node.gd \
       game_kit/ui/components/skill_tree/skill_tree_node.tscn
git commit -m "feat: add SkillTreeNode — diamond node with icon and state visuals"
```

---

## Task 4: SkillTreeTooltip — popup panel for node info

**Files:**
- Create: `game_kit/ui/components/skill_tree/skill_tree_tooltip.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_tooltip.tscn`

- [ ] **Step 1: Create tooltip script**

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_tooltip.gd
class_name SkillTreeTooltip extends PanelContainer

@onready var icon_rect: TextureRect = %TooltipIcon
@onready var name_label: Label = %TooltipName
@onready var description_label: Label = %TooltipDescription


func show_upgrade(upgrade: BaseUpgrade) -> void:
	icon_rect.texture = upgrade.icon
	name_label.text = upgrade.display_name
	description_label.text = upgrade.description
	show()


func hide_tooltip() -> void:
	hide()
```

- [ ] **Step 2: Create tooltip scene**

```
SkillTreeTooltip (PanelContainer) [script: skill_tree_tooltip.gd]
  visible = false
  custom_minimum_size = Vector2(200, 0)
  └── MarginContainer
       └── VBoxContainer
            ├── HBoxContainer
            │    ├── TooltipIcon (TextureRect) [unique, custom_min_size 32x32, stretch keep_aspect_centered]
            │    └── TooltipName (Label) [unique, bold]
            └── TooltipDescription (Label) [unique, autowrap word_smart]
```

- [ ] **Step 3: Commit**

```bash
git add game_kit/ui/components/skill_tree/skill_tree_tooltip.gd \
       game_kit/ui/components/skill_tree/skill_tree_tooltip.tscn
git commit -m "feat: add SkillTreeTooltip — panel showing upgrade name, desc, icon"
```

---

## Task 5: SkillTreeView — runtime tree renderer with pan and lines

**Files:**
- Create: `game_kit/ui/components/skill_tree/skill_tree_view.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_view.tscn`

**Context:** This is the main runtime component. It reads `SkillTreeLayout`, instantiates `SkillTreeNode` for each placement, draws connection lines in `_draw()`, handles pan with right mouse button, and manages the tooltip. It exposes `set_node_state()` and signals for game code integration.

- [ ] **Step 1: Create SkillTreeView script**

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_view.gd
class_name SkillTreeView extends Control

const SKILL_TREE_NODE_SCENE: PackedScene = preload("res://game_kit/ui/components/skill_tree/skill_tree_node.tscn")
const SKILL_TREE_TOOLTIP_SCENE: PackedScene = preload("res://game_kit/ui/components/skill_tree/skill_tree_tooltip.tscn")

const LINE_COLOR_LOCKED: Color = Color(0.3, 0.3, 0.3)
const LINE_COLOR_UNLOCKED: Color = Color(0.0, 0.9, 0.9)
const LINE_WIDTH: float = 3.0

signal node_clicked(upgrade: BaseUpgrade)
signal node_hovered(upgrade: BaseUpgrade)
signal node_unhovered(upgrade: BaseUpgrade)

@export var layout: SkillTreeLayout

var _nodes: Dictionary[String, SkillTreeNode] = {}  # upgrade.id -> node
var _placements: Dictionary[String, SkillTreeNodePlacement] = {}  # upgrade.id -> placement
var _pan_offset: Vector2 = Vector2.ZERO
var _is_panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _tooltip: SkillTreeTooltip
var _nodes_container: Control


func _ready() -> void:
	clip_contents = true
	_nodes_container = Control.new()
	_nodes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nodes_container)
	_tooltip = SKILL_TREE_TOOLTIP_SCENE.instantiate()
	add_child(_tooltip)
	if layout:
		_build_tree()


func _build_tree() -> void:
	_clear_tree()
	var cell_size: int = layout.cell_size

	for placement: SkillTreeNodePlacement in layout.nodes:
		if not placement.upgrade:
			continue
		var node: SkillTreeNode = SKILL_TREE_NODE_SCENE.instantiate()
		node.setup(placement.upgrade)
		_nodes_container.add_child(node)
		node.position = Vector2(placement.grid_x * cell_size, placement.grid_y * cell_size)
		node.clicked.connect(_on_node_clicked)
		node.hovered.connect(_on_node_hovered)
		node.unhovered.connect(_on_node_unhovered)
		_nodes[placement.upgrade.id] = node
		_placements[placement.upgrade.id] = placement

	_center_on_root()
	Log.log_info(self.name, "Skill tree built: %d nodes" % _nodes.size())
	queue_redraw()


func _clear_tree() -> void:
	for node: SkillTreeNode in _nodes.values():
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


# --- State API ---

## Public API — game code uses these to control node states.
## NodeState enum is SkillTreeNode.NodeState (LOCKED=0, AVAILABLE=1, PURCHASED=2).

func set_node_state(upgrade_id: String, state: SkillTreeNode.NodeState) -> void:
	if _nodes.has(upgrade_id):
		_nodes[upgrade_id].set_state(state)
		Log.log_debug(self.name, "Node state changed: %s -> %s" % [upgrade_id, SkillTreeNode.NodeState.keys()[state]])
		queue_redraw()


func set_all_states(states: Dictionary) -> void:
	for upgrade_id: String in states:
		if _nodes.has(upgrade_id):
			_nodes[upgrade_id].set_state(states[upgrade_id])
	queue_redraw()


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
			# L-shaped routing: horizontal first, then vertical
			var mid: Vector2 = Vector2(to_pos.x, from_pos.y)
			draw_line(from_pos, mid, color, LINE_WIDTH, true)
			draw_line(mid, to_pos, color, LINE_WIDTH, true)


func _get_line_color(parent: SkillTreeNodePlacement, child: SkillTreeNodePlacement) -> Color:
	var parent_node: SkillTreeNode = _nodes.get(parent.upgrade.id)
	var child_node: SkillTreeNode = _nodes.get(child.upgrade.id)
	if parent_node and child_node:
		if parent_node.state == SkillTreeNode.NodeState.PURCHASED and child_node.state == SkillTreeNode.NodeState.PURCHASED:
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
	Log.log_debug(self.name, "Node clicked: %s" % upgrade.display_name)
	_show_tooltip(upgrade)
	node_clicked.emit(upgrade)


func _on_node_hovered(upgrade: BaseUpgrade) -> void:
	node_hovered.emit(upgrade)


func _on_node_unhovered(upgrade: BaseUpgrade) -> void:
	node_unhovered.emit(upgrade)


func _show_tooltip(upgrade: BaseUpgrade) -> void:
	if not _nodes.has(upgrade.id):
		return
	var node: SkillTreeNode = _nodes[upgrade.id]
	_tooltip.show_upgrade(upgrade)

	# Position tooltip above the node
	await get_tree().process_frame
	var node_global_pos: Vector2 = node.global_position
	var tooltip_pos: Vector2 = Vector2(
		node_global_pos.x - _tooltip.size.x / 2.0 + node.size.x / 2.0,
		node_global_pos.y - _tooltip.size.y - 8.0
	)
	# Clamp to viewport
	var viewport_size: Vector2 = get_viewport_rect().size
	tooltip_pos.x = clampf(tooltip_pos.x, 0.0, viewport_size.x - _tooltip.size.x)
	if tooltip_pos.y < 0.0:
		tooltip_pos.y = node_global_pos.y + node.size.y + 8.0
	_tooltip.global_position = tooltip_pos


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_tooltip.hide_tooltip()
```

- [ ] **Step 2: Create SkillTreeView scene**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://game_kit/ui/components/skill_tree/skill_tree_view.gd" id="1_script"]

[node name="SkillTreeView" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
clip_contents = true
script = ExtResource("1_script")
```

- [ ] **Step 3: Manual test in Godot**

1. Create a test scene with `SkillTreeView` as root
2. Create 3 test `BaseUpgrade` resources: `test_a.tres`, `test_b.tres`, `test_c.tres` (with placeholder icons)
3. Create a `SkillTreeLayout` resource with 3 placements: A at (0,0), B at (1,0), C at (0,1), A has children [B, C]
4. Assign layout to the view, run scene
5. Verify: 3 diamond nodes render, L-shaped lines drawn, pan works with right-click, tooltip shows on click, tooltip hides on click elsewhere

- [ ] **Step 4: Commit**

```bash
git add game_kit/ui/components/skill_tree/skill_tree_view.gd \
       game_kit/ui/components/skill_tree/skill_tree_view.tscn
git commit -m "feat: add SkillTreeView — runtime tree renderer with pan, lines, tooltips"
```

---

## Task 6: SkillTreeEditor — @tool grid editor with palette

**Files:**
- Create: `game_kit/ui/components/skill_tree/skill_tree_editor.gd`
- Create: `game_kit/ui/components/skill_tree/skill_tree_editor.tscn`

**Context:** This is the `@tool` editor component. It has a left palette listing all `BaseUpgrade` resources from a folder, and a right grid where the designer places nodes. All changes are saved to the `SkillTreeLayout` resource with debounced auto-save.

- [ ] **Step 1: Create SkillTreeEditor script**

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_editor.gd
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
				var name: String = placement.upgrade.display_name if placement.upgrade else "unknown"
				warnings.append("Node not reachable from root: %s" % name)

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
```

- [ ] **Step 2: Create SkillTreeEditor scene**

Scene structure:

```
SkillTreeEditor (Control) [script: skill_tree_editor.gd]
  anchors_preset = 15 (full rect)
  └── HSplitContainer [full rect]
       ├── PaletteList (ItemList) [unique name, custom_min_size.x = 200]
       └── GridPanel (Control) [unique name]
```

Connect signals:
- `PaletteList.item_selected` → `_on_palette_item_selected`
- `GridPanel.draw` → `_on_grid_draw`
- `GridPanel.gui_input` → `_on_grid_gui_input`

- [ ] **Step 3: Manual test in Godot editor**

1. Create a new scene, add `SkillTreeEditor` as root
2. Create an empty `SkillTreeLayout` resource and assign to `layout`
3. Set `upgrades_path` to `"res://game_data/upgrade_tree"`
4. Create 2-3 test `UpgradeTree` `.tres` files with ids, names, icons
5. Open the editor scene — palette should list upgrades
6. Click upgrade in palette, click grid cell — node should appear
7. Right-click one node, then left-click another — connection should appear
8. Delete key removes selected node
9. Close and reopen scene — layout should persist

- [ ] **Step 4: Commit**

```bash
git add game_kit/ui/components/skill_tree/skill_tree_editor.gd \
       game_kit/ui/components/skill_tree/skill_tree_editor.tscn
git commit -m "feat: add SkillTreeEditor — @tool grid editor with palette and connections"
```

**Deferred features** (not in scope for this task, can add later):
- Drag-to-move already placed nodes on the grid (currently must delete + re-place)
- Validation warning display in UI (method `_validate_layout()` exists but is not wired to UI)
- Editor grid pan/offset for working with negative grid coordinates

---

## Task 7: Delete old upgrade_tree components

**Files:**
- Delete: `components/upgrade_tree/upgrade_tree_view.gd`
- Delete: `components/upgrade_tree/upgrade_tree_view.tscn`
- Delete: `components/upgrade_tree/upgrade_tree_node.gd`
- Delete: `components/upgrade_tree/upgrade_tree_node.tscn`
- Delete: `components/upgrade_tree/` (directory and .uid files)

**Context:** These are replaced by the new `game_kit/ui/components/skill_tree/` components. No `.tres` files or scenes reference them (verified — no matches for `upgrade_tree` in `.tscn` or `.tres` files).

- [ ] **Step 1: Verify no references exist**

```bash
grep -r "upgrade_tree_view\|upgrade_tree_node\|UpgradeTreeView\|UpgradeTreeNode" --include="*.gd" --include="*.tscn" --include="*.tres" . | grep -v "components/upgrade_tree/"
```

Expected: no output (no references outside the directory itself). If references found, update them first.

- [ ] **Step 2: Delete files**

```bash
rm -rf components/upgrade_tree/
```

- [ ] **Step 3: Commit**

```bash
git add -A components/upgrade_tree/
git commit -m "chore: remove old upgrade_tree components, replaced by game_kit skill_tree"
```

---

## Task 8: Integration smoke test

**Files:**
- No new files. Manual verification.

- [ ] **Step 1: Create test upgrade resources**

Create 5 `UpgradeTree` `.tres` files in `game_data/upgrade_tree/` via Godot inspector:
- `leadership.tres` (id: "leadership", display_name: "Leadership")
- `fast_features.tres` (id: "fast_features", display_name: "Fast Features")
- `bug_hunter.tres` (id: "bug_hunter", display_name: "Bug Hunter")
- `refactor_guru.tres` (id: "refactor_guru", display_name: "Refactor Guru")
- `budget_boost.tres` (id: "budget_boost", display_name: "Budget Boost")

Give them placeholder icons and descriptions.

- [ ] **Step 2: Build layout with editor**

1. Open `SkillTreeEditor` scene in Godot editor
2. Create `SkillTreeLayout` resource, assign to editor
3. Set `upgrades_path` to `"res://game_data/upgrade_tree"`
4. Place "Leadership" at center, connect to "Fast Features" and "Bug Hunter"
5. Connect "Bug Hunter" to "Refactor Guru", "Fast Features" to "Budget Boost"
6. Save layout as `game_data/upgrade_tree/main_tree_layout.tres`

- [ ] **Step 3: Test runtime view**

1. Create a test scene with `SkillTreeView`
2. Assign the layout created in step 2
3. Run the scene
4. Verify: nodes render as diamonds, lines drawn, pan works, tooltip shows on click
5. Test `set_node_state()` from a test script — change a node to PURCHASED, verify visual change and line color update

- [ ] **Step 4: Commit test resources**

```bash
git add game_data/upgrade_tree/
git commit -m "feat: add test upgrade resources and skill tree layout"
```
