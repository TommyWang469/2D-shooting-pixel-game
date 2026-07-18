extends Enemy
## Ember biome: horned devil that stalks the player, crouches for a beat, then
## lunges in a fast dash. Vulnerable while recovering.

const LUNGE_RANGE := 78.0
const LUNGE_SPEED := 265.0

var _state := "stalk"      # stalk / windup / lunge / recover
var _timer := 0.0
var _lunge_dir := Vector2.ZERO


func _ready() -> void:
	max_hp = 3
	speed = 58.0
	contact_damage = 1
	coin_chance = 0.6
	coin_min = 1
	coin_max = 2
	heart_chance = 0.1
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.92, 0.47, 0.24)
	super._ready()
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp


func _load_texture() -> void:
	sprite.texture = load("res://assets/imp.png")


func _ai_velocity(delta: float) -> Vector2:
	_timer -= delta
	match _state:
		"stalk":
			var to := player.global_position - global_position
			if to.length() < LUNGE_RANGE:
				_state = "windup"
				_timer = 0.38
				return Vector2.ZERO
			return to.normalized() * speed
		"windup":
			if _timer <= 0.0:
				_state = "lunge"
				_timer = 0.26
				_lunge_dir = (player.global_position - global_position).normalized()
				Audio.play("dash", 0.15, -8.0)
			return Vector2.ZERO
		"lunge":
			if _timer <= 0.0:
				_state = "recover"
				_timer = 0.7
			return _lunge_dir * LUNGE_SPEED
		_:
			if _timer <= 0.0:
				_state = "stalk"
			return Vector2.ZERO
	return Vector2.ZERO


func _animate(delta: float) -> void:
	if _state == "windup":
		sprite.frame = 2
		return
	_anim_time += delta
	if _anim_time >= 0.14:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	sprite.frame = _frame
	if player and is_instance_valid(player):
		sprite.flip_h = player.global_position.x < global_position.x
