extends Control

@onready var label: Label = %Label

func _ready() -> void:
	Animations.pulse(self, 1.02, 2.0)
