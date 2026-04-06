# AudioManager — Game Kit Audio System

## Overview

Reusable audio manager component for game_kit. Single scene + script registered as autoload. Provides music playback with crossfade and SFX playback with object pooling and pitch variance.

## Scope

- Crossfade between music tracks (two AudioStreamPlayers, ping-pong)
- SFX object pool (configurable size, queue when full)
- Pitch variance on SFX

Out of scope: adaptive music (dual-track idle/combat), inherited scenes.

## File Structure

```
game_kit/components/audio_manager/
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
# Configuration — called by game code on init
func set_sfx_map(map: Dictionary) -> void       # Dictionary[String, AudioStream]
func set_music_map(map: Dictionary) -> void      # Dictionary[String, AudioStream]

# Music
func play_music(id: String, crossfade: bool = true) -> void
func stop_music() -> void

# SFX
func play_sfx(id: String, pitch_variance: float = 0.0, volume: float = 1.0) -> void
func stop_sfx(id: String) -> void
```

## Internal Architecture

### Music — Ping-Pong Crossfade

Two `AudioStreamPlayer` nodes on the "Music" bus. One is active, one is standby.

`play_music(id, crossfade)`:
- Look up stream from `_music_map[id]`
- If `crossfade == true` and something is playing:
  - Tween active player's `volume_db` to `-80.0` over `crossfade_duration`, then stop it
  - Assign stream to standby player, tween its `volume_db` from `-80.0` to `0.0`
  - Swap active/standby references
- If `crossfade == false` or nothing is playing:
  - Stop active player immediately
  - Assign stream to standby player, set `volume_db = 0.0`, play
  - Swap references

`stop_music()`:
- Fade out active player to `-80.0`, then stop

### SFX — Object Pool with Queue

Array of `AudioStreamPlayer` nodes on the "Sfx" bus, created in `_ready()` based on `sfx_pool_size`.

Two data structures:
- `_sfx_available: Array[AudioStreamPlayer]` — free players
- `_sfx_queue: Array` — pending items when pool is exhausted

`play_sfx(id, pitch_variance, volume)`:
- Look up stream from `_sfx_map[id]`
- Calculate pitch: `randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)`
- If free player available: assign stream, pitch, volume, play
- Else: enqueue

When a player finishes (`finished` signal):
- If queue is not empty: dequeue and play
- Else: return player to available pool

`stop_sfx(id)`:
- Find playing player(s) with matching id, stop them, return to pool

### Pitch Variance Reference

| Variance | Range        | Use case              |
|----------|--------------|-----------------------|
| 0.0      | 1.0          | No variation          |
| 0.2      | 0.8 — 1.2    | Subtle (steps, clicks)|
| 0.5      | 0.5 — 1.5    | Noticeable (hits)     |

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
