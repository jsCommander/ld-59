extends Node2D

const STARTER_DEV: DeveloperData = preload("res://game_data/developer/developer_data_vibecoder.tres")


func _ready() -> void:
	add_to_group("level")
	AM.play_playlist([Constants.Music.FR, Constants.Music.FR3, Constants.Music.SG, Constants.Music.SPB])
	PD.start_game()
	_auto_hire_starter()


func _auto_hire_starter() -> void:
	PD.hire_developer(STARTER_DEV.duplicate())
