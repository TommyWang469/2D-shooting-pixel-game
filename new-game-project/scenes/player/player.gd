extends CharacterBody2D
## The player: WASD movement, mouse aim, dash (with i-frames + afterimage trail),
## a switchable weapon, HP with knockback + i-frames, and full juice (shake, hit-stop,
## sound, particles, floating numbers). Weapons are swapped by treasure chests.

signal hp_changed(current: int, maximum: int)
signal weapon_changed(display_name: String)
signal dash_changed(ready_ratio: float)   ## 0 = just used, 1 = ready

const SPEED := 118.0
const DASH_SPEED := 330.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.85
const IFRAME_TIME := 0.8
const MUZZLE_DIST := 9.0
const KNOCK_DECAY := 620.0

const BULLET := preload("res://scenes/bullet/bullet.tscn")
const FLOAT := preload("res://scenes/fx/floating_text.tscn")

const IDLE_FRAMES := [0, 1, 2, 3]
const WALK_FRAMES := [4, 5, 6, 7]

var max_hp := 4
var hp := 4
var weapon: Weapon
var aim_dir := Vector2.RIGHT

var _invincible := 0.0
var _fire_cd := 0.0
var _dash_time := 0.0
var _dash_cd := 0.0
var _dash_vec := Vector2.ZERO
var _knock := Vector2.ZERO
var _ghost_cd := 0.0
var _anim_time := 0.0
var _frame_index := 0
var _muzzle_tex: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	sprite.texture = load("res://assets/player.png")
	sprite.hframes = 8
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	_muzzle_tex = load("res://assets/muzzle.png")
	weapon = Weapon.starting()
	GameManager.bonus_life.connect(_on_bonus_life)
	hp_changed.emit(hp, max_hp)
	weapon_changed.emit(weapon.display_name)
	dash_changed.emit(1.0)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		return

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		aim_dir = to_mouse.normalized()
	sprite.flip_h = aim_dir.x < 0.0

	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_vec
		_spawn_ghost(delta)
	else:
		velocity = input.normalized() * SPEED
		if _dash_cd <= 0.0 and Input.is_action_just_pressed("dash"):
			_start_dash(input)

	velocity += _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)

	_update_timers(delta)

	if Input.is_action_pressed("shoot") and _fire_cd <= 0.0 and _dash_time <= 0.0:
		_fire()
		_fire_cd = 1.0 / weapon.fire_rate

	_animate(delta, input.length() > 0.1)


func _update_timers(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta
		dash_changed.emit(clampf(1.0 - _dash_cd / DASH_COOLDOWN, 0.0, 1.0))
		if _dash_cd <= 0.0:
			dash_changed.emit(1.0)
	if _invincible > 0.0:
		_invincible -= delta
		sprite.visible = int(_invincible * 20) % 2 == 0
	else:
		sprite.visible = true
	if _fire_cd > 0.0:
		_fire_cd -= delta


func _start_dash(input: Vector2) -> void:
	var dir := input.normalized() if input.length() > 0.1 else aim_dir
	_dash_vec = dir * DASH_SPEED
	_dash_time = DASH_TIME
	_dash_cd = DASH_COOLDOWN
	_invincible = maxf(_invincible, DASH_TIME + 0.06)
	Audio.play("dash", 0.1, -3.0)
	Juice.shake(0.12)
	dash_changed.emit(0.0)


func _spawn_ghost(delta: float) -> void:
	_ghost_cd -= delta
	if _ghost_cd > 0.0:
		return
	_ghost_cd = 0.03
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.hframes = sprite.hframes
	g.frame = sprite.frame
	g.flip_h = sprite.flip_h
	g.z_index = -1
	var world := get_tree().current_scene
	if world == null:
		return
	world.add_child(g)
	g.global_position = global_position
	g.modulate = Color(0.6, 0.8, 1.0, 0.5)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)


func _animate(delta: float, moving: bool) -> void:
	_anim_time += delta
	var fps := 10.0 if moving else 4.0
	if _anim_time >= 1.0 / fps:
		_anim_time = 0.0
		_frame_index = (_frame_index + 1) % 4
	var band := WALK_FRAMES if moving else IDLE_FRAMES
	sprite.frame = band[_frame_index]


func _fire() -> void:
	var muzzle := global_position + aim_dir * MUZZLE_DIST
	var world := get_tree().current_scene
	if world == null:
		return
	for a in weapon.shot_angles():
		var jitter := deg_to_rad(randf_range(-weapon.spread_deg, weapon.spread_deg))
		var dir := aim_dir.rotated(a + jitter)
		var b := BULLET.instantiate()
		b.setup(dir, weapon.bullet_speed, weapon.damage, weapon.bullet_options())
		world.add_child(b)
		b.global_position = muzzle
	Audio.play("shoot", 0.08, -6.0)
	Juice.shake(0.05)
	_muzzle_flash(muzzle)


func _muzzle_flash(pos: Vector2) -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var m := Sprite2D.new()
	m.texture = _muzzle_tex
	m.hframes = 2
	m.frame = 0
	m.z_index = 1
	world.add_child(m)
	m.global_position = pos
	m.rotation = aim_dir.angle()
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector2(0.4, 0.4), 0.06).from(Vector2(1.2, 1.2))
	tw.parallel().tween_property(m, "modulate:a", 0.0, 0.06)
	tw.tween_callback(m.queue_free)


func take_damage(amount: int, source_pos = null) -> void:
	if _invincible > 0.0 or GameManager.is_game_over:
		return
	hp = maxi(0, hp - amount)
	_invincible = IFRAME_TIME
	hp_changed.emit(hp, max_hp)
	Audio.play("hurt")
	Juice.shake(0.5)
	Juice.hitstop(0.05, 0.08)
	_spawn_float("-%d" % amount, Color(1.0, 0.4, 0.4), 16)
	if source_pos != null:
		_knock = (global_position - source_pos).normalized() * 150.0
	if hp <= 0:
		_die()


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)
	Audio.play("heart")
	_spawn_float("+%d" % amount, Color(0.5, 1.0, 0.6), 14)


func _on_bonus_life() -> void:
	max_hp += 1
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	Audio.play("heart", 0.05, 2.0)
	_spawn_float("LIFE UP!", Color(1.0, 0.8, 0.3), 14)


func switch_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	weapon_changed.emit(weapon.display_name)
	Audio.play("upgrade")
	Juice.shake(0.2)
	_spawn_float(weapon.display_name + "!", Color(1.0, 0.9, 0.4), 14)


func weapon_power() -> int:
	return weapon.power if weapon else 1


func weapon_id() -> String:
	return weapon.id if weapon else "blaster"


func _die() -> void:
	Audio.play("gameover")
	Juice.shake(0.7)
	GameManager.trigger_game_over()


func _spawn_float(text: String, color: Color, size := 12) -> void:
	var f := FLOAT.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(f)
		f.global_position = global_position + Vector2(0, -12)
		f.setup(text, color, 26.0, size)
