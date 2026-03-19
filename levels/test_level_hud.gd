extends CanvasLayer

@onready var dna_counter: UiResourceCount = %DnaCounter


func _ready() -> void:
	SB.product_produced.connect(_on_product_produced)
	dna_counter.count = 0


func _on_product_produced(product: ProductData) -> void:
	if product.group == "dna":
		dna_counter.count += 1
