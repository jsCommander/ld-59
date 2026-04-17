class_name DevFace
extends MarginContainer

# --- Exports ---

@export var dev_data: DeveloperData

# --- @onready ---

@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %NameLabel

# --- Lifecycle ---

func _ready() -> void:
	if not dev_data:
		return
	texture_rect.texture = dev_data.head_texture
	name_label.text = Constants.DEV_TYPE_DISPLAY_NAMES[dev_data.dev_type]
