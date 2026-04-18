# Stats Panel Clarity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the opaque 7-percent stats panel in the upgrade dialog with a 3-column view of concrete gameplay values (damage multipliers, auto-click interval, sprint task counts), plus a two-tap select-then-Take flow that previews stat changes before confirming.

**Architecture:** One new pure function `Balance.get_display_stats(stats, level)` produces the rendering data reusing existing balance formulas. One new widget `StatRow` renders a single labeled stat line with three modes: plain / dimmed / diff. Three columns with pre-placed StatRow instances are assembled directly in `ui_upgrade_choice.tscn`. `ui_upgrade_choice.gd` owns value formatting and the select-then-Take flow.

**Tech Stack:** Godot 4, GDScript

**Spec:** `docs/superpowers/specs/2026-04-18-stats-panel-clarity-design.md`

**User rule:** Do not run `git commit` during plan execution. The final task asks the user to review and commit manually.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `globals/balance.gd` | Modify | Add `get_display_stats(stats, level)` pure function |
| `components/ui/ui_upgrade_choice/stat_row.gd` | Create | Single-row widget script: `show_plain` / `show_dimmed` / `show_diff` |
| `components/ui/ui_upgrade_choice/stat_row.tscn` | Create | Single-row widget scene |
| `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn` | Modify | Replace StatsGrid with 3 columns of pre-placed StatRow instances; add Take button |
| `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd` | Modify | Value formatting + two-tap flow + preview diff rendering |
| `components/ui/ui_upgrade_choice/upgrade_card.gd` | Modify | Add `selected` state, replace `chosen`-on-click with `selected_changed` |
| `components/ui/ui_upgrade_choice/stat_summary_item.gd` | Delete | Obsolete |
| `components/ui/ui_upgrade_choice/stat_summary_item.tscn` | Delete | Obsolete |

---

### Task 1: Add `Balance.get_display_stats`

Produce a single source of truth for what the panel renders, reusing the balance formulas already used in combat. Keeping this as a pure function on `Balance` means the UI and the game stay in lockstep — if a formula changes, the display changes automatically.

**Files:**
- Modify: `globals/balance.gd` (append new function at the end, before `_get_stat`)

- [ ] **Step 1: Add the function**

In `globals/balance.gd`, add this function just before `_get_stat` (around line 115). The docstring lists the exact keys the UI expects.

```gdscript
## Compute display-ready values for the upgrade dialog stats panel.
## Returned structure (all floats except where noted):
##   damage.features / damage.refactor — full effective multiplier per task type
##   click.dev_speed_per_stack         — 1 + BASE_BOOST_SPEED + boost_speed, as a multiplier
##   click.auto_click_interval         — seconds; 0.0 means auto click is OFF
##   sprint.size / sprint.features / sprint.refactoring — ints; sum equals sprint.size
static func get_display_stats(stats: Dictionary, player_level: int) -> Dictionary:
	var global_dmg: float = 1.0 + _get_stat(Constants.STAT_GLOBAL_DAMAGE, stats)
	var feature_dmg: float = 1.0 + _get_stat(Constants.STAT_FEATURE_DAMAGE, stats)
	var refactoring_dmg: float = 1.0 + _get_stat(Constants.STAT_REFACTORING_DAMAGE, stats)

	var per_stack: float = 1.0 + Constants.BASE_BOOST_SPEED + _get_stat(Constants.STAT_BOOST_SPEED, stats)
	var auto_interval: float = calculate_auto_click_interval(stats)

	var weights: Dictionary = calculate_task_type_weights(stats)
	var sprint_size: int = _get_sprint_size_for_level(player_level)
	var feature_count: int = roundi(sprint_size * (weights[Constants.TaskType.FEATURE] as float))
	var refactoring_count: int = sprint_size - feature_count

	return {
		"damage": {
			"features": global_dmg * feature_dmg,
			"refactor": global_dmg * refactoring_dmg,
		},
		"click": {
			"dev_speed_per_stack": per_stack,
			"auto_click_interval": auto_interval,
		},
		"sprint": {
			"size": sprint_size,
			"features": feature_count,
			"refactoring": refactoring_count,
		},
	}


## Mirror of PlayerData._get_sprint_size, but taking a level arg so Balance stays stateless.
static func _get_sprint_size_for_level(player_level: int) -> int:
	var result: int = Constants.SPRINT_SIZES[0]["size"]
	for bracket: Dictionary in Constants.SPRINT_SIZES:
		if player_level >= bracket["min_level"]:
			result = bracket["size"]
	return result
```

