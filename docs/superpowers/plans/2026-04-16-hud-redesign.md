# HUD Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Переключить HUD на тёмные панели, обновить цвета, перекомпоновать элементы по спеке.

**Architecture:** Сначала обновляем токены и тему (все цветовые изменения), потом перекомпоновываем HUD лейаут, потом добавляем milestone-лейбл. Каждый таск — отдельный коммит.

**Tech Stack:** Godot 4, GDScript, Theme resources (.tres)

**Spec:** `docs/superpowers/specs/2026-04-16-hud-redesign.md`

---

### Task 1: Update theme_tokens.gd — colors and text

**Files:**
- Modify: `globals/theme_tokens.gd`

- [ ] **Step 1: Update FONT_COLOR and FONT_COLOR_MUTED**

In `globals/theme_tokens.gd:51-52`, change:

```gdscript
# Was:
const FONT_COLOR: Color = SECONDARY
const FONT_COLOR_MUTED: Color = SECONDARY_HOVER

# Now:
const FONT_COLOR: Color = Color("#fff5e6")  # intentionally independent from SURFACE_CARD
const FONT_COLOR_MUTED: Color = Color("#a89880")  # ~3.5:1 on SURFACE_DARK — secondary labels only
```

- [ ] **Step 2: Update BUTTON_DEFAULT_COLOR**

In `globals/theme_tokens.gd:109`, change:

```gdscript
# Was:
const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR

# Now:
const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR_ON_ACCENT
```

- [ ] **Step 3: Update PANEL_CONTAINER_DEFAULT_BG**

In `globals/theme_tokens.gd:119`, change:

```gdscript
# Was:
const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE_CARD

# Now:
const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE_DARK
```

- [ ] **Step 4: Replace PANEL_CONTAINER_DARK_BG with PANEL_CONTAINER_LIGHT_BG**

In `globals/theme_tokens.gd:122`, change:

```gdscript
# Was:
const PANEL_CONTAINER_DARK_BG: Color = SURFACE_DARK

# Now:
const PANEL_CONTAINER_LIGHT_BG: Color = SURFACE_CARD
```

- [ ] **Step 5: Update semantic colors**

In `globals/theme_tokens.gd:82-85`, change:

```gdscript
# Was:
const FEATURE: Color = SKY
const BUG: Color = SALMON
const HP: Color = SALMON
const MONEY: Color = TEAL

# Now:
const FEATURE: Color = Color("#8fb8d9")
const BUG: Color = Color("#d9998f")
const HP: Color = BUG
const MONEY: Color = Color("#5a9980")
```

- [ ] **Step 6: Update RARITY_LEGENDARY**

In `globals/theme_tokens.gd:71`, change:

```gdscript
# Was:
const RARITY_LEGENDARY: Color = DESTRUCTIVE

# Now:
const RARITY_LEGENDARY: Color = PRIMARY
```

- [ ] **Step 7: Delete orphaned tokens**

Remove these lines from `globals/theme_tokens.gd`:

- Line 23: `const SURFACE_CARD_HOVER: Color = Color("#ffeacc")`
- Line 101: `const LABEL_ON_DARK_COLOR: Color = SURFACE_CARD` (no external usages found — only in theme_tokens.gd and ui_game_theme.tres LabelOnDark which is removed in Task 2)
- Lines 103-105 (entire RichTextLabel section):
  ```
  # --- RichTextLabel ---

  const RICH_TEXT_LABEL_DEFAULT_COLOR: Color = FONT_COLOR
  ```

- [ ] **Step 8: Commit**

```
feat(ui): update theme tokens for dark panel redesign
```

---

### Task 2: Update ui_game_theme.tres

**Files:**
- Modify: `resources/ui_game_theme.tres`

- [ ] **Step 1: Update default panel StyleBox to dark**

In `resources/ui_game_theme.tres:53-58`, change `StyleBoxFlat_panel_default`:

