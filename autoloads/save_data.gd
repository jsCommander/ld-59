class_name SaveData extends Node

# --- Constants ---

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_SFX_VOLUME: String = "sfx_volume"

const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_SFX_VOLUME: float = 1.0

# --- State ---

var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME

var _config: ConfigFile

# --- Lifecycle ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = ConfigFile.new()
	_load()

# --- Public ---

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_config.set_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, music_volume)
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_config.set_value(SECTION_AUDIO, KEY_SFX_VOLUME, sfx_volume)
	_save()

# --- Private ---

func _load() -> void:
	var err: Error = _config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		Log.log_warn(name, "Failed to load settings: %s" % error_string(err))
		return
	music_volume = _config.get_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, DEFAULT_MUSIC_VOLUME)
	sfx_volume = _config.get_value(SECTION_AUDIO, KEY_SFX_VOLUME, DEFAULT_SFX_VOLUME)
	Log.log_info(name, "Settings loaded. music=%.2f sfx=%.2f" % [music_volume, sfx_volume])


func _save() -> void:
	var err: Error = _config.save(CONFIG_PATH)
	if err != OK:
		Log.log_warn(name, "Failed to save settings: %s" % error_string(err))
