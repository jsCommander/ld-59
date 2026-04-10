class_name SelectableTrait
extends Area2D

@export var target_sprite: Sprite2D
@export var highlight_material: ShaderMaterial

var is_selected: bool = false
var popup_anchor: Marker2D


func _ready() -> void:
	_find_popup_anchor()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	SB.selection_cleared.connect(_on_selection_cleared)


func _find_popup_anchor() -> void:
	for child in get_children():
		if child is Marker2D:
			popup_anchor = child
			return
	Log.log_error(name, "Missing Marker2D child node for popup anchor")
	push_error("%s: Missing Marker2D child node for popup anchor" % name)


func _on_mouse_entered() -> void:
	if not is_selected:
		highlight()


func _on_mouse_exited() -> void:
	if not is_selected:
		unhighlight()


func _on_input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		viewport.set_input_as_handled()
		SB.entity_selected.emit(get_parent(), popup_anchor.global_position)
		var dev: Developer = get_parent() as Developer
		if dev:
			dev.on_clicked()


func set_selected(value: bool) -> void:
	is_selected = value
	if value:
		highlight()
	else:
		unhighlight()


func _on_selection_cleared() -> void:
	if is_selected:
		set_selected(false)


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
