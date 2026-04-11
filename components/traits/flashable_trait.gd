class_name FlashableTrait
extends Node

# --- Constants ---
const SET_COLOR_SHADER: Shader = preload("res://game_kit/shaders/set_color.gdshader")

# --- State ---
var _flash_material: ShaderMaterial
var _original_material: Material
var _flash_tween: Tween
var _target: CanvasItem


# --- Lifecycle ---
func _ready() -> void:
	_target = get_parent() as CanvasItem
	if not _target:
		Log.log_error(name, "Parent is not a CanvasItem")
		return
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = SET_COLOR_SHADER


# --- Public ---
func flash(duration: float = 0.08) -> void:
	if not _target:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_original_material = _target.material
	_target.material = _flash_material
	_flash_material.set_shader_parameter("active", true)
	_flash_tween = create_tween()
	_flash_tween.tween_callback(func() -> void:
		_target.material = _original_material
	).set_delay(duration)
