@tool
class_name Product
extends RigidBody2D

@export var data: ProductData:
	set(value):
		Log.log_debug(self.name, "Setting product data")
		data = value
		_apply_data()

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	if data and data.group:
		add_to_group(data.group)


func _apply_data() -> void:
	Log.log_debug(self.name, "_apply_data called")
	if not is_node_ready() or not data or not is_instance_valid(sprite):
		return
	Log.log_debug(self.name, "Applying product data: %s" % data.resource_name)
	if data.texture:
		sprite.texture = data.texture
