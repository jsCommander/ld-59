# AudioManager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable AudioManager autoload to game_kit with music crossfade, SFX object pooling, and pitch variance.

**Architecture:** Single scene (`audio_manager.tscn`) with one script (`audio_manager.gd`). Two `AudioStreamPlayer` nodes for music ping-pong crossfade. SFX pool created programmatically in `_ready()`. Registered as autoload by the game project.

**Tech Stack:** Godot 4, GDScript, AudioStreamPlayer, Tween

**Spec:** `docs/superpowers/specs/2026-04-06-audio-manager-design.md`

---

### Task 1: Create AudioManager scene and script skeleton

**Files:**
- Create: `game_kit/autoloads/audio_manager/audio_manager.gd`
- Create: `game_kit/autoloads/audio_manager/audio_manager.tscn`

- [ ] **Step 1: Create the script with exports, class_name, and empty API stubs**

```gdscript
class_name AudioManager extends Node

@export var sfx_pool_size: int = 8
@export var crossfade_duration: float = 2.0

var _music_map: Dictionary[String, AudioStream] = {}
var _sfx_map: Dictionary[String, AudioStream] = {}

var _current_music_id: String = ""
var _active_music_player: AudioStreamPlayer
var _standby_music_player: AudioStreamPlayer
var _crossfade_tween: Tween

var _sfx_available: Array[AudioStreamPlayer] = []
var _sfx_playing: Dictionary = {}  # Dictionary[AudioStreamPlayer, String] — typed dict not supported for Object keys
var _sfx_queue: Array = []  # Array[SfxItem] — typed array not supported for inner class types

class SfxItem:
	var id: String
	var stream: AudioStream
	var pitch_scale: float
	var volume_db: float


func _ready() -> void:
	_active_music_player = $MusicPlayerA
	_standby_music_player = $MusicPlayerB
	_create_sfx_pool()
	Log.log_debug(name, "AudioManager ready. SFX pool size: %d" % sfx_pool_size)


func _create_sfx_pool() -> void:
	for i in sfx_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Sfx"
		add_child(player)
		player.finished.connect(_on_sfx_finished.bind(player))
		_sfx_available.append(player)


func set_sfx_map(map: Dictionary[String, AudioStream]) -> void:
	_sfx_map = map


func set_music_map(map: Dictionary[String, AudioStream]) -> void:
	_music_map = map


func play_music(_id: String, _crossfade: bool = true) -> void:
	pass


func stop_music() -> void:
	pass


func play_sfx(_id: String, _pitch_variance: float = 0.0, _volume: float = 1.0) -> void:
	pass


func stop_sfx(_id: String) -> void:
	pass


func _on_sfx_finished(_player: AudioStreamPlayer) -> void:
	pass
```

- [ ] **Step 2: Create the scene file**

Create `audio_manager.tscn` with root Node (script: `audio_manager.gd`) and two `AudioStreamPlayer` children named `MusicPlayerA` and `MusicPlayerB`, both on bus "Music".

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://game_kit/autoloads/audio_manager/audio_manager.gd" id="1"]

[node name="AudioManager" type="Node"]
script = ExtResource("1")

[node name="MusicPlayerA" type="AudioStreamPlayer" parent="."]
bus = &"Music"

[node name="MusicPlayerB" type="AudioStreamPlayer" parent="."]
bus = &"Music"
```

- [ ] **Step 3: Commit**

```bash
git add game_kit/autoloads/audio_manager/
git commit -m "feat: add AudioManager scene and script skeleton"
```

---

### Task 2: Implement music crossfade

**Files:**
- Modify: `game_kit/autoloads/audio_manager/audio_manager.gd`

- [ ] **Step 1: Implement `play_music`**

Replace the `play_music` stub with:

```gdscript
func play_music(id: String, crossfade: bool = true) -> void:
	if not _music_map.has(id):
		Log.log_warn(name, "Music id not found: %s" % id)
		return
	if id == _current_music_id:
		return

	var stream: AudioStream = _music_map[id]

	if _crossfade_tween:
		_crossfade_tween.kill()

	if crossfade and _active_music_player.playing:
		_crossfade_to(stream)
	else:
		_hard_switch_to(stream)

	_current_music_id = id
	Log.log_info(name, "Playing music: %s" % id)


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
```

- [ ] **Step 2: Implement `stop_music`**

Replace the `stop_music` stub with:

```gdscript
func stop_music() -> void:
	if not _active_music_player.playing and not _standby_music_player.playing:
		return

	if _crossfade_tween:
		_crossfade_tween.kill()

	# Stop standby player in case it was mid-fadeout from a crossfade
	_standby_music_player.stop()

	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_active_music_player, "volume_db", -80.0, crossfade_duration)
	_crossfade_tween.tween_callback(_active_music_player.stop)

	_current_music_id = ""
	Log.log_info(name, "Stopping music")
