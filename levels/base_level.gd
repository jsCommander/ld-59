extends Node2D


func _ready() -> void:
	add_to_group("level")
	AM.play_playlist([Constants.Music.FR, Constants.Music.FR3, Constants.Music.SG, Constants.Music.SPB])
	PD.start_game()
