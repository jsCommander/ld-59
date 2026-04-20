extends CanvasLayer
class_name DialogManager

@onready var dialog_root: Control = %DialogRoot
@onready var color_rect: ColorRect = $Control/ColorRect

func _ready() -> void:
	color_rect.visible = false
	self.visible = false
	
func open_dialog(scene: PackedScene, data: Dictionary, pause_game := false)-> Signal:
	self.visible = true
	color_rect.visible = true

	var dialog_instance: BaseDialog = scene.instantiate()

	dialog_root.add_child(dialog_instance)
	dialog_instance.set_data(data)

	dialog_instance.finished.connect(func(_data):
		Log.log_info(self.name, "Dialog finished")
		dialog_instance.queue_free()
		self.visible = false
		color_rect.visible = false
		
		if pause_game:
			get_tree().paused = false
	)

	if pause_game:
		get_tree().paused = true

	return dialog_instance.finished
