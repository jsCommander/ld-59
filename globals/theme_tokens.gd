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
const SURFACE_DARK: Color = Color("#3d2a1a")
const SURFACE_CARD: Color = Color("#fff5e6")
const SURFACE_CARD_HOVER: Color = Color("#ffeacc")
const OVERLAY: Color = Color("#00000047")
const OUTLINE: Color = Color("#000000")
const NEUTRAL: Color = Color("#dfe0d9")

# --- Feedback ---

const SUCCESS: Color = Color("#33cc33")
const DESTRUCTIVE: Color = Color("#e63333")

# --- Colors ---

const SALMON: Color = Color("#ff826f")
const SKY: Color = Color("#76adff")
const TEAL: Color = Color("#00ab70")
const GREY: Color = Color("#999999")
const BLUE: Color = Color("#3366ff")
const PURPLE: Color = Color("#9933cc")

# ============================================================
# Typography
# ============================================================

const FONT_SIZE_DEFAULT: int = 24
const FONT_SIZE_H1: int = 128
const FONT_SIZE_H2: int = 48
const FONT_SIZE_H3: int = 32

const FONT_COLOR: Color = SECONDARY
const FONT_COLOR_MUTED: Color = SECONDARY_HOVER
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

const RARITY_COMMON: Color = GREY
const RARITY_UNCOMMON: Color = BLUE
const RARITY_EPIC: Color = PURPLE
const RARITY_LEGENDARY: Color = DESTRUCTIVE

const RARITY_COLORS_DICT: Dictionary[Constants.UpgradeRarity, Color] = {
	Constants.UpgradeRarity.COMMON: RARITY_COMMON,
	Constants.UpgradeRarity.UNCOMMON: RARITY_UNCOMMON,
	Constants.UpgradeRarity.EPIC: RARITY_EPIC,
	Constants.UpgradeRarity.LEGENDARY: RARITY_LEGENDARY,
}

# --- Game Entities ---

const FEATURE: Color = SKY
const BUG: Color = SALMON
const HP: Color = SALMON
const MONEY: Color = TEAL

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
const LABEL_ON_DARK_COLOR: Color = SURFACE_CARD

# --- RichTextLabel ---

const RICH_TEXT_LABEL_DEFAULT_COLOR: Color = FONT_COLOR

# --- Button ---

const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR
const BUTTON_DEFAULT_BG: Color = PRIMARY
const BUTTON_DEFAULT_BG_HOVER: Color = PRIMARY_HOVER
const BUTTON_DEFAULT_BG_FOCUS: Color = PRIMARY_HOVER
const BUTTON_DEFAULT_BG_PRESSED: Color = PRIMARY_PRESSED
const BUTTON_DEFAULT_BORDER: Color = SECONDARY
const BUTTON_LARGE_SIZE: int = FONT_SIZE_H2

# --- PanelContainer ---

const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE_CARD
const PANEL_CONTAINER_PRIMARY_BG: Color = PRIMARY
const PANEL_CONTAINER_PRIMARY_HOVER_BG: Color = PRIMARY_HOVER
const PANEL_CONTAINER_DARK_BG: Color = SURFACE_DARK
const PANEL_CONTAINER_RARITY_COMMON_BG: Color = RARITY_COMMON
const PANEL_CONTAINER_RARITY_UNCOMMON_BG: Color = RARITY_UNCOMMON
const PANEL_CONTAINER_RARITY_EPIC_BG: Color = RARITY_EPIC
const PANEL_CONTAINER_RARITY_LEGENDARY_BG: Color = RARITY_LEGENDARY

# --- ProgressBar ---

const PROGRESS_DEFAULT_BG: Color = NEUTRAL
const PROGRESS_DEFAULT_FILL: Color = PRIMARY
const PROGRESS_FEATURE_FILL: Color = FEATURE
const PROGRESS_BUG_FILL: Color = BUG
const PROGRESS_HP_FILL: Color = HP
