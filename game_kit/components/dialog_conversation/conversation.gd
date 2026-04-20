extends Resource
class_name Conversation

@export var speakers: ConversationSpeakerArray:
	set(value):
		update_speakers_dictionary(value)

@export_file("*.json") var json_file: String:
	set(value):
		_json_file_path = value
		update_lines(_json_file_path)

var _json_file_path: String
var speaker_dictionary: Dictionary[String, ConversationSpeaker] = {}
var lines: Array[ConversationLine] = []

func update_speakers_dictionary(_speakers: ConversationSpeakerArray) -> void:
	speaker_dictionary = {}
	for speaker in _speakers.speakers:
		speaker_dictionary[speaker.id] = speaker

func update_lines(path: String) -> void:
	var json = _json_from_file(path)
	lines = _parse_lines_json(json)

func get_line(line_index: int) -> ConversationLine:
	return lines[line_index]

func get_line_count() -> int:
	return lines.size()

func get_speaker(id: String) -> ConversationSpeaker:
	return speaker_dictionary[id]

func _parse_lines_json(json: JSON) -> Array[ConversationLine]:
	var data = json.data
	assert(data is Array, "Data is not an array")
	
	var result: Array[ConversationLine] = []

	for line_data in data:
		var line = ConversationLine.new()
		line.speaker_id = line_data.get("speaker_id", "")
		line.text = line_data.get("text", "")
		result.append(line)

	return result

func _json_from_file(path: String) -> JSON:
	assert(FileAccess.file_exists(path), "File does not exist: %s" % path)

	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	
	assert(error == OK, "JSON Parse Error: %s" % json.get_error_message())

	return json

func validate_lines() -> void:
	for line in lines:
		assert(speaker_dictionary.has(line.speaker_id), "Speaker not found: %s" % line.speaker_id)
