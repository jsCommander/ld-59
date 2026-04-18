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
@onready var boost_tick_timer: Timer = %BoostTickTimer

# --- State ---

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _current_task: TaskData = null
var _boost_stacks: Array[BoostStack] = []
var _auto_click_timer: float = 0.0
var _click_flash_tween: Tween

# --- Lifecycle ---

func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	add_to_group("developer")
	SB.task_assigned.connect(_on_task_assigned)
	SB.task_fly_ended.connect(_on_task_fly_ended)
	clickable.clicked.connect(on_clicked)
	boost_tick_timer.timeout.connect(_on_boost_tick)
	animation_player.play("working")
	_update_boost_visuals()


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

	_process_auto_click(delta)

# --- Handlers ---

func _on_boost_tick() -> void:
	if _boost_stacks.is_empty():
		return
	var interval: float = Constants.BOOST_STACK_TICK_INTERVAL
	var expired: Array[BoostStack] = []
	for stack: BoostStack in _boost_stacks:
		stack.lifetime += interval
		if stack.lifetime >= stack.max_lifetime:
			expired.append(stack)
	if expired.is_empty():
		return
	for stack: BoostStack in expired:
		_boost_stacks.erase(stack)
	_update_boost_visuals()


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


func _process_auto_click(delta: float) -> void:
	var interval: float = Balance.calculate_auto_click_interval(PD.total_stats)
	if interval <= 0.0:
		return
	_auto_click_timer += delta
	if _auto_click_timer >= interval:
		_auto_click_timer -= interval
		_apply_boost(false)


func _change_state(new_state: State) -> void:
	var old_state: State = _state
	_state = new_state
	Log.log_debug(name, "State: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])

	match new_state:
		State.IDLE:
			_attack_timer = 0.0
			task_display.hide_task()


func _perform_attack() -> void:
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.total_stats)
	_current_task.current_hp -= damage
	task_display.update_hp()
	task_display.flash()
	task_display.show_damage(int(damage))
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _get_attack_speed() -> float:
	return Balance.calculate_attack_speed(data, _boost_stacks.size(), PD.total_stats)


func _apply_boost(from_player: bool = true) -> void:
	if _boost_stacks.size() >= Constants.MAX_BOOST_STACKS:
		return
	var stack: BoostStack = BoostStack.new()
	stack.max_lifetime = Constants.BOOST_STACK_MAX_LIFETIME
	_boost_stacks.append(stack)
	_flash_click()
	_update_boost_visuals()
	if from_player:
		SB.player_boost_applied.emit(self )
	else:
		SB.auto_boost_applied.emit(self )


func _flash_click() -> void:
	const FLASH_COLOR: Color = Color(1.4, 0.5, 0.4)
	const FLASH_IN: float = 0.05
	const FLASH_OUT: float = 0.2
	if _click_flash_tween and _click_flash_tween.is_valid():
		_click_flash_tween.kill()
	dev_rig.modulate = Color.WHITE
	_click_flash_tween = create_tween()
	_click_flash_tween.tween_property(dev_rig, "modulate", FLASH_COLOR, FLASH_IN)
	_click_flash_tween.tween_property(dev_rig, "modulate", Color.WHITE, FLASH_OUT)


func _update_boost_visuals() -> void:
	var count: int = _boost_stacks.size()
	sweat_effect.emitting = count > 0
	boost_stack_ui.stack_count = count
	animation_player.speed_scale = 0.4 + count * 0.2


func _apply_data() -> void:
	if not is_node_ready():
		return

	var hired: bool = data != null
	dev_rig.visible = hired

	if hired:
		dev_head_sprite.texture = data.head_texture
		dev_head_sprite.offset = data.head_offset
