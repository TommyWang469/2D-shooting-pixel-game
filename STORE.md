# Threefold Arsenal — itch.io Publishing Form

This is the copy-ready release form for **Threefold Arsenal v1.1.0**. Complete
the fields in this order. Keep the page private until the browser and both
desktop downloads have been tested from itch.io itself.

## 1. Basic information — choose these options

| itch.io field | Enter or choose |
| --- | --- |
| Title | `Threefold Arsenal` |
| Project URL | `threefold-arsenal` |
| Short description | `Blast, dash, and loot through three procedural biomes in a fast pixel-art twin-stick roguelite.` |
| Classification | `Games` |
| Kind of project | `HTML Game` |
| Release status | `Released` |
| Pricing | `$0 or Donate` |
| Suggested donation | `$2.00` |
| Visibility while setting up | Keep the new page private |
| Visibility after final testing | `Public` |

Why `HTML Game`: the Web build is the main version and plays on the page, while
the macOS and Windows ZIPs can remain downloadable files on the same page.

## 2. Uploads — use these files and settings

Re-export with **Godot 4.7** before uploading. Do not upload the `build` folder
itself, loose Web files, source code, or the Godot project folder.

| Upload | itch.io display name | Boxes to select |
| --- | --- | --- |
| `build/ThreefoldArsenal-Web.zip` | `Threefold Arsenal v1.1.0 — Play in browser` | Select **This file will be played in the browser**. Do not mark it as a demo. |
| `build/macos/ThreefoldArsenal.zip` | `Threefold Arsenal v1.1.0 — macOS Universal` | Select **macOS**. Do not set an individual price. |
| `build/windows/ThreefoldArsenal-Windows-x86_64.zip` | `Threefold Arsenal v1.1.0 — Windows 64-bit` | Select **Windows**. Do not set an individual price. |

Before upload, open each ZIP once and check:

- The Web ZIP has `index.html` at the top level, not inside another folder.
- The macOS ZIP contains the Threefold Arsenal application.
- The Windows ZIP contains both `ThreefoldArsenal.exe` and
  `ThreefoldArsenal.pck` at the same level.

## 3. Embed options — choose these after uploading the Web ZIP

| itch.io field | Choose |
| --- | --- |
| How the game is displayed | `Embed in page` |
| Viewport width | `960` |
| Viewport height | `540` |
| Click to play | On |
| Fullscreen button | On |
| Scrollbars | Off |
| Mobile friendly | Off |

The game uses a 16:9, 480×270 internal canvas and is designed for keyboard,
mouse, or controller. The 960×540 embed keeps its pixel art sharp at 2× scale.
Do not mark it mobile friendly because there are no touch controls.

## 4. Description — copy everything in this section into itch.io

# Threefold Arsenal

**Blast. Dash. Loot. Descend.**

Threefold Arsenal is a fast, top-down twin-stick roguelite where every run
carves a new path through the Stone Halls, Ember Depths, and Frost Crypt. Clear
procedural combat rooms, collect an arsenal of wildly different weapons, defeat
three named bosses, and bank gems for permanent upgrades and new heroes.

Beat all three biomes to claim victory—or keep going into Endless Mode and see
how long your build can survive.

## Features

- **13 distinct weapons** — use the Blaster, Shotgun, Crossbow, Homing Wand,
  wall-bouncing Ricochet, Frost Bow, Flame Spitter, Minigun, Railgun, and more.
  Carry up to three weapons and swap during combat.
- **Three unlockable heroes** — Gunner uses Overdrive, Knight uses Shield Bash,
  and Rogue uses Ambush.
- **Three unique bosses** — face the Summoner King, Magma Tyrant, and Frozen
  Warden, each with its own attacks.
- **Permanent progression** — hunt golden elite enemies for gems, unlock heroes,
  and improve Vitality, Power, Swiftness, Recovery, Fortune, and Magnet.
- **Procedural dungeons** — explore changing room layouts with a minimap and a
  guide arrow that helps you find the last enemy.
- **Keyboard and mouse plus full controller support.**
- **Original code-generated pixel art, sound effects, and music.**
- **Single-player and playable offline after downloading.**

## How to play

**Keyboard and mouse**

- Move: WASD or arrow keys
- Aim: Mouse
- Shoot: Left click
- Dash: Space or middle mouse button
- Interact/use: E or F
- Swap weapon: Q or Tab
- Pause: Esc
- Open Settings from the title screen: S

**Controller**

- Move: Left stick or D-pad
- Aim: Right stick
- Shoot: Right trigger
- Dash: B / Circle
- Interact/use: X / Square
- Swap weapon: Y / Triangle
- Pause: Start / Menu