- [ ] **Step 2: Verify the function compiles and produces sensible baseline values**

Open the Godot editor, open `project.godot`, and in the FileSystem dock double-click `globals/balance.gd`. If the file loads without red error banners in the Output panel, the function parses.

Quick sanity check via the Godot remote inspector or a temporary `print` call (revert before Task 2):
- Expected at `get_display_stats({}, 1)` → `damage.features == 1.0`, `damage.refactor == 1.0`, `click.dev_speed_per_stack == 2.5` (1 + 1.5 BASE_BOOST_SPEED), `click.auto_click_interval == 0.0`, `sprint.size == 2`, `sprint.features == 1`, `sprint.refactoring == 1`.

---

### Task 2: Create the `StatRow` widget scene

A deliberately dumb renderer. It knows nothing about stats — it just switches between three visual states. All formatting is pushed to the caller so this widget is reusable if the panel grows.

**Files:**
- Create: `components/ui/ui_upgrade_choice/stat_row.gd`
- Create: `components/ui/ui_upgrade_choice/stat_row.tscn`

- [ ] **Step 1: Create the script**

Write `components/ui/ui_upgrade_choice/stat_row.gd`:

```gdscript
class_name StatRow
extends Control

# --- Constants ---

const DIMMED_MODULATE: Color = Color(1, 1, 1, 0.45)
const NORMAL_MODULATE: Color = Color(1, 1, 1, 1)

# --- @onready ---

@onready var label: Label = %LabelText
@onready var value: Label = %ValueText
@onready var arrow: Label = %ArrowText
@onready var preview: Label = %PreviewText
@onready var delta: Label = %DeltaText

# --- Public ---

func show_plain(label_text: String, value_text: String) -> void:
	self.modulate = NORMAL_MODULATE
	label.text = label_text
	value.text = value_text
	arrow.visible = false
	preview.visible = false
	delta.visible = false


func show_dimmed(label_text: String, value_text: String) -> void:
	self.modulate = DIMMED_MODULATE
	label.text = label_text
	value.text = value_text
	arrow.visible = false
	preview.visible = false
	delta.visible = false


func show_diff(label_text: String, current_text: String, preview_text: String, delta_text: String, positive: bool) -> void:
	self.modulate = NORMAL_MODULATE
	label.text = label_text
	value.text = current_text
	arrow.text = "→"
	arrow.visible = true
	preview.text = preview_text
	preview.visible = true
	delta.text = delta_text
	delta.visible = true
	var color: Color = ThemeTokens.STAT_POSITIVE if positive else ThemeTokens.STAT_NEGATIVE
	delta.add_theme_color_override("font_color", color)
	preview.add_theme_color_override("font_color", color)
```

- [ ] **Step 2: Create the scene**

Open Godot editor → FileSystem → right-click `components/ui/ui_upgrade_choice/` → New Scene... Save as `stat_row.tscn`.

Scene structure (match existing UI patterns — `stat_summary_item.tscn` is a decent reference for margins/colors):

```
StatRow (Control)  — root, script attached
  MarginContainer
    HBoxContainer
      LabelText   (Label, unique_name_in_owner, size_flags_horizontal = FILL + EXPAND, text = "Stat")
      ValueText   (Label, unique_name_in_owner, horizontal_alignment = Right, text = "×1.00")
      ArrowText   (Label, unique_name_in_owner, text = "→", visible = false)
      PreviewText (Label, unique_name_in_owner, text = "×1.10", visible = false)
      DeltaText   (Label, unique_name_in_owner, text = "(+10%)", visible = false)
```

Set margins on the `MarginContainer` (left/right 8, top/bottom 4) to match existing `stat_summary_item.tscn` spacing. Set HBoxContainer `theme_override_constants/separation = 6` so arrow/preview/delta don't collide visually. Attach the `stat_row.gd` script to the root.

