extends Resource
class_name Weapon
## Weapon stats for one upgrade tier. Built via Weapon.for_tier(). Player asks the
## weapon for its fire rate / damage / spread pattern when shooting.

@export var display_name := "Blaster"
@export var damage := 1
@export var fire_rate := 4.0        ## shots per second
@export var bullet_speed := 320.0
@export var spread_deg := 5.0       ## random jitter per shot
@export var shots := 1              ## bullets per trigger pull

const MAX_TIER := 2
const UPGRADE_COST := [0, 15, 30]   ## coin cost to REACH tier index


static func for_tier(tier: int) -> Weapon:
	var w := Weapon.new()
	match tier:
		0:
			w.display_name = "Blaster"
			w.damage = 1
			w.fire_rate = 4.0
			w.bullet_speed = 320.0
			w.spread_deg = 5.0
			w.shots = 1
		1:
			w.display_name = "Rapid Blaster"
			w.damage = 2
			w.fire_rate = 8.0
			w.bullet_speed = 360.0
			w.spread_deg = 7.0
			w.shots = 1
		_:
			w.display_name = "Triple Shot"
			w.damage = 2
			w.fire_rate = 6.0
			w.bullet_speed = 380.0
			w.spread_deg = 6.0
			w.shots = 3
	return w


## Returns the angle offsets (radians) for each bullet in one shot.
func shot_angles() -> Array[float]:
	var out: Array[float] = []
	if shots == 1:
		out.append(0.0)
	else:
		var fan := deg_to_rad(16.0)
		var start := -fan * 0.5
		var step := fan / float(shots - 1)
		for i in shots:
			out.append(start + step * i)
	return out
