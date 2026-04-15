@tool
class_name Developer
extends Node2D

# --- Enums ---

enum State {IDLE, WAITING, WORKING}

# --- Exports ---

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

# --- @onready ---

@onready var dev_rig: Node2D = %DevRig
@onready var dev_head_sprite: Sprite2D = %DevHeadSprite
@onready var task_display: TaskCard = %TaskCard
@onready var task_landing_point: Marker2D = %TaskLandingPoint
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var clickable: ClickableTrait = $ClickableTrait
@onready var sweat_effect: GPUParticles2D = $SweatEffect

# --- State ---

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _current_task: TaskData = null
var _auto_boost_stacks: int = 0
var _auto_boost_decay_timer: float = 0.0
var _player_boost_stacks: int = 0
var _player_boost_decay_timer: float = 0.0
var _auto_click_timer: float = 0.0

# --- Lifecycle ---

func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	add_to_group("developer")
	SB.task_assigned.connect(_on_task_assigned)
	SB.task_fly_ended.connect(_on_task_fly_ended)
	clickable.clicked.connect(on_clicked)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	match _state:
		State.IDLE:
			_process_idle()
		State.WAITING:
			pass
		State.WORKING:
			_process_working(delta)

	_process_boost_decay(delta)
	_process_auto_click(delta)

# --- Handlers ---

func _on_task_killed() -> void:
	SB.task_destroyed.emit(_current_task)
	task_display.visible = false
	task_display.kill()
	_current_task = null
	_change_state(State.IDLE)


func _on_task_assigned(task: TaskData, developer: Developer, _task_position: Vector2) -> void:
	if developer != self:
		return
	_current_task = task
	_change_state(State.WAITING)


func _on_task_fly_ended(_task: TaskData, developer: Developer) -> void:
	if developer != self:
		return
	task_display.visible = true
	task_display.task_data = _current_task
	_change_state(State.WORKING)

# --- Public ---

func on_clicked() -> void:
	if not data:
		return
	_apply_player_boost()


func get_task_position() -> Vector2:
	return task_landing_point.global_position


# --- Private ---

func _process_idle() -> void:
	SB.task_requested.emit(self, get_task_position())


func _process_working(delta: float) -> void:
	if not _current_task:
		_change_state(State.IDLE)
		return
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()


func _process_boost_decay(delta: float) -> void:
	_process_auto_boost_decay(delta)
	_process_player_boost_decay(delta)


func _process_auto_boost_decay(delta: float) -> void:
	if _auto_boost_stacks <= 0:
		return
	_auto_boost_decay_timer += delta
	var decay_interval: float = Balance.calculate_boost_decay_interval(PD.global_upgrades)
	if _auto_boost_decay_timer >= decay_interval:
		_auto_boost_decay_timer -= decay_interval
		_auto_boost_stacks -= 1
		if _auto_boost_stacks <= 0:
			_auto_boost_stacks = 0
		_update_boost_visuals()


func _process_player_boost_decay(delta: float) -> void:
	if _player_boost_stacks <= 0:
		return
	_player_boost_decay_timer += delta
	if _player_boost_decay_timer >= Constants.PLAYER_BOOST_DECAY_INTERVAL:
		_player_boost_decay_timer -= Constants.PLAYER_BOOST_DECAY_INTERVAL
		_player_boost_stacks -= 1
		if _player_boost_stacks <= 0:
			_player_boost_stacks = 0
		_update_boost_visuals()


func _process_auto_click(delta: float) -> void:
	var interval: float = Balance.calculate_auto_click_interval(PD.global_upgrades)
	if interval <= 0.0:
		return
	_auto_click_timer += delta
	if _auto_click_timer >= interval:
		_auto_click_timer -= interval
		_apply_auto_boost()


func _change_state(new_state: State) -> void:
	var old_state: State = _state
	_state = new_state
	Log.log_debug(name, "State: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])

	if old_state == State.WORKING:
		animation_player.stop()

	match new_state:
		State.WORKING:
			animation_player.play("working")
		State.IDLE:
			_attack_timer = 0.0
			task_display.hide_task()


func _perform_attack() -> void:
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades)
	_current_task.current_hp -= damage
	task_display.update_hp()
	task_display.flash()
	task_display.show_damage(int(damage))
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _get_attack_speed() -> float:
	return Balance.calculate_attack_speed(data, _auto_boost_stacks, _player_boost_stacks)


func _apply_auto_boost() -> void:
	var stacks: int = Balance.calculate_boost_stacks(PD.global_upgrades)
	_auto_boost_stacks = mini(_auto_boost_stacks + stacks, Constants.MAX_AUTO_BOOST)
	_update_boost_visuals()


func _apply_player_boost() -> void:
	_player_boost_stacks += 1
	if _player_boost_stacks > Constants.PLAYER_BOOST_MAX:
		_player_boost_stacks = Constants.PLAYER_BOOST_MAX
	_player_boost_decay_timer = 0.0
	_update_boost_visuals()
	SB.boost_applied.emit(self)


func _update_boost_visuals() -> void:
	var auto_heat: float = float(_auto_boost_stacks) / float(Constants.MAX_AUTO_BOOST)
	var player_heat: float = float(_player_boost_stacks) / float(Constants.PLAYER_BOOST_MAX)
	var heat: float = clampf(maxf(auto_heat, player_heat), 0.0, 1.0)
	dev_rig.modulate = Color.WHITE.lerp(Color(2.0, 0.2, 0.2), heat)
	sweat_effect.emitting = _auto_boost_stacks + _player_boost_stacks > 0



func _apply_data() -> void:
	if not is_node_ready():
		return

	var hired: bool = data != null
	dev_rig.visible = hired

	if hired:
		dev_head_sprite.texture = data.head_texture
		dev_head_sprite.offset = data.head_offset
