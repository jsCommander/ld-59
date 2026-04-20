# Game Kit — Build

- Shell scripts for exporting and publishing Godot projects. Run from project root.
- NEVER hardcode game-specific names (`Panda.apk`, `ld57`) here — these scripts are shared across projects. Parametrize or move game-specific values to the game repo.
- NEVER modify export presets or Godot project settings from scripts. Scripts only invoke `godot --export-*`.

---

## Build Scripts Export, Nothing Else

Scripts clean the output folder, run `godot --export-*`, and report the result. No game logic, no asset processing, no post-build patching.

```bash
clean
build
# done
```

Not scripts that modify source files, generate code, or touch `.tscn`/`.tres` — builds are read-only against the project.

---

## Publish Scripts Call Build First

`publish_web.sh` runs the build, then pushes the artifact via `butler`. Keep the two-step chain: build then publish.

```bash
./build_web.sh
butler push "$GAME_ZIP" "$ITCH_USERNAME/$ITCH_GAME_NAME:web"
```

Not publishing without building first — always a fresh export before push.

---

## Run From Project Root

All paths are relative to `./releases/`. Run scripts from the Godot project root.

```bash
./game_kit/build/build_web.sh
```

Not from inside `game_kit/build/` — relative paths will break.
