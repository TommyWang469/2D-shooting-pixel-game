extends Enemy
## Fast, erratic flyer. Weaves toward the player with a sine wobble.

var _t := 0.0


func _ready() -> void:
	max_hp = 2
	speed = 70.0
	contact_damage = 1
	contact_range = 11.0
	coin_min = 1
	coin_max = 1
	heart_chance = 0.10
	sheet_hframes = 3
	death_frame = 2
	super._ready()


func _load_texture() -> void:
	sprite.texture = load("res://assets/bat.png")


func _ai(delta: float) -> void:
	_t += delta
	var to := (player.global_position - global_position).normalized()
	var perp := Vector2(-to.y, to.x)
	velocity = (to + perp * sin(_t * 6.0) * 0.6).normalized() * speed


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.12:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	sprite.frame = _frame
