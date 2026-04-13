class_name UpgradeCard
extends PanelContainer

signal chosen(upgrade: UpgradeData)

var _upgrade: UpgradeData

@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var multiplier_label: Label = %MultiplierLabel


func setup(upgrade: UpgradeData) -> void:
	_upgrade = upgrade


func _ready() -> void:
	if not _upgrade:
		return
	if _upgrade.icon:
		icon_rect.texture = _upgrade.icon
	name_label.text = _upgrade.display_name
	description_label.text = _upgrade.description
	multiplier_label.text = "×%.1f" % _upgrade.multiplier
	if _upgrade.rarity in Constants.RARITY_COLORS:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.border_color = Constants.RARITY_COLORS[_upgrade.rarity]
		style.set_border_width_all(3)
		style.set_corner_radius_all(4)
		style.bg_color = Color(0.1, 0.1, 0.12)
		style.set_content_margin_all(8)
		add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(_upgrade)
