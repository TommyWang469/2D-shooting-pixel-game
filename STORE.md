# Threefold Arsenal — Store & Publishing Guide

## Store page copy (itch.io)

**Tagline:** Blast. Dash. Loot. Descend.

**Short description:**
A fast, juicy twin-stick roguelite. Fight through three procedurally-carved
biomes — Stone Halls, Ember Depths, Frost Crypt — each with its own enemies,
music, and a unique named boss. Collect gems to unlock heroes and buy permanent
upgrades, then push into Endless Mode.

**Feature bullets:**
- 🔫 **13 distinct weapons** — from the humble Blaster to the Homing Wand,
  wall-bouncing Ricochet, chilling Frost Bow, Flame Spitter, Minigun and the
  pierce-everything Railgun. Carry up to 3, swap on the fly.
- 🗡️ **3 heroes with real skills** — Gunner's OVERDRIVE, Knight's SHIELD BASH,
  Rogue's AMBUSH. Unlock them with gems earned in runs.
- 👑 **3 unique bosses** — the Summoner King, the Magma Tyrant, and the Frozen
  Warden, each with its own attack patterns.
- 💎 **Meta-progression** — hunt golden elite enemies for gems; buy permanent
  upgrades (Vitality, Power, Swiftness, Recovery, Fortune, Magnet).
- 🗺️ Procedural rooms (caves, crosses, donuts, lobed chambers), minimap,
  guide arrow — you'll never lose the last enemy.
- 🎮 Full controller support · 🖥️ keyboard + mouse · web & desktop.
- 🎵 Every sprite and every note of music is procedurally generated code.

**Suggested pricing:** launch free/web + "name your price" desktop build on
itch.io to build an audience; $2.99–4.99 once there are ~5 more hours of
content (more chapters/heroes). Soul-Knight-likes monetize on volume, not price.

## Publishing checklist

0. **Final store name:** Threefold Arsenal. Project name, title screen, package
   filenames, bundle ID, product metadata, and store copy use the same branding.
   Exact-title storefront searches found no current game collision; do a formal
   trademark check before a larger commercial launch.
1. **Export templates:** the official Godot 4.7-stable templates are installed
   on this build Mac. On a new machine, use Godot editor → Editor → Manage
   Export Templates and install the templates matching the editor version.
2. **Web build** (primary — plays in browser, most itch traffic): upload
   `build/ThreefoldArsenal-Web.zip` and tick "This file will be played in the
   browser". Its `index.html` is at the archive root.
3. **Desktop builds:** upload `build/macos/ThreefoldArsenal.zip` for macOS and
   `build/windows/ThreefoldArsenal-Windows-x86_64.zip` for Windows.
4. **Page assets:** capture 3–5 GIFs/screenshots — title, each biome, a boss
   fight, the upgrades menu. 630×500 cover image.
5. **Butler** (optional, for updates): `butler push build/web user/threefold-arsenal:web`.

The current v1.1.0 Web, macOS, and Windows packages were exported and validated
with Godot 4.7-stable. The macOS package is ad-hoc signed; Apple notarization and
Windows code signing require your own developer certificates before a signed
store release.

## Post-launch content ideas (roadmap for paid tier)
- Chapters 4–6 (new biomes: Verdant Overgrowth, Void Sanctum…)
- 2 more heroes (Mage: blink instead of dash; Engineer: deployable turret)
- Daily-seed challenge runs + local leaderboard
- Steam release once content justifies $4.99 (needs Steamworks SDK export)