- [ ] **Step 3: Verify the scene opens cleanly**

In Godot, double-click `stat_row.tscn` in FileSystem. The scene should open without errors. Press Play Scene (F6) briefly — you should see "Stat" and "×1.00" laid out in a horizontal row. Close the preview.

---

### Task 3: Restructure `ui_upgrade_choice.tscn` — three columns + Take button

Strip `StatsGrid` and "Current Stats" label, replace with three named columns. Each column gets a header label and two pre-placed `StatRow` instances. Names are important — `ui_upgrade_choice.gd` will grab rows via `%UniqueName` in Task 4.

**Files:**
- Modify: `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn`

- [ ] **Step 1: Remove obsolete nodes**

Open `ui_upgrade_choice.tscn` in the Godot editor. In the Scene dock:
- Delete `StatsSectionLabel`
- Delete `StatsGrid`

- [ ] **Step 2: Add the StatsPanel HBoxContainer**

Inside the VBoxContainer (the one that currently holds `TitleLabel`, `CardContainer`, `RerollButton`), add a new `HBoxContainer` named `StatsPanel`. Put it **below** `RerollButton`. Set:
- `custom_minimum_size = Vector2(0, 160)`
- `size_flags_horizontal = FILL + EXPAND`
- `theme_override_constants/separation = 24`
- `alignment = Center`

- [ ] **Step 3: Add the three column VBoxes**

As children of `StatsPanel`, add three `VBoxContainer`s in order:
- `DamageColumn` (size_flags_horizontal = FILL + EXPAND)
- `ClickColumn` (size_flags_horizontal = FILL + EXPAND)
- `SprintColumn` (size_flags_horizontal = FILL + EXPAND)

Each column gets `theme_override_constants/separation = 4`.

- [ ] **Step 4: Add column headers**

Each column's first child is a `Label`:
- `DamageColumn/HeaderLabel` — text `⚔ DAMAGE`, `theme_type_variation = &"LabelH3"`, `horizontal_alignment = Center`
- `ClickColumn/HeaderLabel` — text `⚡ CLICK BOOST`, `theme_type_variation = &"LabelH3"`, `horizontal_alignment = Center`
- `SprintColumn/HeaderLabel` — text `📋 SPRINT TASKS`, `theme_type_variation = &"LabelH3"`, `horizontal_alignment = Center`

- [ ] **Step 5: Add the six StatRow instances**

Instance `stat_row.tscn` as children of the columns in this order (use FileSystem → drag `stat_row.tscn` into the column node, or Scene dock → Instance Child Scene). Set each instance's `unique_name_in_owner = true` and rename as listed:

`DamageColumn` children after the header:
- `RowDamageFeatures`
- `RowDamageRefactor`

`ClickColumn` children after the header:
- `RowClickPerStack`
- `RowClickAuto`

`SprintColumn` children after the header:
- `RowSprintFeatures`
- `RowSprintRefactor`

Each instance inherits the scene — no further edits needed on individual instances.

- [ ] **Step 6: Add the Take button**

Below `StatsPanel` (still inside the same VBoxContainer, last child), add a `Button`:
- Name: `TakeButton`
- `unique_name_in_owner = true`
- `text = "Take"`
- `custom_minimum_size = Vector2(200, 0)`
- `size_flags_horizontal = SIZE_SHRINK_CENTER`
- `disabled = true`

Save the scene.

- [ ] **Step 7: Verify the scene opens and has no missing refs**

Press F5 to run the game. Trigger the upgrade dialog (level up a couple of sprints). The dialog should open; you'll see placeholder row text ("Stat" / "×1.00") in each column, the reroll button, and a disabled "Take" button. **Clicking cards will currently still apply the upgrade** — that behaviour changes in Task 5. Don't worry about it here; just confirm the layout renders without errors in the Output panel.

---

### Task 4: Render plain stats via `Balance.get_display_stats`

Replace the current `_build_stats_summary` code with the new formatter-driven rendering. This task only covers the **plain** (no-preview) view. Preview diffing comes in Task 6.

**Files:**
- Modify: `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd`

- [ ] **Step 1: Rewrite the script top-to-bottom**

