# Threefold Arsenal

A fast top-down twin-stick roguelite made with Godot 4.7. Fight through three
procedural biomes, defeat a unique boss in each, unlock heroes and permanent
upgrades, then continue into Endless Mode.

## Play

Open `new-game-project/project.godot` in Godot 4.7 and press **F6/F5**, or run:

```sh
godot --path new-game-project
```

Keyboard and mouse: WASD move, mouse aim, left click shoot, Space dash, E use,
Q swap weapons, Esc pause.

Controller: left stick move, right stick aim, RT shoot, B dash, X use, Y swap,
Start pause.

## Release checks

Run the complete isolated test battery without touching the real save or project:

```sh
python3 tools/run_release_checks.py
```

Set `GODOT_BIN` if Godot is not available as `godot`/`godot4` or in the macOS
Downloads folder.

Publishing copy, export commands, and the final checklist live in
[STORE.md](STORE.md). The implementation history is in [PLAN.md](PLAN.md).
