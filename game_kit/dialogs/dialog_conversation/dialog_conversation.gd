extends BaseDialog

@onready var speaker_texture: TextureRect = %SpeakerTexture
@onready var text: Label = %Text
@onready var speaker_name: Label = %SpeakerName

var conversation: Conversation
var current_line_index: int = 0
var allow_complitly_skip: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and allow_complitly_skip:
		close_dialog({"exit": true})

	var is_skip_key_pressed = false
	
	if Input.is_action_just_pressed("action_main") or event.is_action_pressed("ui_cancel"):
		is_skip_key_pressed = true
	
	var skip_keys = [KEY_ENTER, KEY_SPACE, KEY_E]
	for skip_key in skip_keys:
		if event is InputEventKey and event.keycode == skip_key and event.pressed:
			is_skip_key_pressed = true
			break
	
	if is_skip_key_pressed:
		show_next_line()

func set_data(data: Dictionary) -> void:
	assert(data.conversation != null, "Conversation not found in data")
	conversation = data.conversation

	if data.has("line_index"):
		current_line_index = data.line_index

	if data.has("allow_complitly_skip"):
		allow_complitly_skip = data.allow_complitly_skip

	conversation.validate_lines()

	assert(current_line_index >= 0 and current_line_index < conversation.get_line_count(), "Current line index out of bounds")
	
	var line = conversation.get_line(current_line_index)
	update_ui(line)

func update_ui(line: ConversationLine) -> void:
	var speaker = conversation.get_speaker(line.speaker_id)
	assert(speaker != null, "Speaker not found: %s" % line.speaker_id)

	speaker_texture.texture = speaker.texture
	speaker_name.text = speaker.name
	text.text = line.text

func show_next_line() -> void:
	current_line_index += 1
	
	if current_line_index >= conversation.get_line_count():
		close_dialog({"finish": true})
	else:
		var next_line = conversation.get_line(current_line_index)
		update_ui(next_line)
