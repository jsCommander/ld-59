@tool
class_name Developer
extends Node2D

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var desk_sprite: Sprite2D = %DeskSprite
@onready var dev_sprite: Sprite2D = %DevSprite
@onready var damage_number: DamageNumber = $DamageNumber
@onready var attack_progress_bar: ProgressBar = %AttackProgressBar

var _attack_timer: float = 0.0
var _idle_tween: Tween = null


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return
	if PD.task_queue.is_empty():
		_attack_timer = 0.0
		_stop_idle_sway()
		_update_progress_bar()
		return
	_start_idle_sway()
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()
	_update_progress_bar()


func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or PD.task_queue.is_empty():
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / _get_attack_speed()


func _get_attack_speed() -> float:
	var base: float = data.base_attack_speed
	var type_mult: float = PD.get_type_speed_mult(data.dev_type)
	var global_mult: float = PD.global_speed_mult
	return base / (type_mult * global_mult)


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)




func _perform_attack() -> void:
	SB.developer_attack.emit(self)
	Log.log_debug(name, "Attack tick")


func show_damage(damage: int) -> void:
	damage_number.spawn("-%d" % damage, Vector2.UP, Color.YELLOW)



func _start_idle_sway() -> void:
	if _idle_tween and _idle_tween.is_valid():
		return
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(dev_sprite, "rotation_degrees", 3.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(dev_sprite, "rotation_degrees", -3.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_idle_sway() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
		_idle_tween = null
		dev_sprite.rotation_degrees = 0.0


func _apply_data() -> void:
	if not is_instance_valid(dev_sprite):
		return

	if data:
		dev_sprite.texture = data.texture
		dev_sprite.visible = true
		if not Engine.is_editor_hint():
			add_to_group("developer")
			if is_in_group("desk"):
				remove_from_group("desk")
	else:
		dev_sprite.visible = false
		if is_instance_valid(attack_progress_bar):
			attack_progress_bar.visible = false
		if not Engine.is_editor_hint():
			add_to_group("desk")
			if is_in_group("developer"):
				remove_from_group("developer")
