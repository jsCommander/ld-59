extends CanvasLayer

@onready var battery_counter: UiResourceCount = %BatteryCounter


func _ready() -> void:
	SB.battery_produced.connect(_on_battery_produced)
	battery_counter.count = 0


func _on_battery_produced() -> void:
	battery_counter.count += 1
