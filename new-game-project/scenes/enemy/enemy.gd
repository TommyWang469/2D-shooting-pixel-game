extends CharacterBody2D
class_name Enemy
## Base enemy: HP, hit-flash, knockback, contact damage, death drops + juice
## (particles, sound, shake, hit-stop, damage numbers). Subclasses return a desired
## velocity from _ai_velocity() and set their looks in _load_texture()/_animate().

const PICKUP := preload("res://scenes/pickup/pickup.tscn")
const BURST := preload("res://scenes/fx/burst.tscn")
const FLOAT := preload("res://scenes/fx/floating_text.tscn")
const KNOCKBACK_DECAY := 320.0

@export var max_hp := 3
@export var speed := 42.0
@export var contact_damage := 1
@export var contact_range := 12.0
@export var coin_chance := 0.6
@export var coin_min := 1
@export var coin_max := 2
@export var heart_chance := 0.12
@export var sheet_hframes := 4
@export var death_frame := 3
@export var body_color := Color(0.5, 0.85, 0.4)
@export var gem_min := 0          ## gems dropped on death (elites and bosses)
@export var gem_max := 0

var hp := 3
var elite := false                ## golden variant: tanky, fast, drops gems
var base_tint := Color.WHITE      ## theme tint, set via apply_theme()
var player: Node2D
var _slow_mult := 1.0             ## Frost Bow chill: velocity factor while slowed
var _slow_t := 0.0
var _knockback := Vector2.ZERO
var _hit_flash := 0.0
var _contact_cd := 0.0
var _anim_time := 0.0
var _frame := 0
var _dying := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	sprite.hframes = sheet_hframes
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	_load_texture()
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		return
	var move := Vector2.ZERO
	if player and is_instance_valid(player):
		move = _ai_velocity(delta)
	if _slow_t > 0.0:
		_slow_t -= delta
		move *= _slow_mult
		if _slow_t <= 0.0:
			_slow_mult = 1.0
	velocity = move + _knockback
	move_and_slide()
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	_tick(delta)


# --- overridable hooks -------------------------------------------------------
func _ai_velocity(_delta: float) -> Vector2:
	return Vector2.ZERO


func _load_texture() -> void:
	pass


func _animate(_delta: float) -> void:
	pass


# --- shared per-frame logic --------------------------------------------------
func _tick(delta: float) -> void:
	if _contact_cd > 0.0:
		_contact_cd -= delta
	if player and is_instance_valid(player) and not GameManager.is_game_over:
		if global_position.distance_to(player.global_position) < contact_range and _contact_cd <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage, global_position)
				_contact_cd = 0.5

	if _hit_flash > 0.0:
		_hit_flash -= delta
		sprite.modulate = Color(2.2, 2.2, 2.2)
	elif _slow_t > 0.0:
		sprite.modulate = base_tint.lerp(Color(0.55, 0.8, 1.3), 0.5)   # chilled
	else:
		sprite.modulate = base_tint

	_animate(delta)


## Called by the Dungeon right after spawning: biome tint + stat multipliers.
func apply_theme(tint: Color, hp_mult: float, speed_mult: float) -> void:
	base_tint = tint
	sprite.modulate = tint
	max_hp = maxi(1, int(round(max_hp * hp_mult)))
	hp = max_hp
	speed *= speed_mult
	body_color = body_color.lerp(tint, 0.5)


## Promote to a golden elite: tanky, faster, bigger — and guaranteed gems.
func make_elite() -> void:
	elite = true
	max_hp = maxi(2, int(round(max_hp * 2.2)))
	hp = max_hp
	speed *= 1.15
	scale *= 1.25
	coin_min += 2
	coin_max += 3
	gem_min = maxi(gem_min, 1)
	gem_max = maxi(gem_max, 2)
	base_tint = base_tint.lerp(Color(1.0, 0.85, 0.3), 0.55)
	sprite.modulate = base_tint
	body_color = Color(1.0, 0.85, 0.3)


## Frost Bow chill: cap the enemy's movement for a moment (stacks refresh, not add).
func apply_slow(mult: float, dur: float) -> void:
	_slow_mult = minf(_slow_mult if _slow_t > 0.0 else 1.0, mult)
	_slow_t = maxf(_slow_t, dur)


func apply_knockback(impulse: Vector2) -> void:
	_knockback += impulse
	if _knockback.length() > 280.0:
		_knockback = _knockback.normalized() * 280.0


func take_damage(amount: int) -> void:
	if _dying:
		return
	hp -= amount
	_hit_flash = 0.1
	Audio.play("hit", 0.12, -5.0)
	_spawn_float(str(amount), Color(1.0, 0.95, 0.55), 20)
	if hp <= 0:
		_die()


func _die() -> void:
	_dying = true
	set_physics_process(false)
	remove_from_group("enemies")
	GameManager.register_kill()
	# Deferred: death often happens inside a bullet's physics callback, where
	# spawning pickup Areas would be rejected by the physics server.
	call_deferred("_drop_loot")
	_spawn_burst(body_color, 12, 95.0)
	Audio.play("die")
	Juice.shake(0.22)
	Juice.hitstop(0.06, 0.05)
	velocity = Vector2.ZERO
	sprite.modulate = base_tint
	sprite.frame = death_frame
	# Guarded free: something else (room sweep) may have freed us mid-corpse.
	get_tree().create_timer(0.25, false).timeout.connect(func():
		if is_instance_valid(self):
			queue_free())


func _drop_loot() -> void:
	# Coins and hearts roll independently and scatter randomly around the corpse.
	# The Fortune upgrade raises the coin odds; gems only come from elites/bosses.
	var cc := minf(coin_chance * (1.0 + 0.2 * Save.upgrade_level("fortune")), 1.0)
	if randf() < cc:
		var count := randi_range(coin_min, coin_max)
		for i in count:
			_spawn_pickup("coin", 1, _rand_offset(18.0))
	for i in randi_range(gem_min, gem_max):
		_spawn_pickup("gem", 1, _rand_offset(16.0))
	if randf() < heart_chance:
		_spawn_pickup("heart", 1, _rand_offset(14.0))


func _rand_offset(radius: float) -> Vector2:
	var ang := randf() * TAU
	var dist := sqrt(randf()) * radius
	return Vector2(cos(ang), sin(ang)) * dist


func _spawn_pickup(kind: String, value: int, offset: Vector2) -> void:
	var p := PICKUP.instantiate()
	p.kind = kind
	p.value = value
	var world := get_tree().current_scene
	if world:
		world.add_child(p)
		p.global_position = global_position + offset


func _spawn_burst(color: Color, amount: int, spd: float) -> void:
	var b := BURST.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(b)
		b.global_position = global_position
		b.burst(color, amount, spd)


func _spawn_float(text: String, color: Color, size := 12) -> void:
	var f := FLOAT.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(f)
		f.global_position = global_position + Vector2(0, -10)
		f.setup(text, color, 24.0, size)
