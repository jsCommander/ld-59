# Game Kit — Build

- Shell scripts for exporting and publishing Godot projects. Run from project root.
- These scripts currently contain project-specific artifact and itch.io names; verify them before reusing the kit in another project.
- Do not modify source scenes or resources during a build.

---

## Build Scripts Export and Package

Scripts clean the output folder, run `godot --export-*`, and may package or publish the resulting artifacts.

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
