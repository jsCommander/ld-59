@tool
class_name Developer
extends Node2D

# --- Enums ---

enum State {IDLE, WORKING}

# --- Exports ---

@export var data: DeveloperData:
	set(value):
		data = value
		_apply_data()

# --- @onready ---

@onready var dev_rig: Node2D = %DevRig
@onready var dev_head_sprite: Sprite2D = %DevHeadSprite
@onready var task_display: DeveloperTaskCard = %DeveloperTaskCard
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# --- State ---

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _current_task: TaskData = null
var _boost_stacks: int = 0
var _boost_decay_timer: float = 0.0

# --- Lifecycle ---

func _ready() -> void:
	_apply_data()
	if Engine.is_editor_hint():
		return
	add_to_group("developer")


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not data:
		return

	match _state:
		State.IDLE:
			_process_idle()
		State.WORKING:
			_process_working(delta)

	_process_boost_decay(delta)

# --- Handlers ---

func _on_task_killed() -> void:
	SB.task_destroyed.emit(_current_task)
	task_display.kill()
	_current_task = null
	_change_state(State.IDLE)

# --- Public ---

func on_clicked() -> void:
	_apply_boost()


# --- Private ---

func _process_idle() -> void:
	_pick_task()


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
	if _boost_stacks <= 0:
		return
	_boost_decay_timer += delta
	if _boost_decay_timer >= 1.0 / Constants.BOOST_DECAY_RATE:
		_boost_decay_timer -= 1.0 / Constants.BOOST_DECAY_RATE
		_boost_stacks -= 1
		if _boost_stacks <= 0:
			_boost_stacks = 0
			dev_rig.modulate = Color.WHITE


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


func _pick_task() -> void:
	if PD.task_queue.is_empty():
		return

	var task: TaskData = data.task_select.select(data, PD.task_queue)
	if task:
		_current_task = PD.take_task(task)
		if _current_task:
			task_display.task = _current_task
			_change_state(State.WORKING)


func _perform_attack() -> void:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	var damage: float = Balance.calculate_damage(data, _current_task.task_type, PD.global_upgrades, dev_upgrades)
	_current_task.current_hp -= damage
	task_display.update_health_bar()
	task_display.flash()
	task_display.show_damage(int(damage))
	AM.play_sfx(Constants.Sfx.HIT_HURT, 0.15)
	if _current_task.current_hp <= 0.0:
		_on_task_killed()


func _get_attack_speed() -> float:
	var dev_upgrades: Array[UpgradeData] = PD.get_dev_upgrades(data.dev_type)
	return Balance.calculate_attack_speed(data, PD.global_upgrades, dev_upgrades, _boost_stacks)


func _apply_boost() -> void:
	_boost_stacks += 1
	var heat: float = clampf(float(_boost_stacks) / float(Constants.MAX_BOOST), 0.0, 1.0)
	dev_rig.modulate = Color.WHITE.lerp(Color(1.5, 0.5, 0.5), heat)
	if _boost_stacks > Constants.MAX_BOOST:
		_boost_stacks = Constants.MAX_BOOST



func _apply_data() -> void:
	if not is_node_ready():
		return

	var hired: bool = data != null
	dev_rig.visible = hired

	if hired:
		dev_head_sprite.texture = data.head_texture
		dev_head_sprite.offset = data.head_offset
