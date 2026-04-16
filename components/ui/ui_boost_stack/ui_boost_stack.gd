class_name UiBoostStack
extends Control

# --- Constants ---

const ACTIVE_COLOR: Color = Color.WHITE
const INACTIVE_COLOR: Color = Color.BLACK

# --- Exports ---

@export var stack_count: int = 0:
	set(value):
		stack_count = value
		_update_icons()

# --- @onready ---

@onready var _icons: Array[TextureRect] = [%Fire1, %Fire2, %Fire3, %Fire4, %Fire5]

# --- Lifecycle ---

func _ready() -> void:
	visible = false

# --- Private ---

func _update_icons() -> void:
	visible = stack_count > 0
	for i: int in _icons.size():
		if _icons[i]:
			_icons[i].modulate = ACTIVE_COLOR if i < stack_count else INACTIVE_COLOR
