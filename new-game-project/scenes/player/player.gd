extends CharacterBody2D
## The player: WASD movement, mouse aim, animated pixel sprite, HP with i-frames,
## and a weapon that fires toward the cursor. Gains max HP from GameManager's
## bonus_life milestone and buys weapon upgrades from crates.

signal hp_changed(current: int, maximum: int)
signal weapon_changed(display_name: String)

const SPEED := 120.0
const BULLET := preload("res://scenes/bullet/bullet.tscn")
const IFRAME_TIME := 0.8
const MUZZLE_DIST := 9.0

# animation frame bands in player.png (8 frames)
const IDLE_FRAMES := [0, 1, 2, 3]
const WALK_FRAMES := [4, 5, 6, 7]

var max_hp := 4
var hp := 4
var weapon_tier := 0
var weapon: Weapon
var aim_dir := Vector2.RIGHT

var _invincible := 0.0
var _fire_cooldown := 0.0
var _anim_time := 0.0
var _frame_index := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	sprite.texture = load("res://assets/player.png")
	sprite.hframes = 8
	weapon = Weapon.for_tier(weapon_tier)
	GameManager.bonus_life.connect(_on_bonus_life)
	hp_changed.emit(hp, max_hp)
	weapon_changed.emit(weapon.display_name)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	# --- movement ---
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	velocity = input.normalized() * SPEED
	move_and_slide()

	# --- aim ---
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		aim_dir = to_mouse.normalized()
	sprite.flip_h = aim_dir.x < 0.0

	# --- timers ---
	if _invincible > 0.0:
		_invincible -= delta
		sprite.visible = int(_invincible * 20) % 2 == 0   # blink
	else:
		sprite.visible = true

	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta
	if Input.is_action_pressed("shoot") and _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown = 1.0 / weapon.fire_rate

	_animate(delta, input.length() > 0.1)


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
	for a in weapon.shot_angles():
		var jitter := deg_to_rad(randf_range(-weapon.spread_deg, weapon.spread_deg))
		var dir := aim_dir.rotated(a + jitter)
		var b := BULLET.instantiate()
		b.global_position = muzzle
		b.setup(dir, weapon.bullet_speed, weapon.damage)
		_spawn_into_world(b)


func _spawn_into_world(node: Node) -> void:
	var world := get_tree().current_scene
	if world:
		world.add_child(node)
	else:
		get_parent().add_child(node)


func take_damage(amount: int) -> void:
	if _invincible > 0.0 or GameManager.is_game_over:
		return
	hp = max(0, hp - amount)
	_invincible = IFRAME_TIME
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		GameManager.trigger_game_over()


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)


func _on_bonus_life() -> void:
	max_hp += 1
	hp = max_hp                 # full heal on milestone
	hp_changed.emit(hp, max_hp)


## Called by a weapon crate. Returns true if an upgrade was purchased.
func try_buy_upgrade() -> bool:
	if weapon_tier >= Weapon.MAX_TIER:
		return false
	var cost: int = Weapon.UPGRADE_COST[weapon_tier + 1]
	if GameManager.spend_coins(cost):
		weapon_tier += 1
		weapon = Weapon.for_tier(weapon_tier)
		weapon_changed.emit(weapon.display_name)
		return true
	return false
