extends Node2D

const STARTER_DEV: DeveloperData = preload("res://game_data/developer/developer_data_vibecoder.tres")


func _ready() -> void:
	add_to_group("level")
	AM.play_playlist([Constants.Music.FR, Constants.Music.FR3, Constants.Music.SG, Constants.Music.SPB])
	_auto_hire_starter()
	PD.start_game()


func _auto_hire_starter() -> void:
	var desks: Array[Node] = get_tree().get_nodes_in_group("desk")
	if desks.is_empty():
		Log.log_warn(name, "No desks found for starter dev")
		return
	var desk: Developer = desks[0] as Developer
	desk.hire(STARTER_DEV.duplicate())
