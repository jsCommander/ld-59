extends BaseDialog

# --- @onready ---

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider

# --- Lifecycle ---

func _ready() -> void:
	music_slider.set_value_no_signal(SD.music_volume)
	sfx_slider.set_value_no_signal(SD.sfx_volume)

# --- Handlers ---

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close_dialog({"resume": true})


func _on_music_slider_value_changed(value: float) -> void:
	AM.set_music_volume(value)


func _on_sfx_slider_value_changed(value: float) -> void:
	AM.set_sfx_volume(value)


func _on_resume_button_button_down() -> void:
	close_dialog({"resume": true})


func _on_exit_button_button_down() -> void:
	close_dialog({"exit": true})
