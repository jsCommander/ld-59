class_name UiUpgradeButton
extends Control

# --- Signals ---

signal pressed

# --- Constants ---

const PULSE_DURATION: float = 0.6
const PULSE_SCALE: float = 1.05

# --- @onready ---

@onready var button: Button = %UpgradeBtn

# --- State ---

var _pulse_tween: Tween

# --- Lifecycle ---

func _ready() -> void:
	SB.pending_upgrades_changed.connect(_on_pending_upgrades_changed)
	button.pressed.connect(func() -> void: pressed.emit())
	_update()

# --- Handlers ---

func _on_pending_upgrades_changed() -> void:
	_update()

# --- Private ---

func _update() -> void:
	var count: int = PD.pending_upgrades.size()
	visible = count > 0
	button.text = "Get Upgrades (%d)" % count
	if count > 0:
		_start_pulse()
	else:
		_stop_pulse()

func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		return
	button.pivot_offset = button.size / 2.0
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(button, "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_DURATION * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(button, "scale", Vector2.ONE, PULSE_DURATION * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	button.scale = Vector2.ONE
