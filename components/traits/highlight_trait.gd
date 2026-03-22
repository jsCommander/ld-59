class_name HighlightTrait
extends Area2D

@export var target_sprite: Sprite2D
@export var highlight_material: ShaderMaterial

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	highlight()

func _on_mouse_exited() -> void:
	unhighlight()

func highlight() -> void:
	if not highlight_material:
		Log.log_warn(name, "Missing highlight_material")
		return
	target_sprite.material = highlight_material
	target_sprite.material.set_shader_parameter("enabled", true)

func unhighlight() -> void:
	if not target_sprite or not target_sprite.material:
		Log.log_warn(name, "Missing material")
		return
	target_sprite.material.set_shader_parameter("enabled", false)
