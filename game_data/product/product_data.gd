class_name ProductData
extends Resource

@export var texture: Texture2D
@export var product_name: String
@export var group: String = "product"
@export var ingredients: Array[RecipeIngredient] = []
@export var produce_time: float = 5.0
