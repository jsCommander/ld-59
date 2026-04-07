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

var purchased_upgrades: Dictionary = {}
var _attack_timer: float = 0.0


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return
	if PD.task_queue.is_empty():
		_attack_timer = 0.0
		_update_progress_bar()
		return
	_attack_timer += delta
	if _attack_timer >= data.base_attack_speed:
		_attack_timer -= data.base_attack_speed
		_perform_attack()
	_update_progress_bar()


func _update_progress_bar() -> void:
	if not is_instance_valid(attack_progress_bar):
		return
	if not data or PD.task_queue.is_empty():
		attack_progress_bar.visible = false
		return
	attack_progress_bar.visible = true
	attack_progress_bar.value = _attack_timer / data.base_attack_speed


func hire(developer_data: DeveloperData) -> void:
	data = developer_data
	PD.hire_developer(self)



func get_damage_multiplier() -> float:
	var mult: float = 1.0
	for upgrade: DeveloperUpgrade in purchased_upgrades:
		mult += upgrade.damage_bonus * purchased_upgrades[upgrade]
	return mult


func get_upgrade_level(upgrade: DeveloperUpgrade) -> int:
	return purchased_upgrades.get(upgrade, 0)


func get_available_upgrades() -> Array[DeveloperUpgrade]:
	if not data:
		return []
	return data.upgrades.filter(
		func(u: DeveloperUpgrade) -> bool:
			return u.max_level == 0 or get_upgrade_level(u) < u.max_level
	)


func apply_upgrade(upgrade: DeveloperUpgrade) -> void:
	purchased_upgrades[upgrade] = get_upgrade_level(upgrade) + 1
	Log.log_info(name, "Upgraded %s to Lv.%d" % [upgrade.upgrade_name, purchased_upgrades[upgrade]])


func _perform_attack() -> void:
	SB.developer_attack.emit(self)
	_shake_sprite()
	Log.log_debug(name, "Attack tick")


func show_damage(damage: int) -> void:
	damage_number.spawn("-%d" % damage, Vector2.UP, Color.YELLOW)


func _shake_sprite() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(dev_sprite, "rotation_degrees", 5.0, 0.05)
	tween.tween_property(dev_sprite, "rotation_degrees", -5.0, 0.05)
	tween.tween_property(dev_sprite, "rotation_degrees", 0.0, 0.1)


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