```
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel_default"]
bg_color = Color(0.239216, 0.164706, 0.101961, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
```

(bg_color was `Color(1, 0.960784, 0.901961, 1)` — SURFACE_CARD, now SURFACE_DARK)

- [ ] **Step 2: Add StyleBoxFlat_panel_light, replace PanelContainerDark with PanelContainerLight**

Add new sub_resource after `StyleBoxFlat_panel_default`:

```
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel_light"]
bg_color = Color(1, 0.960784, 0.901961, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
```

In `resources/ui_game_theme.tres:182-183`, replace:

```
# Was:
PanelContainerDark/base_type = &"PanelContainer"
PanelContainerDark/styles/panel = SubResource("StyleBoxFlat_panel_dark")

# Now:
PanelContainerLight/base_type = &"PanelContainer"
PanelContainerLight/styles/panel = SubResource("StyleBoxFlat_panel_light")
```

Remove the now-unused `StyleBoxFlat_panel_dark` sub_resource (lines 60-65).

- [ ] **Step 3: Update Label default color**

In `resources/ui_game_theme.tres:159`, change:

```
# Was:
Label/colors/font_color = Color(0.470588, 0.301961, 0.196078, 1)

# Now:
Label/colors/font_color = Color(1, 0.960784, 0.901961, 1)
```

- [ ] **Step 4: Update Button font colors to white**

In `resources/ui_game_theme.tres:146-150`, change all five button font_color entries:

```
Button/colors/font_color = Color(1, 1, 1, 1)
Button/colors/font_focus_color = Color(1, 1, 1, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_hover_pressed_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(1, 1, 1, 1)
```

- [ ] **Step 5: Update RichTextLabel default color**

In `resources/ui_game_theme.tres:204`, change:

```
# Was:
RichTextLabel/colors/default_color = Color(0.470588, 0.301961, 0.196078, 1)

# Now:
RichTextLabel/colors/default_color = Color(1, 0.960784, 0.901961, 1)
```

- [ ] **Step 6: Remove LabelOnDark variation**

Delete `resources/ui_game_theme.tres:170-171`:

```
LabelOnDark/base_type = &"Label"
LabelOnDark/colors/font_color = Color(1, 0.960784, 0.901961, 1)
```

- [ ] **Step 7: Update rarity legendary StyleBox**

In `resources/ui_game_theme.tres:94-99`, change `StyleBoxFlat_rarity_legendary`:

```
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_rarity_legendary"]
bg_color = Color(1, 0.780392, 0.321569, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
```

(bg_color was red DESTRUCTIVE, now gold PRIMARY)

- [ ] **Step 8: Update semantic progress bar colors**

In `resources/ui_game_theme.tres`:

