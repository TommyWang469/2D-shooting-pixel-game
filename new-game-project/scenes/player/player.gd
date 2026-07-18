extends CharacterBody2D
## The player. Applies the chosen character's stats/skill, then handles movement, aim,
## dash (i-frames + trail), shooting, HP with knockback, and weapon swapping via
## ground pickups. Full juice: shake, hit-stop, sound, particles, floating numbers.

signal hp_changed(current: int, maximum: int)
signal weapons_changed(names: Array, index: int, slots: int)
signal dash_changed(ready_ratio: float)

const DASH_SPEED := 330.0
const DASH_TIME := 0.16
const IFRAME_TIME := 0.8
const MUZZLE_DIST := 9.0
const KNOCK_DECAY := 620.0
const MAX_HP_CAP := 12
const JOY_AIM_DEADZONE := 0.35

const BULLET := preload("res://scenes/bullet/bullet.tscn")
const FLOAT := preload("res://scenes/fx/floating_text.tscn")
const BURST := preload("res://scenes/fx/burst.tscn")
const WEAPON_PICKUP := preload("res://scenes/pickup/weapon_pickup.tscn")

const IDLE_FRAMES := [0, 1, 2, 3]
const WALK_FRAMES := [4, 5, 6, 7]

var max_hp := 4
var hp := 4
var weapon: Weapon                      ## currently equipped (weapons[weapon_index])
var weapons: Array[Weapon] = []         ## carried weapons
var weapon_index := 0
var max_weapon_slots := 1               ## buy more at the boss-room Workshop
var aim_dir := Vector2.RIGHT

# character-derived stats
var _speed := 118.0
var _dash_cooldown := 0.85
var _fire_rate_mult := 1.0
var _tint := Color.WHITE
var _skill_id := ""

# skill state
var _overdrive := 0.0            # gunner: fire-rate burst after dash
var _ambush := 0.0               # rogue: 3x-damage window after dash
var _bash_hits: Array = []       # knight: enemies already hit this dash

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
var _use_joy_aim := false
var _last_mouse_pos := Vector2.INF

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	sprite.texture = load("res://assets/player.png")
	sprite.hframes = 8
	if has_node("Shadow"):
		$Shadow.texture = load("res://assets/shadow.png")
	_muzzle_tex = load("res://assets/muzzle.png")
	_apply_character()
	GameManager.bonus_life.connect(_on_bonus_life)
	hp_changed.emit(hp, max_hp)
	_emit_weapons()
	dash_changed.emit(1.0)


func _apply_character() -> void:
	var ch := Character.get_data(GameManager.character_id)
	sprite.texture = load(ch.get("sprite", "res://assets/player.png"))
	max_hp = ch["max_hp"]
	hp = max_hp
	_speed = ch["speed"]
	_dash_cooldown = ch["dash_cooldown"]
	_fire_rate_mult = ch["fire_rate_mult"]
	_skill_id = ch.get("skill_id", "")
	_tint = ch["tint"]
	sprite.modulate = _tint
	weapons = [Weapon.by_id(ch["start_weapon"])]
	weapon_index = 0
	weapon = weapons[0]


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		return

	_update_aim()
	sprite.flip_h = aim_dir.x < 0.0

	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_vec
		_spawn_ghost(delta)
		if _skill_id == "bash":
			_bash_sweep()
	else:
		velocity = input.normalized() * _speed
		if _dash_cd <= 0.0 and Input.is_action_just_pressed("dash"):
			_start_dash(input)

	velocity += _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)

	_update_timers(delta)

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("swap_weapon"):
		_cycle_weapon()

	if Input.is_action_pressed("shoot") and _fire_cd <= 0.0 and _dash_time <= 0.0:
		_fire()
		var rate := weapon.fire_rate * _fire_rate_mult
		if _overdrive > 0.0:
			rate *= 2.0
		_fire_cd = 1.0 / rate

	_animate(delta, input.length() > 0.1)


## Mouse aims by default; the right stick takes over while it's pushed, and keeps
## priority until the mouse actually moves again (last-used-device wins).
func _update_aim() -> void:
	var joy := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var mouse_screen := get_viewport().get_mouse_position()
	if joy.length() > JOY_AIM_DEADZONE:
		aim_dir = joy.normalized()
		_use_joy_aim = true
	elif _use_joy_aim and _last_mouse_pos != Vector2.INF \
			and mouse_screen.distance_to(_last_mouse_pos) > 6.0:
		_use_joy_aim = false
	if not _use_joy_aim:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 1.0:
			aim_dir = to_mouse.normalized()
	_last_mouse_pos = mouse_screen


