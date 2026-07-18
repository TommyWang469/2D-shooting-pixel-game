extends Enemy
## Slow, steady chaser that bounces toward the player.


func _ready() -> void:
	max_hp = 3
	speed = 42.0
	contact_damage = 1
	coin_min = 1
	coin_max = 2
	heart_chance = 0.14
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.47, 0.84, 0.35)
	super._ready()
	_scale_to_difficulty()


func _scale_to_difficulty() -> void:
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp
	speed *= (0.9 + (d - 1.0) * 0.12)


func _load_texture() -> void:
	sprite.texture = load("res://assets/slime.png")


func _ai_velocity(_delta: float) -> Vector2:
	return (player.global_position - global_position).normalized() * speed


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.15:
		_anim_time = 0.0
		_frame = (_frame + 1) % 3
	sprite.frame = _frame