Replace the entire contents of `ui_upgrade_choice.gd` with:

```gdscript
class_name UiUpgradeChoice
extends BaseDialog

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel
@onready var reroll_button: Button = %RerollButton
@onready var take_button: Button = %TakeButton

@onready var row_damage_features: StatRow = %RowDamageFeatures
@onready var row_damage_refactor: StatRow = %RowDamageRefactor
@onready var row_click_per_stack: StatRow = %RowClickPerStack
@onready var row_click_auto: StatRow = %RowClickAuto
@onready var row_sprint_features: StatRow = %RowSprintFeatures
@onready var row_sprint_refactor: StatRow = %RowSprintRefactor

# --- State ---

var _reroll_used: bool = false

# --- Lifecycle ---

func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	take_button.pressed.connect(_on_take_pressed)

# --- Public ---

func set_data(data: Dictionary) -> void:
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_render_plain(PD.total_stats, PD.level)

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.chosen.connect(_on_upgrade_chosen)
		card_container.add_child(card)


func _render_plain(stats: Dictionary, level: int) -> void:
	var d: Dictionary = Balance.get_display_stats(stats, level)
	row_damage_features.show_plain("Features:", _fmt_mult(d["damage"]["features"]))
	row_damage_refactor.show_plain("Refactor:", _fmt_mult(d["damage"]["refactor"]))
	row_click_per_stack.show_plain("Dev Speed Per Stack:", _fmt_mult(d["click"]["dev_speed_per_stack"]))
	row_click_auto.show_plain("Auto click:", _fmt_interval(d["click"]["auto_click_interval"]))
	row_sprint_features.show_plain("Features:", _fmt_count(d["sprint"]["features"], d["sprint"]["size"]))
	row_sprint_refactor.show_plain("Refactoring:", _fmt_count(d["sprint"]["refactoring"], d["sprint"]["size"]))


func _fmt_mult(value: float) -> String:
	return "×%.2f" % value


func _fmt_interval(seconds: float) -> String:
	if is_zero_approx(seconds):
		return "Off"
	return "%.1fs" % seconds


func _fmt_count(count: int, total: int) -> String:
	return "%d/%d" % [count, total]

# --- Handlers ---

func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	close_dialog({"upgrade": upgrade})


func _on_take_pressed() -> void:
	# Filled in Task 6 — does nothing useful yet, button stays disabled.
	pass


func _on_reroll_pressed() -> void:
	if _reroll_used:
		return
	_reroll_used = true
	reroll_button.disabled = true
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_render_plain(PD.total_stats, PD.level)
	Log.log_info(self.name, "Upgrade choices rerolled")
```

- [ ] **Step 2: Verify plain rendering in-game**

Run the game (F5), level up, open the upgrade dialog. Verify:
- Damage column shows `Features: ×1.00` and `Refactor: ×1.00` at zero upgrades (or the correct multipliers if the save already has some upgrades).
- Click Boost column shows `Dev Speed Per Stack: ×2.50` and `Auto click: Off` at zero upgrades.
- Sprint Tasks column shows counts that sum to the current sprint size (e.g. `Features: 1/2, Refactoring: 1/2` at level 1).
- No errors in the Output panel.
- Clicking a card still immediately applies the upgrade (the old `chosen` signal path still fires). This is expected until Task 5.

---

### Task 5: Add `selected` state to `UpgradeCard`

Stop cards from emitting `chosen` on click. Instead emit `selected_changed(self, true)`. The dialog takes over: it enforces single-selection, tracks which card is selected, and decides when `chosen` fires (via the Take button or a second click on the same card).

**Files:**
- Modify: `components/ui/ui_upgrade_choice/upgrade_card.gd`

- [ ] **Step 1: Rewrite card script**

Replace the contents of `components/ui/ui_upgrade_choice/upgrade_card.gd` with:

