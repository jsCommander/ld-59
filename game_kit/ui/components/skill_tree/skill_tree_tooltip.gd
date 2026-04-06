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
