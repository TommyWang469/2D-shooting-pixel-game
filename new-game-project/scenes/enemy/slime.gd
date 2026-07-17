extends Enemy
## Slow, steady chaser. Bounces toward the player.


func _ready() -> void:
	max_hp = 3
	speed = 42.0
	contact_damage = 1
	coin_min = 1
	coin_max = 2
	heart_chance = 0.14
	sheet_hframes = 4
	death_frame = 3
	super._ready()


func _load_texture() -> void:
	sprite.texture = load("res://assets/slime.png")


func _ai(_delta: float) -> void:
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.15:
		_anim_time = 0.0
		_frame = (_frame + 1) % 3
	sprite.frame = _frame
