class_name UpgradeCard
extends Control

# --- Constants ---
const STAT_MODIFIER: PackedScene = preload("res://components/ui/stat_modifier/stat_modifier.tscn")

const RARITY_VARIATIONS: Dictionary = {
	Constants.UpgradeRarity.COMMON: &"PanelContainerRarityCommon",
	Constants.UpgradeRarity.UNCOMMON: &"PanelContainerRarityUncommon",
	Constants.UpgradeRarity.RARE: &"PanelContainerRarityRare",
	Constants.UpgradeRarity.EPIC: &"PanelContainerRarityEpic",
	Constants.UpgradeRarity.LEGENDARY: &"PanelContainerRarityLegendary",
}

const STAT_MODIFIERS: Array[Dictionary] = [
	{"field": "multiplier", "name": "Damage"},
	{"field": "click_boost_power_mult", "name": "Boost Power"},
	{"field": "click_boost_duration_mult", "name": "Boost Duration"},
	{"field": "auto_click_speed_mult", "name": "Auto Click"},
]

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
	modulate = Color(0.75, 0.75, 0.75)


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_upgrade)


# --- Private ---
func _populate_stats() -> void:
	for mod: Dictionary in STAT_MODIFIERS:
		var value: float = _upgrade.get(mod["field"])
		if is_equal_approx(value, 1.0):
			continue
		var stat_row: StatModifier = STAT_MODIFIER.instantiate()
		stat_row.setup(mod["name"], value)
		stats_container.add_child(stat_row)
