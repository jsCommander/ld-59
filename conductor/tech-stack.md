# Tech Stack: Restoration Protocol

## Engine

- **Godot 4.6** — open-source game engine
- **Rendering:** GL Compatibility (mobile-friendly fallback)
- **Resolution:** 1920x1080 (16:9)

## Language

- **GDScript** with full static typing (all variables, arguments, return types, collections)

## Project Structure

```
game_kit/       # Reusable engine-agnostic components (camera, dialogs, UI, VFX, utils)
scenes/         # Game entities (drill, plant, robot, lab)
levels/         # Level scenes and level-specific scripts
scripts/        # Resource class definitions (stats, configs)
resources/      # .tres instances (actual values)
assets/         # Art, music, SFX
data/           # External data files (configs)
```

## Architecture

- Composition over inheritance (component nodes)
- Autonomous agents (entities find each other via groups)
- Signals up, calls down (no sibling communication)
- Data in .tres Resources, logic in scenes/scripts
- Physics layers as interaction contract

## Export Targets

| Platform | Priority | Format | Distribution |
|----------|----------|--------|-------------|
| Web | Primary | HTML5 | itch.io (Butler CLI) |
| Android | Secondary | APK | Direct / itch.io |

## Build & Deploy

- `./build_web.sh` — export to `releases/web/`, zip
- `./build_android.sh` — export debug APK to `releases/android/`
- `./publish_web.sh` — build web + push to itch.io via Butler

## Dependencies

- **Game Kit** (`game_kit/`) — in-repo reusable components:
  - Scene manager with fade transitions
  - Character animation rig
  - Smooth follow camera with zoom/shake
  - JSON-driven dialog system
  - UI components (progress bars, action bars, resource counters, upgrade dialogs)
  - VFX (damage numbers, hurt/slash effects)
  - Shaders (color overlay, masks)
  - Utils (tween factories, logger, targeting helpers)

## External Tools

- **Butler CLI** — itch.io deployment
- **Godot headless** — CI/CD export
