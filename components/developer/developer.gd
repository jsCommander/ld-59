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
@onready var task_display: TaskDisplay = %TaskDisplay

var _attack_timer: float = 0.0
var _idle_tween: Tween = null
var _current_task: TaskData = null


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	if not _current_task:
		_pick_task()
		if not _current_task:
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


func _pick_task() -> void:
	if PD.task_queue.is_empty():
		return
	var task: TaskData = data.task_select.select(data, PD.task_queue)
	if task:
		_current_task = PD.take_task(task)
		if _current_task:
			task_display.show_task(_current_task)


func _perform_attack() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, dev_upgrades)
	_current_task.current_hp -= damage
	show_damage(int(damage))
	task_display.update_hp(_current_task.current_hp, _current_task.max_hp)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _on_task_killed() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	var debt: float = Balance.calculate_debt(data, PD.global_upgrades, dev_upgrades)
	SB.task_destroyed.emit(_current_task)
	SB.tech_debt_produced.emit(debt)
	task_display.hide_task()
	_current_task = null


func _get_attack_speed() -> float:
	var dev_upgrades: Array[UpgradeData] = PD.dev_upgrades.get(data.dev_type, [])
	return Balance.calculate_attack_speed(data, PD.global_upgrades, dev_upgrades)


func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or not _current_task:
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / _get_attack_speed()


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)


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
