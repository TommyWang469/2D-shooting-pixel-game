extends Enemy
## Ember biome: stationary magma turret. Opens its molten mouth and spits a 3-way
## spread at the player. Tanky and shrugs off most knockback.

const EBULLET := preload("res://scenes/bullet/enemy_bullet.tscn")

var _shoot_cd := 2.0
var _mouth := 0.0


func _ready() -> void:
	max_hp = 6
	speed = 0.0
	contact_damage = 1
	contact_range = 13.0
	coin_chance = 0.8
	coin_min = 2
	coin_max = 3
	heart_chance = 0.15
	sheet_hframes = 3
	death_frame = 2
	body_color = Color(0.72, 0.5, 0.4)
	super._ready()
	var d := GameManager.difficulty()
	max_hp = int(round(max_hp * (0.7 + d * 0.3)))
	hp = max_hp
	_shoot_cd = randf_range(1.0, 2.0)


func _load_texture() -> void:
	sprite.texture = load("res://assets/spitter.png")


func apply_knockback(impulse: Vector2) -> void:
	super.apply_knockback(impulse * 0.25)   # rooted in the rock


func _ai_velocity(delta: float) -> Vector2:
	_shoot_cd -= delta
	if _shoot_cd <= 0.0 and not GameManager.is_game_over:
		_spit()
		_shoot_cd = maxf(randf_range(1.9, 2.6) / sqrt(GameManager.difficulty()), 0.9)
	return Vector2.ZERO


func _spit() -> void:
	var world := get_tree().current_scene
	if world == null or player == null or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	for a in [-0.3, 0.0, 0.3]:
		var b := EBULLET.instantiate()
		world.add_child(b)
		b.global_position = global_position + dir * 6.0
		b.setup(dir.rotated(a), 140.0, contact_damage)
	Audio.play("shoot", 0.12, -9.0)
	_mouth = 0.35


func _animate(delta: float) -> void:
	if _mouth > 0.0:
		_mouth -= delta
		sprite.frame = 1
	else:
		sprite.frame = 0