## How to play in your browser

1. Click **Run game** above.
2. Click inside the game once so it receives keyboard and mouse input.
3. For the clearest view, use itch.io's fullscreen button.

A desktop browser is recommended. The game does not have touch controls, so it
is not designed for phones or tablets. If the browser version does not load,
refresh the page once or use one of the desktop downloads below.

## How to download and open the Windows version

1. Download **Threefold Arsenal v1.1.0 — Windows 64-bit**.
2. Right-click the downloaded ZIP and choose **Extract All**. Do not run the game
   from inside the ZIP.
3. Open the extracted folder and double-click `ThreefoldArsenal.exe`.
4. Keep `ThreefoldArsenal.exe` and `ThreefoldArsenal.pck` together in the same
   folder.

This independent release is not digitally signed. Windows SmartScreen may show
a warning the first time it opens. If you downloaded it from this official
itch.io page, choose **More info**, then **Run anyway**.

## How to download and open the macOS version

1. Download **Threefold Arsenal v1.1.0 — macOS Universal**.
2. Double-click the ZIP to extract it.
3. Move **Threefold Arsenal** to Applications if you want, then open it.
4. If macOS blocks the first launch because the game is not notarized,
   Control-click the app, choose **Open**, then choose **Open** again.

The macOS build is Universal and supports both Apple silicon and Intel Macs.

## Settings and accessibility

Open **Settings** from the title or pause menu to adjust Master, Music, and SFX
volume, toggle fullscreen, and turn screen shake off. Combat includes bright
pixel hit flashes and optional screen shake.

## Feedback and bug reports

If you find a problem, leave a comment on this itch.io page. Please include
whether you used Web, Windows, or macOS, your browser or operating-system
version, and what happened before the problem appeared.

## Credits

Created by Tommy with Godot 4.7. All game sprites, sound effects, and music were
generated from the project's own code-based asset tools.

Thank you for playing!

## 5. Genre, tags, and metadata — choose these options

| itch.io field | Choose |
| --- | --- |
| Genre | `Action` |
| Tags (maximum 10) | `Roguelite`, `Action Roguelike`, `Twin Stick Shooter`, `Pixel Art`, `Procedural Generation`, `Dungeon Crawler`, `Top-Down`, `Singleplayer`, `Controller`, `Difficult` |
| Made with | `Godot` |
| Platforms | `Windows`, `macOS`, `HTML5` |
| Multiplayer support | `Singleplayer` |
| Input methods | `Keyboard`, `Mouse`, `Gamepad` |
| Languages | `English` only |
| Average session | `About a half-hour`; Endless Mode can run longer |
| Adult content | No |
| Generative AI disclosure, if shown | No — procedural/code-generated art and audio are not generative AI |

Only choose tags that itch.io currently offers in its autocomplete. If one tag
is unavailable, omit it instead of creating an unrelated replacement.

## 6. Images and page presentation

- **Cover image:** upload a 630×500 image. Use the title, hero, and readable
  combat silhouettes; do not fill it with small text.
- **Screenshots:** upload 3–5 images: title/hero select, Stone Halls combat, Ember
  Depths combat, Frost Crypt combat, and one boss or upgrades screen.
- **Animated GIF:** optional. If used, keep it short and avoid rapid flashing.
- **Page colors:** dark purple/black background, warm off-white text, gold links,
  and a purple or red button color. Keep description text easy to read.
- **Comments:** enable comments so players have a simple support channel.

## 7. Final publish checklist

- [ ] The title and version still read **Threefold Arsenal v1.1.0** in the game.
- [ ] The complete local release check passes before export.
- [ ] The Web ZIP launches from itch.io and audio begins after clicking the game.
- [ ] Keyboard/mouse and one controller both work in the browser build.
- [ ] The Windows ZIP was downloaded from itch.io, extracted, and launched.
- [ ] The macOS ZIP was downloaded from itch.io, extracted, and launched.
- [ ] Saving, settings, hero unlocks, and permanent upgrades survive a restart.
- [ ] The cover image and at least three screenshots are uploaded.
- [ ] The page is previewed while private.
- [ ] After every check passes, change visibility to **Public** and save.

## Official itch.io references — do not paste into the store description

- Creating and publishing a project: <https://itch.io/docs/creators/getting-started>
- Uploading an HTML game: <https://itch.io/docs/creators/html5>
- Pricing choices: <https://itch.io/docs/creators/pricing>
- Content quality guidelines: <https://itch.io/docs/creators/quality-guidelines>
