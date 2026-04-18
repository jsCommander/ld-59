@tool
extends Node2D
class_name FloatingText

# --- Exports ---

@export var direction: Vector2 = Vector2.UP
@export var travel_distance: float = 70.0
@export var spread_angle: float = 30.0
@export var duration: float = 0.7
@export var fade_out_time: float = 0.3
@export var pop_scale: float = 1.4
@export var pop_duration: float = 0.15
## Minimum seconds between spawns. Calls that come faster are silently dropped.
## Set to 0.0 to disable throttling.
@export var throttle_time: float = 0.1
@export var debug: bool = false:
	set(value):
		debug = value
		set_process(debug and Engine.is_editor_hint())

# --- State ---

var _label_template: Label
var _spawned_labels: Array[Label] = []
var _debug_timer: float = 0.0
var _last_spawn_time: float = 0.0

# --- Lifecycle ---

func _ready() -> void:
	_label_template = _find_label()
	if _label_template:
		_label_template.visible = false
	set_process(debug and Engine.is_editor_hint())

func _process(delta: float) -> void:
	_debug_timer += delta
	if _debug_timer >= 0.5:
		_debug_timer = 0.0
		spawn(str(randi_range(1, 999)))

# --- Public ---

func spawn(text: String) -> void:
	if throttle_time > 0.0:
		var now: float = Time.get_ticks_msec() * 0.001
		if now - _last_spawn_time < throttle_time:
			return
		_last_spawn_time = now
	if not _label_template:
		_label_template = _find_label()
		if _label_template:
			_label_template.visible = false
	if not _label_template:
		if debug:
			Log.log_warn(name, "No Label child found")
		return

	var label: Label = _label_template.duplicate()
	label.text = text
	label.modulate.a = 0.0
	label.visible = true
	label.scale = Vector2(pop_scale, pop_scale)
	label.pivot_offset = label.size / 2.0

	if Engine.is_editor_hint():
		add_child(label)
		label.position = Vector2.ZERO
	else:
		get_tree().root.add_child(label)
		label.global_position = global_position
	_spawned_labels.append(label)

	_animate(label)

# --- Private ---

func _find_label() -> Label:
	for child in get_children():
		if child is Label:
			return child
	return null

func _animate(label: Label) -> void:
	var half_spread: float = deg_to_rad(spread_angle / 2.0)
	var angle: float = direction.angle() + randf_range(-half_spread, half_spread)
	var dir: Vector2 = Vector2.from_angle(angle)
	var target_pos: Vector2 = label.global_position + dir * travel_distance

	# Pop-in: scale down + fade in
	var pop_tween: Tween = label.create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(label, "scale", Vector2.ONE, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(label, "modulate:a", 1.0, pop_duration * 0.5)

	# Move with ease out (fast start, slow end)
	var move_tween: Tween = label.create_tween()
	move_tween.tween_property(label, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Fade out at the end
	var fade_tween: Tween = label.create_tween()
	fade_tween.tween_interval(duration - fade_out_time)
	fade_tween.tween_property(label, "modulate:a", 0.0, fade_out_time)

	await fade_tween.finished

	_spawned_labels.erase(label)
	label.queue_free()

func _on_tree_exiting() -> void:
	for label in _spawned_labels:
		if is_instance_valid(label):
			Animations.fade_out(label, 0.2).finished.connect(func():
				if is_instance_valid(label):
					label.queue_free())
