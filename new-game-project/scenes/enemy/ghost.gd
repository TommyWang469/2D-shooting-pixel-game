extends Enemy
## Frost biome: a phantom that drifts straight through walls and obstacles, fading
## in and out as it closes in. Slow but relentless — and it hits hard.

var _t := 0.0


func _ready() -> void:
	max_hp = 3
	speed = 40.0
	contact_damage = 2
	contact_range = 11.0
	coin_chance = 0.55
	coin_min = 1
	coin_max = 2
	heart_chance = 0.12
	sheet_hframes = 3
	death_frame = 2
	body_color = Color(0.75, 0.85, 1.0)
	super._ready()
	collision_mask = 0            # phases through the world
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp


func _load_texture() -> void:
	sprite.texture = load("res://assets/ghost.png")


func _ai_velocity(delta: float) -> Vector2:
	_t += delta
	# straight-line haunt: walls mean nothing to it
	return (player.global_position - global_position).normalized() * speed


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.22:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	sprite.frame = _frame
	# spectral fade pulse (layered on top of the theme tint)
	sprite.modulate.a = 0.55 + sin(_t * 3.2) * 0.3
	if player and is_instance_valid(player):
		sprite.flip_h = player.global_position.x < global_position.x
