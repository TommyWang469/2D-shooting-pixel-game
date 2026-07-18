extends Enemy
## Ranged caster. Keeps its distance, strafes, and lobs enemy bullets at the player.

const EBULLET := preload("res://scenes/bullet/enemy_bullet.tscn")
const DESIRED_DIST := 135.0

var _shoot_cd := 1.5
var _cast := 0.0
var _strafe := 0.0


func _ready() -> void:
	max_hp = 4
	speed = 50.0
	contact_damage = 1
	coin_chance = 0.75
	coin_min = 2
	coin_max = 3
	heart_chance = 0.16
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.5, 0.55, 0.9)
	super._ready()
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp
	_shoot_cd = randf_range(0.6, 1.4)


func _load_texture() -> void:
	sprite.texture = load("res://assets/mage.png")


func _ai_velocity(delta: float) -> Vector2:
	_strafe += delta
	var to := player.global_position - global_position
	var dist := to.length()
	var dir := to.normalized()
	var move := Vector2.ZERO
	if dist < DESIRED_DIST - 20.0:
		move = -dir * speed
	elif dist > DESIRED_DIST + 30.0:
		move = dir * speed
	else:
		var perp := Vector2(-dir.y, dir.x)
		move = perp * speed * 0.6 * sin(_strafe * 2.0)

	_shoot_cd -= delta
	if _shoot_cd <= 0.0 and not GameManager.is_game_over:
		_shoot(dir)
		# floor keeps deep endless chapters dodgeable
		_shoot_cd = maxf(randf_range(1.4, 2.2) / GameManager.difficulty(), 0.55)
		_cast = 0.25
	return move


func _shoot(dir: Vector2) -> void:
	var b := EBULLET.instantiate()
	var world := get_tree().current_scene
	if world == null:
		return
	world.add_child(b)
	b.global_position = global_position
	b.setup(dir, 155.0, contact_damage)
	Audio.play("shoot", 0.1, -9.0)


func _animate(delta: float) -> void:
	if _cast > 0.0:
		_cast -= delta
		sprite.frame = 2
		return
	_anim_time += delta
	if _anim_time >= 0.3:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	sprite.frame = _frame
