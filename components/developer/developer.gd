@tool
class_name Developer
extends Node2D

enum State { IDLE, WORKING, YOUTUBE, BURNOUT }

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

@onready var desk_sprite: Sprite2D = %DeskSprite
@onready var dev_sprite: Sprite2D = %DevSprite
@onready var damage_number: DamageNumber = $DamageNumber
@onready var task_display: TaskDisplay = %TaskDisplay

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _idle_tween: Tween = null
var _current_task: TaskData = null

# Boost system
var _boost_stacks: int = 0
var _boost_decay_timer: float = 0.0

# Burnout
var _burnout_timer: float = 0.0


func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	match _state:
		State.IDLE:
			_process_idle()
		State.WORKING:
			_process_working(delta)
		State.YOUTUBE:
			_process_youtube()
		State.BURNOUT:
			_process_burnout(delta)

	_process_boost_decay(delta)


func _process_idle() -> void:
	_stop_idle_sway()
	_pick_task()


func _process_working(delta: float) -> void:
	if not _current_task:
		_change_state(State.IDLE)
		return
	_start_idle_sway()
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()


func _process_youtube() -> void:
	_stop_idle_sway()


func _process_burnout(delta: float) -> void:
	_stop_idle_sway()
	_burnout_timer -= delta
	if _burnout_timer <= 0.0:
		_change_state(State.IDLE)
		Log.log_debug(name, "Recovered from burnout")


func _process_boost_decay(delta: float) -> void:
	if _boost_stacks <= 0:
		return
	_boost_decay_timer += delta
	if _boost_decay_timer >= 1.0 / Constants.BOOST_DECAY_RATE:
		_boost_decay_timer -= 1.0 / Constants.BOOST_DECAY_RATE
		_boost_stacks -= 1
		if _boost_stacks <= 0:
			_boost_stacks = 0
			dev_sprite.modulate = Color.WHITE


func _change_state(new_state: State) -> void:
	var old_state: State = _state
	_state = new_state
	Log.log_debug(name, "State: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])

	match new_state:
		State.YOUTUBE:
			task_display.show_youtube()
		State.BURNOUT:
			_burnout_timer = Constants.BURNOUT_DURATION
			_boost_stacks = 0
			dev_sprite.modulate = Color.WHITE
			task_display.show_burnout()
		State.IDLE:
			_attack_timer = 0.0
			task_display.hide_task()


func _pick_task() -> void:
	if PD.task_queue.is_empty():
		return

	if randf() < Constants.YOUTUBE_CHANCE:
		_change_state(State.YOUTUBE)
		return

	var task: TaskData = data.task_select.select(data, PD.task_queue)
	if task:
		_current_task = PD.take_task(task)
		if _current_task:
			task_display.show_task(_current_task)
			_change_state(State.WORKING)


func _perform_attack() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, dev_upgrades)
	_current_task.current_hp -= damage
	show_damage(int(damage))
	task_display.update_hp(_current_task.current_hp, _current_task.max_hp)
	task_display.flash_hit()
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _on_task_killed() -> void:
	SB.task_destroyed.emit(_current_task)
	task_display.hide_task()
	_current_task = null
	_change_state(State.IDLE)


func _get_attack_speed() -> float:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	return Balance.calculate_attack_speed(data, PD.global_upgrades, dev_upgrades, _boost_stacks)


# --- Player interaction ---

func on_clicked() -> void:
	match _state:
		State.YOUTUBE:
			_change_state(State.IDLE)
			Log.log_debug(name, "Snapped out of YouTube")
		State.WORKING, State.IDLE:
			_apply_boost()


func _apply_boost() -> void:
	_boost_stacks += 1
	var heat: float = clampf(float(_boost_stacks) / float(Constants.MAX_BOOST), 0.0, 1.0)
	dev_sprite.modulate = Color.WHITE.lerp(Color(1.5, 0.5, 0.5), heat)
	damage_number.spawn("+BOOST", Vector2.UP, Color.ORANGE_RED)
	if _boost_stacks >= Constants.MAX_BOOST:
		_change_state(State.BURNOUT)
		Log.log_info(name, "Burned out from too much boost!")


# --- Visual ---

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
		if not Engine.is_editor_hint():
			add_to_group("desk")
			if is_in_group("developer"):
				remove_from_group("developer")
