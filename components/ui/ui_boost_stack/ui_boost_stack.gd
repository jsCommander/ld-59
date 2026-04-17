class_name UiBoostStack
extends Control

# --- Constants ---

const ACTIVE_COLOR: Color = Color.WHITE
const INACTIVE_COLOR: Color = Color.BLACK
const FADE_DURATION: float = 0.4
const ICON_TWEEN_DURATION: float = 0.15

# --- Exports ---

@export var stack_count: int = 0:
	set(value):
		stack_count = value
		_update_icons()

# --- @onready ---

@onready var _icons: Array[TextureRect] = [%Fire1, %Fire2, %Fire3, %Fire4, %Fire5, %Fire6]

# --- State ---

var _fade_tween: Tween
var _icon_tweens: Array[Tween] = []

# --- Lifecycle ---

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	_icon_tweens.resize(_icons.size())

# --- Private ---

func _update_icons() -> void:
	_fade_to(stack_count > 0)
	for i: int in _icons.size():
		if _icons[i]:
			_tween_icon(i, ACTIVE_COLOR if i < stack_count else INACTIVE_COLOR)


func _tween_icon(index: int, target: Color) -> void:
	var tw: Tween = _icon_tweens[index]
	if tw and tw.is_valid():
		tw.kill()
	tw = create_tween()
	tw.tween_property(_icons[index], "modulate", target, ICON_TWEEN_DURATION)
	_icon_tweens[index] = tw


func _fade_to(should_show: bool) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if should_show:
		visible = true
	var target_alpha: float = 1.0 if should_show else 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, FADE_DURATION)
	if not show:
		_fade_tween.tween_callback(func() -> void: visible = false)
