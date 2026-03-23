extends CanvasLayer

@onready var fruit_counter: UiResourceCount = %FruitCounter
@onready var battery_counter: UiResourceCount = %BatteryCounter


func _ready() -> void:
	PD.data_changed.connect(_on_data_changed)


func _on_data_changed() -> void:
	fruit_counter.count = PD.get_product(C.PRODUCT_FRUIT)
	battery_counter.count = PD.get_product(C.PRODUCT_BATTERY)
