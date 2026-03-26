extends CanvasLayer

@onready var products_bar: HudProductsBar = %HudProductsBar


func _ready() -> void:
	SB.player_data_changed.connect(_on_data_changed)
	_on_data_changed()


func _on_data_changed() -> void:
	products_bar.update(PD.products)