```gdscript
class_name UpgradeCard
extends Control

# --- Constants ---
const STAT_MODIFIER: PackedScene = preload("res://components/ui/ui_sprint_panel/stat_modifier.tscn")

const RARITY_VARIATIONS: Dictionary = {
	Constants.UpgradeRarity.COMMON: &"PanelContainerRarityCommon",
	Constants.UpgradeRarity.UNCOMMON: &"PanelContainerRarityUncommon",
	Constants.UpgradeRarity.EPIC: &"PanelContainerRarityEpic",
	Constants.UpgradeRarity.LEGENDARY: &"PanelContainerRarityLegendary",
}

const RARITY_HOVER_VARIATIONS: Dictionary = {
	Constants.UpgradeRarity.COMMON: &"PanelContainerRarityCommonHover",
	Constants.UpgradeRarity.UNCOMMON: &"PanelContainerRarityUncommonHover",
	Constants.UpgradeRarity.EPIC: &"PanelContainerRarityEpicHover",
	Constants.UpgradeRarity.LEGENDARY: &"PanelContainerRarityLegendaryHover",
}

# --- Signals ---

signal chosen(upgrade: UpgradeData)
signal selected_changed(card: UpgradeCard, is_selected: bool)

# --- @onready ---

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stats_container: VBoxContainer = %Stats
@onready var upgrade_rarity_panel: PanelContainer = %UpgradeRarity

# --- State ---

var upgrade: UpgradeData
var is_selected: bool = false

# --- Public ---

func setup(new_upgrade: UpgradeData) -> void:
	upgrade = new_upgrade


func set_selected(value: bool) -> void:
	if is_selected == value:
		return
	is_selected = value
	_apply_rarity_variation()

# --- Lifecycle ---

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not upgrade:
		return
	if upgrade.icon:
		icon_rect.texture = upgrade.icon
	name_label.text = upgrade.display_name
	description_label.text = upgrade.description
	_populate_stats()
	_apply_rarity_variation()

# --- Handlers ---

func _on_mouse_entered() -> void:
	if is_selected:
		return
	if upgrade and upgrade.rarity in RARITY_HOVER_VARIATIONS:
		upgrade_rarity_panel.theme_type_variation = RARITY_HOVER_VARIATIONS[upgrade.rarity]


func _on_mouse_exited() -> void:
	if is_selected:
		return
	if upgrade and upgrade.rarity in RARITY_VARIATIONS:
		upgrade_rarity_panel.theme_type_variation = RARITY_VARIATIONS[upgrade.rarity]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_changed.emit(self, true)

# --- Private ---

func _apply_rarity_variation() -> void:
	if not upgrade:
		return
	var variations: Dictionary = RARITY_HOVER_VARIATIONS if is_selected else RARITY_VARIATIONS
	if upgrade.rarity in variations:
		upgrade_rarity_panel.theme_type_variation = variations[upgrade.rarity]


func _populate_stats() -> void:
	for field: String in Constants.STAT_ORDER:
		var value: float = upgrade.get(field)
		if not is_zero_approx(value):
			var stat_row: StatModifier = STAT_MODIFIER.instantiate()
			stat_row.setup(Constants.STAT_DISPLAY_NAMES[field], value)
			stats_container.add_child(stat_row)
```

Key changes from the original:
- The private `_upgrade` became a public `upgrade` so the dialog can reach `card.upgrade.get(field)` for preview computation.
- `chosen` signal stays for back-compat but is no longer emitted automatically.
- Click now emits `selected_changed(self, true)` instead of `chosen`.
- New `is_selected` state + `set_selected(value)` method; when selected, the card uses the hover rarity variation as visual feedback and stays there regardless of mouse position.

- [ ] **Step 2: Verify card compiles**

Reload the project in Godot (`Project → Reload Current Project`). Open `upgrade_card.gd` — no red errors in Output. The upgrade dialog may briefly still function via the old `chosen` connection from `ui_upgrade_choice.gd` (that connection exists but will never fire now because `_gui_input` no longer emits `chosen`). Leaving it in place means no visual regression during Task 5; it gets cleaned up in Task 6.

---

### Task 6: Wire the two-tap flow + preview diff

This is the big one. Card click → panel shows preview diff → Take button activates. Second click on the same card = take. Reroll clears selection.

**Files:**
- Modify: `components/ui/ui_upgrade_choice/ui_upgrade_choice.gd`

- [ ] **Step 1: Replace the script contents in full**

Final version of `ui_upgrade_choice.gd`:

