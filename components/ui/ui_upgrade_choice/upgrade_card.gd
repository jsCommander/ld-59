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

# --- @onready ---
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stats_container: VBoxContainer = %Stats
@onready var upgrade_rarity_panel: PanelContainer = %UpgradeRarity

# --- State ---
var _upgrade: UpgradeData


# --- Public ---
func setup(upgrade: UpgradeData) -> void:
	_upgrade = upgrade


# --- Lifecycle ---
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not _upgrade:
		return
	if _upgrade.icon:
		icon_rect.texture = _upgrade.icon
	name_label.text = _upgrade.display_name
	description_label.text = _upgrade.description
	_populate_stats()
	if _upgrade.rarity in RARITY_VARIATIONS:
		upgrade_rarity_panel.theme_type_variation = RARITY_VARIATIONS[_upgrade.rarity]


# --- Handlers ---
func _on_mouse_entered() -> void:
	if _upgrade and _upgrade.rarity in RARITY_HOVER_VARIATIONS:
		upgrade_rarity_panel.theme_type_variation = RARITY_HOVER_VARIATIONS[_upgrade.rarity]


func _on_mouse_exited() -> void:
	if _upgrade and _upgrade.rarity in RARITY_VARIATIONS:
		upgrade_rarity_panel.theme_type_variation = RARITY_VARIATIONS[_upgrade.rarity]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_upgrade)


# --- Private ---
func _populate_stats() -> void:
	for field: String in Constants.STAT_ORDER:
		var value: float = _upgrade.get(field)
		if not is_zero_approx(value):
			var stat_row: StatModifier = STAT_MODIFIER.instantiate()
			stat_row.setup(Constants.STAT_DISPLAY_NAMES[field], value)
			stats_container.add_child(stat_row)
