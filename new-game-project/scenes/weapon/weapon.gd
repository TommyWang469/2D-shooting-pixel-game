extends Resource
class_name Weapon
## A weapon definition. Built from a catalog by id. Treasure chests hand the player a
## new weapon (a real switch, not just a stat bump). The player asks the weapon for
## its fire rate and per-shot angles, and passes bullet options through to bullets.

@export var id := "blaster"
@export var display_name := "Blaster"
@export var damage := 1
@export var fire_rate := 4.0        ## shots per second
@export var bullet_speed := 320.0
@export var spread_deg := 5.0       ## random jitter per bullet
@export var shots := 1              ## bullets per trigger pull
@export var fan_deg := 0.0          ## total angular fan for multi-shot
@export var pierce := 0             ## extra enemies each bullet passes through
@export var knockback := 50.0
@export var bullet_scale := 1.0
@export var bullet_life := 1.4
@export var bullet_color := Color.WHITE
@export var power := 1              ## rough tier, used to weight chest drops

const START_ID := "blaster"

const CATALOG := {
	"blaster": {
		"display_name": "Blaster", "damage": 1, "fire_rate": 5.0, "bullet_speed": 320.0,
		"spread_deg": 4.0, "shots": 1, "fan_deg": 0.0, "pierce": 0, "knockback": 50.0,
		"bullet_scale": 1.0, "bullet_life": 1.4, "bullet_color": Color(1.0, 0.9, 0.4), "power": 1,
	},
	"smg": {
		"display_name": "SMG", "damage": 1, "fire_rate": 12.0, "bullet_speed": 380.0,
		"spread_deg": 9.0, "shots": 1, "fan_deg": 0.0, "pierce": 0, "knockback": 26.0,
		"bullet_scale": 0.85, "bullet_life": 1.1, "bullet_color": Color(0.5, 0.9, 1.0), "power": 2,
	},
	"triple": {
		"display_name": "Triple Shot", "damage": 2, "fire_rate": 5.0, "bullet_speed": 360.0,
		"spread_deg": 3.0, "shots": 3, "fan_deg": 22.0, "pierce": 0, "knockback": 50.0,
		"bullet_scale": 1.0, "bullet_life": 1.4, "bullet_color": Color(0.6, 1.0, 0.6), "power": 3,
	},
	"shotgun": {
		"display_name": "Shotgun", "damage": 1, "fire_rate": 2.2, "bullet_speed": 320.0,
		"spread_deg": 5.0, "shots": 6, "fan_deg": 40.0, "pierce": 0, "knockback": 110.0,
		"bullet_scale": 0.9, "bullet_life": 0.45, "bullet_color": Color(1.0, 0.7, 0.35), "power": 3,
	},
	"piercer": {
		"display_name": "Piercer", "damage": 2, "fire_rate": 6.0, "bullet_speed": 480.0,
		"spread_deg": 2.0, "shots": 1, "fan_deg": 0.0, "pierce": 5, "knockback": 20.0,
		"bullet_scale": 1.2, "bullet_life": 1.6, "bullet_color": Color(0.8, 0.6, 1.0), "power": 4,
	},
	"cannon": {
		"display_name": "Cannon", "damage": 5, "fire_rate": 1.6, "bullet_speed": 280.0,
		"spread_deg": 2.0, "shots": 1, "fan_deg": 0.0, "pierce": 1, "knockback": 180.0,
		"bullet_scale": 2.3, "bullet_life": 1.8, "bullet_color": Color(1.0, 0.5, 0.4), "power": 5,
	},
}

const CHEST_POOL := ["smg", "triple", "shotgun", "piercer", "cannon"]


static func by_id(weapon_id: String) -> Weapon:
	var w := Weapon.new()
	var data: Dictionary = CATALOG.get(weapon_id, CATALOG[START_ID])
	w.id = weapon_id
	for key in data:
		w.set(key, data[key])
	return w


static func starting() -> Weapon:
	return by_id(START_ID)


## Pick a chest weapon, biased toward something at least as strong as `current_power`
## and different from `avoid_id` when possible.
static func random_reward(current_power: int, avoid_id: String) -> Weapon:
	var choices: Array[String] = []
	for cid in CHEST_POOL:
		if cid == avoid_id:
			continue
		if CATALOG[cid]["power"] >= current_power:
			choices.append(cid)
	if choices.is_empty():
		for cid in CHEST_POOL:
			if cid != avoid_id:
				choices.append(cid)
	if choices.is_empty():
		choices = CHEST_POOL.duplicate()
	return by_id(choices[randi() % choices.size()])


## Angle offsets (radians) for each bullet in a single shot.
func shot_angles() -> Array[float]:
	var out: Array[float] = []
	if shots <= 1:
		out.append(0.0)
	else:
		var fan := deg_to_rad(fan_deg)
		var start := -fan * 0.5
		var step := fan / float(shots - 1)
		for i in shots:
			out.append(start + step * i)
	return out


## Options dictionary handed to Bullet.setup().
func bullet_options() -> Dictionary:
	return {
		"life": bullet_life,
		"pierce": pierce,
		"knockback": knockback,
		"scale": bullet_scale,
		"color": bullet_color,
	}