```gdscript
class_name UiUpgradeChoice
extends BaseDialog

const UPGRADE_CARD: PackedScene = preload("res://components/ui/ui_upgrade_choice/upgrade_card.tscn")

# --- @onready ---

@onready var card_container: HBoxContainer = %CardContainer
@onready var title_label: Label = %TitleLabel
@onready var reroll_button: Button = %RerollButton
@onready var take_button: Button = %TakeButton

@onready var row_damage_features: StatRow = %RowDamageFeatures
@onready var row_damage_refactor: StatRow = %RowDamageRefactor
@onready var row_click_per_stack: StatRow = %RowClickPerStack
@onready var row_click_auto: StatRow = %RowClickAuto
@onready var row_sprint_features: StatRow = %RowSprintFeatures
@onready var row_sprint_refactor: StatRow = %RowSprintRefactor

# --- State ---

var _reroll_used: bool = false
var _selected_card: UpgradeCard = null

# --- Lifecycle ---

func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	take_button.pressed.connect(_on_take_pressed)
	take_button.disabled = true

# --- Public ---

func set_data(data: Dictionary) -> void:
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_render_plain(PD.total_stats, PD.level)

# --- Handlers ---

func _on_card_selected(card: UpgradeCard, _is_selected: bool) -> void:
	# Second click on the already-selected card = confirm (mouse-power-user shortcut).
	if _selected_card == card:
		_confirm(card.upgrade)
		return
	# First click, or switching selection.
	if _selected_card != null:
		_selected_card.set_selected(false)
	_selected_card = card
	card.set_selected(true)
	take_button.disabled = false
	var preview_stats: Dictionary = _compute_preview_stats(PD.total_stats, card.upgrade)
	_render_preview(PD.total_stats, preview_stats, PD.level)


func _on_take_pressed() -> void:
	if _selected_card == null:
		return
	_confirm(_selected_card.upgrade)


func _on_reroll_pressed() -> void:
	if _reroll_used:
		return
	_reroll_used = true
	reroll_button.disabled = true
	var upgrades: Array[UpgradeData] = PD.get_level_up_upgrades()
	_build_cards(upgrades)
	_selected_card = null
	take_button.disabled = true
	_render_plain(PD.total_stats, PD.level)
	Log.log_info(self.name, "Upgrade choices rerolled")

# --- Private ---

func _build_cards(upgrades: Array[UpgradeData]) -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
	for upgrade: UpgradeData in upgrades:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.setup(upgrade)
		card.selected_changed.connect(_on_card_selected)
		card_container.add_child(card)


func _confirm(upgrade: UpgradeData) -> void:
	close_dialog({"upgrade": upgrade})


func _compute_preview_stats(current: Dictionary, upgrade: UpgradeData) -> Dictionary:
	var result: Dictionary = {}
	for field: String in Constants.STAT_ORDER:
		var base: float = current.get(field, 0.0) as float
		var delta: float = upgrade.get(field) as float
		result[field] = base + delta
	return result


func _render_plain(stats: Dictionary, level: int) -> void:
	var d: Dictionary = Balance.get_display_stats(stats, level)
	row_damage_features.show_plain("Features:", _fmt_mult(d["damage"]["features"]))
	row_damage_refactor.show_plain("Refactor:", _fmt_mult(d["damage"]["refactor"]))
	row_click_per_stack.show_plain("Dev Speed Per Stack:", _fmt_mult(d["click"]["dev_speed_per_stack"]))
	row_click_auto.show_plain("Auto click:", _fmt_interval(d["click"]["auto_click_interval"]))
	row_sprint_features.show_plain("Features:", _fmt_count(d["sprint"]["features"], d["sprint"]["size"]))
	row_sprint_refactor.show_plain("Refactoring:", _fmt_count(d["sprint"]["refactoring"], d["sprint"]["size"]))


func _render_preview(current_stats: Dictionary, preview_stats: Dictionary, level: int) -> void:
	var cur: Dictionary = Balance.get_display_stats(current_stats, level)
	var prv: Dictionary = Balance.get_display_stats(preview_stats, level)
	_render_mult_row(row_damage_features, "Features:", cur["damage"]["features"], prv["damage"]["features"])
	_render_mult_row(row_damage_refactor, "Refactor:", cur["damage"]["refactor"], prv["damage"]["refactor"])
	_render_mult_row(row_click_per_stack, "Dev Speed Per Stack:", cur["click"]["dev_speed_per_stack"], prv["click"]["dev_speed_per_stack"])
	_render_interval_row(row_click_auto, "Auto click:", cur["click"]["auto_click_interval"], prv["click"]["auto_click_interval"])
	_render_count_row(row_sprint_features, "Features:", cur["sprint"]["features"], prv["sprint"]["features"], cur["sprint"]["size"], prv["sprint"]["size"])
	_render_count_row(row_sprint_refactor, "Refactoring:", cur["sprint"]["refactoring"], prv["sprint"]["refactoring"], cur["sprint"]["size"], prv["sprint"]["size"])


func _render_mult_row(row: StatRow, label: String, current: float, preview: float) -> void:
	var cur_s: String = _fmt_mult(current)
	var prv_s: String = _fmt_mult(preview)
	if cur_s == prv_s:
		row.show_dimmed(label, cur_s)
		return
	var delta_pct: int = roundi((preview - current) / current * 100.0) if current > 0.0 else 0
	var delta_s: String = "(%+d%%)" % delta_pct
	row.show_diff(label, cur_s, prv_s, delta_s, preview > current)


func _render_interval_row(row: StatRow, label: String, current: float, preview: float) -> void:
	var cur_s: String = _fmt_interval(current)
	var prv_s: String = _fmt_interval(preview)
	if cur_s == prv_s:
		row.show_dimmed(label, cur_s)
		return
	# Positive direction for auto-click = faster = lower interval.
	var positive: bool = (is_zero_approx(current) and preview > 0.0) or (preview > 0.0 and preview < current)
	var delta_s: String
	if is_zero_approx(current):
		delta_s = "(On)"
	elif is_zero_approx(preview):
		delta_s = "(Off)"
	else:
		var delta_pct: int = roundi((current - preview) / current * 100.0)
		delta_s = "(%+d%% faster)" % delta_pct
	row.show_diff(label, cur_s, prv_s, delta_s, positive)


func _render_count_row(row: StatRow, label: String, current_count: int, preview_count: int, current_size: int, preview_size: int) -> void:
	var cur_s: String = _fmt_count(current_count, current_size)
	var prv_s: String = _fmt_count(preview_count, preview_size)
	if cur_s == prv_s:
		row.show_dimmed(label, cur_s)
		return
	var diff: int = preview_count - current_count
	var delta_s: String = "(%+d)" % diff
	row.show_diff(label, cur_s, prv_s, delta_s, diff > 0)


func _fmt_mult(value: float) -> String:
	return "×%.2f" % value


func _fmt_interval(seconds: float) -> String:
	if is_zero_approx(seconds):
		return "Off"
	return "%.1fs" % seconds


func _fmt_count(count: int, total: int) -> String:
	return "%d/%d" % [count, total]
```

