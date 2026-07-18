extends RefCounted
class_name Character
## Playable characters. Each has different stats, a starting weapon, and a colour tint
## so they read differently. The chosen id lives on GameManager and is applied by the
## player on spawn.

const CATALOG := {
	"gunner": {
		"display_name": "Gunner",
		"skill": "OVERDRIVE — dashing doubles fire rate for 1.6s. +25% base fire rate.",
		"skill_id": "overdrive",
		"max_hp": 4,
		"speed": 118.0,
		"dash_cooldown": 0.85,
		"fire_rate_mult": 1.25,
		"start_weapon": "blaster",
		"tint": Color(1.0, 1.0, 1.0),
		"sprite": "res://assets/player.png",
	},
	"knight": {
		"display_name": "Knight",
		"skill": "SHIELD BASH — dashing smashes enemies aside (damage + heavy knockback). +2 max HP.",
		"skill_id": "bash",
		"max_hp": 6,
		"speed": 104.0,
		"dash_cooldown": 1.15,
		"fire_rate_mult": 1.0,
		"start_weapon": "shotgun",
		"tint": Color(1.0, 1.0, 1.0),
		"sprite": "res://assets/knight.png",
	},
	"rogue": {
		"display_name": "Rogue",
		"skill": "AMBUSH — first shot after a dash deals 3x damage. Fast, rapid dashes, 3 HP.",
		"skill_id": "ambush",
		"max_hp": 3,
		"speed": 140.0,
		"dash_cooldown": 0.5,
		"fire_rate_mult": 1.1,
		"start_weapon": "smg",
		"tint": Color(1.0, 1.0, 1.0),
		"sprite": "res://assets/rogue.png",
	},
}

const ORDER := ["gunner", "knight", "rogue"]


static func get_data(id: String) -> Dictionary:
	return CATALOG.get(id, CATALOG["gunner"])
