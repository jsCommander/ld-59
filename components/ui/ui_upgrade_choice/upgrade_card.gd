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

const RARITY_SELECTED_VARIATIONS: Dictionary = {
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

# --- Lifecycle ---

func _ready() -> void:
	if not upgrade:
		return
	if upgrade.icon:
		icon_rect.texture = upgrade.icon
	name_label.text = upgrade.display_name
	description_label.text = upgrade.description
	_populate_stats()
	_apply_rarity_variation()

# --- Handlers ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_changed.emit(self, true)

# --- Public ---

func setup(new_upgrade: UpgradeData) -> void:
	upgrade = new_upgrade


func set_selected(value: bool) -> void:
	if is_selected == value:
		return
	is_selected = value
	_apply_rarity_variation()

# --- Private ---

func _apply_rarity_variation() -> void:
	if not upgrade:
		return
	var variations: Dictionary = RARITY_SELECTED_VARIATIONS if is_selected else RARITY_VARIATIONS
	if upgrade.rarity in variations:
		upgrade_rarity_panel.theme_type_variation = variations[upgrade.rarity]


func _populate_stats() -> void:
	for field: String in Constants.STAT_ORDER:
		var value: float = upgrade.get(field)
		if not is_zero_approx(value):
			var stat_row: StatModifier = STAT_MODIFIER.instantiate()
			stat_row.setup(Constants.STAT_DISPLAY_NAMES[field], value)
			stats_container.add_child(stat_row)