Notes:
- `_fmt_mult` uses `×%.2f`; two multipliers that round to the same 2-decimal string are treated as unchanged (`row.show_dimmed`) — that's intentional, avoids misleading "+0%" deltas from sub-1% differences.
- Auto-click direction: "better" means lower interval (or `Off → N.Ns`). `positive` reflects that.
- Sprint rounding can flip by ±1 between `current_size` and `preview_size` if size changes between snapshots; both sizes are passed so the `M/N` strings stay honest. In practice `preview_size == current_size` because sprint size depends on level, not on upgrade stats — but the code doesn't assume that.

- [ ] **Step 2: Test the select-then-Take flow**

Run the game (F5), level up until the upgrade dialog appears. Verify each of these in one session:

1. **Dialog opens.** Take button is greyed out. No card has the "hover" visual.
2. **Click card A.** Card A shows hover variation permanently. Stats panel rows update: unchanged rows are dimmed, rows that would change show `current → preview (delta)` with green (positive) or red (negative) delta.
3. **Click card B.** Card A returns to idle visual, Card B becomes selected. Panel re-renders under B.
4. **Click Take.** Dialog closes, upgrade applies. Next dialog (if queued) opens with defaults.
5. **Level up again. Click card A twice rapidly.** First click selects, second click applies. No error in Output.
6. **Level up again. Click Reroll after selecting a card.** New cards appear. No card is selected. Take is disabled again. Panel returns to plain (undimmed) view.

