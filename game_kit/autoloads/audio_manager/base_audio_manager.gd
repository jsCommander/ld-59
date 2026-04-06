class_name BaseAudioManager extends Node

@export var sfx_pool_size: int = 8
@export var crossfade_duration: float = 2.0

var _music_registry: Dictionary[int, AudioStream]
var _sfx_registry: Dictionary[int, AudioStream]

var _current_music_id: int = -1
var _active_music_player: AudioStreamPlayer
var _standby_music_player: AudioStreamPlayer
var _crossfade_tween: Tween

var _playlist: Array
var _playlist_index: int = -1

var _sfx_available_players: Array[AudioStreamPlayer]
var _sfx_playing: Dictionary[AudioStreamPlayer, int]
var _sfx_queue: Array[AudioManagerSfxItem]


func _ready() -> void:
	_create_music_players()
	_create_sfx_pool()
	Log.log_debug(name, "AudioManager ready. SFX pool size: %d" % sfx_pool_size)


func _create_music_players() -> void:
	_active_music_player = AudioStreamPlayer.new()
	_active_music_player.bus = "Music"
	_active_music_player.finished.connect(_on_music_finished)
	add_child(_active_music_player)

	_standby_music_player = AudioStreamPlayer.new()
	_standby_music_player.bus = "Music"
	_standby_music_player.finished.connect(_on_music_finished)
	add_child(_standby_music_player)


func _create_sfx_pool() -> void:
	for _i in sfx_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Sfx"
		add_child(player)
		player.finished.connect(_on_sfx_finished.bind(player))
		_sfx_available_players.append(player)


func register_music(id: int, stream: AudioStream) -> void:
	_music_registry[id] = stream


func register_sfx(id: int, stream: AudioStream) -> void:
	_sfx_registry[id] = stream


func play_playlist(ids: Array, crossfade: bool = true) -> void:
	_playlist = ids.duplicate()
	_playlist.shuffle()
	_playlist_index = 0
	_play_music_internal(_playlist[0], crossfade)
	Log.log_info(name, "Started playlist with %d tracks (shuffled)" % _playlist.size())


func _on_music_finished() -> void:
	if _playlist.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist.size()
	if _playlist_index == 0:
		_playlist.shuffle()
	_play_music_internal(_playlist[_playlist_index])


func play_music(id: int, crossfade: bool = true) -> void:
	_playlist = []
	_playlist_index = -1
	_play_music_internal(id, crossfade)


func _play_music_internal(id: int, crossfade: bool = true) -> void:
	if id == _current_music_id:
		return
	if not _music_registry.has(id):
		Log.log_warn(name, "Music id not registered: %d" % id)
		return

	var stream: AudioStream = _music_registry[id]

	if _crossfade_tween:
		_crossfade_tween.kill()

	if crossfade and _active_music_player.playing:
		_crossfade_to(stream)
	else:
		_hard_switch_to(stream)

	_current_music_id = id
	Log.log_info(name, "Playing music: %s" % stream.resource_path)


func _crossfade_to(stream: AudioStream) -> void:
	var fading_out: AudioStreamPlayer = _active_music_player
	_standby_music_player.stream = stream
	_standby_music_player.volume_db = -80.0
	_standby_music_player.play()

	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(fading_out, "volume_db", -80.0, crossfade_duration)
	_crossfade_tween.tween_property(_standby_music_player, "volume_db", 0.0, crossfade_duration)
	_crossfade_tween.chain().tween_callback(fading_out.stop)

	_swap_music_players()


func _hard_switch_to(stream: AudioStream) -> void:
	_active_music_player.stop()
	_standby_music_player.stream = stream
	_standby_music_player.volume_db = 0.0
	_standby_music_player.play()
	_swap_music_players()


func _swap_music_players() -> void:
	var temp: AudioStreamPlayer = _active_music_player
	_active_music_player = _standby_music_player
	_standby_music_player = temp


func stop_music() -> void:
	if not _active_music_player.playing and not _standby_music_player.playing:
		return

	if _crossfade_tween:
		_crossfade_tween.kill()

	_standby_music_player.stop()

	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_active_music_player, "volume_db", -80.0, crossfade_duration)
	_crossfade_tween.tween_callback(_active_music_player.stop)

	_current_music_id = -1
	Log.log_info(name, "Stopping music")


func play_sfx(id: int, pitch_variance: float = 0.0, volume: float = 1.0) -> void:
	if not _sfx_registry.has(id):
		Log.log_warn(name, "SFX id not registered: %d" % id)
		return

	var stream: AudioStream = _sfx_registry[id]
	var pitch: float = maxf(0.01, randf_range(1.0 - pitch_variance, 1.0 + pitch_variance))
	var vol_db: float = linear_to_db(volume)

	if _sfx_available_players.size() > 0:
		var player: AudioStreamPlayer = _sfx_available_players.pop_front()
		_play_sfx_on(player, id, stream, pitch, vol_db)
	else:
		var item: AudioManagerSfxItem = AudioManagerSfxItem.new()
		item.id = id
		item.stream = stream
		item.pitch_scale = pitch
		item.volume_db = vol_db
		_sfx_queue.push_back(item)
		Log.log_warn(name, "SFX pool exhausted, queuing: %d" % id)


func _play_sfx_on(player: AudioStreamPlayer, id: int, stream: AudioStream, pitch: float, vol_db: float) -> void:
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = vol_db
	player.play()
	_sfx_playing[player] = id


func stop_sfx(id: int) -> void:
	_sfx_queue = _sfx_queue.filter(func(item: AudioManagerSfxItem) -> bool: return item.id != id)

	var to_stop: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _sfx_playing:
		if _sfx_playing[player] == id:
			to_stop.append(player)

	for player: AudioStreamPlayer in to_stop:
		player.stop()
		_sfx_playing.erase(player)
		_sfx_available_players.append(player)

	Log.log_debug(name, "Stopped SFX: %d (players: %d)" % [id, to_stop.size()])


func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_sfx_playing.erase(player)

	if player in _sfx_available_players:
		return

	if _sfx_queue.size() > 0:
		var item: AudioManagerSfxItem = _sfx_queue.pop_front()
		_play_sfx_on(player, item.id, item.stream, item.pitch_scale, item.volume_db)
		Log.log_debug(name, "Dequeued SFX: %d" % item.id)
	else:
		_sfx_available_players.append(player)
