extends RefCounted
class_name Character
## Playable characters. Each has different stats, a starting weapon, and a colour tint
## so they read differently. The chosen id lives on GameManager and is applied by the
## player on spawn.

const CATALOG := {
	"gunner": {
		"display_name": "Gunner",
		"skill": "Rapid Trigger — +25% fire rate, balanced all-rounder.",
		"max_hp": 4,
		"speed": 118.0,
		"dash_cooldown": 0.85,
		"fire_rate_mult": 1.25,
		"start_weapon": "blaster",
		"tint": Color(1.0, 1.0, 1.0),
	},
	"knight": {
		"display_name": "Knight",
		"skill": "Iron Body — +2 max HP and a shotgun, but slower and heavier dash.",
		"max_hp": 6,
		"speed": 104.0,
		"dash_cooldown": 1.15,
		"fire_rate_mult": 1.0,
		"start_weapon": "shotgun",
		"tint": Color(0.7, 0.85, 1.0),
	},
	"rogue": {
		"display_name": "Rogue",
		"skill": "Fleetfoot — fast, short dash cooldown, SMG. Glass cannon (3 HP).",
		"max_hp": 3,
		"speed": 140.0,
		"dash_cooldown": 0.5,
		"fire_rate_mult": 1.1,
		"start_weapon": "smg",
		"tint": Color(0.75, 1.0, 0.8),
	},
}

const ORDER := ["gunner", "knight", "rogue"]


static func get_data(id: String) -> Dictionary:
	return CATALOG.get(id, CATALOG["gunner"])