7. **Auto-click unlock edge case.** If an available upgrade has `+auto_click_speed` and the player currently has zero, the `Auto click` row should preview `Off → 1.5s (On)` (exact interval depends on the upgrade magnitude).

8. **Trade-off edge case.** If a card has one positive and one negative stat, verify the diff row colours — positive stat in green, negative stat in red, both visible simultaneously.

Any issues in the Output panel → fix before moving on.

---

### Task 7: Delete obsolete files

**Files:**
- Delete: `components/ui/ui_upgrade_choice/stat_summary_item.gd`
- Delete: `components/ui/ui_upgrade_choice/stat_summary_item.gd.uid`
- Delete: `components/ui/ui_upgrade_choice/stat_summary_item.tscn`

- [ ] **Step 1: Confirm nothing references `StatSummaryItem`**

From the project root:

```bash
rg "stat_summary_item|StatSummaryItem" --glob '!docs/**'
```

Expected: only matches inside `stat_summary_item.*` (self-references). If anything else matches — stop and investigate.

- [ ] **Step 2: Delete the files via Godot's FileSystem dock**

In Godot: right-click `stat_summary_item.gd` → Move to Trash. Same for `stat_summary_item.tscn`. Let Godot resolve .uid cleanup. If Godot reports broken references, you missed a usage — revert and re-check Step 1.

- [ ] **Step 3: Re-open the upgrade dialog in-game**

Launch, level up, open dialog. Nothing visibly changes vs. the end of Task 6. Output panel should have no "missing script" warnings.

---

### Task 8: Final manual validation

- [ ] **Step 1: Run through the full matrix**

Start a fresh game (delete `user://` save if you want the cleanest state). Play through the first few level-ups and confirm:

| Scenario | Expected |
|----------|----------|
| Level 1, zero upgrades, dialog open | Damage `×1.00` / `×1.00`; Click `×2.50` / `Off`; Sprint `1/2` / `1/2`; Take disabled |
| Hover upgrade card | Rarity hover colour (existing behaviour, unchanged) |
| Click upgrade with `+global_damage` | Both damage rows highlight green; click rows dimmed; sprint rows dimmed |
| Click upgrade with `+feature_damage` only | Only `Features` damage row highlights; `Refactor` row dimmed |
| Click upgrade with `+auto_click_speed` from 0 | `Auto click` row shows `Off → N.Ns (On)`, green |
| Click upgrade with `+feature_chance` | Sprint rows shift by 1 in opposite directions (e.g. features +1, refactoring −1) |
| Trade-off upgrade (mixed signs) | Appropriate rows show green vs. red simultaneously |
| Reroll | Cards replaced, selection cleared, Take disabled, rows plain |
| Take | Dialog closes, next dialog (if any) opens |

- [ ] **Step 2: Ask the user to review and commit**

Stop here. Say to the user:

> "Implementation done. All changes are unstaged. Want me to stage and commit, or review the diff first? (`git status` / `git diff`)"

Do **not** run `git commit` or `git add` without the user's explicit say-so.

---

## Spec Coverage Check

| Spec section | Task(s) |
|---|---|
| § Design / 1. Panel layout | 3, 4 |
| § Design / 2. Two-tap selection flow | 5, 6 |
| § Design / 3. Component architecture — `Balance.get_display_stats` | 1 |
| § Design / 3. Component architecture — `StatRow` | 2 |
| § Design / 3. Component architecture — `ui_upgrade_choice.tscn` | 3 |
| § Design / 3. Component architecture — `ui_upgrade_choice.gd` | 4, 6 |
| § Design / 3. Component architecture — `UpgradeCard` changes | 5 |
| § Design / 4. Data flow for preview | 6 |
| § Design / 5. Files touched | 1, 2, 3, 4, 5, 6, 7 |
| § Design / 6. Edge cases (dim, trade-off, auto-click unlock, sprint rounding) | 6, 8 |
| § Design / 7. Testing | 8 |