func _update_timers(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta
		dash_changed.emit(clampf(1.0 - _dash_cd / _dash_cooldown, 0.0, 1.0))
		if _dash_cd <= 0.0:
			dash_changed.emit(1.0)
	if _invincible > 0.0:
		_invincible -= delta
		sprite.visible = int(_invincible * 20) % 2 == 0
	else:
		sprite.visible = true
	if _fire_cd > 0.0:
		_fire_cd -= delta
	if _overdrive > 0.0:
		_overdrive -= delta
	if _ambush > 0.0:
		_ambush -= delta


func _start_dash(input: Vector2) -> void:
	var dir := input.normalized() if input.length() > 0.1 else aim_dir
	_dash_vec = dir * DASH_SPEED
	_dash_time = DASH_TIME
	_dash_cd = _dash_cooldown
	_invincible = maxf(_invincible, DASH_TIME + 0.06)
	Audio.play("dash", 0.1, -3.0)
	Juice.shake(0.12)
	dash_changed.emit(0.0)
	# hero skill triggers
	match _skill_id:
		"overdrive":
			_overdrive = 1.6
			_spawn_float("OVERDRIVE!", Color(1.0, 0.85, 0.3), 12)
		"ambush":
			_ambush = 1.6
		"bash":
			_bash_hits.clear()


## Knight skill: dashing smashes through enemies — damage + heavy knockback.
func _bash_sweep() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or _bash_hits.has(e):
			continue
		if global_position.distance_to(e.global_position) < 16.0:
			_bash_hits.append(e)
			if e.has_method("take_damage"):
				e.take_damage(2)
			if e.has_method("apply_knockback"):
				e.apply_knockback(_dash_vec.normalized() * 220.0)
			Juice.shake(0.15)


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
	g.modulate = Color(_tint.r * 0.7, _tint.g * 0.85, 1.0, 0.5)
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
	var dmg := weapon.damage
	if _ambush > 0.0:                       # rogue: ambush strike
		dmg *= 3
		_ambush = 0.0
		_spawn_float("AMBUSH x3!", Color(0.7, 1.0, 0.6), 12)
	for a in weapon.shot_angles():
		var jitter := deg_to_rad(randf_range(-weapon.spread_deg, weapon.spread_deg))
		var dir := aim_dir.rotated(a + jitter)
		var b := BULLET.instantiate()
		b.setup(dir, weapon.bullet_speed, dmg, weapon.bullet_options())
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


## Returns false once the HP cap is reached (shrine uses this to refuse the sale).
func gain_max_hp() -> bool:
	if max_hp >= MAX_HP_CAP:
		return false
	max_hp += 1
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	Audio.play("heart", 0.05, 2.0)
	_spawn_float("+1 LIFE", Color(1.0, 0.8, 0.3), 14)
	_pickup_pop(Color(1.0, 0.5, 0.6))
	return true


func _on_bonus_life() -> void:
	# At the cap the kill milestone still rewards a full heal.
	if not gain_max_hp():
		heal(max_hp)


func switch_weapon(new_weapon: Weapon) -> void:
	weapons[weapon_index] = new_weapon
	weapon = new_weapon
	_emit_weapons()
	Audio.play("upgrade")
	Juice.shake(0.2)
	_spawn_float(weapon.display_name + "!", Color(1.0, 0.9, 0.4), 14)
	_pickup_pop(weapon.bullet_color)


## Q / Tab: cycle through carried weapons.
func _cycle_weapon() -> void:
	if weapons.size() < 2:
		return
	weapon_index = (weapon_index + 1) % weapons.size()
	weapon = weapons[weapon_index]
	_emit_weapons()
	Audio.play("click", 0.08, -4.0)
	_spawn_float(weapon.display_name, weapon.bullet_color, 12)


## Workshop purchase: carry one more weapon (max 3 slots).
func add_weapon_slot() -> bool:
	if max_weapon_slots >= 3:
		return false
	max_weapon_slots += 1
	_emit_weapons()
	_spawn_float("+1 WEAPON SLOT", Color(0.6, 0.9, 1.0), 14)
	_pickup_pop(Color(0.6, 0.9, 1.0))
	return true


func weapon_ids() -> Array:
	var out := []
	for w in weapons:
		out.append(w.id)
	return out


func _emit_weapons() -> void:
	var names := []
	for w in weapons:
		names.append(w.display_name)
	weapons_changed.emit(names, weapon_index, max_weapon_slots)


## Little flourish when equipping / buying: a burst + a scale-pop on the sprite.
func _pickup_pop(color: Color) -> void:
	var b := BURST.instantiate()
	var world := get_tree().current_scene
	if world:
		world.add_child(b)
		b.global_position = global_position
		b.burst(color, 14, 90.0)
	var tw := sprite.create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.08).from(Vector2.ONE)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func weapon_power() -> int:
	return weapon.power if weapon else 1


func weapon_id() -> String:
	return weapon.id if weapon else "blaster"


## Interact with the nearest thing in range (weapon on the ground, shop station).
func _try_interact() -> void:
	var best: Node = null
	var best_d := 1.0e9
	for it in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(it) or not it.has_method("player_near"):
			continue
		if not it.player_near():
			continue
		var d := global_position.distance_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	if best and best.has_method("interact"):
		best.interact(self)


## Take a weapon from the ground. With a free slot it's simply added; with full
## slots it swaps with the current weapon, dropping it where the new one lay.
func take_weapon_from(pickup: Node) -> void:
	var new_weapon: Weapon = pickup.weapon
	var pos: Vector2 = pickup.global_position
	pickup.queue_free()
	if weapons.size() < max_weapon_slots:
		weapons.append(new_weapon)
		weapon_index = weapons.size() - 1
		weapon = new_weapon
		_emit_weapons()
		Audio.play("upgrade")
		_spawn_float(new_weapon.display_name + "!", Color(1.0, 0.9, 0.4), 14)
		_pickup_pop(new_weapon.bullet_color)
	else:
		var old_weapon := weapon
		switch_weapon(new_weapon)
		drop_weapon(old_weapon, pos)


func drop_weapon(w: Weapon, pos: Vector2) -> void:
	if w == null:
		return
	var wp := WEAPON_PICKUP.instantiate()
	var world := get_tree().current_scene
	if world == null:
		return
	world.add_child(wp)
	wp.global_position = pos
	wp.set_weapon(w)


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
