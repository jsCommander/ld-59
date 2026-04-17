extends Control

@onready var label: Label = %Label

func _ready() -> void:
	Animations.pulse(self, 1.08, 1.2)
