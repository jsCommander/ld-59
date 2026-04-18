class_name ThemeTokens extends Resource

# ============================================================
# Theme Colors
# ============================================================

# --- Primary (gold — main actions, CTA) ---

const PRIMARY: Color = Color("#ffc752")
const PRIMARY_HOVER: Color = Color("#ffdea1")
const PRIMARY_PRESSED: Color = Color("#e48f44")

# --- Secondary (brown — secondary actions, borders, text) ---

const SECONDARY: Color = Color("#784d32")
const SECONDARY_HOVER: Color = Color("#a0754f")

# --- Surface ---

const SURFACE: Color = Color("#ffffff")
const SURFACE_DARK: Color = Color("#5e4432")
const SURFACE_CARD: Color = Color("#ead9b8")

const OVERLAY: Color = Color("#00000047")
const OUTLINE: Color = Color("#000000")
const NEUTRAL: Color = Color("#dfe0d9")

# --- Feedback ---

const SUCCESS: Color = Color("#218521")
const DESTRUCTIVE: Color = Color("#962121")

# --- Colors ---

const SALMON: Color = Color("#ff826f")
const SKY: Color = Color("#76adff")
const TEAL: Color = Color("#00ab70")
const GREY: Color = Color("#b5b3ae")
const BLUE: Color = Color("#8aadff")
const PURPLE: Color = Color("#b98de0")

# ============================================================
# Typography
# ============================================================

const FONT_SIZE_DEFAULT: int = 24
const FONT_SIZE_H1: int = 64
const FONT_SIZE_H2: int = 48
const FONT_SIZE_H3: int = 32

const FONT_COLOR: Color = Color("#000000")
const FONT_COLOR_MUTED: Color = Color("#a89880") # ~3.5:1 on SURFACE_DARK — secondary labels only
const FONT_COLOR_ON_ACCENT: Color = SURFACE
const FONT_COLOR_ON_ACCENT_OUTLINE: Color = OUTLINE
const FONT_COLOR_ON_ACCENT_SHADOW: Color = OUTLINE

# ============================================================
# Game Semantics
# ============================================================

# --- Stats ---

const STAT_POSITIVE: Color = SUCCESS
const STAT_NEGATIVE: Color = DESTRUCTIVE

# --- Rarity ---
# Base = pastel (unselected cards). Selected = darker saturated color — high contrast
# so the selected card visibly pops out against its pastel neighbours.

const RARITY_COMMON: Color = Color("#b8b5ad")
const RARITY_UNCOMMON: Color = Color("#8fafe3")
const RARITY_EPIC: Color = Color("#b993d3")
const RARITY_LEGENDARY: Color = Color("#e8c580")

const RARITY_COMMON_HOVER: Color = Color("#6f6d68")
const RARITY_UNCOMMON_HOVER: Color = Color("#2c5dd4")
const RARITY_EPIC_HOVER: Color = Color("#7a2eb5")
const RARITY_LEGENDARY_HOVER: Color = Color("#d99117")

const RARITY_COLORS_DICT: Dictionary[Constants.UpgradeRarity, Color] = {
	Constants.UpgradeRarity.COMMON: RARITY_COMMON,
	Constants.UpgradeRarity.UNCOMMON: RARITY_UNCOMMON,
	Constants.UpgradeRarity.EPIC: RARITY_EPIC,
	Constants.UpgradeRarity.LEGENDARY: RARITY_LEGENDARY,
}

# --- Game Entities ---

const FEATURE: Color = Color("#4ea8e0")
const REFACTORING: Color = Color("#e86b6b")
const HP: Color = REFACTORING
const MONEY: Color = Color("#00cc44")

# ============================================================
# Component Variants (Godot theme type variations)
# ============================================================

# --- Label ---

const LABEL_DEFAULT_COLOR: Color = FONT_COLOR
const LABEL_DEFAULT_SIZE: int = FONT_SIZE_DEFAULT
const LABEL_H1_SIZE: int = FONT_SIZE_H1
const LABEL_H2_SIZE: int = FONT_SIZE_H2
const LABEL_H3_SIZE: int = FONT_SIZE_H3
const LABEL_ON_ACCENT_COLOR: Color = FONT_COLOR_ON_ACCENT
const LABEL_ON_ACCENT_OUTLINE: Color = FONT_COLOR_ON_ACCENT_OUTLINE
const LABEL_ON_ACCENT_SHADOW: Color = FONT_COLOR_ON_ACCENT_SHADOW
const LABEL_MONEY_COLOR: Color = MONEY

# --- Button ---

const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR_ON_ACCENT
const BUTTON_DEFAULT_BG: Color = PRIMARY
const BUTTON_DEFAULT_BG_HOVER: Color = PRIMARY_HOVER
const BUTTON_DEFAULT_BG_FOCUS: Color = PRIMARY_HOVER
const BUTTON_DEFAULT_BG_PRESSED: Color = PRIMARY_PRESSED
const BUTTON_DEFAULT_BORDER: Color = SECONDARY
const BUTTON_LARGE_SIZE: int = FONT_SIZE_H2
const BUTTON_LARGE_BG: Color = SURFACE_CARD
const BUTTON_LARGE_BG_HOVER: Color = Color("#f5e8c8")
const BUTTON_LARGE_BG_PRESSED: Color = Color("#d4c3a2")

# --- PanelContainer ---

const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE
const PANEL_CONTAINER_PRIMARY_BG: Color = PRIMARY
const PANEL_CONTAINER_PRIMARY_HOVER_BG: Color = PRIMARY_HOVER
const PANEL_CONTAINER_CARD_BG: Color = SURFACE_CARD
const PANEL_CONTAINER_RARITY_COMMON_BG: Color = RARITY_COMMON
const PANEL_CONTAINER_RARITY_UNCOMMON_BG: Color = RARITY_UNCOMMON
const PANEL_CONTAINER_RARITY_EPIC_BG: Color = RARITY_EPIC
const PANEL_CONTAINER_RARITY_LEGENDARY_BG: Color = RARITY_LEGENDARY
const PANEL_CONTAINER_RARITY_COMMON_HOVER_BG: Color = RARITY_COMMON_HOVER
const PANEL_CONTAINER_RARITY_UNCOMMON_HOVER_BG: Color = RARITY_UNCOMMON_HOVER
const PANEL_CONTAINER_RARITY_EPIC_HOVER_BG: Color = RARITY_EPIC_HOVER
const PANEL_CONTAINER_RARITY_LEGENDARY_HOVER_BG: Color = RARITY_LEGENDARY_HOVER

# --- ProgressBar ---

const PROGRESS_DEFAULT_BG: Color = SURFACE
const PROGRESS_DEFAULT_FILL: Color = PRIMARY
const PROGRESS_FEATURE_FILL: Color = FEATURE
const PROGRESS_REFACTORING_FILL: Color = REFACTORING
const PROGRESS_HP_FILL: Color = HP
const PROGRESS_EXP_FILL: Color = MONEY