```

- [ ] **Step 3: Commit**

```bash
git add game_kit/autoloads/audio_manager/audio_manager.gd
git commit -m "feat: implement music crossfade in AudioManager"
```

---

### Task 3: Implement SFX pool with pitch variance

**Files:**
- Modify: `game_kit/autoloads/audio_manager/audio_manager.gd`

- [ ] **Step 1: Implement `play_sfx`**

Replace the `play_sfx` stub with:

```gdscript
func play_sfx(id: String, pitch_variance: float = 0.0, volume: float = 1.0) -> void:
	if not _sfx_map.has(id):
		Log.log_warn(name, "SFX id not found: %s" % id)
		return

	var stream: AudioStream = _sfx_map[id]
	var pitch: float = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	var vol_db: float = linear_to_db(volume)

	if _sfx_available.size() > 0:
		var player: AudioStreamPlayer = _sfx_available.pop_front()
		_play_sfx_on(player, id, stream, pitch, vol_db)
	else:
		var item: SfxItem = SfxItem.new()
		item.id = id
		item.stream = stream
		item.pitch_scale = pitch
		item.volume_db = vol_db
		_sfx_queue.push_back(item)
		Log.log_warn(name, "SFX pool exhausted, queuing: %s" % id)


func _play_sfx_on(player: AudioStreamPlayer, id: String, stream: AudioStream, pitch: float, vol_db: float) -> void:
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = vol_db
	player.play()
	_sfx_playing[player] = id
```

- [ ] **Step 2: Implement `_on_sfx_finished`**

Replace the `_on_sfx_finished` stub with:

```gdscript
func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_sfx_playing.erase(player)

	if _sfx_queue.size() > 0:
		var item: SfxItem = _sfx_queue.pop_front()
		_play_sfx_on(player, item.id, item.stream, item.pitch_scale, item.volume_db)
		Log.log_debug(name, "Dequeued SFX: %s" % item.id)
	else:
		_sfx_available.append(player)
```

- [ ] **Step 3: Implement `stop_sfx`**

Replace the `stop_sfx` stub with:

```gdscript
func stop_sfx(id: String) -> void:
	# Clear queued items with this id
	_sfx_queue = _sfx_queue.filter(func(item: SfxItem) -> bool: return item.id != id)

	# Stop active players with this id
	var to_stop: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _sfx_playing:
		if _sfx_playing[player] == id:
			to_stop.append(player)

	for player: AudioStreamPlayer in to_stop:
		player.stop()
		_sfx_playing.erase(player)
		_sfx_available.append(player)

	Log.log_debug(name, "Stopped SFX: %s (players: %d)" % [id, to_stop.size()])
```

- [ ] **Step 4: Commit**

```bash
git add game_kit/autoloads/audio_manager/audio_manager.gd
git commit -m "feat: implement SFX pool with pitch variance in AudioManager"
```

---

### Task 4: Verify in Godot editor

**Files:**
- None created/modified — manual verification only

- [ ] **Step 1: Register autoload in project.godot**

Add to `project.godot` under `[autoload]`:
```
AudioManager="*res://game_kit/autoloads/audio_manager/audio_manager.tscn"
```

- [ ] **Step 2: Verify scene loads without errors**

Open the project in Godot editor. Check the Output panel for errors. Verify the AudioManager node appears in the scene tree with MusicPlayerA and MusicPlayerB children plus 8 SFX pool players.

- [ ] **Step 3: Quick smoke test from test level**

Add temporary code to `test_level` or any existing scene's `_ready()`:

```gdscript
func _ready() -> void:
	AudioManager.set_music_map({
		"spb": preload("res://assets/music/spb.mp3"),
		"fr": preload("res://assets/music/fr.mp3"),
	})
	AudioManager.play_music("spb")
	await get_tree().create_timer(3.0).timeout
	AudioManager.play_music("fr")  # should crossfade
```

Verify: music starts, crossfade is audible after 3 seconds.

- [ ] **Step 4: Remove test code, commit**

Remove the temporary test code. Commit if any changes were needed.

```bash
git add -A
git commit -m "chore: register AudioManager autoload"
```