`StyleBoxFlat_progress_bug` (line 122-127) and `StyleBoxFlat_progress_hp` (line 136-141) — update bg_color:
```
bg_color = Color(0.851, 0.6, 0.561, 1)
```
(#d9998f in float form)

`StyleBoxFlat_progress_feature` (line 129-134) — update bg_color:
```
bg_color = Color(0.561, 0.722, 0.851, 1)
```
(#8fb8d9 in float form)

- [ ] **Step 9: Commit**

```
feat(ui): update game theme for dark panels and muted colors
```

---

### Task 3: Update .tscn files — remove PanelContainerDark references and hardcoded colors

**Files:**
- Modify: `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn:17`
- Modify: `components/ui/ui_hire_choice/ui_hire_choice.tscn:17`
- Modify: `components/ui/ui_sprint_panel/ui_sprint_panel.tscn:14`
- Modify: `components/ui/ui_sprint_panel/ui_sprint_panel_label.tscn:10`
- Modify: `components/ui/ui_capitalization/ui_capitalization.tscn`

- [ ] **Step 1: Remove PanelContainerDark from 4 .tscn files**

In each file, delete the line:
```
theme_type_variation = &"PanelContainerDark"
```

Files:
- `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn:17`
- `components/ui/ui_hire_choice/ui_hire_choice.tscn:17`
- `components/ui/ui_sprint_panel/ui_sprint_panel.tscn:14`
- `components/ui/ui_sprint_panel/ui_sprint_panel_label.tscn:10`

Default PanelContainer is now dark, so these don't need a variation.

- [ ] **Step 2: Update hardcoded MONEY color in ui_capitalization.tscn**

In `components/ui/ui_capitalization/ui_capitalization.tscn`, the `LabelSettings_h6tq0` sub_resource has:
```
font_color = Color(5.390644e-06, 0.70436645, 0.374116, 1)
```

Change to new muted MONEY color:
```
font_color = Color(0.353, 0.6, 0.502, 1)
```
(#5a9980 in float form)

- [ ] **Step 3: Run validate_theme.gd**

Open Godot Editor → Script > Run on `resources/validate_theme.gd`. All token colors should be found in theme. Fix any mismatches.

- [ ] **Step 4: Commit**

```
feat(ui): update scene files for dark panel theme
```

---

### Task 4: Reorganize HUD layout — top-left cluster

**Files:**
- Modify: `components/ui/ui_hud/ui_hud.tscn`
- Modify: `components/ui/ui_hud/ui_hud.gd`

- [ ] **Step 1: Create top-left VBoxContainer in ui_hud.tscn**

Restructure `ui_hud.tscn` to add a VBoxContainer anchored top-left containing:

1. `UiGameTimer` (moved from top-right) — "Time left" label + timer value, H3 size
2. `UiXpBar` (stays top-left but inside VBox) — "Next level" label + progress bar
3. New HBoxContainer with Level label and Sprint label (FONT_SIZE_DEFAULT)

The VBox anchors: `anchor_left = 0, anchor_top = 0`, no preset needed beyond top-left.

- [ ] **Step 2: Move UiGameTimer into the top-left cluster**

Remove UiGameTimer's current top-right anchoring (anchor_left=1, anchor_right=1). Make it a child of the new top-left VBoxContainer.

- [ ] **Step 3: Move UiXpBar into the top-left cluster**

Make UiXpBar a child of the top-left VBoxContainer, below UiGameTimer.

- [ ] **Step 4: Add Level + Sprint labels to the cluster**

Add an HBoxContainer as third child of the VBox with two Labels:
- `LevelLabel` — "Level X"
- `SprintLabel` — "Sprint X"

Both FONT_SIZE_DEFAULT. Remove the standalone `UiSprintLabel` node from `ui_hud.tscn`.

- [ ] **Step 5: Update ui_hud.gd — add level/sprint label logic**

```gdscript
# --- @onready ---
@onready var level_label: Label = %LevelLabel
@onready var sprint_label_hud: Label = %SprintLabel

# In _ready():
SB.level_up.connect(_on_level_up_label)
SB.sprint_number_changed.connect(_on_sprint_number_changed)
level_label.text = "Level %d" % PD.level
sprint_label_hud.text = "Sprint %d" % PD.sprint_number

# --- Handlers ---
func _on_level_up_label(level: int) -> void:
	level_label.text = "Level %d" % level

func _on_sprint_number_changed(sprint_number: int) -> void:
	sprint_label_hud.text = "Sprint %d" % sprint_number
```

Initialize both labels in `_ready()` with current values from `PD`, then update on signal.

- [ ] **Step 6: Commit**

```
feat(ui): reorganize HUD top-left cluster with timer, xp, level/sprint
```

---

### Task 5: Reorganize HUD layout — top-right CEO cluster

**Files:**
- Modify: `components/ui/ui_hud/ui_hud.tscn`

- [ ] **Step 1: Move UiCeoCommentator to top-right**

Change anchors from bottom-right to top-right:
```
anchor_left = 1.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
grow_horizontal = 0
grow_vertical = 2
```

Adjust offsets to fit top-right corner.

- [ ] **Step 2: Move UiCeoComment next to UiCeoCommentator**

Change UiCeoComment anchors from bottom-right to top-right, positioned to the left of or below the commentator.

Adjust offsets so comment and commentator are adjacent.

- [ ] **Step 3: Commit**

```
feat(ui): move CEO commentator and comment to top-right
```

---

### Task 6: Reorganize HUD layout — bottom HBox

**Files:**
- Modify: `components/ui/ui_hud/ui_hud.tscn`

- [ ] **Step 1: Wrap SprintPanel and UpgradeButton in HBoxContainer**

Create an HBoxContainer anchored bottom-left. Move `UiSprintPanel` and `UiUpgradeButton` as children.

Anchors for HBox:
```
anchor_top = 1.0
anchor_bottom = 1.0
grow_vertical = 0
```

- [ ] **Step 2: Remove standalone UiSprintLabel**

Already removed in Task 4 Step 4. Verify `UiSprintLabel` node (which instances `ui_sprint_panel_label.tscn`) is gone from `ui_hud.tscn`.

- [ ] **Step 3: Commit**

```
feat(ui): group sprint panel and upgrade button in bottom HBox
```

---

### Task 7: Add milestone label to UiCapitalization

**Files:**
- Modify: `components/ui/ui_capitalization/ui_capitalization.gd`
- Modify: `components/ui/ui_capitalization/ui_capitalization.tscn`
- Modify: `components/ui/ui_ceo_comment/ui_ceo_comment.gd`

- [ ] **Step 1: Add MilestoneLabel node to ui_capitalization.tscn**

Add a Label node as child of the VBox (under ValuationLabel):

```
[node name="MilestoneLabel" type="Label" parent="PanelContainer/MarginContainer/Vbox"]
unique_name_in_owner = true
layout_mode = 2
text = ""
horizontal_alignment = 1
```

Style with FONT_SIZE_DEFAULT, visible = false by default.

- [ ] **Step 2: Add milestone logic to ui_capitalization.gd**

```gdscript
@onready var milestone_label: Label = %MilestoneLabel

var _last_milestone: String = ""

func _update_valuation() -> void:
	valuation_label.text = "$%d" % PD.valuation
	_update_milestone()

func _update_milestone() -> void:
	var current_company: String = ""
	for milestone: Dictionary in Constants.COMPANY_MILESTONES:
		if PD.valuation >= milestone["valuation"]:
			current_company = milestone["name"]
	if current_company != _last_milestone:
		_last_milestone = current_company
		if _last_milestone:
			milestone_label.text = "Bigger than %s!" % _last_milestone
			milestone_label.visible = true
		else:
			milestone_label.visible = false
```

- [ ] **Step 3: Remove milestone logic from UiCeoComment**

In `components/ui/ui_ceo_comment/ui_ceo_comment.gd`:

- Remove `MILESTONE_COMMENTS` constant (lines 9-11)
- Remove `_last_milestone` state var (line 40)
- Remove milestone detection from `_on_valuation_changed()` (lines 57-65). The method only does milestone detection, so remove the entire method and the `SB.valuation_changed.connect()` from `_ready()`

- [ ] **Step 4: Commit**

```
feat(ui): add milestone label to capitalization, remove from CEO comment
```

---

### Task 8: Visual verification

- [ ] **Step 1: Run the game and verify**

Check:
- Dark panels visible on all level backgrounds
- Light text readable on dark panels
- Buttons: white text readable on gold
- Semantic colors (feature/bug/money progress bars) are muted
- Legendary rarity cards show gold, not red
- Top-left cluster: timer → xp bar → level/sprint
- Top-center: capitalization with milestone text
- Top-right: CEO commentator + comment
- Bottom-left: sprint panel + upgrade button in HBox
- CEO no longer shows milestone comments (only periodic/slow sprint comments)

- [ ] **Step 2: Run validate_theme.gd**

Godot Editor → Script > Run on `resources/validate_theme.gd`. Expected: all token colors found.
