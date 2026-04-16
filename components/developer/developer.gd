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
@onready var boost_stack_ui: UiBoostStack = %UiBoostStack

# --- State ---

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _current_task: TaskData = null
var _boost_stacks: int = 0
var _boost_decay_timer: float = 0.0
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

	_process_decay(delta)
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
	_apply_boost()


func get_task_position() -> Vector2:
	return task_landing_point.global_position


# --- Private ---

func _process_idle() -> void:
	SB.task_requested.emit(self , get_task_position())


func _process_working(delta: float) -> void:
	if not _current_task:
		_change_state(State.IDLE)
		return
	var speed: float = _get_attack_speed()
	_attack_timer += delta
	if _attack_timer >= speed:
		_attack_timer -= speed
		_perform_attack()


func _process_decay(delta: float) -> void:
	if _boost_stacks <= 0:
		return
	_boost_decay_timer += delta
	if _boost_decay_timer >= Constants.BOOST_DECAY_INTERVAL:
		_boost_decay_timer -= Constants.BOOST_DECAY_INTERVAL
		_boost_stacks -= 1
		_update_boost_visuals()


func _process_auto_click(delta: float) -> void:
	var interval: float = Balance.calculate_auto_click_interval(PD.total_stats)
	if interval <= 0.0:
		return
	_auto_click_timer += delta
	if _auto_click_timer >= interval:
		_auto_click_timer -= interval
		_apply_boost()


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
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.total_stats, _boost_stacks)
	_current_task.current_hp -= damage
	task_display.update_hp()
	task_display.flash()
	task_display.show_damage(int(damage))
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _get_attack_speed() -> float:
	return Balance.calculate_attack_speed(data, _boost_stacks, PD.total_stats)


func _apply_boost() -> void:
	_boost_stacks = mini(_boost_stacks + 1, Constants.MAX_BOOST_STACKS)
	_boost_decay_timer = 0.0
	_update_boost_visuals()
	SB.boost_applied.emit(self)


func _update_boost_visuals() -> void:
	var heat: float = float(_boost_stacks) / float(Constants.MAX_BOOST_STACKS)
	dev_rig.modulate = Color.WHITE.lerp(Color(1.4, 0.5, 0.4), heat)
	sweat_effect.emitting = _boost_stacks > 0
	boost_stack_ui.stack_count = _boost_stacks


func _apply_data() -> void:
	if not is_node_ready():
		return

	var hired: bool = data != null
	dev_rig.visible = hired

	if hired:
		dev_head_sprite.texture = data.head_texture
		dev_head_sprite.offset = data.head_offset
