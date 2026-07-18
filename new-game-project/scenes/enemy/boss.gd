extends Enemy
## Chapter boss. Big HP, chases the player, and cycles three attacks: a radial bullet
## ring, summoning adds, and a charge. Attacks speed up as its health drops. Emits
## health_changed (for the boss bar) and died (for the dungeon to advance).

signal health_changed(current: int, maximum: int)
signal died

const EBULLET := preload("res://scenes/bullet/enemy_bullet.tscn")
const SLIME := preload("res://scenes/enemy/slime.tscn")
const BAT := preload("res://scenes/enemy/bat.tscn")

var attack_weights: Array = [1.0, 1.0, 1.0]   ## ring, summon, charge — themed per biome

var _attack_cd := 2.5
var _state := "move"
var _charge_dir := Vector2.ZERO
var _charge_t := 0.0


func _ready() -> void:
	max_hp = 42
	speed = 34.0
	contact_damage = 2
	contact_range = 20.0
	coin_chance = 1.0
	coin_min = 18
	coin_max = 28
	heart_chance = 1.0
	sheet_hframes = 4
	death_frame = 3
	body_color = Color(0.5, 0.9, 0.5)
	super._ready()
	max_hp = int(round(max_hp * GameManager.difficulty()))
	hp = max_hp
	add_to_group("boss")
	call_deferred("emit_signal", "health_changed", hp, max_hp)


func _load_texture() -> void:
	sprite.texture = load("res://assets/boss.png")


func _ai_velocity(delta: float) -> Vector2:
	_attack_timer(delta)
	if _state == "charge":
		_charge_t -= delta
		if _charge_t <= 0.0:
			_state = "move"
		return _charge_dir * speed * 4.2
	return (player.global_position - global_position).normalized() * speed


func _attack_timer(delta: float) -> void:
	_attack_cd -= delta
	if _attack_cd <= 0.0 and not GameManager.is_game_over:
		_do_attack()
		var frac := float(hp) / float(max_hp)
		_attack_cd = lerpf(1.1, 2.8, frac)


func _do_attack() -> void:
	var total: float = attack_weights[0] + attack_weights[1] + attack_weights[2]
	var r := randf() * total
	if r < attack_weights[0]:
		_ring()
	elif r < attack_weights[0] + attack_weights[1]:
		_summon()
	else:
		_charge()


func _ring() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var n := 12
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * i / n)
		var b := EBULLET.instantiate()
		world.add_child(b)
		b.global_position = global_position
		b.setup(dir, 125.0, contact_damage)
	Audio.play("shoot", 0.05, -2.0)
	sprite.frame = 2


func _summon() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	for i in 2:
		var scene: PackedScene = SLIME if randf() < 0.5 else BAT
		var e := scene.instantiate()
		world.add_child(e)
		e.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))


func _charge() -> void:
	if player and is_instance_valid(player):
		_charge_dir = (player.global_position - global_position).normalized()
		_state = "charge"
		_charge_t = 0.5
		Juice.shake(0.2)


func _animate(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= 0.25:
		_anim_time = 0.0
		_frame = (_frame + 1) % 2
	if _state != "charge":
		sprite.frame = _frame


func take_damage(amount: int) -> void:
	if _dying:
		return
	super.take_damage(amount)
	health_changed.emit(maxi(hp, 0), max_hp)


func _die() -> void:
	died.emit()
	Juice.shake(0.9)
	Juice.hitstop(0.12, 0.12)
	_spawn_burst(body_color, 40, 170.0)
	super._die()
