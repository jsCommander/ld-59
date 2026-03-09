@tool
extends Control
class_name ThinkBubble

@onready var icon_rect: TextureRect = %IconRect

var current_icon: Texture2D

func _ready() -> void:
	_update_icon()

func show_bubble(icon: Texture2D, duration: float = 0.0) -> void:
	current_icon = icon
	_update_icon()

	if duration > 0.0:
		visible = false
		await Animations.fade_in(self, 0.2).finished
		await get_tree().create_timer(duration).timeout
		await Animations.fade_out(self, 0.2).finished
		visible = false

func _update_icon() -> void:
	if not is_node_ready():
		return

	if current_icon:
		Log.log_debug(self.name, "Updating icon to: %s" % current_icon)
		icon_rect.texture = current_icon
