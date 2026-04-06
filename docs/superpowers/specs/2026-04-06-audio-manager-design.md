# AudioManager — Game Kit Audio System

## Overview

Reusable audio manager for game_kit. Single scene + script, registered as autoload. Provides music playback with crossfade and SFX playback with object pooling and pitch variance. All sounds are non-positional (`AudioStreamPlayer`, not `AudioStreamPlayer2D`).

## Scope

- Crossfade between music tracks (two AudioStreamPlayers, ping-pong)
- SFX object pool (configurable size, queue when full)
- Pitch variance on SFX

Out of scope: adaptive music (dual-track idle/combat), inherited scenes, positional audio.

## File Structure

```
game_kit/autoloads/audio_manager/
├── audio_manager.gd
└── audio_manager.tscn
```

## Exports

```gdscript
@export var sfx_pool_size: int = 8
@export var crossfade_duration: float = 2.0
```

## Public API

```gdscript
class_name AudioManager extends Node

# Configuration — called by game code on init
func set_sfx_map(map: Dictionary[String, AudioStream]) -> void
func set_music_map(map: Dictionary[String, AudioStream]) -> void

# Music
func play_music(id: String, crossfade: bool = true) -> void
func stop_music() -> void

# SFX
func play_sfx(id: String, pitch_variance: float = 0.0, volume: float = 1.0) -> void
func stop_sfx(id: String) -> void
```

## Internal Architecture

### Music — Ping-Pong Crossfade

Two `AudioStreamPlayer` nodes on the "Music" bus. One is active, one is standby. Track `_current_music_id: String` to detect duplicate calls.

`play_music(id, crossfade)`:
- If `id` not in `_music_map`: `Log.log_warn`, return
- If `id == _current_music_id`: return (no-op, don't crossfade into self)
- Kill any active `_crossfade_tween` to handle rapid calls
- If `crossfade == true` and something is playing:
  - Tween active player's `volume_db` to `-80.0` over `crossfade_duration`, then stop it
  - Assign stream to standby player, tween its `volume_db` from `-80.0` to `0.0`
  - Swap active/standby references
- If `crossfade == false` or nothing is playing:
  - Stop active player immediately
  - Assign stream to standby player, set `volume_db = 0.0`, play
  - Swap references
- Update `_current_music_id = id`

`stop_music()`:
- Fade out active player to `-80.0` over `crossfade_duration`, then stop
- Set `_current_music_id = ""`

### SFX — Object Pool with Queue

Array of `AudioStreamPlayer` nodes on the "Sfx" bus, created in `_ready()` based on `sfx_pool_size`.

Data structures:
- `_sfx_available: Array[AudioStreamPlayer]` — free players
- `_sfx_playing: Dictionary[AudioStreamPlayer, String]` — maps active player to its sfx id (for `stop_sfx` lookup)
- `_sfx_queue: Array[SfxItem]` — pending items when pool is exhausted

Queue item structure:
```gdscript
class SfxItem:
    var id: String
    var stream: AudioStream
    var pitch_scale: float
    var volume_db: float
```

`play_sfx(id, pitch_variance, volume)`:
- If `id` not in `_sfx_map`: `Log.log_warn`, return
- Look up stream from `_sfx_map[id]`
- Calculate pitch: `randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)`
- Convert volume: `linear_to_db(volume)` (1.0 = 0 dB, 0.5 = -6 dB, 0.0 = silence)
- If free player available: assign stream, pitch, volume_db, play; add to `_sfx_playing`
- Else: enqueue as `SfxItem`; `Log.log_warn` on pool exhaustion

When a player finishes (`finished` signal):
- Remove from `_sfx_playing`
- If queue is not empty: dequeue and play
- Else: return player to `_sfx_available`

`stop_sfx(id)`:
- Iterate `_sfx_playing`, find player(s) where value == id, stop them, remove from `_sfx_playing`, return to `_sfx_available`

### Pitch Variance Reference

| Variance | Range        | Use case              |
|----------|--------------|-----------------------|
| 0.0      | 1.0          | No variation          |
| 0.2      | 0.8 — 1.2    | Subtle (steps, clicks)|
| 0.5      | 0.5 — 1.5    | Noticeable (hits)     |

### Logging

- `Log.log_info`: music track changes, stop_music
- `Log.log_warn`: invalid id in play_sfx/play_music, SFX pool exhaustion
- `Log.log_debug`: pool creation in _ready, sfx queue/dequeue

## Audio Bus Layout

Uses existing `default_audio_bus_layout.tres`:

```
Master
├── Music
└── Sfx
```

## Usage Example

```gdscript
# In game autoload or level _ready()
func _ready() -> void:
    AudioManager.set_music_map({
        "exploration": preload("res://assets/music/exploration.ogg"),
        "boss": preload("res://assets/music/boss.ogg"),
    })
    AudioManager.set_sfx_map({
        "hit": preload("res://assets/sfx/hit.ogg"),
        "click": preload("res://assets/sfx/click.ogg"),
    })

# Playing
AudioManager.play_music("exploration")
AudioManager.play_music("boss")  # crossfades from exploration
AudioManager.play_music("boss", false)  # hard switch, no fade

AudioManager.play_sfx("hit", 0.3)  # with pitch variance
AudioManager.play_sfx("click")     # no variance
```
